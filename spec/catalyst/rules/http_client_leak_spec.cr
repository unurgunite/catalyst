require "../../spec_helper"

module Catalyst
  module Rules
    describe HttpClientLeak do
      rule = HttpClientLeak.new

      describe "#check" do
        it "detects HTTP::Client.new with url" do
          assert_finding(rule, <<-CRYSTAL
            HTTP::Client.new("https://example.com")
            CRYSTAL
          )
        end

        it "detects HTTP::Client.new assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            c = HTTP::Client.new("https://example.com")
            CRYSTAL
          )
        end

        it "detects HTTP::Client.new even with .close call present" do
          assert_finding(rule, <<-CRYSTAL
            c = HTTP::Client.new("https://example.com")
            c.close
            CRYSTAL
          )
        end

        it "ignores HTTP::Client.new with block" do
          assert_no_finding(rule, <<-CRYSTAL
            HTTP::Client.new("https://example.com") { |c| c.get("/") }
            CRYSTAL
          )
        end

        it "ignores non-HTTP::Client .new calls" do
          assert_no_finding(rule, <<-CRYSTAL
            TCPSocket.new("example.com", 80)
            CRYSTAL
          )
        end

        it "ignores HTTP::Client method calls other than new" do
          assert_no_finding(rule, <<-CRYSTAL
            HTTP::Client.get("https://example.com")
            CRYSTAL
          )
        end

        it "ignores HTTP::Client as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = HTTP::Client
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-028" do
          rule.id.should eq("CAT-028")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("HTTP::Client")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
