# frozen_string_literal: true

require_relative "../runner/aoc"

def parsed = @parsed ||= input.lines(chomp: true)

def decode(literal)
  chars = literal[1..-2].chars
  decoded = +""
  until chars.empty?
    char = chars.shift
    if char == "\\"
      case (escaped = chars.shift)
      when '"', "\\" then decoded << escaped
      when "x" then decoded << chars.shift(2).join.to_i(16)
      else raise "invalid escape: \\#{escaped}"
      end
    else
      decoded << char
    end
  end
  decoded
end

def encode(string)
  encoded = string.chars.map { ['"', "\\"].include?(it) ? "\\#{it}" : it }.join
  %("#{encoded}")
end

def part1 = parsed.sum { it.size - decode(it).size }

def part2 = parsed.sum { encode(it).size - it.size }

example '""', part1: 2, part2: 4
example '"abc"', part1: 2, part2: 4
example '"aaa\"aaa"', part1: 3, part2: 6
example '"\x27"', part1: 5, part2: 5
example <<~'INPUT', part1: 3, part2: 6
  "\\"
INPUT
example <<~'INPUT', part1: 3, part2: 6
  "\\x27"
INPUT
example <<~'INPUT', part1: 12, part2: 19
  ""
  "abc"
  "aaa\"aaa"
  "\x27"
INPUT
