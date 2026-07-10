require "../../spec_helper"

module Catalyst
  module Rules
    describe TempfileLeak do
      rule = TempfileLeak.new

      describe "#check" do
        it "detects Tempfile.new with arg" do
          assert_finding(rule, <<-CRYSTAL
            Tempfile.new("data")
            CRYSTAL
          )
        end

        it "detects Tempfile.new assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            f = Tempfile.new("data")
            CRYSTAL
          )
        end

        it "ignores Tempfile.new with block" do
          assert_no_finding(rule, <<-CRYSTAL
            Tempfile.new("data") { |f| f.puts "hello" }
            CRYSTAL
          )
        end

        it "ignores non-Tempfile .new calls" do
          assert_no_finding(rule, <<-CRYSTAL
            Array(Int32).new
            CRYSTAL
          )
        end

        it "ignores Tempfile method calls other than new" do
          assert_no_finding(rule, <<-CRYSTAL
            Tempfile.open("data")
            CRYSTAL
          )
        end

        it "ignores Tempfile as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = Tempfile
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-027" do
          rule.id.should eq("CAT-027")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Tempfile")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
