require "compiler/crystal/syntax"
require "./catalyst/version"
require "./catalyst/config"
require "./catalyst/rules/base"
require "./catalyst/visitors/base"
require "./catalyst/formatters/base"
require "./catalyst/formatters/terminal"
require "./catalyst/formatters/json"
require "./catalyst/runner"
require "./cli"

## Static performance analysis tool for Crystal.
##
## Detects performance anti-patterns via AST traversal
## using the built-in `Crystal::Parser`.
module Catalyst
end

Catalyst::CLI.run(ARGV)
