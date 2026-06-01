# frozen_string_literal: true

require_relative 'test_helper'

class InputStoreTest < Minitest::Test
  include RunnerTestSupport

  def test_reads_cached_input_without_downloading
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      write_file(paths.input_path(2024, 2), "cached\n")
      downloader = Object.new
      downloader.define_singleton_method(:download) do |*_args|
        raise 'download should not be called'
      end

      assert_equal "cached\n", AOC::InputStore.new(paths: paths, downloader: downloader).read(2024, 2)
    end
  end

  def test_downloads_missing_input
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join('config'))
      calls = []
      downloader = Object.new
      downloader.define_singleton_method(:download) do |*args|
        calls << args
        "downloaded\n"
      end

      assert_equal "downloaded\n", AOC::InputStore.new(paths: paths, downloader: downloader).read(2024, 2)
      assert_equal [[2024, 2, paths.input_path(2024, 2)]], calls
    end
  end
end
