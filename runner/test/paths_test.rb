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
  end

  def test_identifies_day_files
    assert AOC::Paths.day_file?("2024/02.rb")
    refute AOC::Paths.day_file?("runner/aoc.rb")
    refute AOC::Paths.day_file?("2024/day_2.rb"), "non-canonical names should be rejected"
    refute AOC::Paths.day_file?("2024/2.rb"), "non-zero-padded names should be rejected"
  end

  def test_recognizes_variant_files_as_executable_day_files
    assert AOC::Paths.day_file?("2024/02_alt.rb"), "underscore variant should be executable"
    assert AOC::Paths.day_file?("2024/02-brute.rb"), "dash variant should be executable"
    refute AOC::Paths.day_file?("2024/021.rb"), "a third digit is not a variant separator"
  end

  def test_infers_year_day_from_variant_path
    paths = AOC::Paths.new(root: PROJECT_ROOT)

    assert_equal [2024, 2], paths.infer_year_day("/tmp/aoc/2024/02_bitset.rb")
    assert_equal [2024, 2], paths.infer_year_day("/tmp/aoc/2024/02-brute.rb")
  end

  def test_variant_path_builds_zero_padded_sibling
    paths = AOC::Paths.new(root: "/tmp/aoc")

    assert_equal Pathname("/tmp/aoc/2024/02_bitset.rb"), paths.variant_path(2024, 2, "bitset")
  end

  def test_infer_variant_returns_slug_or_nil
    paths = AOC::Paths.new(root: PROJECT_ROOT)

    assert_nil paths.infer_variant("2024/02.rb")
    assert_equal "bitset", paths.infer_variant("2024/02_bitset.rb")
    assert_equal "brute", paths.infer_variant("2024/02-brute.rb")
  end

  def test_day_variants_lists_canonical_first_then_sorted_variants
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      %w[02.rb 02_bitset.rb 02-brute.rb 02_alt.rb].each do |name|
        path = root.join("2024", name)
        path.dirname.mkpath
        path.write("")
      end

      variants = paths.day_variants(2024, 2).map { |path| path.basename.to_s }

      assert_equal "02.rb", variants.first, "canonical must come first"
      assert_equal ["02-brute.rb", "02_alt.rb", "02_bitset.rb"], variants.drop(1)
    end
  end

  def test_day_variants_omits_missing_canonical
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      path = root.join("2024", "02_only.rb")
      path.dirname.mkpath
      path.write("")

      variants = paths.day_variants(2024, 2).map { |p| p.basename.to_s }

      assert_equal ["02_only.rb"], variants
    end
  end

  def test_day_files_stays_strict_and_excludes_variants
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      %w[02.rb 02_bitset.rb 03.rb].each do |name|
        path = root.join("2024", name)
        path.dirname.mkpath
        path.write("")
      end

      files = paths.day_files(2024).map { |path| path.basename.to_s }

      assert_equal ["02.rb", "03.rb"], files, "day_files must not pick up variants"
    end
  end

  def test_infer_year_day_rejects_non_day_files
    paths = AOC::Paths.new(root: PROJECT_ROOT)

    error = assert_raises(AOC::UserError) { paths.infer_year_day("runner/aoc.rb") }

    assert_equal 'Could not infer year/day from "runner/aoc.rb". Use a structure like 2024/02.rb.', error.message
  end

  def test_default_is_memoized
    first = AOC::Paths.default
    second = AOC::Paths.default

    assert_same first, second
  end

  def test_reset_default_clears_the_memoization
    AOC::Paths.default # warm the cache
    AOC::Paths.reset_default!

    assert_nil AOC::Paths.instance_variable_get(:@default)
  ensure
    AOC::Paths.reset_default!
  end
end
