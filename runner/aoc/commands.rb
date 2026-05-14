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
      "[0-9][0-9][0-9][0-9]/[0-9][0-9].rb"
    ].freeze

    # Files included in `rake test`.
    TEST_FILE_GLOB = "runner/test/**/*_test.rb"

    module_function

    def help
      puts <<~TEXT
        Usage:
          rake 'new[2024,2]'  # create 2024/02.rb
          rake 2024:02        # run 2024/02.rb
          rake all            # show global progress
          rake 'all[2024]'    # run real inputs for a year
          rake check          # validate Ruby syntax, style, and tests

        Direct execution also works:
          ruby 2024/02.rb
      TEXT
    end

    def new_day(year, day, paths: Paths.default, output: $stdout, error: $stderr)
      Scaffolder.new(paths: paths, output: output, error: error).create(year, day)
    end

    def run_day(year, day, paths: Paths.default, command_runner: method(:system))
      path = paths.day_path(year, day)

      unless path.exist?
        raise UserError, "File not found: #{paths.relative(path)}. Create it with: rake 'new[#{year},#{day.to_i}]'"
      end

      run_command(command_runner, RbConfig.ruby, path.to_s)
    end

    def all(year = nil, paths: Paths.default)
      if year.nil? || year.to_s.empty?
        overview(paths: paths)
      else
        run_year(year, paths: paths)
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

    def run_command(command_runner, *command)
      return if command_runner.call(*command)

      raise CommandFailed, "Command failed: #{command.join(" ")}"
    end
  end
end
