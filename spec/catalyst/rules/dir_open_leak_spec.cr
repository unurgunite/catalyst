require "../../spec_helper"

module Catalyst
  module Rules
    describe DirOpenLeak do
      rule = DirOpenLeak.new

      describe "#check" do
        it "detects Dir.open with path arg" do
          assert_finding(rule, <<-CRYSTAL
            Dir.open(".")
            CRYSTAL
          )
        end

        it "detects Dir.open assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            d = Dir.open(".")
            CRYSTAL
          )
        end

        it "ignores Dir.open with block" do
          assert_no_finding(rule, <<-CRYSTAL
            Dir.open(".") { |d| d.entries }
            CRYSTAL
          )
        end

        it "ignores non-Dir .open calls" do
          assert_no_finding(rule, <<-CRYSTAL
            File.open("file.txt")
            CRYSTAL
          )
        end

        it "ignores Dir method calls other than open" do
          assert_no_finding(rule, <<-CRYSTAL
            Dir.new(".")
            CRYSTAL
          )
        end

        it "ignores Dir as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = Dir
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-026" do
          rule.id.should eq("CAT-026")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Dir.open")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
