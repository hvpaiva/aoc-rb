# frozen_string_literal: true

require "net/http"
require "openssl"

require_relative "test_helper"

class DownloaderTest < Minitest::Test
  include RunnerTestSupport

  def test_default_clock_returns_integer_seconds
    clock = AOC::Downloader.new(paths: AOC::Paths.new(root: PROJECT_ROOT)).instance_variable_get(:@clock)

    assert_kind_of Integer, clock.call
  end

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
      response = ok_response("input body\n")
      http = FakeHTTP.new(response: response)

      body = AOC::Downloader.new(paths: paths, config: config, http: http).download(2024, 2)

      assert_equal "input body\n", body
      assert_equal "input body\n", paths.input_path(2024, 2).read
      assert_equal "adventofcode.com", http.captured[:host]
      assert_equal 443, http.captured[:port]
      assert_equal true, http.captured[:opts][:use_ssl]
      assert_operator http.captured[:opts][:open_timeout], :>, 0
      assert_operator http.captured[:opts][:read_timeout], :>, 0
      assert_equal "session=abc123", http.captured[:request]["Cookie"]
      assert_equal "test agent", http.captured[:request]["User-Agent"]
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
      paths = paths_in(dir)
      response = Net::HTTPForbidden.new("1.1", "403", "Forbidden")
      http = FakeHTTP.new(response: response)

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: ready_config(paths), http: http).download(2024, 2)
      end

      assert_equal "Failed to download input for 2024/2: HTTP 403 Forbidden", error.message
    end
  end

  def test_reports_redirect_as_expired_session
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
      response = Net::HTTPFound.new("1.1", "302", "Found")
      http = FakeHTTP.new(response: response)

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: ready_config(paths), http: http).download(2024, 2)
      end

      assert_match(/Session cookie likely expired/, error.message)
    end
  end

  def test_wraps_network_socket_errors_as_user_error
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
      http = FakeHTTP.new(error: SocketError.new("name resolution failed"))

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: ready_config(paths), http: http).download(2024, 2)
      end

      assert_match(/Network error contacting adventofcode.com/, error.message)
      assert_match(/SocketError/, error.message)
    end
  end

  def test_wraps_network_timeouts_as_user_error
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
      http = FakeHTTP.new(error: Net::OpenTimeout.new("open timeout"))

      error = assert_raises(AOC::UserError) do
        AOC::Downloader.new(paths: paths, config: ready_config(paths), http: http).download(2024, 2)
      end

      assert_match(/Network error contacting adventofcode.com/, error.message)
      assert_match(/OpenTimeout/, error.message)
    end
  end

  def test_throttles_downloads_using_cache_stamp
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
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
      http = FakeHTTP.new(response: ok_response("input\n"))
      sleeper = FakeSleeper.new
      clock = -> { 200 }

      AOC::Downloader.new(paths: paths, config: config, http: http, sleeper: sleeper, clock: clock).download(2024, 2)

      assert_equal [200], sleeper.sleeps
      assert_equal "200", paths.cache_dir.join("last_request_at").read
    end
  end

  def test_first_download_writes_stamp_without_sleeping
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
      config = throttled_config(paths)
      http = FakeHTTP.new(response: ok_response("input\n"))
      sleeper = FakeSleeper.new
      clock = -> { 500 }

      AOC::Downloader.new(paths: paths, config: config, http: http, sleeper: sleeper, clock: clock).download(2024, 2)

      assert_empty sleeper.sleeps
      assert_equal "500", paths.cache_dir.join("last_request_at").read
    end
  end

  def test_skips_sleep_when_interval_has_already_elapsed
    Dir.mktmpdir do |dir|
      paths = paths_in(dir)
      FileUtils.mkdir_p(paths.cache_dir)
      paths.cache_dir.join("last_request_at").write("100")
      config = throttled_config(paths)
      http = FakeHTTP.new(response: ok_response("input\n"))
      sleeper = FakeSleeper.new
      clock = -> { 1000 }

      AOC::Downloader.new(paths: paths, config: config, http: http, sleeper: sleeper, clock: clock).download(2024, 2)

      assert_empty sleeper.sleeps
      assert_equal "1000", paths.cache_dir.join("last_request_at").read
    end
  end

  private

  def throttled_config(paths)
    AOC::Config.new(
      paths: paths,
      env: {
        "AOC_SESSION" => "abc123",
        "AOC_USER_AGENT" => "test agent",
        "AOC_MIN_INTERVAL_SECONDS" => "300"
      }
    )
  end

  def paths_in(dir)
    root = Pathname(dir)
    AOC::Paths.new(root: root, config_dir: root.join("config"))
  end

  def ready_config(paths)
    AOC::Config.new(
      paths: paths,
      env: {
        "AOC_SESSION" => "abc123",
        "AOC_USER_AGENT" => "test agent",
        "AOC_MIN_INTERVAL_SECONDS" => "0"
      }
    )
  end

  def ok_response(body)
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.define_singleton_method(:body) { body }
    end
  end
end
