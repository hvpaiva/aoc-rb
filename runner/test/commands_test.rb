# frozen_string_literal: true

require_relative 'test_helper'

class CommandsTest < Minitest::Test
  include RunnerTestSupport

  def test_help_documents_public_commands
    stdout, = capture_io { AOC::Commands.help }

    assert_includes stdout, "rake 'new[2024,2]'"
    assert_includes stdout, 'rake all'
    assert_includes stdout, "rake 'all[2024]'"
    assert_includes stdout, 'ruby 2024/02.rb'
    assert_includes stdout, "rake 'new[2024,2,bitset]'"
    assert_includes stdout, "rake 'all[2024,2]'"
    assert_includes stdout, 'ruby 2024/02_bitset.rb'
    assert_includes stdout, 'rake ci'
    assert_includes stdout, 'rake runner:check'
  end

  def test_all_without_year_uses_overview_not_year_runner
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      stdout, = capture_io do
        AOC::Commands.all(nil, paths: paths)
      end

      assert_includes stdout, 'Ruby Advent of Code'
      assert_includes stdout, 'stars'
    end
  end

  def test_all_with_year_runs_that_year
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      error = assert_raises(AOC::UserError) do
        AOC::Commands.all(2024, paths: paths)
      end

      assert_equal 'No days found for 2024.', error.message
    end
  end

  def test_all_with_year_and_day_dispatches_to_comparison
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      error = assert_raises(AOC::UserError) do
        AOC::Commands.all(2024, 2, paths: paths)
      end

      assert_includes error.message, 'No files found for 2024 day 02'
    end
  end

  def test_run_day_focuses_variant_file
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.variant_path(2024, 2, 'bitset'), "# frozen_string_literal: true\n")
      commands = []
      command_runner = lambda do |*command|
        commands << command
        true
      end

      AOC::Commands.run_day(2024, 2, variant: 'bitset', paths: paths, command_runner: command_runner)

      assert_equal paths.variant_path(2024, 2, 'bitset').to_s, commands.first.last
    end
  end

  def test_run_day_reports_missing_variant_with_slug_hint
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      error = assert_raises(AOC::UserError) do
        AOC::Commands.run_day(2024, 2, variant: 'bitset', paths: paths)
      end

      assert_equal "File not found: 2024/02_bitset.rb. Create it with: rake 'new[2024,2,bitset]'", error.message
    end
  end

  def test_new_day_with_slug_creates_variant
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      AOC::Commands.new_day(2024, 2, 'bitset', paths: paths, output: StringIO.new, error: StringIO.new)

      assert paths.variant_path(2024, 2, 'bitset').exist?
      refute paths.day_path(2024, 2).exist?, 'variant creation must not touch the canonical file'
    end
  end

  def test_solution_files_includes_variant_files
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      write_file(paths.variant_path(2024, 2, 'bitset'), "# frozen_string_literal: true\n")

      names = AOC::Commands.solution_files(paths).map { |path| path.basename.to_s }

      assert_includes names, '02.rb'
      assert_includes names, '02_bitset.rb'
    end
  end

  def test_run_all_day_capturing_marks_failure_without_raising
    status = Object.new
    status.define_singleton_method(:success?) { false }
    marker = AOC::AllResultProtocol::MARKER
    process_runner = lambda { |*_command|
      ["#{marker}{\"day\":2,\"part\":1,\"answer\":\"x\",\"elapsed\":0.1}\n", "boom\n", status]
    }

    results, ok = AOC::Commands.run_all_day_capturing('2024/02_bad.rb', process_runner: process_runner)

    refute ok, 'a non-zero subprocess must be reported as not ok'
    assert_equal 1, results.length, 'results emitted before the failure are kept'
  end

  def test_run_day_comparison_tolerates_a_failing_variant
    with_project do |root|
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      write_file(root.join('inputs', '2024', '02.txt'), "abc\n")
      write_file(root.join('2024', '02.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        def part1 = input.chomp.length
      RUBY
      write_file(root.join('2024', '02_boom.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        def part1 = raise "kaboom"
      RUBY

      stdout, = capture_io do
        AOC::Commands.run_day_comparison(2024, 2, paths: paths)
      end

      assert_includes stdout, 'Ruby Advent of Code 2024 day 02'
      assert_includes stdout, 'base'
      assert_includes stdout, 'boom'
      assert_includes stdout, 'errored'
      assert_includes stdout, 'answer: "3"'
    end
  end

  def test_runner_check_runs_syntax_rubocop_and_runner_tests
    commands = []
    command_runner = lambda do |*command|
      commands << command
      true
    end

    AOC::Commands.runner_check(paths: AOC::Paths.new(root: PROJECT_ROOT), command_runner: command_runner)

    assert(commands.any? { |command| command[1] == '-c' && command.last == 'Rakefile' })
    assert(commands.any? { |command| command.first(3) == %w[bundle exec rubocop] })
    assert(commands.any? { |command| command.include?('-rminitest/pride') })
    assert(commands.any? { |command| command.include?('-Irunner/test') })
  end

  def test_check_lints_solutions_with_rubocop_only
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      commands = []
      command_runner = lambda do |*command|
        commands << command
        true
      end

      AOC::Commands.check(paths: paths, command_runner: command_runner)

      assert(commands.any? { |command| command.first(3) == %w[bundle exec rubocop] })
      refute commands.any? { |command| command.include?('-rminitest/pride') }, 'check must not run runner tests'
      assert commands.last.include?('2024/02.rb'), 'rubocop should target the solution file'
    end
  end

  def test_check_is_a_blocking_gate_on_rubocop_offenses
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      command_runner = ->(*command) { !command.include?('rubocop') }

      assert_raises(AOC::CommandFailed) do
        AOC::Commands.check(paths: paths, command_runner: command_runner)
      end
    end
  end

  def test_check_is_a_noop_without_solutions
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      commands = []
      command_runner = lambda do |*command|
        commands << command
        true
      end

      AOC::Commands.check(paths: paths, command_runner: command_runner)

      assert_empty commands, 'no solution files means nothing to lint'
    end
  end

  def test_ci_runs_runner_gate_then_solution_lint
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      write_file(paths.root.join('runner', 'test', 'fake_test.rb'), "# frozen_string_literal: true\n")
      write_file(paths.root.join('runner', 'aoc', 'fake.rb'), "# frozen_string_literal: true\n")
      commands = []
      command_runner = lambda do |*command|
        commands << command
        true
      end

      AOC::Commands.ci(paths: paths, command_runner: command_runner)

      rubocop_targets = commands.select { |command| command.first(3) == %w[bundle exec rubocop] }
                                .map(&:last)
      assert rubocop_targets.any? { |target| target.start_with?('runner/') }, 'ci lints the runner with RuboCop'
      assert_includes rubocop_targets, '2024/02.rb', 'ci lints the solutions with RuboCop'
      assert commands.any? { |command| command.include?('-rminitest/pride') }, 'ci runs the runner tests'
    end
  end

  def test_new_day_delegates_to_scaffolder
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      AOC::Commands.new_day(2024, 2, paths: paths, output: StringIO.new, error: StringIO.new)

      assert paths.day_path(2024, 2).exist?
    end
  end

  def test_run_day_invokes_existing_day_file
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      commands = []
      command_runner = lambda do |*command|
        commands << command
        true
      end

      AOC::Commands.run_day(2024, 2, paths: paths, command_runner: command_runner)

      assert_equal 1, commands.length
      assert_equal paths.day_path(2024, 2).to_s, commands.first.last
    end
  end

  def test_run_day_reports_missing_day_file
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      error = assert_raises(AOC::UserError) do
        AOC::Commands.run_day(2024, 2, paths: paths)
      end

      assert_equal "File not found: 2024/02.rb. Create it with: rake 'new[2024,2]'", error.message
    end
  end

  def test_run_year_runs_existing_days
    with_project do |root|
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      write_file(root.join('2024', '02.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        def part1 = input.chomp.reverse
      RUBY
      write_file(root.join('inputs', '2024', '02.txt'), "abc\n")

      stdout, = capture_io do
        AOC::Commands.run_year(2024, paths: paths)
      end

      assert_includes stdout, 'Ruby Advent of Code 2024'
      assert_includes stdout, 'day 02'
      assert_includes stdout, 'answer: "cba"'
    end
  end

  def test_run_year_reports_invalid_year
    error = assert_raises(AOC::UserError) { AOC::Commands.run_year('bad') }

    assert_equal 'Year must be an integer.', error.message
  end

  def test_run_year_does_not_mask_argument_errors_from_collaborators
    paths = Object.new
    paths.define_singleton_method(:day_files) { |_year| raise ArgumentError, 'boom from collaborator' }

    error = assert_raises(ArgumentError) { AOC::Commands.run_year('2024', paths: paths) }

    assert_equal 'boom from collaborator', error.message
  end

  def test_test_command_reports_when_no_test_files_found
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      error = assert_raises(AOC::UserError) do
        AOC::Commands.test(paths: paths, command_runner: ->(*_) { true })
      end

      assert_equal 'No runner tests found.', error.message
    end
  end

  def test_runner_files_excludes_missing_root_files
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))

      files = AOC::Commands.runner_files(paths)

      refute(files.any? { |f| f.basename.to_s == 'Gemfile' })
      refute(files.any? { |f| f.basename.to_s == 'Rakefile' })
    end
  end

  def test_runner_and_solution_file_sets_are_disjoint
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config'))
      write_file(paths.day_path(2024, 2), "# frozen_string_literal: true\n")
      write_file(paths.variant_path(2024, 2, 'bitset'), "# frozen_string_literal: true\n")
      write_file(paths.root.join('runner', 'aoc', 'fake.rb'), "# frozen_string_literal: true\n")

      runner = AOC::Commands.runner_files(paths).map { |path| path.basename.to_s }
      solutions = AOC::Commands.solution_files(paths).map { |path| path.basename.to_s }

      assert_equal ['fake.rb'], runner
      assert_equal ['02.rb', '02_bitset.rb'], solutions
    end
  end

  def test_run_all_day_reports_failed_process_without_output
    Dir.mktmpdir do |dir|
      script = Pathname(dir).join('exit.rb')
      write_file(script, <<~RUBY)
        # frozen_string_literal: true

        exit(false)
      RUBY

      assert_raises(AOC::CommandFailed) { AOC::Commands.run_all_day(script) }
    end
  end

  def test_run_all_day_replays_failed_process_output
    status = Object.new
    status.define_singleton_method(:success?) { false }
    process_runner = ->(*_command) { ["out\n", "err\n", status] }
    output = StringIO.new
    error = StringIO.new

    assert_raises(AOC::CommandFailed) do
      AOC::Commands.run_all_day('fail.rb', process_runner: process_runner, output: output, error: error)
    end

    assert_equal "out\n", output.string
    assert_equal "err\n", error.string
  end

  def test_run_command_raises_on_failed_command
    error = assert_raises(AOC::CommandFailed) do
      AOC::Commands.run_command(->(*_command) { false }, 'bad', 'command')
    end

    assert_equal 'Command failed: bad command', error.message
  end

  def test_direct_day_execution_runs_examples_and_cached_input
    with_project do |root|
      write_file(root.join('2024', '02.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        example "abc", part1: 3

        def part1 = input.chomp.length

        def part2 = input.lines.count
      RUBY
      write_file(root.join('inputs', '2024', '02.txt'), "abcd\n")

      stdout, stderr, status = run_ruby(root, '2024/02.rb', env: { 'AOC_ASCII' => '1', 'NO_COLOR' => '1' })

      assert status.success?, stderr
      assert_includes stdout, 'Examples'
      assert_includes stdout, 'expected = got = 3'
      assert_includes stdout, 'Real input'
      assert_includes stdout, 'part 1 answer: 4'
      assert_includes stdout, 'part 2 answer: 1'
    end
  end

  def test_direct_day_execution_stops_when_example_fails
    with_project do |root|
      write_file(root.join('2024', '02.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        example "abc", part1: 99

        def part1 = input.length
      RUBY

      stdout, _stderr, status = run_ruby(root, '2024/02.rb', env: { 'AOC_ASCII' => '1', 'NO_COLOR' => '1' })

      refute status.success?
      assert_includes stdout, 'Stopped before real input.'
      refute_includes stdout, 'Real input'
    end
  end

  def test_running_aoc_rb_directly_prints_help
    with_project do |root|
      stdout, _stderr, status = run_ruby(root, 'runner/aoc.rb', env: { 'AOC_ASCII' => '1', 'NO_COLOR' => '1' })

      assert status.success?
      assert_includes stdout, "rake 'new[2024,2]'"
      assert_includes stdout, 'rake 2024:02'
    end
  end

  def test_all_mode_outputs_machine_readable_results
    with_project do |root|
      write_file(root.join('2024', '02.rb'), <<~RUBY)
        # frozen_string_literal: true

        require_relative "../runner/aoc"

        example "abc", part1: 99

        def part1 = input.chomp.upcase
      RUBY
      write_file(root.join('inputs', '2024', '02.txt'), "abcd\n")

      stdout, stderr, status = run_ruby(root, '2024/02.rb',
                                        env: { 'AOC_RUN_MODE' => 'all', 'AOC_ASCII' => '1', 'NO_COLOR' => '1' })

      assert status.success?, stderr
      assert_includes stdout, 'AOC_ALL_RESULT'
      assert_includes stdout, '"answer":"ABCD"'
      refute_includes stdout, 'Examples'
    end
  end
end
