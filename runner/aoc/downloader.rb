# frozen_string_literal: true

require 'fileutils'
require 'net/http'
require 'openssl'
require 'uri'

module AOC
  # Fetches puzzle input from adventofcode.com. Enforces a polite throttle,
  # wraps network errors as {UserError}, treats 302 redirects as expired
  # cookies, and caches the response to disk. Designed to be injected with
  # fakes for `http`, `sleeper`, and `clock` so tests never touch the network.
  class Downloader
    OPEN_TIMEOUT_SECONDS = 10
    READ_TIMEOUT_SECONDS = 30
    WRITE_TIMEOUT_SECONDS = 10

    NETWORK_EXCEPTIONS = [
      SocketError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Net::WriteTimeout,
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      OpenSSL::SSL::SSLError,
      IOError
    ].freeze

    # @param paths [Paths]
    # @param config [Config]
    # @param http [#start] Net::HTTP-compatible client factory.
    # @param sleeper [#sleep] anything that responds to `sleep(seconds)`.
    # @param clock [#call] zero-argument callable returning the current
    #   time in integer seconds.
    def initialize(
      paths: Paths.default,
      config: Config.new(paths: paths),
      http: Net::HTTP,
      sleeper: Kernel,
      clock: -> { Time.now.to_i }
    )
      @paths = paths
      @config = config
      @http = http
      @sleeper = sleeper
      @clock = clock
    end

    # Downloads and caches puzzle input.
    #
    # @param year [Integer]
    # @param day [Integer]
    # @param path [Pathname] target cache location (defaults to
    #   `paths.input_path(year, day)`).
    # @return [String] response body, also written to `path`.
    # @raise [UserError] when session or User-Agent is missing, the network
    #   call fails, the cookie has expired (302), or the HTTP status is
    #   not success.
    def download(year, day, path = @paths.input_path(year, day))
      session = @config.session!
      user_agent = @config.user_agent!

      throttle!

      response = perform_request(year, day, session, user_agent)

      handle_response(response, year, day)

      FileUtils.mkdir_p(path.dirname)
      path.write(response.body)

      response.body
    end

    private

    def perform_request(year, day, session, user_agent)
      uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")

      @http.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: OPEN_TIMEOUT_SECONDS,
        read_timeout: READ_TIMEOUT_SECONDS,
        write_timeout: WRITE_TIMEOUT_SECONDS
      ) do |client|
        request = Net::HTTP::Get.new(uri)
        # Tolerate raw cookie with or without the "session=" prefix.
        request['Cookie'] = "session=#{session.delete_prefix('session=')}"
        request['User-Agent'] = user_agent
        client.request(request)
      end
    rescue *NETWORK_EXCEPTIONS => e
      raise UserError, "Network error contacting adventofcode.com: #{e.class}: #{e.message}"
    end

    def handle_response(response, year, day)
      case response
      when Net::HTTPSuccess
        nil
      when Net::HTTPRedirection
        # AoC redirects to the login page when the session cookie is invalid or expired.
        raise UserError, "Session cookie likely expired. Refresh AOC_SESSION or #{@paths.config_dir.join('session')}."
      else
        raise UserError, "Failed to download input for #{year}/#{day}: HTTP #{response.code} #{response.message}"
      end
    end

    def throttle!
      min_interval = @config.min_interval_seconds
      return if min_interval <= 0

      FileUtils.mkdir_p(@paths.cache_dir)
      stamp = @paths.cache_dir.join('last_request_at')

      if stamp.exist?
        elapsed = now - stamp.read.to_i
        @sleeper.sleep(min_interval - elapsed) if elapsed < min_interval
      end

      # Stamp before the request so failures still count toward the rate limit
      # (be polite to adventofcode.com regardless of outcome).
      stamp.write(now.to_s)
    end

    def now
      @clock.call
    end
  end
end
