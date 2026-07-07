require "file_utils"
require "compiler/crystal/syntax"

module Catalyst
  class Runner
    @rules : Array(Rule)

    def initialize(@config : Config, @options : Options)
      @rules = load_rules
    end

    def run(paths : Array(String)) : Array(Result)
      files = collect_files(paths)
      results = [] of Result

      files.each do |file|
        begin
          source = File.read(file)
          context = Context.new(file, source)

          @rules.each(&.setup(file, source))

          parser = Crystal::Parser.new(source)
          nodes = parser.parse

          visitor = Visitors::FileVisitor.new(@rules, context)
          nodes.accept(visitor)

          results.concat(visitor.results)
        rescue ex : Crystal::SyntaxException
          STDOUT.puts "catalyst: parse error in #{file}: #{ex.message}"
        rescue ex
          STDOUT.puts "catalyst: error processing #{file}: #{ex.message}"
        end
      end

      results
    end

    private def collect_files(paths : Array(String)) : Array(String)
      files = [] of String
      paths.each do |path|
        if File.directory?(path)
          Dir.glob(File.join(path, "**", "*.cr")).each { |f| files << f }
        elsif File.file?(path) && path.ends_with?(".cr")
          files << path
        end
      end
      # Apply ignore patterns from config
      files.reject! do |f|
        @config.ignore.any? { |pattern| File.match?(pattern, f) }
      end
      files.sort!
      files
    end

    private def load_rules : Array(Rule)
      # Phase 1: return empty — rules registered via macros later
      Rule.all.select(&.enabled_by_default?)
    end
  end
end
