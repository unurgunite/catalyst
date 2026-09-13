require "../../spec_helper"

module Catalyst
  module Rules
    describe FileOpenLeak do
      rule = FileOpenLeak.new

      describe "#check" do
        it "detects File.open with path arg" do
          assert_finding(rule, <<-CRYSTAL
            File.open("file.txt")
            CRYSTAL
          )
        end

        it "detects File.open with path and mode" do
          assert_finding(rule, <<-CRYSTAL
            File.open("file.txt", "w")
            CRYSTAL
          )
        end

        it "detects File.open assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            f = File.open("file.txt")
            CRYSTAL
          )
        end

        it "ignores File.open with block" do
          assert_no_finding(rule, <<-CRYSTAL
            File.open("file.txt") { |f| f.gets }
            CRYSTAL
          )
        end

        it "ignores non-File .open calls" do
          assert_no_finding(rule, <<-CRYSTAL
            Dir.open(".")
            CRYSTAL
          )
        end

        it "ignores File method calls other than open" do
          assert_no_finding(rule, <<-CRYSTAL
            File.read("file.txt")
            CRYSTAL
          )
        end

        it "ignores File as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = File
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-025" do
          rule.id.should eq("CAT-025")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("File.open")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
