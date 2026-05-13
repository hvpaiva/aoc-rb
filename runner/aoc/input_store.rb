# frozen_string_literal: true

module AOC
  class InputStore
    def initialize(paths: Paths.default, downloader: Downloader.new(paths: paths))
      @paths = paths
      @downloader = downloader
    end

    def read(year, day)
      path = @paths.input_path(year, day)
      return path.read if path.exist?

      @downloader.download(year, day, path)
    end
  end
end
