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

module Catalyst
end

Catalyst::CLI.run(ARGV)
