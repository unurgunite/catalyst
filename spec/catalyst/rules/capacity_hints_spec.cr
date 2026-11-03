require "../../spec_helper"

module Catalyst
  module Rules
    describe CapacityHints do
      rule = CapacityHints.new

      # # The old spec asserted a finding for a bare `Array(Int32).new` with
      # # no loop in sight, i.e. it pinned the rule's habit of telling people
      # # to pre-size a collection whose size nothing in the file reveals.
      describe "#check" do
        it "detects an array created empty and filled in a loop" do
          code = <<-CR
            def collect(items)
              result = Array(Int32).new
              items.each { |item| result << item }
              result
            end
            CR
          assert_finding(rule, code)
        end

        it "detects a hash created empty and filled in a loop" do
          code = <<-CR
            def tally(items)
              counts = Hash(String, Int32).new
              items.each { |item| counts[item] = 1 }
              counts
            end
            CR
          assert_finding(rule, code)
        end

        it "detects a collection filled in a while loop" do
          code = <<-CR
            def drain(source)
              found = Array(String).new
              while line = source.gets
                found << line
              end
              found
            end
            CR
          assert_finding(rule, code)
        end

        it "detects a collection filled in a times block" do
          code = <<-CR
            def ticks
              marks = Array(Int64).new
              5.times { |i| marks.push(i.to_i64) }
              marks
            end
            CR
          assert_finding(rule, code)
        end

        it "ignores an array created empty but filled outside a loop" do
          code = <<-CR
            def once
              found = Array(Int32).new
              found << 1
              found
            end
            CR
          assert_no_finding(rule, code)
        end

        it "ignores an array that already has a capacity argument" do
          code = <<-CR
            def collect(items)
              result = Array(Int32).new(items.size)
              items.each { |item| result << item }
              result
            end
            CR
          assert_no_finding(rule, code)
        end

        it "ignores Array.new without a generic type" do
          code = <<-CR
            def collect(items)
              result = Array.new
              items.each { |item| result << item }
              result
            end
            CR
          assert_no_finding(rule, code)
        end

        it "ignores Set(Int32).new" do
          code = <<-CR
            def collect(items)
              seen = Set(Int32).new
              items.each { |item| seen << item }
              seen
            end
            CR
          assert_no_finding(rule, code)
        end

        it "ignores a collection filled in a loop but not created locally" do
          code = <<-CR
            def fill(target, items)
              items.each { |item| target << item }
              target
            end
            CR
          assert_no_finding(rule, code)
        end
      end

      describe "#id" do
        it "returns CAT-038" do
          rule.id.should eq("CAT-038")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#enabled_by_default?" do
        it "is opt-in because the size is inferred from the loop" do
          rule.enabled_by_default?.should be_false
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Pre-size")
          rule.description.should contain("loop")
        end
      end
    end
  end
end
