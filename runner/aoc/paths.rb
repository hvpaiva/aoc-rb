# frozen_string_literal: true

module AOC
  class Paths
    DEFAULT_ROOT = Pathname(__dir__).join("..", "..").expand_path.freeze
    DEFAULT_CONFIG_DIR = File.join(Dir.home, ".config", "aoc-rb")
    DAY_FILE_PATTERN = %r{(?:^|/)(20\d{2})/(?:day_?)?(\d{1,2})\.rb\z}

    attr_reader :root, :config_dir

    def self.default
      @default ||= new
    end

    def self.day_file?(path)
      Pathname(path).to_s.tr("\\", "/").match?(DAY_FILE_PATTERN)
    end

    def initialize(root: DEFAULT_ROOT, config_dir: nil, env: ENV)
      @root = Pathname(root).expand_path
      @config_dir = Pathname(config_dir || env.fetch("AOC_CONFIG_DIR", DEFAULT_CONFIG_DIR)).expand_path
    end

    def inputs_dir = root.join("inputs")

    def cache_dir = root.join(".cache")

    def day_path(year, day)
      root.join(year.to_s, "#{format("%02d", Integer(day))}.rb")
    end

    def input_path(year, day)
      inputs_dir.join(year.to_s, "#{format("%02d", Integer(day))}.txt")
    end

    def day_files(year)
      Pathname.glob(root.join(year.to_s, "[0-9][0-9].rb").to_s).sort_by(&:to_s)
    end

    def test_files
      Pathname.glob(root.join("runner", "test", "*_test.rb").to_s).sort_by(&:to_s)
    end

    def check_files
      files = %w[Gemfile Rakefile].filter_map do |path|
        candidate = root.join(path)
        candidate if candidate.exist?
      end

      files.concat(Pathname.glob(root.join("runner", "**", "*.rb").to_s))
      files.concat(Pathname.glob(root.join("[0-9][0-9][0-9][0-9]", "[0-9][0-9].rb").to_s))
      files.uniq.sort_by(&:to_s)
    end

    def relative(path)
      Pathname(path).expand_path.relative_path_from(root).to_s
    rescue ArgumentError
      Pathname(path).to_s
    end

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
  end
end
