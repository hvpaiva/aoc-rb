# frozen_string_literal: true

module AOC
  module SolutionStatus
    module_function

    def available_parts
      [1, 2].select do |part|
        Object.private_method_defined?(:"part#{part}") || Object.method_defined?(:"part#{part}")
      end
    end

    def year_stars(year, paths: Paths.default)
      (1..Calendar.max_day_for(year)).flat_map do |day|
        path = paths.day_path(year, day)
        path.exist? ? day_stars(path) : [false, false]
      end
    end

    def day_stars(path)
      source = path.read
      [part_complete?(source, 1), part_complete?(source, 2)]
    end

    def part_complete?(source, part)
      method_source = source[/^\s*def\s+part#{part}\b.*?(?=^\s*def\s|\z)/m]

      method_source && !method_source.match?(/raise\s+["']part#{part} not implemented["']/)
    end
  end
end
