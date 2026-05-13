# frozen_string_literal: true

require_relative "test_helper"

class ConfigTest < Minitest::Test
  include RunnerTestSupport

  def test_reads_environment_before_config_files
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_file(root.join("config", "session"), "file-session\n")

      config = AOC::Config.new(
        paths: AOC::Paths.new(root: root, config_dir: root.join("config")),
        env: {"AOC_SESSION" => " env-session "}
      )

      assert_equal "env-session", config.session
    end
  end

  def test_reads_config_file_when_env_is_missing
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      write_file(root.join("config", "user_agent"), "agent\n")

      config = AOC::Config.new(
        paths: AOC::Paths.new(root: root, config_dir: root.join("config")),
        env: {}
      )

      assert_equal "agent", config.user_agent
    end
  end

  def test_min_interval_defaults_and_overrides
    default = AOC::Config.new(env: {})
    custom = AOC::Config.new(env: {"AOC_MIN_INTERVAL_SECONDS" => "0"})

    assert_equal 300, default.min_interval_seconds
    assert_equal 0, custom.min_interval_seconds
  end
end
