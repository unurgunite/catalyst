require "../../spec_helper"

module Catalyst
  module Rules
    describe SelectFirstToFind do
      rule = SelectFirstToFind.new

      describe "#check" do
        it "detects select{}.first" do
          assert_finding(rule, "[1, 2, 3].select { |x| x.even? }.first")
        end

        it "detects select(&.even?).first" do
          assert_finding(rule, "[1, 2, 3].select(&.even?).first")
        end

        it "detects select{}.first?" do
          assert_finding(rule, "[1, 2, 3].select { |x| x.even? }.first?")
        end

        it "detects filter{}.first" do
          assert_finding(rule, "[1, 2, 3].filter { |x| x.even? }.first")
        end

        it "detects chained select.first" do
          assert_finding(rule, "ary.select(&.foo).first")
        end

        it "ignores select{}.last" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }.last")
        end

        it "ignores first without select" do
          assert_no_finding(rule, "[1, 2, 3].first")
        end

        it "ignores find (already optimal)" do
          assert_no_finding(rule, "[1, 2, 3].find { |x| x.even? }")
        end

        it "ignores select alone" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }")
        end

        it "ignores select.first with argument" do
          assert_no_finding(rule, "[1, 2, 3].select { |x| x.even? }.first(2)")
        end

        it "ignores select with index block (find yields element only)" do
          assert_no_finding(rule, "[1, 2, 3].select { |x, i| x > i }.first")
        end

        it "detects select with implicit-it block" do
          assert_finding(rule, "[1, 2, 3].select { it.even? }.first")
        end
      end

      describe "#fix_replacement" do
        # The `?` belongs to the replaced call. A pattern that consumed
        # `first` inside `first?` left the `?` behind, producing
        # `find { ... }?`, which does not parse.
        it "replaces first? with find and drops the question mark" do
          fix_for(rule, "x = collect { arr.select { |y| y > 2 }.first? }").should eq(
            "x = collect { arr.find { |y| y > 2 } }"
          )
        end

        it "replaces first with find!" do
          fix_for(rule, "x = collect { arr.select { |y| y > 2 }.first }").should eq(
            "x = collect { arr.find! { |y| y > 2 } }"
          )
        end

        # Rewriting the first matching text turned the wrong call into
        # `find!` and left the `.first` in place. The AST names the call.
        it "rewrites the select that owns the first, not the first select on the line" do
          fix_for(rule, "x = a.select { |q| q }.map(&.to_s).select { |r| r }.first").should eq(
            "x = a.select { |q| q }.map(&.to_s).find! { |r| r }"
          )
        end

        # A greedy body matched past the inner block and swallowed the
        # enclosing block's brace.
        it "stops at the inner block's closing brace" do
          fix_for(rule, "arr.select { |x| x > n / 2 }.first").should eq(
            "arr.find! { |x| x > n / 2 }"
          )
        end

        # The enclosing block must survive.
        it "does not swallow an enclosing block's brace" do
          fix_for(rule, "m = measure { one.select { |x| x > 1 }.first }").should eq(
            "m = measure { one.find! { |x| x > 1 } }"
          )
        end

        it "keeps a receiver whose name contains select" do
          fix_for(rule, "list.select { |x| x > 1 }.first").should eq(
            "list.find! { |x| x > 1 }"
          )
        end

        it "leaves a multi-line block alone" do
          code = <<-CR
            r = list.select do |item|
              item.active?
            end.first
            CR
          fix_for(rule, code).should be_nil
        end
      end

      describe "#id" do
        it "returns CAT-008" do
          rule.id.should eq("CAT-008")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("find")
          rule.description.should contain("select")
        end
      end
    end
  end
end
