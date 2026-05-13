# frozen_string_literal: true

require "net/http"

require_relative "test_helper"

class DownloaderTest < Minitest::Test
  def test_downloads_input_with_session_and_user_agent_without_real_network
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      config = AOC::Config.new(
        paths: paths,
        env: {
          "AOC_SESSION" => "session=abc123",
          "AOC_USER_AGENT" => "test agent",
          "AOC_MIN_INTERVAL_SECONDS" => "0"
        }
      )
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.define_singleton_method(:body) { "input body\n" }
      captured = {}
      client = Object.new
      client.define_singleton_method(:request) do |request|
        captured[:request] = request
        response
      end
      http = Object.new
      http.define_singleton_method(:start) do |host, port, use_ssl:, &block|
        captured[:host] = host
        captured[:port] = port
        captured[:use_ssl] = use_ssl
        block.call(client)
      end

      body = AOC::Downloader.new(paths: paths, config: config, http: http).download(2024, 2)

      assert_equal "input body\n", body
      assert_equal "input body\n", paths.input_path(2024, 2).read
      assert_equal "adventofcode.com", captured[:host]
      assert_equal 443, captured[:port]
      assert_equal true, captured[:use_ssl]
      assert_equal "session=abc123", captured[:request]["Cookie"]
      assert_equal "test agent", captured[:request]["User-Agent"]
    end
  end

  def test_rejects_missing_configuration_before_network
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      config = AOC::Config.new(paths: paths, env: {"AOC_MIN_INTERVAL_SECONDS" => "0"})

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: config).download(2024, 2)
      end

      assert_match(/Configure AOC_SESSION/, error.message)
    end
  end

  def test_rejects_missing_user_agent_before_network
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      config = AOC::Config.new(
        paths: paths,
        env: {"AOC_SESSION" => "abc123", "AOC_MIN_INTERVAL_SECONDS" => "0"}
      )

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: config).download(2024, 2)
      end

      assert_match(/Configure AOC_USER_AGENT/, error.message)
    end
  end

  def test_reports_http_failures
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      config = AOC::Config.new(
        paths: paths,
        env: {
          "AOC_SESSION" => "abc123",
          "AOC_USER_AGENT" => "test agent",
          "AOC_MIN_INTERVAL_SECONDS" => "0"
        }
      )
      response = Net::HTTPForbidden.new("1.1", "403", "Forbidden")
      http = Object.new
      http.define_singleton_method(:start) { |_host, _port, use_ssl:, &_block| response }

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: config, http: http).download(2024, 2)
      end

      assert_equal "Failed to download input for 2024/2: HTTP 403 Forbidden", error.message
    end
  end

  def test_throttles_downloads_using_cache_stamp
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      paths = AOC::Paths.new(root: root, config_dir: root.join("config"))
      FileUtils.mkdir_p(paths.cache_dir)
      paths.cache_dir.join("last_request_at").write("100")
      config = AOC::Config.new(
        paths: paths,
        env: {
          "AOC_SESSION" => "abc123",
          "AOC_USER_AGENT" => "test agent",
          "AOC_MIN_INTERVAL_SECONDS" => "300"
        }
      )
      response = Net::HTTPOK.new("1.1", "200", "OK")
      response.define_singleton_method(:body) { "input\n" }
      client = fake_http_client(response)
      http = Object.new
      http.define_singleton_method(:start) { |_host, _port, use_ssl:, &block| block.call(client) }
      sleeper = Object.new
      sleeps = []
      sleeper.define_singleton_method(:sleep) { |seconds| sleeps << seconds }
      clock = Object.new
      clock.define_singleton_method(:now) { Time.at(200) }

      AOC::Downloader.new(paths: paths, config: config, http: http, sleeper: sleeper, clock: clock).download(2024, 2)

      assert_equal [200], sleeps
      assert_equal "200", paths.cache_dir.join("last_request_at").read
    end
  end

  private

  def fake_http_client(response)
    Object.new.tap do |client|
      client.define_singleton_method(:request) { |_request| response }
    end
  end
end
