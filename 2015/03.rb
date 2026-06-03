# frozen_string_literal: true

require_relative "../runner/aoc"

MOVES = {">" => 1, "^" => 1i, "<" => -1, "v" => -1i}.freeze

def moves = @moves ||= input.chomp.chars.map { MOVES.fetch(it) }

def trail(moves)
  position = 0i
  visited = Set[position]
  moves.each { visited << (position += it) }
  visited
end

def part1 = trail(moves).size

def part2
  moves.partition
    .with_index { |_, i| i.even? }
    .map { trail(it) }.reduce(:|).size
end

example ">", part1: 2
example "^>v<", part1: 4, part2: 3
example "^v^v^v^v^v", part1: 2, part2: 11
example "^v", part2: 3
