# frozen_string_literal: true

module AOC
  class Config
    def initialize(paths: Paths.default, env: ENV)
      @paths = paths
      @env = env
    end

    def session = value("session")

    def user_agent = value("user_agent")

    def min_interval_seconds
      Integer(@env.fetch("AOC_MIN_INTERVAL_SECONDS", "300"))
    end

    def value(name)
      env_name = "AOC_#{name.upcase}"
      env_value = @env[env_name]&.strip
      return env_value if present?(env_value)

      file = @paths.config_dir.join(name)
      return nil unless file.exist?

      file_value = file.read.strip
      present?(file_value) ? file_value : nil
    end

    private

    def present?(value)
      value && !value.empty?
    end
  end
end
