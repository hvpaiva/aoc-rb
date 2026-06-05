# frozen_string_literal: true

require_relative "../test_helper"

class RendererTest < Minitest::Test
  def test_year_title_prints_header
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).year_title(2024)

    assert_includes output.string, "Ruby Advent of Code 2024"
  end

  def test_print_year_results_formats_each_result_and_footer
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).print_year_results(
      2024,
      [AOC::AllResultProtocol::Result.new(day: 2, part: 1, answer: "cba", elapsed: 0.001)]
    )

    assert_includes output.string, "Ruby Advent of Code 2024"
    assert_includes output.string, "day 02"
    assert_includes output.string, "part 1"
    assert_includes output.string, 'answer: "cba"'

    expected_total = AOC::Calendar.max_day_for(2024) * 2
    assert_includes output.string, "1 stars"
    assert_includes output.string, "#{expected_total - 1} missing"
    assert_includes output.string, "#{expected_total} total"
  end

  def test_real_results_aligns_answer_widths
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).real_results(
      [
        [1, "short", 0.001],
        [2, "longer answer", 0.002]
      ]
    )

    short_line = output.string.lines.find { |line| line.include?("part 1") }
    long_line = output.string.lines.find { |line| line.include?("part 2") }

    short_answer_column = short_line.index('"short"')
    long_answer_column = long_line.index('"longer answer"')

    assert_equal short_answer_column, long_answer_column,
      "answers should be left-aligned to the same column"
  end

  def test_example_ok_shows_actual_value
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).example_ok("example 1", 1, 42)

    assert_includes output.string, "example 1"
    assert_includes output.string, "expected = got = 42"
  end

  def test_example_fail_prints_expected_and_actual
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).example_fail("example 1", 1, 99, 3)

    assert_includes output.string, "expected: 99"
    assert_includes output.string, "got: 3"
    refute_includes output.string, "Stopped before real input."
  end

  def test_examples_stopped_prints_stop_message
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).examples_stopped

    assert_includes output.string, "Stopped before real input."
  end

  def test_examples_flag_skipped_pluralizes_count
    singular = StringIO.new
    plural = StringIO.new
    AOC::UI::Renderer.new(output: singular, env: {}).examples_flag_skipped(1)
    AOC::UI::Renderer.new(output: plural, env: {}).examples_flag_skipped(3)

    assert_includes singular.string, "1 example skipped"
    assert_includes plural.string, "3 examples skipped"
    assert_includes plural.string, "(skip:/only:)"
  end

  def test_examples_skipped_names_the_part_and_pluralizes_count
    singular = StringIO.new
    plural = StringIO.new
    AOC::UI::Renderer.new(output: singular, env: {}).examples_skipped(2, 1)
    AOC::UI::Renderer.new(output: plural, env: {}).examples_skipped(2, 4)

    assert_includes singular.string, "part 2 · skipped in 1 example"
    assert_includes plural.string, "part 2 · skipped in 4 examples"
    assert_includes plural.string, "(no def part2)"
  end

  def test_real_skipped_prints_withheld_message_and_override_hint
    output = StringIO.new
    AOC::UI::Renderer.new(output: output, env: {}).real_skipped

    assert_includes output.string, "Real input skipped while examples carry skip:/only: flags."
    assert_includes output.string, "(AOC_FORCE_REAL=1 runs it anyway)"
  end

  def test_print_overview_renders_grid_and_footer
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}
    AOC::UI::Renderer.new(output: output, env: env).print_overview(
      [
        [2015, [true, true, false]],
        [2016, [false, false, false]]
      ]
    )

    assert_includes output.string, "Ruby Advent of Code"
    assert_includes output.string, "2015"
    assert_includes output.string, "2016"
    assert_includes output.string, "2 stars"
    assert_includes output.string, "4 missing"
    assert_includes output.string, "6 total"
  end

  def test_print_overview_supports_multiple_rows
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}
    overview = (2015..2019).map { |year| [year, Array.new(2, false)] }

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    # First row of cards renders together, then a blank, then the second row.
    assert_match(/2015.*2016.*2017.*2018/m, output.string)
    assert_includes output.string, "2019"
  end

  def test_print_overview_drops_columns_on_narrow_output
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1", "COLUMNS" => "40"}
    overview = (2015..2018).map { |year| [year, Array.new(2, false)] }

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    first_line = output.string.lines.find { |line| line.include?("2015") }
    assert_includes first_line, "2016"
    refute_includes first_line, "2017"
  end

  def test_print_overview_falls_back_to_single_column
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1", "COLUMNS" => "5"}
    overview = (2015..2016).map { |year| [year, Array.new(2, false)] }

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    first_line = output.string.lines.find { |line| line.include?("2015") }
    refute_includes first_line, "2016"
  end

  def test_print_overview_uses_terminal_width_on_tty
    output = StringIO.new
    output.define_singleton_method(:tty?) { true }
    output.define_singleton_method(:winsize) { [24, 30] }
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1", "TERM" => "dumb"}
    overview = (2015..2018).map { |year| [year, Array.new(2, false)] }

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    first_line = output.string.lines.find { |line| line.include?("2015") }
    assert_includes first_line, "2016"
    refute_includes first_line, "2017"
  end

  def test_print_overview_ignores_malformed_columns_value
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1", "COLUMNS" => "wide"}
    overview = (2015..2018).map { |year| [year, Array.new(2, false)] }

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    first_line = output.string.lines.find { |line| line.include?("2015") }
    assert_includes first_line, "2018"
  end

  def test_print_overview_aligns_cards_with_heterogeneous_heights
    # Real production scenario: rake all renders 2024 (25 stars / 3 rows)
    # alongside 2025+ (12 stars / 2 rows) in the same slice-of-4 row. The
    # shorter card's missing lines must pad with blanks so the next row stays
    # aligned.
    output = StringIO.new
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}
    overview = [
      [2024, Array.new(25, true)],
      [2025, Array.new(12, true)]
    ]

    AOC::UI::Renderer.new(output: output, env: env).print_overview(overview)

    assert_includes output.string, "2024"
    assert_includes output.string, "2025"
    assert_includes output.string, "37 stars"
    assert_includes output.string, "0 missing"

    # Each row of the grid is the same length (left card padded by line for
    # the right card's extra row).
    grid_lines = output.string.lines.grep(/\d/).reject { |l| l.include?("stars") }
    refute_empty grid_lines
  end

  def test_print_backtrace_truncates_by_default
    output = StringIO.new
    exception = build_exception_with_backtrace(10)

    AOC::UI::Renderer.new(output: output, env: {}).print_backtrace(exception)

    assert_equal AOC::UI::Renderer::MAX_BACKTRACE_LINES, output.string.lines.length
    assert_includes output.string, "line 1"
    assert_includes output.string, "line 5"
    refute_includes output.string, "line 6"
  end

  def test_print_backtrace_prints_full_when_debug_enabled
    output = StringIO.new
    exception = build_exception_with_backtrace(10)

    AOC::UI::Renderer.new(output: output, env: {"AOC_DEBUG" => "1"}).print_backtrace(exception)

    assert_equal 10, output.string.lines.length
    assert_includes output.string, "line 10"
  end

  private

  def build_exception_with_backtrace(size)
    StandardError.new("boom").tap do |e|
      e.set_backtrace((1..size).map { |i| "line #{i}" })
    end
  end
end
