# frozen_string_literal: true

require_relative "test_helper"

class PathsTest < Minitest::Test
  def test_resolves_project_paths
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, "config"))

      assert_equal Pathname(dir).join("2024", "02.rb"), paths.day_path(2024, 2)
      assert_equal Pathname(dir).join("inputs", "2024", "02.txt"), paths.input_path(2024, 2)
      assert_equal Pathname(dir).join(".cache"), paths.cache_dir
    end
  end

  def test_uses_injected_env_for_default_config_dir
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, env: {"AOC_CONFIG_DIR" => File.join(dir, "custom-config")})

      assert_equal Pathname(dir).join("custom-config"), paths.config_dir
    end
  end

  def test_infers_year_day_from_day_file_path
    paths = AOC::Paths.new(root: PROJECT_ROOT)

    assert_equal [2024, 2], paths.infer_year_day("/tmp/aoc/2024/02.rb")
    assert_equal [2024, 2], paths.infer_year_day("/tmp/aoc/2024/day_2.rb")
  end

  def test_identifies_day_files
    assert AOC::Paths.day_file?("2024/02.rb")
    refute AOC::Paths.day_file?("runner/aoc.rb")
  end

  def test_infer_year_day_rejects_non_day_files
    paths = AOC::Paths.new(root: PROJECT_ROOT)

    error = assert_raises(AOC::UserError) { paths.infer_year_day("runner/aoc.rb") }

    assert_equal 'Could not infer year/day from "runner/aoc.rb". Use a structure like 2024/02.rb.', error.message
  end
end
