require "../../spec_helper"

module Catalyst
  module Rules
    describe RegexNewToConstant do
      rule = RegexNewToConstant.new

      describe "#check" do
        it "detects Regex.new" do
          assert_finding(rule, %q(Regex.new("pattern")))
        end

        it "detects Regex.compile" do
          assert_finding(rule, %q(Regex.compile("pattern")))
        end

        it "detects Regex.new in block" do
          assert_finding(rule, %q([1, 2, 3].each { Regex.new("pattern") }))
        end

        it "emits a fix only for a bare call statement in a constant-legal scope" do
          results = run_rule(rule, <<-CR)
            class Foo
              Regex.new("user-id")
            end
            CR
          results.size.should eq(1)
          results.first.fix_replacement.should eq(%q(  USER_ID = Regex.new("user-id")))
        end

        it "emits no fix for a call inside a method body" do
          # `NAME = ...` inside a method is "dynamic constant assignment".
          results = run_rule(rule, <<-CR)
            def f
              rx = Regex.new("user-id")
            end
            CR
          results.size.should eq(1)
          results.first.fix_replacement.should be_nil
        end

        it "emits no fix when the call is not the whole statement" do
          results = run_rule(rule, <<-CR)
            class Foo
              Regex.new("x").match("x")
            end
            CR
          results.size.should eq(1)
          results.first.fix_replacement.should be_nil
        end

        it "never emits a bare undefined constant name" do
          [
            %q(rx = Regex.new("pattern")),
            <<-CR,
              class Foo
                Regex.new("pattern")
              end
              CR
            <<-CR,
              module M
                Regex.compile("p")
              end
              CR
          ].each do |code|
            run_rule(rule, code).each do |result|
              next unless replacement = result.fix_replacement
              replacement.should contain("Regex")
            end
          end
        end

        it "emits no fix for dynamic patterns" do
          results = run_rule(rule, <<-CR)
            class Foo
              Regex.new(pattern)
            end
            CR
          results.size.should eq(1)
          results.first.fix_replacement.should be_nil
        end

        it "still reports Regex.new assigned to a bare constant" do
          # A line sink cannot rewrite `RE = ...` into a hoisted constant, so
          # this one keeps a finding (with no edit for the local assignment).
          assert_finding(rule, %q(rx = Regex.new("pattern")))
        end

        it "resets scope tracking between files" do
          # A method body in file A must not leak "inside def" into file B.
          run_rule(rule, <<-CR)
            def f
              Regex.new("pattern")
            end
            CR
          results = run_rule(rule, <<-CR)
            class Foo
              Regex.new("pattern")
            end
            CR
          results.first.fix_replacement.should_not be_nil
        end

        it "ignores non-Regex calls" do
          assert_no_finding(rule, %q(Foo.new("bar")))
        end
      end

      describe "#id" do
        it "returns CAT-019" do
          rule.id.should eq("CAT-019")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Regex.new")
        end
      end
    end
  end
end
