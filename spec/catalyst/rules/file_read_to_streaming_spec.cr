require "../../spec_helper"

module Catalyst
  module Rules
    describe FileReadToStreaming do
      rule = FileReadToStreaming.new

      describe "#check" do
        it "detects File.read" do
          assert_finding(rule, %(File.read("large_file.txt")))
        end

        it "detects File.read_lines" do
          assert_finding(rule, %(File.read_lines("large_file.txt")))
        end

        it "detects File.read with variable path" do
          assert_finding(rule, %(path = "data.txt"\nFile.read(path)))
        end

        it "detects File.read_lines with variable path" do
          assert_finding(rule, %(path = "data.txt"\nFile.read_lines(path)))
        end

        it "ignores File.open" do
          assert_no_finding(rule, %(File.open("large_file.txt") { |f| f.gets }))
        end

        it "ignores File.write" do
          assert_no_finding(rule, %(File.write("output.txt", "data")))
        end

        it "ignores unrelated method call" do
          assert_no_finding(rule, %(puts "hello"))
        end

        it "ignores read on non-File receiver" do
          assert_no_finding(rule, %(reader.read))
        end

        it "ignores other File methods" do
          assert_no_finding(rule, %(File.exists?("foo.txt")))
        end

        it "ignores File.delete" do
          assert_no_finding(rule, %(File.delete("foo.txt")))
        end
      end

      describe "#id" do
        it "returns CAT-014" do
          rule.id.should eq("CAT-014")
        end
      end

      describe "#severity" do
        it "returns warning" do
          rule.severity.should eq("warning")
        end
      end

      describe "#description" do
        it "returns description text" do
          rule.description.should contain("streaming")
        end
      end
    end
  end
end
