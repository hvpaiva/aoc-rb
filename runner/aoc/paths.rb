# frozen_string_literal: true

module AOC
  # Resolves filesystem paths used throughout the runner: project root,
  # day files, cached inputs, config directory. Construct with explicit
  # `root:` and/or `config_dir:` for tests; production code typically uses
  # {Paths.default}.
  class Paths
    DEFAULT_ROOT = Pathname(__dir__).join("..", "..").expand_path.freeze
    # Recognition pattern: matches an executable day file. The optional
    # `[_-]<slug>` suffix admits variant siblings (e.g. `06_bitset.rb`) while
    # still capturing the canonical two-digit day, so a variant resolves to the
    # same year/day (and shares the canonical input). This loosens RECOGNITION
    # only; COUNTING toward stars stays governed by the strict glob in
    # {#day_files}. See ARCHITECTURE.md ("Variants and the recognition seam").
    DAY_FILE_PATTERN = %r{(?:^|/)(20\d{2})/(\d{2})(?:[_-][^/]*)?\.rb\z}

    # Captures the slug of a variant day file, or nil for the canonical file.
    VARIANT_PATTERN = %r{(?:^|/)20\d{2}/\d{2}[_-]([^/]*)\.rb\z}

    # @return [Pathname] project root, where day files and `inputs/` live.
    attr_reader :root

    # @return [Pathname] directory holding `session` and `user_agent` files.
    attr_reader :config_dir

    class << self
      # Lazy process-wide convenience instance. Tests that mutate ENV or
      # Dir.home should call {reset_default!} so the next caller rebuilds.
      # @return [Paths]
      def default
        @default ||= new
      end

      # Clears the memoized {default} so the next call rebuilds with the
      # current ENV and Dir.home values.
      # @return [void]
      def reset_default!
        @default = nil
      end

      # @param path [String, Pathname] candidate path to classify.
      # @return [Boolean] true when the path matches the canonical
      #   `YYYY/NN.rb` shape.
      def day_file?(path)
        Pathname(path).to_s.tr("\\", "/").match?(DAY_FILE_PATTERN)
      end
    end

    # @param root [String, Pathname] project root. Defaults to the runner's
    #   own parent directory.
    # @param config_dir [String, Pathname, nil] explicit config directory.
    #   When nil, falls back to `AOC_CONFIG_DIR` and then to
    #   `~/.config/aoc-rb`.
    # @param env [Hash, ENV] environment hash used to resolve `AOC_CONFIG_DIR`.
    def initialize(root: DEFAULT_ROOT, config_dir: nil, env: ENV)
      @root = Pathname(root).expand_path
      @config_dir = Pathname(
        config_dir || env.fetch("AOC_CONFIG_DIR") { default_config_dir }
      ).expand_path
    end

    # @return [Pathname] `root/inputs`.
    def inputs_dir = root.join("inputs")

    # @return [Pathname] `root/.cache`, used by Downloader for the throttle
    #   stamp.
    def cache_dir = root.join(".cache")

    # @param year [Integer, String]
    # @param day [Integer, String]
    # @return [Pathname] absolute path to the day source file.
    def day_path(year, day)
      root.join(year.to_s, "#{format("%02d", Integer(day))}.rb")
    end

    # @param year [Integer, String]
    # @param day [Integer, String]
    # @return [Pathname] absolute path to the cached input file. Variants share
    #   the canonical input, so there is no per-variant variant of this path.
    def input_path(year, day)
      inputs_dir.join(year.to_s, "#{format("%02d", Integer(day))}.txt")
    end

    # @param year [Integer, String]
    # @param day [Integer, String]
    # @param slug [String] variant slug (already validated by the caller).
    # @return [Pathname] absolute path to a variant day source file
    #   (`YYYY/NN_<slug>.rb`).
    def variant_path(year, day, slug)
      root.join(year.to_s, "#{format("%02d", Integer(day))}_#{slug}.rb")
    end

    # @param year [Integer]
    # @return [Array<Pathname>] sorted list of existing day files for the
    #   given year.
    def day_files(year)
      Pathname.glob(root.join(year.to_s, "[0-9][0-9].rb")).sort_by(&:to_s)
    end

    # All executable files for a single day: the canonical file first (when it
    # exists), then variant siblings sorted by name. This is the basis of the
    # comparison mode and is intentionally distinct from {#day_files}, which
    # stays strict for star counting.
    #
    # @param year [Integer, String]
    # @param day [Integer, String]
    # @return [Array<Pathname>] existing day files for this day.
    def day_variants(year, day)
      nn = format("%02d", Integer(day))
      canonical = root.join(year.to_s, "#{nn}.rb")
      variants = Pathname.glob(root.join(year.to_s, "#{nn}[_-]*.rb")).sort_by(&:to_s)

      files = []
      files << canonical if canonical.exist?
      files.concat(variants)
      files
    end

    # @param path [String, Pathname]
    # @return [String, nil] the variant slug, or nil when the path is canonical.
    def infer_variant(path)
      match = Pathname(path).to_s.tr("\\", "/").match(VARIANT_PATTERN)
      match && match[1]
    end

    # @param path [String, Pathname]
    # @return [String] path expressed relative to {root}.
    def relative(path)
      Pathname(path).expand_path.relative_path_from(root).to_s
    end

    # Extracts the year and day numbers from a day-file path.
    #
    # @param path [String, Pathname] candidate path.
    # @return [Array(Integer, Integer)] `[year, day]`.
    # @raise [UserError] when the path does not match `YYYY/NN.rb` or the
    #   numbers fall outside the AoC calendar.
    def infer_year_day(path)
      normalized = Pathname(path).to_s.tr("\\", "/")
      match = normalized.match(DAY_FILE_PATTERN)

      unless match
        raise UserError, "Could not infer year/day from #{path.inspect}. Use a structure like 2024/02.rb."
      end

      year = match[1].to_i
      day = match[2].to_i
      Calendar.validate_year_day!(year, day)

      [year, day]
    end

    private

    def default_config_dir
      File.join(Dir.home, ".config", "aoc-rb")
    end
  end
end
