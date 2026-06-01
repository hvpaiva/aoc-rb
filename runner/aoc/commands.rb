# frozen_string_literal: true

require "date"
require "open3"
require "rbconfig"

module AOC
  module Commands
    # Files included in `rake check` (syntax + style).
    CHECK_FILES_AT_ROOT = %w[Gemfile Rakefile].freeze
    CHECK_FILE_GLOBS = [
      "runner/**/*.rb",
      "[0-9][0-9][0-9][0-9]/[0-9][0-9].rb",
      "[0-9][0-9][0-9][0-9]/[0-9][0-9][_-]*.rb"
    ].freeze

    # Files included in `rake test`.
    TEST_FILE_GLOB = "runner/test/**/*_test.rb"

    module_function

    def help
      puts <<~TEXT
        Usage:
          rake 'new[2024,2]'         # create 2024/02.rb
          rake 'new[2024,2,bitset]'  # create the 2024/02_bitset.rb variant
          rake 2024:02               # run 2024/02.rb
          rake '2024:02[bitset]'     # run the 2024/02_bitset.rb variant
          rake all                   # show global progress
          rake 'all[2024]'           # run real inputs for a year
          rake 'all[2024,2]'         # compare a day's variants on real input
          rake check                 # validate Ruby syntax, style, and tests

        Direct execution also works:
          ruby 2024/02.rb
          ruby 2024/02_bitset.rb
      TEXT
    end

    def new_day(year, day, slug = nil, paths: Paths.default, output: $stdout, error: $stderr)
      slug = nil if slug.to_s.empty?
      Scaffolder.new(paths: paths, output: output, error: error).create(year, day, slug)
    end

    def run_day(year, day, variant: nil, paths: Paths.default, command_runner: method(:system))
      variant = nil if variant.to_s.empty?
      path = variant ? paths.variant_path(year, day, variant) : paths.day_path(year, day)

      unless path.exist?
        hint = variant ? "rake 'new[#{year},#{day.to_i},#{variant}]'" : "rake 'new[#{year},#{day.to_i}]'"
        raise UserError, "File not found: #{paths.relative(path)}. Create it with: #{hint}"
      end

      run_command(command_runner, RbConfig.ruby, path.to_s)
    end

    def all(year = nil, day = nil, paths: Paths.default)
      if year.nil? || year.to_s.empty?
        overview(paths: paths)
      elsif day.nil? || day.to_s.empty?
        run_year(year, paths: paths)
      else
        run_day_comparison(year, day, paths: paths)
      end
    end

    def overview(paths: Paths.default, renderer: UI::Renderer.new)
      years = (2015..Date.today.year).to_a
      overview = years.map { |year| [year, SolutionStatus.year_stars(year, paths: paths)] }

      renderer.print_overview(overview)
    end

    def run_year(year, paths: Paths.default, renderer: UI::Renderer.new)
      year = parse_year(year)
      day_paths = paths.day_files(year)

      raise UserError, "No days found for #{year}." if day_paths.empty?

      results = day_paths.flat_map { |path| run_all_day(path) }

      renderer.print_year_results(year, results)
    end

    # Comparison mode (`rake 'all[YYYY,DD]'`): runs the canonical file and every
    # variant of one day against the real input only (no examples) and renders a
    # per-variant table with per-part timing and answer divergence. Unlike
    # {#run_year}, a single failing file is collected and marked rather than
    # aborting its siblings.
    def run_day_comparison(year, day, paths: Paths.default, renderer: UI::Renderer.new)
      year, day = Calendar.normalize_year_day!(year, day)
      files = paths.day_variants(year, day)

      if files.empty?
        raise UserError, "No files found for #{year} day #{format("%02d", day)}. Create one with: rake 'new[#{year},#{day}]'"
      end

      variants = files.map do |path|
        label = paths.infer_variant(path) || "base"
        results, ok = run_all_day_capturing(path)
        [label, results, ok]
      end

      renderer.print_day_comparison(year, day, variants)
    end

    def parse_year(value)
      Integer(value)
    rescue ArgumentError
      raise UserError, "Year must be an integer."
    end

    def check(paths: Paths.default, command_runner: method(:system))
      files = check_files(paths).map { |path| paths.relative(path) }

      files.each do |path|
        run_command(command_runner, RbConfig.ruby, "-c", path)
      end

      run_command(command_runner, "bundle", "exec", "standardrb", *files)
      test(paths: paths, command_runner: command_runner)
    end

    def test(paths: Paths.default, command_runner: method(:system))
      tests = test_files(paths).map { |path| paths.relative(path) }
      raise UserError, "No runner tests found." if tests.empty?

      run_command(
        command_runner,
        "bundle",
        "exec",
        RbConfig.ruby,
        "-rminitest/pride",
        "-Irunner/test",
        "-e",
        "ARGV.each { |file| require File.expand_path(file) }",
        *tests
      )
    end

    def check_files(paths)
      files = CHECK_FILES_AT_ROOT.filter_map do |name|
        candidate = paths.root.join(name)
        candidate if candidate.exist?
      end

      CHECK_FILE_GLOBS.each do |pattern|
        files.concat(Pathname.glob(paths.root.join(pattern)))
      end

      files.uniq.sort_by(&:to_s)
    end

    def test_files(paths)
      Pathname.glob(paths.root.join(TEST_FILE_GLOB)).sort_by(&:to_s)
    end

    def run_all_day(path, process_runner: Open3.method(:capture3), output: $stdout, error: $stderr)
      stdout, stderr, status = process_runner.call({"AOC_RUN_MODE" => "all"}, RbConfig.ruby, path.to_s)

      unless status.success?
        output.write(stdout)
        error.write(stderr)
        raise CommandFailed, "Command failed: #{RbConfig.ruby} #{path}"
      end

      AllResultProtocol.parse(stdout)
    end

    # Like {#run_all_day} but tolerant: returns `[results, ok]` instead of
    # raising on a non-zero subprocess, so comparison mode can mark a failing
    # variant and keep going. Any results emitted before the failure are kept.
    def run_all_day_capturing(path, process_runner: Open3.method(:capture3))
      stdout, _stderr, status = process_runner.call({"AOC_RUN_MODE" => "all"}, RbConfig.ruby, path.to_s)

      [AllResultProtocol.parse(stdout), status.success?]
    end

    def run_command(command_runner, *command)
      return if command_runner.call(*command)

      raise CommandFailed, "Command failed: #{command.join(" ")}"
    end
  end
end
