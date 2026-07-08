require "compiler/crystal/syntax"
require "./catalyst/version"
require "./catalyst/config"
require "./catalyst/rules/base"
require "./catalyst/rules/hash_keys_each_to_each_key"
require "./catalyst/rules/io_memory_to_string_build"
require "./catalyst/rules/map_sum_to_direct_sum"
require "./catalyst/rules/select_first_to_find"
require "./catalyst/rules/sort_first_to_min"
require "./catalyst/rules/time_local_to_utc"
require "./catalyst/visitors/base"
require "./catalyst/formatters/base"
require "./catalyst/formatters/terminal"
require "./catalyst/formatters/json"
require "./catalyst/runner"
require "./cli"

# # Static performance analysis tool for Crystal.
##
# # Detects performance anti-patterns via AST traversal
# # using the built-in `Crystal::Parser`.
module Catalyst
end

Catalyst::CLI.run(ARGV)
