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
require_relative "aoc/all_result_protocol"
require_relative "aoc/runner"
require_relative "aoc/commands"
require_relative "aoc/boot"

module AOC
  # Prints `Commands.help` when this file is executed directly via
  # `ruby runner/aoc.rb`. No-op when required by another file (day files,
  # the Rakefile, or test_helper).
  def self.cli_entrypoint!(program_name: $PROGRAM_NAME, source_file: __FILE__)
    return unless File.expand_path(program_name) == File.expand_path(source_file)

    Commands.help
  end
end

AOC::Boot.install!
AOC.cli_entrypoint!
