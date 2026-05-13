# frozen_string_literal: true

require "json"

module AOC
  class Runner
    def initialize(
      paths: Paths.default,
      input_store: InputStore.new(paths: paths),
      ui: UI,
      output: $stdout,
      clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
      exiter: Kernel.method(:exit)
    )
      @paths = paths
      @input_store = input_store
      @ui = ui
      @output = output
      @clock = clock
      @exiter = exiter
    end

    def run!(path: $PROGRAM_NAME)
      year, day = @paths.infer_year_day(path)
      parts = SolutionStatus.available_parts

      @ui.title(year, day)

      if parts.empty?
        @ui.config_error("Define def part1 and/or def part2 in the day file.")
        @exiter.call(false)
      end

      run_examples!(parts)
      run_real_input!(year, day, parts)
    rescue SystemExit
      raise
    rescue => e
      @ui.error(e)
      @exiter.call(false)
    end

    def run_all_day!(path: $PROGRAM_NAME)
      year, day = @paths.infer_year_day(path)
      real_input = @input_store.read(year, day)

      SolutionStatus.available_parts.each do |part|
        started = monotonic_time
        answer = solve(part, real_input)
        elapsed = monotonic_time - started

        @output.puts "AOC_ALL_RESULT #{JSON.generate(day: day, part: part, answer: @ui.value(answer), elapsed: elapsed)}"
      end
    rescue SystemExit
      raise
    rescue => e
      @ui.error(e)
      @exiter.call(false)
    end

    def run_examples!(parts)
      return if DSL.examples.empty?

      @ui.examples_header

      DSL.examples.each_with_index do |example, index|
        label = example.name || "example #{format("%2d", index + 1)}"

        example.expected.each do |part, expected|
          unless parts.include?(part)
            @ui.example_skip(label, part)
            next
          end

          actual = solve(part, example.input)

          if actual == expected
            @ui.example_ok(label, part, actual)
          else
            @ui.example_fail(label, part, expected, actual)
            @exiter.call(false)
          end
        rescue => e
          @ui.example_exception(label, part, e)
          @exiter.call(false)
        end
      end
    end

    def run_real_input!(year, day, parts)
      @ui.real_header

      real_input = @input_store.read(year, day)
      results = []

      parts.each do |part|
        started = monotonic_time

        begin
          answer = solve(part, real_input)
          elapsed = monotonic_time - started
        rescue => e
          elapsed = monotonic_time - started
          @ui.real_exception(part, e, elapsed)
          @exiter.call(false)
        end

        results << [part, answer, elapsed]
      end

      answer_width = results.map { |_part, answer, _elapsed| @ui.value(answer).length }.max || 0

      results.each do |part, answer, elapsed|
        @ui.real_part(part, answer, elapsed, answer_width)
      end
    end

    def solve(part, raw_input)
      runner = Object.new
      runner.extend(DSL::RuntimeInput)
      runner.__send__(:__aoc_input=, raw_input.dup)

      method = runner.method(:"part#{part}")

      unless method.arity.zero?
        raise "def part#{part} must receive zero arguments; use input inside your methods."
      end

      method.call
    end

    private

    def monotonic_time
      @clock.call
    end
  end
end
