# frozen_string_literal: true

require_relative "../runner/aoc"

LINE = /\A(?<action>turn on|toggle|turn off) (?<x1>\d+),(?<y1>\d+) through (?<x2>\d+),(?<y2>\d+)\z/

Instruction = Data.define(:action, :from_x, :from_y, :to_x, :to_y)

PART1 = {
  turn_on: ->(row, ys) { row.fill(1, ys.begin, ys.size) },
  turn_off: ->(row, ys) { row.fill(0, ys.begin, ys.size) },
  toggle: ->(row, ys) { ys.each { |y| row[y] ^= 1 } }
}.freeze

PART2 = {
  turn_on: ->(row, ys) { ys.each { |y| row[y] += 1 } },
  turn_off: ->(row, ys) { ys.each { |y| row[y] -= 1 if row[y].positive? } },
  toggle: ->(row, ys) { ys.each { |y| row[y] += 2 } }
}.freeze

def instructions
  @instructions ||= input.lines(chomp: true).map do |line|
    m = LINE.match(line) or raise "invalid line: #{line}"
    Instruction.new(
      action: m[:action].tr(" ", "_").to_sym,
      from_x: m[:x1].to_i, from_y: m[:y1].to_i,
      to_x: m[:x2].to_i, to_y: m[:y2].to_i
    )
  end
end

def part1 = solve(PART1)
def part2 = solve(PART2)

def solve(ops)
  grid = Array.new(1_000) { Array.new(1_000, 0) }
  instructions.each do |ins|
    xs = ins.from_x..ins.to_x
    ys = ins.from_y..ins.to_y
    op = ops.fetch(ins.action)
    xs.each { |x| op.call(grid[x], ys) }
  end
  grid.sum(&:sum)
end

example <<~INPUT, part1: 998_996
  turn on 0,0 through 999,999
  toggle 0,0 through 999,0
  turn off 499,499 through 500,500
INPUT
