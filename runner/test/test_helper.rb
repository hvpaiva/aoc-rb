# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "stringio"
require "tmpdir"

PROJECT_ROOT = Pathname(__dir__).join("..", "..").expand_path

require_relative "../aoc"

module RunnerTestSupport
  def with_project
    Dir.mktmpdir("aoc-rb-") do |dir|
      root = Pathname(dir)
      FileUtils.cp_r(PROJECT_ROOT.join("runner"), root.join("runner"))
      yield root
    end
  end

  def write_file(path, content)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
  end

  def run_ruby(root, *args, env: {})
    Open3.capture3(env, RbConfig.ruby, *args, chdir: root.to_s)
  end
end
