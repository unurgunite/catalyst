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

        it "ignores whole reads of config files" do
          assert_no_finding(rule, %(File.read("config/settings.yml")))
          assert_no_finding(rule, %(File.read("data.json")))
          assert_no_finding(rule, %(File.read_lines("app.toml")))
        end

        it "ignores reads feeding config parsing" do
          assert_no_finding(rule, %(AppConfig.from_yaml(File.read(CONFIG_PATH))))
          assert_no_finding(rule, %(cfg = Config.from_json(File.read(path))))
        end

        it "flags one-off reads as info/low with if-large caveat" do
          results = run_rule(rule, %(File.read("data.bin")))
          results.size.should eq(1)
          results.first.severity.should eq("info")
          results.first.confidence.should eq("low")
          results.first.message.should contain("if the file can be large")
        end

        it "flags reads inside loops as warning/medium" do
          results = run_rule(rule, %(paths.each { |p| File.read(p) }))
          results.size.should eq(1)
          results.first.severity.should eq("warning")
          results.first.confidence.should eq("medium")
        end

        it "flags reads inside while loops as warning/medium" do
          results = run_rule(rule, %(while running\n  File.read(path)\nend))
          results.size.should eq(1)
          results.first.severity.should eq("warning")
          results.first.confidence.should eq("medium")
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
