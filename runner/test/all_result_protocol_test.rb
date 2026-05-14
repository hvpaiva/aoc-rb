# frozen_string_literal: true

require_relative "test_helper"

class AllResultProtocolTest < Minitest::Test
  def test_emit_writes_marker_prefixed_json_line
    io = StringIO.new
    result = AOC::AllResultProtocol::Result.new(day: 2, part: 1, answer: "cba", elapsed: 0.125)

    AOC::AllResultProtocol.emit(io, result)

    assert io.string.start_with?(AOC::AllResultProtocol::MARKER)
    assert_includes io.string, '"day":2'
    assert_includes io.string, '"part":1'
    assert_includes io.string, '"answer":"cba"'
    assert_includes io.string, '"elapsed":0.125'
    assert io.string.end_with?("\n"), "emit should terminate the line"
  end

  def test_parse_returns_results_for_marker_lines
    stdout = <<~OUT
      #{AOC::AllResultProtocol::MARKER}{"day":1,"part":1,"answer":"42","elapsed":0.001}
      #{AOC::AllResultProtocol::MARKER}{"day":1,"part":2,"answer":"foo","elapsed":0.002}
    OUT

    results = AOC::AllResultProtocol.parse(stdout)

    assert_equal 2, results.length
    assert_equal AOC::AllResultProtocol::Result.new(day: 1, part: 1, answer: "42", elapsed: 0.001), results[0]
    assert_equal AOC::AllResultProtocol::Result.new(day: 1, part: 2, answer: "foo", elapsed: 0.002), results[1]
  end

  def test_parse_ignores_lines_without_marker
    stdout = <<~OUT
      noise from the solution
      #{AOC::AllResultProtocol::MARKER}{"day":5,"part":1,"answer":"x","elapsed":0.01}
      more noise
    OUT

    results = AOC::AllResultProtocol.parse(stdout)

    assert_equal 1, results.length
    assert_equal 5, results.first.day
  end

  def test_parse_returns_empty_when_no_marker_lines
    assert_empty AOC::AllResultProtocol.parse("no markers here\njust noise\n")
  end

  def test_emit_and_parse_roundtrip
    io = StringIO.new
    original = [
      AOC::AllResultProtocol::Result.new(day: 1, part: 1, answer: "a", elapsed: 0.1),
      AOC::AllResultProtocol::Result.new(day: 2, part: 2, answer: "b", elapsed: 0.2)
    ]
    original.each { |r| AOC::AllResultProtocol.emit(io, r) }

    assert_equal original, AOC::AllResultProtocol.parse(io.string)
  end

  def test_result_is_immutable_value_type
    result = AOC::AllResultProtocol::Result.new(day: 1, part: 1, answer: "x", elapsed: 0.1)

    assert_raises(NoMethodError) { result.day = 2 }
  end
end
