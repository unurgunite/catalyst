require "../../spec_helper"

module Catalyst
  module Rules
    describe StructVsClass do
      rule = StructVsClass.new

      describe "#id" do
        it "returns CAT-015" do
          rule.id.should eq("CAT-015")
        end
      end

      describe "#severity" do
        it "returns info" do
          rule.severity.should eq("info")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("Struct")
          rule.description.should contain("Class")
        end
      end

      describe "#check" do
        it "detects class with property" do
          assert_finding(rule, "class Foo\n  property :x, :y\nend")
        end

        it "detects class with getter and setter" do
          assert_finding(rule, "class Foo\n  getter :x\n  setter :x\nend")
        end

        it "detects class with up to 4 properties" do
          assert_finding(rule, "class Foo\n  property :a, :b, :c, :d\nend")
        end

        it "ignores class with more than 4 properties" do
          assert_no_finding(rule, "class Foo\n  property :a, :b, :c, :d, :e\nend")
        end

        it "ignores class with custom method" do
          assert_no_finding(rule, "class Foo\n  property :x\n  def process\n    @x + 1\n  end\nend")
        end

        it "ignores struct (already a struct)" do
          assert_no_finding(rule, "struct Foo\n  property :x, :y\nend")
        end

        it "ignores class with parent" do
          assert_no_finding(rule, "class Foo < Bar\n  property :x\nend")
        end

        it "ignores empty class body" do
          assert_no_finding(rule, "class Foo\nend")
        end

        it "detects class with property and initialize" do
          assert_finding(rule, "class Foo\n  property :x\n  def initialize(@x : Int32)\n  end\nend")
        end

        it "ignores class with non-accessor call" do
          assert_no_finding(rule, "class Foo\n  property :x\n  include SomeModule\nend")
        end
      end
    end
  end
end
