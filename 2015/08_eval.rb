# frozen_string_literal: true

require_relative "../runner/aoc"

def parsed = @parsed ||= input.lines(chomp: true)

def part1 = parsed.sum { it.size - eval(it).size } # standard:disable Security/Eval

def part2 = parsed.sum { it.inspect.size - it.size }

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
