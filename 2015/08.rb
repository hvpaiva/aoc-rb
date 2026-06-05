# frozen_string_literal: true

require_relative "../runner/aoc"

ESCAPES = /\\"|\\\\|\\x[0-9a-f]{2}/
ESCAPABLE = /["\\]/

def parsed = @parsed ||= input.lines(chomp: true)

def part1 = parsed.sum { it.size - it[1..-2].gsub(ESCAPES, "*").size }

def part2 = parsed.sum { it.gsub(ESCAPABLE, "**").size + 2 - it.size }

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
