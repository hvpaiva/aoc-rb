# frozen_string_literal: true

require "fileutils"

module AOC
  # Generates a new day file from {TEMPLATE}. Refuses to overwrite an
  # existing file, reporting the conflict via the injected error stream.
  class Scaffolder
    TEMPLATE = <<~RUBY
      # frozen_string_literal: true

      require_relative "../runner/aoc"

      def parsed = @parsed ||= input.lines(chomp: true)

      def part1
        raise "part1 not implemented"
      end

      # example <<~INPUT, part1: 0
      # INPUT
    RUBY

    # @param paths [Paths]
    # @param output [IO] stream for success messages.
    # @param error [IO] stream for conflict messages.
    def initialize(paths: Paths.default, output: $stdout, error: $stderr)
      @paths = paths
      @output = output
      @error = error
    end

    # Writes a fresh day file at `paths.day_path(year, day)`.
    #
    # @param year [Integer, String]
    # @param day [Integer, String]
    # @return [Pathname] the day file path (created or preexisting).
    # @raise [UserError] when year/day are invalid.
    def create(year, day)
      year, day = Calendar.normalize_year_day!(year, day)
      path = @paths.day_path(year, day)
      display_path = @paths.relative(path)

      if path.exist?
        @error.puts "Already exists: #{display_path}"
        return path
      end

      FileUtils.mkdir_p(path.dirname)
      path.write(TEMPLATE)

      @output.puts "Created: #{display_path}"
      path
    end
  end
end
