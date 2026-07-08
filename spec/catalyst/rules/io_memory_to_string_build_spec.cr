require "../../spec_helper"

module Catalyst
  module Rules
    describe IoMemoryToStringBuild do
      rule = IoMemoryToStringBuild.new

      describe "#check" do
        it "detects IO::Memory.new.to_s" do
          assert_finding(rule, "IO::Memory.new.to_s")
        end

        it "detects IO::Memory.new.write(data).to_s" do
          assert_finding(rule, "IO::Memory.new.write(data).to_s")
        end

        it "detects IO::Memory.new with chained methods" do
          assert_finding(rule, "IO::Memory.new.print(data).puts(other).to_s")
        end

        it "detects IO::Memory.new.to_string" do
          assert_finding(rule, "IO::Memory.new.to_string")
        end

        it "ignores IO::Memory.new (no to_s)" do
          assert_no_finding(rule, "IO::Memory.new")
        end

        it "ignores String.build (already optimal)" do
          assert_no_finding(rule, "String.build { |io| io << \"hello\" }")
        end

        it "ignores data.to_s (not IO::Memory)" do
          assert_no_finding(rule, "data.to_s")
        end

        it "ignores to_s with argument" do
          assert_no_finding(rule, "IO::Memory.new.to_s(42)")
        end
      end

      describe "#id" do
        it "returns CAT-020" do
          rule.id.should eq("CAT-020")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("String.build")
          rule.description.should contain("IO::Memory")
        end
      end
    end
  end
end
