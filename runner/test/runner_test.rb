# frozen_string_literal: true

require_relative "test_helper"

class RunnerTest < Minitest::Test
  include RunnerTestSupport

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

  def test_solve_uses_input_dsl_and_new_object_per_run
    Object.class_eval do
      def part1
        @seen ||= []
        @seen << input
        @seen.length
      end
    end

    runner = AOC::Runner.new

    assert_equal 1, runner.solve(1, "first")
    assert_equal 1, runner.solve(1, "second")
  end

  def test_solve_rejects_part_methods_with_arguments
    Object.class_eval do
      def part1(value)
        value
      end
    end

    error = assert_raises(AOC::Runner::InvalidPartSignatureError) { AOC::Runner.new.solve(1, "input") }

    assert_equal "def part1 must take no required arguments; use input inside your methods.", error.message
  end

  def test_solve_accepts_part_methods_with_default_arguments
    Object.class_eval do
      def part1(_unused = nil) = input.length
    end

    assert_equal 3, AOC::Runner.new.solve(1, "abc")
  end

  def test_run_executes_examples_and_real_input_in_process
    Object.class_eval do
      def part1 = input.chomp.upcase
    end
    AOC::DSL.add_example("abc\n", part1: "ABC")
    paths = FakePaths.new(year: 2024, day: 2)
    input_store = FakeInputStore.new("xyz\n")

    stdout, = capture_io do
      AOC::Runner.new(paths: paths, input_store: input_store).run!(path: "2024/02.rb")
    end

    assert_includes stdout, "Ruby Advent of Code 2024 day 02"
    assert_includes stdout, "Examples"
    assert_includes stdout, 'expected = got = "ABC"'
    assert_includes stdout, "Real input"
    assert_includes stdout, 'part 1 answer: "XYZ"'
  end

  def test_run_exits_when_no_parts_are_defined
    paths = FakePaths.new(year: 2024, day: 2)

    stdout, = capture_io do
      assert_raises(SystemExit) do
        AOC::Runner.new(paths: paths, input_store: FakeInputStore.new("input")).run!(path: "2024/02.rb")
      end
    end

    assert_includes stdout, "Configuration error:"
    assert_includes stdout, "Define def part1 and/or def part2"
  end

  def test_run_reports_unexpected_errors
    paths = Object.new
    paths.define_singleton_method(:infer_year_day) { |_path| raise "boom" }

    stdout, = capture_io do
      assert_raises(SystemExit) do
        AOC::Runner.new(paths: paths, input_store: FakeInputStore.new("input")).run!(path: "bad.rb")
      end
    end

    assert_includes stdout, "Error:"
    assert_includes stdout, "RuntimeError: boom"
  end

  def test_run_all_day_outputs_json_results
    Object.class_eval do
      def part1 = input.chomp.reverse
    end
    paths = FakePaths.new(year: 2024, day: 2)
    output = StringIO.new
    ticks = [10.0, 10.125]
    clock = -> { ticks.shift }

    AOC::Runner.new(paths: paths, input_store: FakeInputStore.new("abc\n"), output: output,
      clock: clock).run_all_day!(path: "2024/02.rb")

    assert_includes output.string, "AOC_ALL_RESULT"
    assert_includes output.string, '"day":2'
    assert_includes output.string, '"part":1'
    assert_includes output.string, '"answer":"cba"'
    assert_includes output.string, '"elapsed":0.125'
  end

  def test_run_all_day_reports_unexpected_errors
    paths = FakePaths.new(year: 2024, day: 2)
    input_store = Object.new
    input_store.define_singleton_method(:read) { |_year, _day| raise "input failed" }

    stdout, = capture_io do
      assert_raises(SystemExit) do
        AOC::Runner.new(paths: paths, input_store: input_store).run_all_day!(path: "2024/02.rb")
      end
    end

    assert_includes stdout, "Error:"
    assert_includes stdout, "RuntimeError: input failed"
  end

  def test_run_all_day_reraises_system_exit_from_solution
    Object.class_eval do
      def part1 = exit(false)
    end
    paths = FakePaths.new(year: 2024, day: 2)

    assert_raises(SystemExit) do
      AOC::Runner.new(paths: paths, input_store: FakeInputStore.new("abc\n")).run_all_day!(path: "2024/02.rb")
    end
  end

  def test_run_examples_collapses_skips_for_missing_part
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part2: 0)
    AOC::DSL.add_example("xy", part2: 0)

    stdout, = capture_io do
      AOC::Runner.new.run_examples!([1])
    end

    assert_includes stdout, "part 2 · skipped in 2 examples"
    assert_includes stdout, "(no def part2)"
  end

  def test_run_examples_excludes_skip_flagged_example
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 99, skip: true)
    AOC::DSL.add_example("xyz", part1: 3)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    assert passed
    assert_includes stdout, "1 example skipped"
    assert_includes stdout, "(skip:/only:)"
    refute_includes stdout, "expected: 99"
  end

  def test_run_examples_only_flag_excludes_unmarked_examples
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 99)
    AOC::DSL.add_example("wxyz", part1: 4, only: true)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    assert passed
    assert_includes stdout, "example  2"
    assert_includes stdout, "1 example skipped"
    refute_includes stdout, "example  1"
  end

  def test_run_examples_missing_part_count_ignores_flag_skipped_examples
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part2: 0, skip: true)
    AOC::DSL.add_example("xy", part2: 0)

    stdout, = capture_io do
      AOC::Runner.new.run_examples!([1])
    end

    assert_includes stdout, "part 2 · skipped in 1 example"
    assert_includes stdout, "1 example skipped  (skip:/only:)"
  end

  def test_run_examples_flagged_failure_still_returns_false
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 99, only: true)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    refute passed
    assert_includes stdout, "Stopped before real input."
  end

  def test_run_withholds_real_input_when_examples_carry_flags
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 3, only: true)
    exits = []

    stdout, = capture_io do
      AOC::Runner.new(
        paths: FakePaths.new(year: 2024, day: 2),
        input_store: FakeInputStore.new("hello\n"),
        env: {},
        exiter: ->(success) { exits << success }
      ).run!(path: "2024/02.rb")
    end

    assert_empty exits
    assert_includes stdout, "Real input skipped while examples carry skip:/only: flags."
    refute_includes stdout, "answer:"
  end

  def test_run_force_real_env_runs_real_input_despite_flags
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 3, skip: true)

    stdout, = capture_io do
      AOC::Runner.new(
        paths: FakePaths.new(year: 2024, day: 2),
        input_store: FakeInputStore.new("hello\n"),
        env: {"AOC_FORCE_REAL" => "1"}
      ).run!(path: "2024/02.rb")
    end

    assert_includes stdout, "part 1 answer: 6"
    refute_includes stdout, "Real input skipped while"
  end

  def test_run_examples_continues_past_mismatch_and_returns_false
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 99)
    AOC::DSL.add_example("xyz", part1: 3)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    refute passed
    assert_includes stdout, "expected: 99"
    assert_includes stdout, "got: 3"
    assert_includes stdout, "example  2"
    assert_includes stdout, "Stopped before real input."
  end

  def test_run_examples_returns_true_when_all_pass
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 3)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    assert passed
    refute_includes stdout, "Stopped before real input."
  end

  def test_run_examples_aborts_on_exception_and_returns_false
    Object.class_eval do
      def part1 = raise "example exploded"
    end
    AOC::DSL.add_example("abc", part1: 1)
    AOC::DSL.add_example("xyz", part1: 1)

    passed = nil
    stdout, = capture_io do
      passed = AOC::Runner.new.run_examples!([1])
    end

    refute passed
    assert_includes stdout, "raised RuntimeError"
    assert_includes stdout, "example exploded"
    assert_includes stdout, "Stopped before real input."
    refute_includes stdout, "example  2"
  end

  def test_run_exits_without_real_input_when_examples_fail
    Object.class_eval do
      def part1 = input.length
    end
    AOC::DSL.add_example("abc", part1: 99)
    exits = []

    stdout, = capture_io do
      AOC::Runner.new(
        paths: FakePaths.new(year: 2024, day: 2),
        input_store: FakeInputStore.new("hello\n"),
        exiter: ->(success) { exits << success }
      ).run!(path: "2024/02.rb")
    end

    assert_equal [false], exits
    assert_includes stdout, "Stopped before real input."
    refute_includes stdout, "Real input"
  end

  def test_run_real_input_exits_on_exception
    Object.class_eval do
      def part1 = raise "real exploded"
    end

    stdout, = capture_io do
      assert_raises(SystemExit) do
        AOC::Runner.new(input_store: FakeInputStore.new("abc")).run_real_input!(2024, 2, [1])
      end
    end

    assert_includes stdout, "Real input"
    assert_includes stdout, "raised RuntimeError"
    assert_includes stdout, "real exploded"
  end

  def test_run_examples_is_noop_when_no_examples_declared
    Object.class_eval do
      def part1 = input.length
    end

    stdout, = capture_io { AOC::Runner.new.run_examples!([1]) }

    assert_empty stdout, "no examples means no Examples header should be printed"
  end

  def test_run_real_input_skips_render_when_aborted_via_fake_exiter
    Object.class_eval do
      def part1 = raise "fail fast"
      def part2 = 42
    end
    exits = []

    stdout, = capture_io do
      AOC::Runner.new(
        input_store: FakeInputStore.new("abc"),
        exiter: ->(success) { exits << success }
      ).run_real_input!(2024, 2, [1, 2])
    end

    # part1 failed, throw :stop ran, results never matched parts.length, so
    # no answer-line render happened.
    assert_equal [false], exits
    refute_includes stdout, "part 1 answer:"
    refute_includes stdout, "part 2 answer:"
  end

  def test_run_returns_after_config_error_with_fake_exiter
    paths = FakePaths.new(year: 2024, day: 2)
    exits = []

    stdout, = capture_io do
      AOC::Runner.new(
        paths: paths,
        input_store: FakeInputStore.new("input"),
        exiter: ->(success) { exits << success }
      ).run!(path: "2024/02.rb")
    end

    assert_equal [false], exits
    assert_includes stdout, "Configuration error:"
    # Returning early means the Examples / Real input headers must not render.
    refute_includes stdout, "Examples"
    refute_includes stdout, "Real input"
  end
end
