# frozen_string_literal: true

require_relative "aoc/errors"
require_relative "aoc/calendar"
require_relative "aoc/paths"
require_relative "aoc/config"
require_relative "aoc/downloader"
require_relative "aoc/input_store"
require_relative "aoc/dsl"
require_relative "aoc/ui"
require_relative "aoc/solution_status"
require_relative "aoc/scaffolder"
require_relative "aoc/runner"
require_relative "aoc/commands"
require_relative "aoc/boot"

module AOC
  ROOT = Paths.default.root
  INPUTS = Paths.default.inputs_dir
  CACHE = Paths.default.cache_dir
  CONFIG = Paths.default.config_dir
end

AOC::Boot.install!

if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)
  AOC::Commands.cli!(ARGV)
end
