# frozen_string_literal: true

module AOC
  # Returns puzzle input for a given year/day. Cached inputs are read from
  # disk; misses are delegated to {Downloader}, which handles throttle and
  # session cookie. Cached inputs never trigger network access.
  class InputStore
    # @param paths [Paths]
    # @param downloader [Downloader] injected for testing; the default
    #   constructs a new one bound to `paths`.
    def initialize(paths: Paths.default, downloader: Downloader.new(paths: paths))
      @paths = paths
      @downloader = downloader
    end

    # @param year [Integer]
    # @param day [Integer]
    # @return [String] raw input bytes.
    # @raise [UserError] when the input is missing and the download fails
    #   (missing session, network error, expired cookie, etc.).
    def read(year, day)
      path = @paths.input_path(year, day)
      return path.read if path.exist?

      @downloader.download(year, day, path)
    end
  end
end
