# frozen_string_literal: true

require "date"
require "json"
require "open3"
require "rbconfig"

module AOC
  module Commands
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

    def overview(paths: Paths.default)
      years = (2015..Date.today.year).to_a
      overview = years.map { |year| [year, SolutionStatus.year_stars(year, paths: paths)] }

      UI.print_overview(overview)
    end

    def run_year(year, paths: Paths.default)
      year = Integer(year)
      day_paths = paths.day_files(year)

      raise UserError, "No days found for #{year}." if day_paths.empty?

      results = day_paths.flat_map { |path| run_all_day(path) }

      UI.print_year_results(year, results)
    rescue ArgumentError
      raise UserError, "Year must be an integer."
    end

    def check(paths: Paths.default, command_runner: method(:system))
      files = paths.check_files.map { |path| paths.relative(path) }

      files.each do |path|
        run_command(command_runner, RbConfig.ruby, "-c", path)
      end

      run_command(command_runner, "bundle", "exec", "standardrb", *files)
      test(paths: paths, command_runner: command_runner)
    end

    def test(paths: Paths.default, command_runner: method(:system))
      test_files = paths.test_files.map { |path| paths.relative(path) }
      raise UserError, "No runner tests found." if test_files.empty?

      run_command(
        command_runner,
        "bundle",
        "exec",
        RbConfig.ruby,
        "-rminitest/pride",
        "-Irunner/test",
        "-e",
        "ARGV.each { |file| require File.expand_path(file) }",
        *test_files
      )
    end

    def cli!(argv, error: $stderr, exiter: Kernel.method(:exit))
      command, year, day = argv

      case command
      when "new"
        raise UserError, "Usage: ruby runner/aoc.rb new 2024 1" unless year && day

        new_day(year, day)
      else
        raise UserError, "Usage: ruby runner/aoc.rb new 2024 1"
      end
    rescue UserError => e
      error.puts e.message
      exiter.call(false)
    end

    def run_all_day(path, process_runner: Open3.method(:capture3), output: $stdout, error: $stderr)
      stdout, stderr, status = process_runner.call({"AOC_RUN_MODE" => "all"}, RbConfig.ruby, path.to_s)

      unless status.success?
        output.write(stdout)
        error.write(stderr)
        raise CommandFailed, "Command failed: #{RbConfig.ruby} #{path}"
      end

      stdout.each_line.filter_map do |line|
        next unless line.start_with?("AOC_ALL_RESULT ")

        JSON.parse(line.delete_prefix("AOC_ALL_RESULT "))
      end
    end

    def run_command(command_runner, *command)
      return if command_runner.call(*command)

      raise CommandFailed, "Command failed: #{command.join(" ")}"
    end
  end
end
