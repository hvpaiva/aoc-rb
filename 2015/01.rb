require_relative "../aoc"

example <<~INPUT, part1: 0
  (())()()
INPUT

example <<~INPUT, part1: 6
  ((((()(()(
INPUT

example <<~INPUT, part1: 3, part2: 1
  ))(((((
INPUT

example <<~INPUT, part1: -6, part2: 1
  ))))())())
INPUT

def part1
  input.count("(") - input.count(")")
end

STEPS = {"(" => 1, ")" => -1}.freeze

def part2
  floor = 0
  input.each_char.with_index(1) do |step, i|
    floor += STEPS.fetch(step, 0)
    return i if floor.negative?
  end
end
