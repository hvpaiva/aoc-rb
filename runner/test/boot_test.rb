# frozen_string_literal: true

require_relative "test_helper"

class BootTest < Minitest::Test
  def test_install_is_idempotent_for_non_day_processes
    original_installed = AOC::Boot.instance_variable_get(:@installed)
    AOC::Boot.instance_variable_set(:@installed, nil)

    AOC::Boot.install!(program_name: "runner/test/boot_test.rb")
    AOC::Boot.install!(program_name: "runner/test/boot_test.rb")

    assert_equal true, AOC::Boot.instance_variable_get(:@installed)
  ensure
    AOC::Boot.instance_variable_set(:@installed, original_installed)
  end

  def test_install_registers_day_file_at_exit_for_normal_run
    calls = with_stubbed_day_file_boot do |block, calls|
      block.call
      calls
    end

    assert_equal [:run], calls
  end

  def test_install_registers_day_file_at_exit_for_all_mode
    calls = with_stubbed_day_file_boot(env: {"AOC_RUN_MODE" => "all"}) do |block, calls|
      block.call
      calls
    end

    assert_equal [:run_all_day], calls
  end

  private

  def with_stubbed_day_file_boot(env: {})
    original_installed = AOC::Boot.instance_variable_get(:@installed)
    captured_block = nil
    calls = []
    fake_runner = Object.new
    fake_runner.define_singleton_method(:run!) { calls << :run }
    fake_runner.define_singleton_method(:run_all_day!) { calls << :run_all_day }
    at_exit_handler = ->(&block) { captured_block = block }
    runner_factory = -> { fake_runner }

    AOC::Boot.instance_variable_set(:@installed, nil)

    AOC::Boot.install!(
      program_name: "2024/02.rb",
      env: env,
      at_exit_handler: at_exit_handler,
      runner_factory: runner_factory,
      failure: -> {}
    )

    yield captured_block, calls
  ensure
    AOC::Boot.instance_variable_set(:@installed, original_installed)
  end
end
