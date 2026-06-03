# frozen_string_literal: true

require "fileutils"

module AOC
  # Generates a new day file from {TEMPLATE}. Refuses to overwrite an
  # existing file, reporting the conflict via the injected error stream.
  # With a slug it writes a variant sibling (`YYYY/NN_<slug>.rb`) instead of
  # the canonical file, using the same template.
  class Scaffolder
    SLUG_PATTERN = /\A[a-z0-9]+\z/
    RESERVED_SLUG = "base"

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

    # Writes a fresh day file. With `slug` nil it targets the canonical
    # `paths.day_path(year, day)`; with a slug it targets the variant sibling
    # `paths.variant_path(year, day, slug)`.
    #
    # @param year [Integer, String]
    # @param day [Integer, String]
    # @param slug [String, nil] variant slug, or nil for the canonical file.
    # @return [Pathname] the day file path (created or preexisting).
    # @raise [UserError] when year/day are invalid or the slug is rejected.
    def create(year, day, slug = nil)
      year, day = Calendar.normalize_year_day!(year, day)
      path = target_path(year, day, slug)
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

    private

    def target_path(year, day, slug)
      return @paths.day_path(year, day) if slug.nil?

      @paths.variant_path(year, day, validate_slug!(slug))
    end

    def validate_slug!(slug)
      slug = slug.to_s

      unless slug.match?(SLUG_PATTERN)
        raise UserError, "Variant slug must match #{SLUG_PATTERN.inspect} (got #{slug.inspect})."
      end

      if slug == RESERVED_SLUG
        raise UserError, "Variant slug #{RESERVED_SLUG.inspect} is reserved; the canonical day file is the base."
      end

      slug
    end
  end
end
