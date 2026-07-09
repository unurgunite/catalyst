require "../../spec_helper"

module Catalyst
  module Rules
    describe JsonParseToSerializable do
      rule = JsonParseToSerializable.new

      describe "#check" do
        it "detects JSON.parse(str).as_h" do
          assert_finding(rule, %(JSON.parse(raw).as_h))
        end

        it "detects JSON.parse(str).as_a" do
          assert_finding(rule, %(JSON.parse(raw).as_a))
        end

        it "detects standalone JSON.parse(str)" do
          assert_finding(rule, %(JSON.parse(raw)))
        end

        it "detects JSON.parse with method call result" do
          assert_finding(rule, %(data = JSON.parse(raw); data.as_h))
        end

        it "ignores JSON.parse with block" do
          assert_no_finding(rule, %(JSON.parse(raw) { |v| v }))
        end

        it "ignores unrelated code" do
          assert_no_finding(rule, %(x = 42))
        end

        it "ignores JSON.parse with no args" do
          assert_no_finding(rule, %(JSON.parse))
        end
      end

      describe "#id" do
        it "returns CAT-012" do
          rule.id.should eq("CAT-012")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("JSON::Serializable")
          rule.description.should contain("JSON.parse")
        end
      end
    end
  end
end
