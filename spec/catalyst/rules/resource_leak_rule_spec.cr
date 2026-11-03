require "../../spec_helper"

# All members of this family share `ResourceLeakRule`; only the type they
# match, their ID and their severity differ. Copy-pasting one file and
# forgetting to change an ID is the obvious risk, so IDs and severities are
# asserted per rule as well as the shared detection behavior.
private def leak_rule(rule : Catalyst::Rule, code : String) : Int32
  run_rule(rule, code).size
end

private def all_leak_rules : Array(Catalyst::Rule)
  [
    Catalyst::Rules::FileOpenLeak.new.as(Catalyst::Rule),
    Catalyst::Rules::DirOpenLeak.new.as(Catalyst::Rule),
    Catalyst::Rules::DbOpenLeak.new.as(Catalyst::Rule),
    Catalyst::Rules::HttpClientLeak.new.as(Catalyst::Rule),
    Catalyst::Rules::TcpSocketLeak.new.as(Catalyst::Rule),
    Catalyst::Rules::TempfileLeak.new.as(Catalyst::Rule),
  ]
end

describe Catalyst::Rules::ResourceLeakRule do
  describe "identity" do
    it "uses a distinct rule ID per resource" do
      ids = all_leak_rules.map(&.id)
      ids.should eq(%w[CAT-025 CAT-026 CAT-029 CAT-028 CAT-013 CAT-027])
      ids.uniq.size.should eq(ids.size)
    end

    it "reports sockets as an error and other leaks as warnings or info" do
      Catalyst::Rules::TcpSocketLeak.new.severity.should eq("error")
      Catalyst::Rules::DirOpenLeak.new.severity.should eq("warning")
      Catalyst::Rules::FileOpenLeak.new.severity.should eq("info")
    end
  end

  describe "detection" do
    it "reports an unclosed File.open" do
      leak_rule(Catalyst::Rules::FileOpenLeak.new, %q(f = File.open("x"))).should eq(1)
    end

    it "reports an unclosed Dir.open" do
      leak_rule(Catalyst::Rules::DirOpenLeak.new, %q(d = Dir.open("x"))).should eq(1)
    end

    it "reports an unclosed DB.open" do
      leak_rule(Catalyst::Rules::DbOpenLeak.new, %q(db = DB.open("sqlite3://x"))).should eq(1)
    end

    it "reports an unclosed HTTP::Client" do
      leak_rule(Catalyst::Rules::HttpClientLeak.new, %q(c = HTTP::Client.new("example.com"))).should eq(1)
    end

    it "reports an unclosed TCPSocket" do
      leak_rule(Catalyst::Rules::TcpSocketLeak.new, %q(s = TCPSocket.new("host", 80))).should eq(1)
    end

    it "reports an unclosed Tempfile" do
      leak_rule(Catalyst::Rules::TempfileLeak.new, %q(t = Tempfile.new("x"))).should eq(1)
    end

    it "stays silent when the block form closes the resource" do
      leak_rule(Catalyst::Rules::FileOpenLeak.new, %q(File.open("x") { |f| f.gets })).should eq(0)
      leak_rule(Catalyst::Rules::TcpSocketLeak.new, %q(TCPSocket.new("host", 80) { |s| s.gets })).should eq(0)
    end

    it "ignores calls on a different type" do
      leak_rule(Catalyst::Rules::FileOpenLeak.new, %q(DB.open("x"))).should eq(0)
    end

    it "ignores a differently named method on the same type" do
      leak_rule(Catalyst::Rules::FileOpenLeak.new, %q(File.size("x"))).should eq(0)
    end

    # Reporting `new` followed by `close` on the next line was the largest
    # source of false positives when these rules ran on real projects: a
    # helper that opens a handle, closes it and returns a Bool is correct.
    it "stays silent when the enclosing method closes the resource" do
      code = <<-CRYSTAL
        def tcp_alive?(host : String, port : Int32) : Bool
          sock = TCPSocket.new(host, port)
          sock.close
          true
        rescue
          false
        end
        CRYSTAL
      leak_rule(Catalyst::Rules::TcpSocketLeak.new, code).should eq(0)
    end

    it "stays silent when the resource is closed on exit" do
      code = <<-CRYSTAL
        def connect
          d = ::DB.open("url")
          at_exit { d.close }
          d
        end
        CRYSTAL
      leak_rule(Catalyst::Rules::DbOpenLeak.new, code).should eq(0)
    end

    # The closing scan must not swallow a genuine leak in the same file.
    it "still reports a leak in a method that never closes it" do
      code = <<-CRYSTAL
        def connect
          d = ::DB.open("url")
          d
        end
        CRYSTAL
      leak_rule(Catalyst::Rules::DbOpenLeak.new, code).should eq(1)
    end

    it "reports a leak in a method alongside a clean factory" do
      code = <<-CRYSTAL
        def alive? : Bool
          sock = TCPSocket.new("h", 80)
          sock.close
          true
        end

        def leaky
          sock = TCPSocket.new("h", 80)
          sock
        end
        CRYSTAL
      leak_rule(Catalyst::Rules::TcpSocketLeak.new, code).should eq(1)
    end
  end
end # A factory hands the handle back and the caller owns it. Closing it
# inside would break the API, so these are not leaks.
it "ignores an acquire call returned by the enclosing method" do
  code = <<-CRYSTAL
    module Net
      def self.connect(host, port) : TCPSocket
        TCPSocket.new(host, port)
      end
    end
    CRYSTAL
  leak_rule(Catalyst::Rules::TcpSocketLeak.new, code).should eq(0)
end

# Without a declared return type the intent is not explicit, so the handle
# left on the last line keeps reporting.
it "reports a handle returned by a method with no declared type" do
  code = <<-CRYSTAL
    module Net
      def self.connect(host, port)
        TCPSocket.new(host, port)
      end
    end
    CRYSTAL
  leak_rule(Catalyst::Rules::TcpSocketLeak.new, code).should eq(1)
end

# The method body used to be found by counting `def`/`do`/`end` in the source
# text, which got three shapes wrong. Each of these reported code that closes
# its handle; all three are pinned here.
describe "method scope" do
  it "sees a close that follows a nested block" do
    # A `do` used to count as an opener, so the body ended at the block's
    # `end` and the `close` below it fell outside the scan.
    code = <<-CRYSTAL
      def run
        sock = TCPSocket.new("h", 80)
        3.times do |i|
          puts i
        end
        sock.close
      end
      CRYSTAL
    leak_rule(Catalyst::Rules::TcpSocketLeak.new, code).should eq(0)
  end

  it "recognises private def" do
    # `private def` was not matched, so the scan escaped into the neighbouring
    # method and reported a helper that closes its own file.
    code = <<-CRYSTAL
      private def helper
        file = File.open("x", "w")
        file.close
      end
      CRYSTAL
    leak_rule(Catalyst::Rules::FileOpenLeak.new, code).should eq(0)
  end

  it "reports a private def that really leaks" do
    code = <<-CRYSTAL
      private def helper
        file = File.open("x", "w")
        puts file
      end
      CRYSTAL
    leak_rule(Catalyst::Rules::FileOpenLeak.new, code).should eq(1)
  end

  it "does not depend on method order in the file" do
    # The reported line used to change when an unrelated method preceded the
    # leaking one, because the body scan started from the wrong place.
    first = <<-CRYSTAL
      def leaks
        sock = TCPSocket.new("h", 80)
        sock.read
      end
      CRYSTAL
    second = <<-CRYSTAL
      def other
        puts 1
      end

      def leaks
        sock = TCPSocket.new("h", 80)
        sock.read
      end
      CRYSTAL
    leak_rule(Catalyst::Rules::TcpSocketLeak.new, first).should eq(1)
    leak_rule(Catalyst::Rules::TcpSocketLeak.new, second).should eq(1)
  end
end
