# Emits `require` lines for every rule file.
#
# Runs at compile time via `{{ run(...) }}` from src/catalyst.cr.
# Uses an absolute path anchored at this script's directory so the build
# does not depend on the compiler's working directory: a build from any
# CWD must embed the same rule set instead of silently producing
# a binary with zero rules.
# Forward slashes: backslash paths break Dir.glob on Windows
# (`\a`, `\c`, … are read as glob escapes and match nothing).
rules_dir = File.expand_path(File.join(__DIR__, "..", "src", "catalyst", "rules")).gsub("\\", "/")

# NOTE: no File.join here — it would reintroduce a backslash separator
# on Windows and break the glob again.
rule_files = Dir.glob("#{rules_dir}/*.cr").sort

if rule_files.empty?
  STDERR.puts "generate_rules_require: no rule files found in #{rules_dir}"
  exit 1
end

# Shared bases must load before the rules that inherit from them.
shared = rule_files.select do |file|
  {"resource_leak_rule.cr", "loop_tracking.cr"}.includes?(File.basename(file))
end
shared.each do |file|
  puts "require \"./catalyst/rules/#{File.basename(file)}\""
end

rule_files.each do |file|
  basename = File.basename(file)
  next if basename == "base.cr"
  next if shared.includes?(file)
  puts "require \"./catalyst/rules/#{basename}\""
end
