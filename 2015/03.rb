# frozen_string_literal: true

require_relative "../aoc"

MOVES = {">" => [1, 0], "^" => [0, 1], "<" => [-1, 0], "v" => [0, -1]}.freeze

example <<~INPUT, part1: 2
  >
INPUT

example <<~INPUT, part1: 4
  ^>v<
INPUT

example <<~INPUT, part1: 2
  ^v^v^v^v^v
INPUT

def directions
  @directions ||= input.chomp.each_char.map { |ch| MOVES.fetch(ch) }
end

def part1
  pos = [0, 0]
  visited = directions.map { |dx, dy| pos = [pos[0] + dx, pos[1] + dy] }
  (visited << [0, 0]).uniq.size
end
