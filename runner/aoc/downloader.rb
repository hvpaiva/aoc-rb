# frozen_string_literal: true

require "fileutils"
require "net/http"

module AOC
  class Downloader
    def initialize(paths: Paths.default, config: Config.new(paths: paths), http: Net::HTTP, sleeper: Kernel, clock: Time)
      @paths = paths
      @config = config
      @http = http
      @sleeper = sleeper
      @clock = clock
    end

    def download(year, day, path = @paths.input_path(year, day))
      session = @config.session
      user_agent = @config.user_agent

      raise UserError, "Configure AOC_SESSION or #{@paths.config_dir.join("session")}." unless present?(session)
      raise UserError, "Configure AOC_USER_AGENT or #{@paths.config_dir.join("user_agent")}." unless present?(user_agent)

      throttle!

      uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")
      response = @http.start(uri.host, uri.port, use_ssl: true) do |client|
        request = Net::HTTP::Get.new(uri)
        request["Cookie"] = "session=#{session.sub(/\Asession=/, "")}"
        request["User-Agent"] = user_agent
        client.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise UserError, "Failed to download input for #{year}/#{day}: HTTP #{response.code} #{response.message}"
      end

      FileUtils.mkdir_p(path.dirname)
      path.write(response.body)

      response.body
    end

    private

    def throttle!
      min_interval = @config.min_interval_seconds
      return if min_interval <= 0

      FileUtils.mkdir_p(@paths.cache_dir)
      stamp = @paths.cache_dir.join("last_request_at")

      if stamp.exist?
        elapsed = @clock.now.to_i - stamp.read.to_i
        @sleeper.sleep(min_interval - elapsed) if elapsed < min_interval
      end

      stamp.write(@clock.now.to_i.to_s)
    end

    def present?(value)
      value && !value.empty?
    end
  end
end
