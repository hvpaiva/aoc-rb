# frozen_string_literal: true

require_relative "../runner/aoc"

FORBIDDEN = /[iol]/
PAIR = /(.)\1/
STRAIGHT = Regexp.union(("a".."x").map { |c| "#{c}#{c.next}#{c.next.next}" })

def valid?(password)
  !password.match?(FORBIDDEN) &&
    password.match?(STRAIGHT) &&
    password.scan(PAIR).uniq.size >= 2
end

def next_password(current)
  password = current.dup
  password.next! until valid?(password)
  password
end

def part1 = next_password(input.strip)
def part2 = next_password(part1.next)

example "abcdefgh", part1: "abcdffaa", part2: "abcdffbb"
example "ghijklmn", part1: "ghjaabcc", part2: "ghjbbcdd"
