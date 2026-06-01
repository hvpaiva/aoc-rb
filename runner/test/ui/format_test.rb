# frozen_string_literal: true

require_relative '../test_helper'

class FormatTest < Minitest::Test
  def test_value_inspects_short_objects
    assert_equal '"abc"', AOC::UI::Format.value('abc')
    assert_equal '42', AOC::UI::Format.value(42)
    assert_equal '[1, 2, 3]', AOC::UI::Format.value([1, 2, 3])
  end

  def test_value_escapes_newlines
    assert_equal '"a\\nb"', AOC::UI::Format.value("a\nb")
  end

  def test_value_truncates_long_output
    value = AOC::UI::Format.value('a' * 200)

    assert_equal AOC::UI::Format::MAX_VALUE_LENGTH, value.length
    assert value.end_with?(AOC::UI::Format::VALUE_TRUNCATION_TAIL)
  end

  def test_ms_uses_two_decimals_under_ten
    assert_equal '0.10ms', AOC::UI::Format.ms(0.0001)
    assert_equal '9.99ms', AOC::UI::Format.ms(0.00999)
  end

  def test_ms_uses_one_decimal_at_or_above_ten
    assert_equal '12.3ms', AOC::UI::Format.ms(0.01234)
    assert_equal '1234.5ms', AOC::UI::Format.ms(1.23451)
  end
end
