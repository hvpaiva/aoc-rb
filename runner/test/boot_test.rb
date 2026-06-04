# frozen_string_literal: true

require_relative "test_helper"

class BootTest < Minitest::Test
  def setup
    AOC::Boot.reset!
  end

  def teardown
    AOC::Boot.reset!
  end

  def test_install_is_idempotent_for_non_day_processes
    handlers = []
    at_exit_handler = ->(&block) { handlers << block }

    AOC::Boot.install!(program_name: "runner/test/boot_test.rb", at_exit_handler: at_exit_handler)
    AOC::Boot.install!(program_name: "runner/test/boot_test.rb", at_exit_handler: at_exit_handler)

    assert_empty handlers, "non-day-file process should never register an at_exit handler"
  end

  def test_install_only_registers_auto_runner_once
    handlers = []
    at_exit_handler = ->(&block) { handlers << block }
    runner_factory = -> { Object.new.tap { |r| r.define_singleton_method(:run!) { nil } } }

    AOC::Boot.install!(
      program_name: "2024/02.rb",
      at_exit_handler: at_exit_handler,
      runner_factory: runner_factory,
      failure: -> {}
    )
    AOC::Boot.install!(
      program_name: "2024/02.rb",
      at_exit_handler: at_exit_handler,
      runner_factory: runner_factory,
      failure: -> {}
    )

    assert_equal 1, handlers.length
  end

  def test_install_registers_day_file_at_exit_for_normal_run
    calls = with_stubbed_day_file_boot do |block, calls|
      block.call
      calls
    end

    assert_equal [:run], calls
  end

  def test_install_registers_day_file_at_exit_for_protocol_emission
    calls = with_stubbed_day_file_boot(env: {"AOC_EMIT" => "protocol"}) do |block, calls|
      block.call
      calls
    end

    assert_equal [:run_all_day], calls
  end

  def test_install_registers_auto_runner_for_variant_day_file
    handlers = []
    at_exit_handler = ->(&block) { handlers << block }
    runner_factory = -> { Object.new.tap { |r| r.define_singleton_method(:run!) { nil } } }

    AOC::Boot.install!(
      program_name: "2024/02_bitset.rb",
      at_exit_handler: at_exit_handler,
      runner_factory: runner_factory,
      failure: -> {}
    )

    assert_equal 1, handlers.length, "a variant day file should register the auto-runner"
  end

  def test_install_skips_auto_runner_when_process_is_unwinding
    captured_block = nil
    calls = []
    fake_runner = Object.new
    fake_runner.define_singleton_method(:run!) { calls << :run }
    at_exit_handler = ->(&block) { captured_block = block }

    AOC::Boot.install!(
      program_name: "2024/02.rb",
      env: {},
      at_exit_handler: at_exit_handler,
      runner_factory: -> { fake_runner },
      failure: -> { RuntimeError.new("uncaught") }
    )

    captured_block.call

    assert_empty calls
  end

  private

  def with_stubbed_day_file_boot(env: {})
    captured_block = nil
    calls = []
    fake_runner = Object.new
    fake_runner.define_singleton_method(:run!) { calls << :run }
    fake_runner.define_singleton_method(:run_all_day!) { calls << :run_all_day }
    at_exit_handler = ->(&block) { captured_block = block }
    runner_factory = -> { fake_runner }

    AOC::Boot.install!(
      program_name: "2024/02.rb",
      env: env,
      at_exit_handler: at_exit_handler,
      runner_factory: runner_factory
    )

    yield captured_block, calls
  end
end
