# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'stringio'
require 'tmpdir'

PROJECT_ROOT = Pathname(__dir__).join('..', '..').expand_path

# SimpleCov must boot before `minitest/autorun`: at_exit hooks fire in
# LIFO order, so SimpleCov has to register first to run last (after
# Minitest finishes executing tests).
require 'simplecov'
# Load Minitest before SimpleCov so its framework auto-detection sees it.
# Minitest's at_exit (registered now) still fires before SimpleCov's
# (registered next), thanks to at_exit's LIFO order.
require 'minitest/autorun'

SimpleCov.start do
  root PROJECT_ROOT.to_s
  # Explicit name so every run (direct ruby or `rake test`) merges into a
  # single entry in .resultset.json instead of accumulating "Minitest" plus
  # "Unit Tests" from SimpleCov's $0-based auto-detection.
  command_name 'Minitest'
  track_files 'runner/aoc/**/*.rb'
  add_filter '/runner/test/'
  enable_coverage :branch
end

require_relative '../aoc'
require_relative 'support/fakes'

module RunnerTestSupport
  def with_project
    Dir.mktmpdir('aoc-rb-') do |dir|
      root = Pathname(dir)
      FileUtils.cp_r(PROJECT_ROOT.join('runner'), root.join('runner'))
      yield root
    end
  end

  def write_file(path, content)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
  end

  def run_ruby(root, *, env: {})
    Open3.capture3(env, RbConfig.ruby, *, chdir: root.to_s)
  end
end
