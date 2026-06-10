# frozen_string_literal: true

require_relative "../runner/aoc"

LINE = /\A(?<action>turn on|toggle|turn off) (?<x1>\d+),(?<y1>\d+) through (?<x2>\d+),(?<y2>\d+)\z/
SIZE = 1_000

def instructions
  @instructions ||= input.lines(chomp: true).map do |line|
    m = LINE.match(line)
    raise ArgumentError, "invalid line: #{line.inspect}" unless m

    [m[:action].tr(" ", "_").to_sym, m[:x1].to_i..m[:x2].to_i, m[:y1].to_i..m[:y2].to_i]
  end
end

PART1 = {
  turn_on: ->(grid, lo, len) { grid.fill(1, lo, len) },
  turn_off: ->(grid, lo, len) { grid.fill(0, lo, len) },
  toggle: ->(grid, lo, len) { (lo...lo + len).each { |i| grid[i] ^= 1 } }
}.freeze

PART2 = {
  turn_on: ->(grid, lo, len) { (lo...lo + len).each { |i| grid[i] += 1 } },
  turn_off: ->(grid, lo, len) { (lo...lo + len).each { |i| grid[i] = [grid[i] - 1, 0].max } },
  toggle: ->(grid, lo, len) { (lo...lo + len).each { |i| grid[i] += 2 } }
}.freeze

def part1 = solve(PART1)
def part2 = solve(PART2)

def solve(ops)
  grid = Array.new(SIZE * SIZE, 0)
  instructions.each do |action, xs, ys|
    op = ops.fetch(action)
    xs.each { |x| op.call(grid, (x * SIZE) + ys.begin, ys.size) }
  end
  grid.sum
end

example <<~INPUT, part1: 998_996, part2: 1_001_996
  turn on 0,0 through 999,999
  toggle 0,0 through 999,0
  turn off 499,499 through 500,500
INPUT
