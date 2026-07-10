require "../../spec_helper"

module Catalyst
  module Rules
    describe TcpSocketLeak do
      rule = TcpSocketLeak.new

      describe "#check" do
        it "detects bare TCPSocket.new with args" do
          assert_finding(rule, <<-CRYSTAL
            TCPSocket.new("example.com", 80)
            CRYSTAL
          )
        end

        it "detects TCPSocket.new assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            s = TCPSocket.new("example.com", 80)
            CRYSTAL
          )
        end

        it "detects TCPSocket.new even with .close call present" do
          assert_finding(rule, <<-CRYSTAL
            s = TCPSocket.new("example.com", 80)
            s.close
            CRYSTAL
          )
        end

        it "detects TCPSocket.new inside method without ensure" do
          assert_finding(rule, <<-CRYSTAL
            def fetch
              s = TCPSocket.new("example.com", 80)
              s.gets
              s.close
            end
            CRYSTAL
          )
        end

        it "detects TCPSocket.new inside method with ensure close" do
          assert_finding(rule, <<-CRYSTAL
            def fetch
              s = TCPSocket.new("example.com", 80)
              s.gets
            ensure
              s.close
            end
            CRYSTAL
          )
        end

        it "detects TCPSocket.new with named args" do
          assert_finding(rule, <<-CRYSTAL
            TCPSocket.new(host: "example.com", port: 80)
            CRYSTAL
          )
        end

        it "ignores TCPSocket.new with block (no args)" do
          assert_no_finding(rule, <<-CRYSTAL
            TCPSocket.new { |s| s.gets }
            CRYSTAL
          )
        end

        it "ignores TCPSocket.new with block and args" do
          assert_no_finding(rule, <<-CRYSTAL
            TCPSocket.new("example.com", 80) { |s| s.gets }
            CRYSTAL
          )
        end

        it "ignores non-TCPSocket Path.new calls" do
          assert_no_finding(rule, <<-CRYSTAL
            Array(Int32).new
            CRYSTAL
          )
        end

        it "ignores HTTP::Client.new (different path)" do
          assert_no_finding(rule, <<-CRYSTAL
            HTTP::Client.new("example.com")
            CRYSTAL
          )
        end

        it "ignores TCPSocket method calls other than new" do
          assert_no_finding(rule, <<-CRYSTAL
            TCPSocket.open("example.com", 80)
            CRYSTAL
          )
        end

        it "ignores TCPSocket as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = TCPSocket
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-013" do
          rule.id.should eq("CAT-013")
        end
      end

      describe "#severity" do
        it "returns error" do
          rule.severity.should eq("error")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("TCPSocket")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
