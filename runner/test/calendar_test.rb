# frozen_string_literal: true

require_relative "test_helper"

class CalendarTest < Minitest::Test
  def test_max_day_for_full_and_short_calendars
    assert_equal 25, AOC::Calendar.max_day_for(2024)
    assert_equal 12, AOC::Calendar.max_day_for(2025)
  end

  def test_released_days_is_zero_outside_december
    assert_equal 0, AOC::Calendar.released_days(2026, now: Time.utc(2026, 6, 4))
  end

  def test_released_days_tracks_december_progress
    assert_equal 5, AOC::Calendar.released_days(2026, now: Time.utc(2026, 12, 5, 12))
  end

  def test_released_days_caps_at_calendar_length
    assert_equal 12, AOC::Calendar.released_days(2026, now: Time.utc(2026, 12, 20))
    assert_equal 25, AOC::Calendar.released_days(2024, now: Time.utc(2024, 12, 31))
  end

  def test_released_days_for_past_and_future_years
    assert_equal 25, AOC::Calendar.released_days(2015, now: Time.utc(2026, 6, 4))
    assert_equal 0, AOC::Calendar.released_days(2027, now: Time.utc(2026, 12, 5))
  end

  def test_released_days_follows_us_eastern_midnight
    assert_equal 0, AOC::Calendar.released_days(2026, now: Time.utc(2026, 12, 1, 4, 59))
    assert_equal 1, AOC::Calendar.released_days(2026, now: Time.utc(2026, 12, 1, 5, 0))
  end

  def test_normalize_year_day_accepts_strings
    assert_equal [2024, 2], AOC::Calendar.normalize_year_day!("2024", "2")
  end

  def test_normalize_year_day_rejects_invalid_values
    error = assert_raises(AOC::UserError) { AOC::Calendar.normalize_year_day!("2025", "13") }

    assert_equal "Day must be between 1 and 12 for 2025.", error.message
  end

  def test_normalize_year_day_rejects_non_integer_values
    error = assert_raises(AOC::UserError) { AOC::Calendar.normalize_year_day!("2024", "bad") }

    assert_equal "Year and day must be integers.", error.message
  end

  def test_validate_year_day_rejects_pre_2015_year
    error = assert_raises(AOC::UserError) { AOC::Calendar.validate_year_day!(2014, 1) }

    assert_equal "Year must be 2015 or later.", error.message
  end
end
