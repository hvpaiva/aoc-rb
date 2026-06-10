# frozen_string_literal: true

require_relative "../runner/aoc"

STEPS = {"(" => 1, ")" => -1}.freeze

def part1
  input.count("(") - input.count(")")
end

def part2
  floor = 0
  input.each_char.find_index { (floor += STEPS.fetch(it, 0)).negative? } + 1
end

example "(())()()", part1: 0
example "((((()(()(", part1: 6
example "))(((((", part1: 3, part2: 1
example "))))())())", part1: -6, part2: 1
