# frozen_string_literal: true

require_relative 'test_helper'

class ConfigTest < Minitest::Test
  include RunnerTestSupport

  def test_reads_environment_before_config_files
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_file(root.join('config', 'session'), "file-session\n")

      config = AOC::Config.new(
        paths: AOC::Paths.new(root: root, config_dir: root.join('config')),
        env: { 'AOC_SESSION' => ' env-session ' }
      )

      assert_equal 'env-session', config.session
    end
  end

  def test_reads_config_file_when_env_is_missing
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_file(root.join('config', 'user_agent'), "agent\n")

      config = AOC::Config.new(
        paths: AOC::Paths.new(root: root, config_dir: root.join('config')),
        env: {}
      )

      assert_equal 'agent', config.user_agent
    end
  end

  def test_min_interval_defaults_and_overrides
    default = AOC::Config.new(env: {})
    custom = AOC::Config.new(env: { 'AOC_MIN_INTERVAL_SECONDS' => '0' })

    assert_equal 300, default.min_interval_seconds
    assert_equal 0, custom.min_interval_seconds
  end

  def test_min_interval_treats_blank_as_default
    config = AOC::Config.new(env: { 'AOC_MIN_INTERVAL_SECONDS' => '   ' })

    assert_equal 300, config.min_interval_seconds
  end

  def test_min_interval_rejects_non_integer
    config = AOC::Config.new(env: { 'AOC_MIN_INTERVAL_SECONDS' => 'abc' })

    error = assert_raises(AOC::UserError) { config.min_interval_seconds }

    assert_match(/AOC_MIN_INTERVAL_SECONDS must be a non-negative integer/, error.message)
  end

  def test_min_interval_rejects_negative
    config = AOC::Config.new(env: { 'AOC_MIN_INTERVAL_SECONDS' => '-1' })

    error = assert_raises(AOC::UserError) { config.min_interval_seconds }

    assert_match(/AOC_MIN_INTERVAL_SECONDS must be a non-negative integer/, error.message)
  end

  def test_session_bang_raises_when_missing
    Dir.mktmpdir do |dir|
      config = AOC::Config.new(
        paths: AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config')),
        env: {}
      )

      error = assert_raises(AOC::UserError) { config.session! }

      assert_match(/Configure AOC_SESSION/, error.message)
    end
  end

  def test_user_agent_bang_raises_when_missing
    Dir.mktmpdir do |dir|
      config = AOC::Config.new(
        paths: AOC::Paths.new(root: dir, config_dir: File.join(dir, 'config')),
        env: {}
      )

      error = assert_raises(AOC::UserError) { config.user_agent! }

      assert_match(/Configure AOC_USER_AGENT/, error.message)
    end
  end

  def test_session_bang_returns_value_when_present
    config = AOC::Config.new(env: { 'AOC_SESSION' => 'abc' })

    assert_equal 'abc', config.session!
  end

  def test_blank_config_file_is_treated_as_absent
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_file(root.join('config', 'session'), "   \n")

      config = AOC::Config.new(
        paths: AOC::Paths.new(root: root, config_dir: root.join('config')),
        env: {}
      )

      assert_nil config.session
    end
  end
end
