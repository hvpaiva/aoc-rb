# frozen_string_literal: true

require "fileutils"

module AOC
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

    def initialize(paths: Paths.default, output: $stdout, error: $stderr)
      @paths = paths
      @output = output
      @error = error
    end

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
