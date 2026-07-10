require "../../spec_helper"

module Catalyst
  module Rules
    describe DbOpenLeak do
      rule = DbOpenLeak.new

      describe "#check" do
        it "detects DB.open with url" do
          assert_finding(rule, <<-CRYSTAL
            DB.open("postgres://localhost/mydb")
            CRYSTAL
          )
        end

        it "detects DB.open assigned to variable" do
          assert_finding(rule, <<-CRYSTAL
            db = DB.open("postgres://localhost/mydb")
            CRYSTAL
          )
        end

        it "ignores DB.open with block" do
          assert_no_finding(rule, <<-CRYSTAL
            DB.open("postgres://localhost/mydb") { |db| db.exec("SELECT 1") }
            CRYSTAL
          )
        end

        it "ignores non-DB .open calls" do
          assert_no_finding(rule, <<-CRYSTAL
            File.open("file.txt")
            CRYSTAL
          )
        end

        it "ignores DB method calls other than open" do
          assert_no_finding(rule, <<-CRYSTAL
            DB.new("postgres://localhost/mydb")
            CRYSTAL
          )
        end

        it "ignores DB as a reference (not a call)" do
          assert_no_finding(rule, <<-CRYSTAL
            x = DB
            CRYSTAL
          )
        end
      end

      describe "#id" do
        it "returns CAT-029" do
          rule.id.should eq("CAT-029")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("DB.open")
          rule.description.should contain("resource leak")
        end
      end
    end
  end
end
