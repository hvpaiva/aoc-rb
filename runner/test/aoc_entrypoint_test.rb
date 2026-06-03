# frozen_string_literal: true

require_relative "test_helper"

class AocEntrypointTest < Minitest::Test
  def test_prints_help_when_program_matches_source_file
    stdout, = capture_io do
      AOC.cli_entrypoint!(
        program_name: "/path/to/runner/aoc.rb",
        source_file: "/path/to/runner/aoc.rb"
      )
    end

    assert_includes stdout, "rake 'new[2024,2]'"
    assert_includes stdout, "rake 2024:02"
  end

  def test_is_a_no_op_when_program_differs_from_source_file
    stdout, = capture_io do
      AOC.cli_entrypoint!(
        program_name: "/path/to/some_day.rb",
        source_file: "/path/to/runner/aoc.rb"
      )
    end

    assert_empty stdout
  end
end
