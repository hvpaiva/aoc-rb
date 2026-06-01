# frozen_string_literal: true

require_relative '../runner/aoc'

VOWELS = 'aeiou'
DOUBLE = /(.)\1/
FORBIDDEN = /ab|cd|pq|xy/
TWICE = /(..).*\1/
SANDWICH = /(.).\1/

def parsed = @parsed ||= input.lines(chomp: true)

def part1 = parsed.count { it.count(VOWELS) >= 3 && it.match?(DOUBLE) && !it.match?(FORBIDDEN) }

def part2 = parsed.count { it.match?(TWICE) && it.match?(SANDWICH) }

example 'ugknbfddgicrmopn', part1: 1
example 'aaa', part1: 1
example 'jchzalrnumimnmhp', part1: 0
example 'haegwjzuvuyypxyu', part1: 0
example 'dvszwmarrgswjxmb', part1: 0
example 'qjhvhtzxzqqjkmpb', part2: 1
example 'xxyxx', part2: 1
example 'uurcxstgmygtbstg', part2: 0
example 'ieodomkazucvgmuy', part2: 0
