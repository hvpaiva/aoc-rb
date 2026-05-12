require_relative "../aoc"

MOVES = {">" => 1, "^" => 1i, "<" => -1, "v" => -1i}.freeze

example <<~INPUT, part1: 2
  >
INPUT

example <<~INPUT, part1: 4, part2: 3
  ^>v<
INPUT

example <<~INPUT, part1: 2, part2: 11
  ^v^v^v^v^v
INPUT

example <<~INPUT, part2: 3
  ^v
INPUT

def moves
  @moves ||= input.chomp.chars.map { MOVES.fetch(it) }
end

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
