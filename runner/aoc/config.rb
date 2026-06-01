# frozen_string_literal: true

module AOC
  # Reads runtime configuration with a fixed precedence: environment
  # variables (`AOC_SESSION`, `AOC_USER_AGENT`, `AOC_MIN_INTERVAL_SECONDS`)
  # win, then files under {Paths#config_dir} (`session`, `user_agent`).
  # Blank values are treated as absent.
  class Config
    # @param paths [Paths] used to locate config files.
    # @param env [Hash, ENV] environment hash for variable lookups.
    def initialize(paths: Paths.default, env: ENV)
      @paths = paths
      @env = env
    end

    # @return [String, nil] session cookie, or nil when unset.
    def session = value('session')

    # @return [String, nil] HTTP User-Agent, or nil when unset.
    def user_agent = value('user_agent')

    # @return [String] session cookie.
    # @raise [UserError] when no session is configured.
    def session!
      session || raise(UserError, "Configure AOC_SESSION or #{@paths.config_dir.join('session')}.")
    end

    # @return [String] HTTP User-Agent.
    # @raise [UserError] when no User-Agent is configured.
    def user_agent!
      user_agent || raise(UserError, "Configure AOC_USER_AGENT or #{@paths.config_dir.join('user_agent')}.")
    end

    # Minimum interval between downloads, in seconds. Defaults to 300.
    # @return [Integer] non-negative integer.
    # @raise [UserError] when `AOC_MIN_INTERVAL_SECONDS` is negative or
    #   non-integer.
    def min_interval_seconds
      raw = @env['AOC_MIN_INTERVAL_SECONDS']
      return 300 if raw.nil? || raw.strip.empty?

      value = Integer(raw)
      if value.negative?
        raise UserError,
              "AOC_MIN_INTERVAL_SECONDS must be a non-negative integer (got #{raw.inspect})."
      end

      value
    rescue ArgumentError
      raise UserError, "AOC_MIN_INTERVAL_SECONDS must be a non-negative integer (got #{raw.inspect})."
    end

    private

    def value(name)
      env_name = "AOC_#{name.upcase}"
      env_value = @env[env_name]&.strip
      return env_value if present?(env_value)

      file = @paths.config_dir.join(name)
      return nil unless file.exist?

      file_value = file.read.strip
      present?(file_value) ? file_value : nil
    end

    def present?(value)
      value && !value.empty?
    end
  end
end
