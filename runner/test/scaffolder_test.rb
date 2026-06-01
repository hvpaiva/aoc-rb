# frozen_string_literal: true

require_relative 'test_helper'

class ScaffolderTest < Minitest::Test
  include RunnerTestSupport

  EXPECTED_TEMPLATE = <<~RUBY
    # frozen_string_literal: true

    require_relative "../runner/aoc"

    def parsed = @parsed ||= input.lines(chomp: true)

    def part1
      raise "part1 not implemented"
    end

    # example <<~INPUT, part1: 0
    # INPUT
  RUBY

  def test_creates_expected_day_template
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))

      path = AOC::Scaffolder.new(paths: paths, output: StringIO.new, error: StringIO.new).create(2024, 2)

      assert_equal root.join('2024', '02.rb'), path
      assert_equal EXPECTED_TEMPLATE, path.read
    end
  end

  def test_does_not_overwrite_existing_day
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      write_file(paths.day_path(2024, 2), "existing\n")
      error = StringIO.new

      AOC::Scaffolder.new(paths: paths, output: StringIO.new, error: error).create(2024, 2)

      assert_equal "existing\n", paths.day_path(2024, 2).read
      assert_equal "Already exists: 2024/02.rb\n", error.string
    end
  end

  def test_creates_variant_sibling_with_same_template
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      output = StringIO.new

      path = AOC::Scaffolder.new(paths: paths, output: output, error: StringIO.new).create(2024, 2, 'bitset')

      assert_equal root.join('2024', '02_bitset.rb'), path
      assert_equal EXPECTED_TEMPLATE, path.read
      assert_equal "Created: 2024/02_bitset.rb\n", output.string
    end
  end

  def test_does_not_overwrite_existing_variant
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      write_file(paths.variant_path(2024, 2, 'bitset'), "existing\n")
      error = StringIO.new

      AOC::Scaffolder.new(paths: paths, output: StringIO.new, error: error).create(2024, 2, 'bitset')

      assert_equal "existing\n", paths.variant_path(2024, 2, 'bitset').read
      assert_equal "Already exists: 2024/02_bitset.rb\n", error.string
    end
  end

  def test_rejects_invalid_slug
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))

      error = assert_raises(AOC::UserError) do
        AOC::Scaffolder.new(paths: paths, output: StringIO.new, error: StringIO.new).create(2024, 2, 'Bit_Set')
      end

      assert_includes error.message, 'Variant slug must match'
    end
  end

  def test_rejects_reserved_base_slug
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))

      error = assert_raises(AOC::UserError) do
        AOC::Scaffolder.new(paths: paths, output: StringIO.new, error: StringIO.new).create(2024, 2, 'base')
      end

      assert_includes error.message, 'reserved'
    end
  end
end
