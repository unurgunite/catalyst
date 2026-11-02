require "../../spec_helper"

module Catalyst
  module Rules
    describe SelectRejectToPartition do
      rule = SelectRejectToPartition.new

      describe "#check" do
        it "detects select followed by reject on same receiver" do
          assert_finding(SelectRejectToPartition.new, "arr.select { |x| x > 5 }\narr.reject { |x| x > 5 }")
        end

        it "detects reject followed by select on same receiver" do
          assert_finding(SelectRejectToPartition.new, "arr.reject { |x| x > 5 }\narr.select { |x| x > 5 }")
        end

        it "ignores select without reject" do
          assert_no_finding(SelectRejectToPartition.new, "arr.select { |x| x > 5 }")
        end

        it "ignores reject without select" do
          assert_no_finding(SelectRejectToPartition.new, "arr.reject { |x| x > 5 }")
        end

        it "ignores select and reject on different receivers" do
          assert_no_finding(SelectRejectToPartition.new, "arr1.select { |x| x > 5 }\narr2.reject { |x| x > 5 }")
        end

        it "detects select and reject on method chain receiver" do
          assert_finding(SelectRejectToPartition.new, "ary.map(&.id).select { |x| x > 5 }\nary.map(&.id).reject { |x| x > 5 }")
        end

        it "detects only one finding when both are present" do
          results = run_rule(SelectRejectToPartition.new, "arr.select { |x| x > 5 }\narr.reject { |x| x > 5 }")
          results.size.should eq(1)
        end

        # The receiver is compared by its source text, so `results.reject` in
        # one method and `results.select` in another read as the same
        # receiver. That produced a false positive on catalyst's own
        # runner.cr, where a `reject` helper and an unrelated `select` both
        # name `results`.
        it "does not pair calls that sit in different methods" do
          code = <<-CRYSTAL
            class Jobs
              def suppress(results, sources)
                results.reject do |result|
                  lines = sources[result.file]? || [] of String
                  lines.empty?
                end
              end

              def apply_fixes(results)
                fixable = results.select(&.fix_replacement)
                fixable.size
              end
            end
            CRYSTAL
          assert_no_finding(SelectRejectToPartition.new, code)
        end

        it "still pairs calls in one method" do
          code = <<-CRYSTAL
            class Jobs
              def split(results)
                results.reject { |r| r.odd? }
                results.select(&.wanted?)
              end
            end
            CRYSTAL
          assert_finding(SelectRejectToPartition.new, code)
        end
      end

      describe "#id" do
        it "returns CAT-003" do
          rule.id.should eq("CAT-003")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("partition")
          rule.description.should contain("select")
          rule.description.should contain("reject")
        end
      end
    end
  end
end
