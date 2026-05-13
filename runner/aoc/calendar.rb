# frozen_string_literal: true

module AOC
  module Calendar
    module_function

    def max_day_for(year)
      (Integer(year) >= 2025) ? 12 : 25
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
