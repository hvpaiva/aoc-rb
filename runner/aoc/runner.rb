# frozen_string_literal: true

module AOC
  # Drives the execution of a day file: infers year/day from the file path,
  # checks which parts are defined, runs declared examples, and then solves
  # against the real input. Also supports a machine-readable mode used by
  # `rake all[YYYY]` via {AllResultProtocol}.
  class Runner
    class InvalidPartSignatureError < AOC::UserError; end

    # @param paths [Paths]
    # @param input_store [InputStore] resolves cached input or downloads it.
    # @param ui [UI::Renderer] anything implementing the renderer surface
    #   (`title`, `examples_header`, `real_results`, etc.).
    # @param output [IO] machine-mode emission target.
    # @param clock [#call] zero-argument callable returning a monotonic
    #   time value for elapsed measurements.
    # @param exiter [#call] one-argument callable used to exit on failure
    #   (defaults to `Kernel.method(:exit)`).
    def initialize(
      paths: Paths.default,
      input_store: InputStore.new(paths: paths),
      ui: UI::Renderer.new,
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

    # Human mode: runs examples first, then the real input, rendering each
    # outcome through the renderer.
    #
    # @param path [String] path of the day file (defaults to
    #   `$PROGRAM_NAME`, the path under which the script was invoked).
    # @return [void]
    def run!(path: $PROGRAM_NAME)
      year, day = @paths.infer_year_day(path)
      parts = SolutionStatus.available_parts

      @ui.title(year, day)

      if parts.empty?
        @ui.config_error("Define def part1 and/or def part2 in the day file.")
        @exiter.call(false)
        return
      end

      run_examples!(parts)
      run_real_input!(year, day, parts)
    rescue SystemExit
      raise
    rescue => e
      @ui.error(e)
      @exiter.call(false)
    end

    # Machine mode: emits one {AllResultProtocol::Result} per part on
    # `@output`. Invoked when `AOC_RUN_MODE=all` is set.
    #
    # @param path [String] path of the day file.
    # @return [void]
    def run_all_day!(path: $PROGRAM_NAME)
      year, day = @paths.infer_year_day(path)
      real_input = @input_store.read(year, day)

      SolutionStatus.available_parts.each do |part|
        started = monotonic_time
        answer = solve(part, real_input)
        elapsed = monotonic_time - started

        AllResultProtocol.emit(
          @output,
          AllResultProtocol::Result.new(day: day, part: part, answer: answer.to_s, elapsed: elapsed)
        )
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

      catch(:stop) do
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
              throw :stop
            end
          rescue => e
            @ui.example_exception(label, part, e)
            @exiter.call(false)
            throw :stop
          end
        end
      end
    end

    def run_real_input!(year, day, parts)
      @ui.real_header

      real_input = @input_store.read(year, day)
      results = []

      catch(:stop) do
        parts.each do |part|
          started = monotonic_time

          begin
            answer = solve(part, real_input)
            elapsed = monotonic_time - started
          rescue => e
            elapsed = monotonic_time - started
            @ui.real_exception(part, e, elapsed)
            @exiter.call(false)
            throw :stop
          end

          results << [part, answer, elapsed]
        end
      end

      return if results.length != parts.length

      @ui.real_results(results)
    end

    # Invokes `part1` or `part2` on a fresh object that has access to the
    # puzzle input via {DSL::RuntimeInput}. The method must come from the
    # `Object` pollution caused by `def part1` at the top of the day file.
    #
    # @param part [Integer] 1 or 2.
    # @param raw_input [String] the puzzle input.
    # @return [Object] whatever the part method returned.
    # @raise [InvalidPartSignatureError] when the part method takes
    #   required positional arguments.
    def solve(part, raw_input)
      runner = Object.new
      runner.extend(DSL::RuntimeInput)
      # dup so a solution that mutates `input` (e.g. `input.upcase!`) does not
      # leak across parts or across runs that share the same source string.
      runner.__send__(:__aoc_input=, raw_input.dup)

      method = runner.method(:"part#{part}")

      if method.parameters.any? { |type, _| type == :req }
        raise InvalidPartSignatureError, "def part#{part} must take no required arguments; use input inside your methods."
      end

      method.call
    end

    private

    def monotonic_time
      @clock.call
    end
  end
end
