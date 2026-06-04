# frozen_string_literal: true

module AOC
  module Calendar
    # Puzzles unlock one per day of December at midnight US-Eastern.
    AOC_UTC_OFFSET = "-05:00"

    module_function

    def max_day_for(year)
      (Integer(year) >= 2025) ? 12 : 25
    end

    def released_days(year, now: Time.now)
      aoc_now = now.getlocal(AOC_UTC_OFFSET)

      return max_day_for(year) if aoc_now.year > year
      return 0 if aoc_now.year < year || aoc_now.month < 12

      [aoc_now.day, max_day_for(year)].min
    end

    def normalize_year_day!(year, day)
      year = Integer(year)
      day = Integer(day)

      validate_year_day!(year, day)

      [year, day]
    rescue ArgumentError
      raise UserError, "Year and day must be integers."
    end

    def validate_year_day!(year, day)
      raise UserError, "Year must be 2015 or later." if year < 2015

      max_day = max_day_for(year)
      return if (1..max_day).cover?(day)

      raise UserError, "Day must be between 1 and #{max_day} for #{year}."
    end
  end
end
