require_relative "../aoc"

VOWELS = "aeiou"
DOUBLE = /(.)\1/
FORBIDDEN = /ab|cd|pq|xy/
TWICE = /(..).*\1/
SANDWICH = /(.).\1/

example <<~INPUT, part1: 1
  ugknbfddgicrmopn
INPUT

example <<~INPUT, part1: 1
  aaa
INPUT

example <<~INPUT, part1: 0
  jchzalrnumimnmhp
INPUT

example <<~INPUT, part1: 0
  haegwjzuvuyypxyu
INPUT

example <<~INPUT, part1: 0
  dvszwmarrgswjxmb
INPUT

example <<~INPUT, part2: 1
  qjhvhtzxzqqjkmpb
INPUT

example <<~INPUT, part2: 1
  xxyxx
INPUT

example <<~INPUT, part2: 0
  uurcxstgmygtbstg
INPUT

example <<~INPUT, part2: 0
  ieodomkazucvgmuy
INPUT

def parsed = @parsed ||= input.lines(chomp: true)

def part1 = parsed.count { it.count(VOWELS) >= 3 && it.match?(DOUBLE) && !it.match?(FORBIDDEN) }

def part2 = parsed.count { it.match?(TWICE) && it.match?(SANDWICH) }
