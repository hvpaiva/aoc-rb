# frozen_string_literal: true

require_relative "test_helper"

# Full-output (golden) tests. Treat these as visual contracts: when the
# rendered output legitimately changes, update the expected heredoc. If a
# refactor unintentionally changes spacing, ordering, wording, icon
# glyphs, or color codes, these tests catch it.
#
# Most tests run with AOC_ASCII=1 + NO_COLOR=1 to keep snapshots stable.
# A dedicated section then re-renders selected scenarios with Unicode
# icons and with ANSI color codes enabled to lock those down too.
class SnapshotsTest < Minitest::Test
  include RunnerTestSupport

  ASCII_NO_COLOR = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}.freeze
  UNICODE_NO_COLOR = {"NO_COLOR" => "1"}.freeze

  def setup
    AOC::DSL.reset!
  end

  def teardown
    AOC::DSL.reset!
    Object.class_eval do
      remove_method(:part1) if method_defined?(:part1) || private_method_defined?(:part1)
      remove_method(:part2) if method_defined?(:part2) || private_method_defined?(:part2)
    end
  end

  # -------------------------------------------------------------------- ASCII

  def test_ascii_full_run
    Object.class_eval do
      def part1 = input.chomp.upcase
      def part2 = input.chomp.length
    end
    AOC::DSL.add_example("abc\n", part1: "ABC", part2: 3)

    output = StringIO.new
    ticks = [0.0, 0.001, 0.001, 0.0025]

    AOC::Runner.new(
      paths: FakePaths.new(year: 2024, day: 2),
      input_store: FakeInputStore.new("hello\n"),
      ui: AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR),
      clock: -> { ticks.shift }
    ).run!(path: "2024/02.rb")

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2024 day 02

      Examples
        * example  1 · part 1  expected = got = "ABC"
        * example  1 · part 2  expected = got = 3

      Real input
        * part 1 answer: "HELLO"  (1.00ms)
        * part 2 answer: 5        (1.50ms)
    OUT
  end

  def test_ascii_example_failure
    Object.class_eval { def part1 = input.length }
    AOC::DSL.add_example("abc", part1: 99)

    output = StringIO.new
    AOC::Runner.new(ui: ascii_renderer(output)).run_examples!([1])

    assert_equal <<~OUT, output.string

      Examples
        ! example  1 · part 1
           expected: 99
                got: 3

      Stopped before real input.
    OUT
  end

  def test_ascii_example_failure_still_runs_remaining_examples
    Object.class_eval { def part1 = input.length }
    AOC::DSL.add_example("abc", part1: 99)
    AOC::DSL.add_example("wxyz", part1: 4)

    output = StringIO.new
    AOC::Runner.new(ui: ascii_renderer(output)).run_examples!([1])

    assert_equal <<~OUT, output.string

      Examples
        ! example  1 · part 1
           expected: 99
                got: 3
        * example  2 · part 1  expected = got = 4

      Stopped before real input.
    OUT
  end

  def test_ascii_example_skip
    Object.class_eval { def part1 = input.length }
    AOC::DSL.add_example("abc", part2: 4)

    output = StringIO.new
    AOC::Runner.new(ui: ascii_renderer(output)).run_examples!([1])

    assert_equal <<~OUT, output.string

      Examples
        > example  1 · part 2  skipped (def part2 not defined)
    OUT
  end

  def test_ascii_example_exception
    Object.class_eval { def part1 = raise "boom" }
    AOC::DSL.add_example("abc", part1: 1)

    output = StringIO.new
    AOC::Runner.new(ui: ascii_renderer(output)).run_examples!([1])

    body = output.string.lines
    backtrace_dropped = body.reject { |line| line.start_with?("     /") || line.match?(/\.rb:\d+/) }

    assert_equal <<~OUT.lines.first(4), backtrace_dropped.first(4)

      Examples
        x example  1 · part 1  raised RuntimeError
           boom
    OUT
    assert_includes output.string, "Stopped before real input."
  end

  def test_ascii_real_input_exception
    Object.class_eval { def part1 = raise "real boom" }

    output = StringIO.new
    ticks = [0.0, 0.002]

    AOC::Runner.new(
      input_store: FakeInputStore.new("abc"),
      ui: ascii_renderer(output),
      clock: -> { ticks.shift },
      exiter: noop_exiter
    ).run_real_input!(2024, 2, [1])

    header = output.string.lines.first(3)
    assert_equal <<~OUT.lines, header

      Real input
        x part 1 raised RuntimeError  (2.00ms)
    OUT
  end

  def test_ascii_config_error
    output = StringIO.new
    AOC::Runner.new(
      paths: FakePaths.new(year: 2024, day: 2),
      input_store: FakeInputStore.new("input"),
      ui: ascii_renderer(output),
      exiter: noop_exiter
    ).run!(path: "2024/02.rb")

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2024 day 02
      Configuration error:
        Define def part1 and/or def part2 in the day file.
    OUT
  end

  def test_ascii_top_level_error
    paths = Object.new
    paths.define_singleton_method(:infer_year_day) { |_| raise "infrastructure exploded" }

    output = StringIO.new
    AOC::Runner.new(
      paths: paths,
      input_store: FakeInputStore.new("input"),
      ui: ascii_renderer(output),
      exiter: noop_exiter
    ).run!(path: "broken.rb")

    # The first two lines are stable; the backtrace lines that follow depend
    # on where the test is invoked from. We snapshot the header and assert
    # that at least one indented backtrace line follows.
    head = output.string.lines.first(2)
    assert_equal <<~OUT.lines, head
      Error:
        RuntimeError: infrastructure exploded
    OUT
    backtrace_lines = output.string.lines.drop(2)
    refute_empty backtrace_lines
    assert backtrace_lines.all? { |line| line.start_with?("     ") }, "backtrace lines should be indented"
  end

  def test_ascii_overview_grid
    output = StringIO.new
    overview = [
      [2015, [true, true, false, false, false, false, false, false, false, false]],
      [2016, [true, false, false, false, false, false, false, false, false, false]]
    ]

    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR).print_overview(overview)

    assert_equal <<~OUT, output.string
       Ruby Advent of Code

      2015            2016
        **--------      *---------

      * 3 stars · - 17 missing · 20 total
    OUT
  end

  def test_ascii_year_results
    output = StringIO.new
    results = [
      AOC::AllResultProtocol::Result.new(day: 1, part: 1, answer: "42", elapsed: 0.001),
      AOC::AllResultProtocol::Result.new(day: 2, part: 1, answer: "longer", elapsed: 0.0123)
    ]

    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR).print_year_results(2024, results)

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2024

      * day 01 · part 1 · answer: "42"      (1.00ms)
      * day 02 · part 1 · answer: "longer"  (12.3ms)

      * 2 stars · - 48 missing · 50 total
    OUT
  end

  def test_ascii_day_comparison_without_divergence
    output = StringIO.new
    result = ->(part, answer, elapsed) { AOC::AllResultProtocol::Result.new(day: 6, part: part, answer: answer, elapsed: elapsed) }
    variants = [
      ["base", [result.call(1, "543903", 0.0123), result.call(2, "1060", 0.015)], true],
      ["bitset", [result.call(1, "543903", 0.004), result.call(2, "1060", 0.005)], true]
    ]

    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR).print_day_comparison(2015, 6, variants)

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2015 day 06

      * base   · part 1 · answer: "543903"  (12.3ms)
      * base   · part 2 · answer: "1060"    (15.0ms)
      * bitset · part 1 · answer: "543903"  (4.00ms)
      * bitset · part 2 · answer: "1060"    (5.00ms)
    OUT
  end

  def test_ascii_day_comparison_with_divergence_and_failures
    output = StringIO.new
    result = ->(answer, elapsed) { AOC::AllResultProtocol::Result.new(day: 6, part: 1, answer: answer, elapsed: elapsed) }
    variants = [
      ["base", [result.call("543903", 0.0123)], true],
      ["wrong", [result.call("999", 0.004)], true],
      ["boom", [], false],
      ["empty", [], true]
    ]

    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR).print_day_comparison(2015, 6, variants)

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2015 day 06

      ! base  · part 1 · answer: "543903"  (12.3ms)
      ! wrong · part 1 · answer: "999"     (4.00ms)
      x boom  · errored (run it directly for the trace)
      > empty · no parts implemented

      Variants disagree on part 1.
    OUT
  end

  def test_ascii_day_comparison_marks_partial_failure_after_its_results
    output = StringIO.new
    partial = AOC::AllResultProtocol::Result.new(day: 6, part: 1, answer: "543903", elapsed: 0.0123)
    variants = [["base", [partial], false]]

    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR).print_day_comparison(2015, 6, variants)

    assert_equal <<~OUT, output.string
       Ruby Advent of Code 2015 day 06

      * base · part 1 · answer: "543903"  (12.3ms)
      x base · errored (run it directly for the trace)
    OUT
  end

  # ------------------------------------------------------------------ Unicode

  def test_unicode_run_uses_emoji_icons
    Object.class_eval { def part1 = input.chomp.upcase }
    AOC::DSL.add_example("abc\n", part1: "ABC")

    output = StringIO.new
    ticks = [0.0, 0.001]

    AOC::Runner.new(
      paths: FakePaths.new(year: 2024, day: 2),
      input_store: FakeInputStore.new("hi\n"),
      ui: AOC::UI::Renderer.new(output: output, env: UNICODE_NO_COLOR),
      clock: -> { ticks.shift }
    ).run!(path: "2024/02.rb")

    assert_equal <<~OUT, output.string
      🎄 Ruby Advent of Code 2024 day 02

      Examples
        ✅ example  1 · part 1  expected = got = "ABC"

      Real input
        ⭐ part 1 answer: "HI"  (1.00ms)
    OUT
  end

  def test_unicode_overview_uses_star_glyphs
    output = StringIO.new
    overview = [[2024, [true, false]]]

    AOC::UI::Renderer.new(output: output, env: UNICODE_NO_COLOR).print_overview(overview)

    # Filled stars render with no trailing space; empty stars carry a trailing
    # space (the renderer pads them so two empties stay separated). The
    # `rstrip` at the end of the grid line removes the dangling final space.
    assert_equal <<~OUT, output.string
      🎄 Ruby Advent of Code

      2024
        ⭐☆

      ⭐ 1 stars · ☆ 1 missing · 2 total
    OUT
  end

  # -------------------------------------------------------------------- Color

  def test_color_emits_ansi_escapes_when_tty_and_color_allowed
    output = tty_stringio
    AOC::UI::Renderer.new(output: output, env: ascii_with_term("xterm-256color"))
      .example_ok("example  1", 1, 42)

    assert_equal "  \e[32m*\e[0m \e[34mexample  1\e[0m · \e[33mpart 1\e[0m  \e[2mexpected = got = 42\e[0m\n",
      output.string
  end

  def test_color_omits_ansi_when_output_is_not_a_tty
    output = StringIO.new # not a TTY
    AOC::UI::Renderer.new(output: output, env: ascii_with_term("xterm-256color"))
      .example_ok("example  1", 1, 42)

    refute_includes output.string, "\e["
  end

  def test_color_omits_ansi_when_env_has_no_color
    output = tty_stringio
    env = ASCII_NO_COLOR.merge("TERM" => "xterm-256color")
    AOC::UI::Renderer.new(output: output, env: env).example_ok("example  1", 1, 42)

    refute_includes output.string, "\e["
  end

  def test_color_omits_ansi_when_term_is_dumb
    output = tty_stringio
    AOC::UI::Renderer.new(output: output, env: ascii_with_term("dumb"))
      .example_ok("example  1", 1, 42)

    refute_includes output.string, "\e["
  end

  # ----------------------------------------------------------------- Commands

  def test_help_command_snapshot
    stdout, = capture_io { AOC::Commands.help }

    assert_equal <<~OUT, stdout
      Usage:
        rake 'new[2024,2]'         # create 2024/02.rb
        rake 'new[2024,2,bitset]'  # create the 2024/02_bitset.rb variant
        rake 2024:02               # run 2024/02.rb
        rake '2024:02[bitset]'     # run the 2024/02_bitset.rb variant
        rake all                   # show global progress
        rake 'all[2024]'           # run real inputs for a year
        rake 'all[2024,2]'         # compare a day's variants on real input
        rake check                 # lint the solutions (Standard study aid)
        rake ci                    # full gate: runner checks + solution lint

      Runner (the tool) maintenance:
        rake runner:test           # run the runner test suite
        rake runner:check          # syntax + Standard + tests for runner/

      Direct execution also works:
        ruby 2024/02.rb
        ruby 2024/02_bitset.rb
    OUT
  end

  def test_new_day_created_snapshot
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, "config"))
      output = StringIO.new
      error = StringIO.new

      AOC::Commands.new_day(2024, 7, paths: paths, output: output, error: error)

      assert_equal "Created: 2024/07.rb\n", output.string
      assert_empty error.string
    end
  end

  def test_new_day_already_exists_snapshot
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, "config"))
      write_file(paths.day_path(2024, 8), "preexisting\n")
      output = StringIO.new
      error = StringIO.new

      AOC::Commands.new_day(2024, 8, paths: paths, output: output, error: error)

      assert_empty output.string
      assert_equal "Already exists: 2024/08.rb\n", error.string
    end
  end

  private

  def ascii_renderer(output)
    AOC::UI::Renderer.new(output: output, env: ASCII_NO_COLOR)
  end

  def ascii_with_term(term)
    {"AOC_ASCII" => "1", "TERM" => term}
  end

  def tty_stringio
    StringIO.new.tap { |io| io.define_singleton_method(:tty?) { true } }
  end

  def noop_exiter
    ->(_success) {}
  end
end
