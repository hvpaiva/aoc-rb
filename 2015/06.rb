# frozen_string_literal: true

require_relative '../runner/aoc'

LINE = /\A(?<action>turn on|toggle|turn off) (?<x1>\d+),(?<y1>\d+) through (?<x2>\d+),(?<y2>\d+)\z/
Instruction = Data.define(:action, :from_x, :from_y, :to_x, :to_y)

def instructions
  @instructions ||= input.lines(chomp: true).map do |line|
    m = LINE.match(line) or raise "invalid line: #{line}"
    Instruction.new(
      action: m[:action].tr(' ', '_').to_sym,
      from_x: m[:x1].to_i, from_y: m[:y1].to_i,
      to_x: m[:x2].to_i, to_y:   m[:y2].to_i
    )
  end
end

def part1
  solve(turn_on: ->(_) { 1 }, turn_off: ->(_) { 0 }, toggle: ->(v) { v ^ 1 })
end

def part2
  solve(turn_on: ->(v) { v + 1 }, turn_off: ->(v) { [v - 1, 0].max }, toggle: ->(v) { v + 2 })
end

def solve(ops)
  grid = Array.new(1_000) { Array.new(1_000, 0) }
  instructions.each do |ins|
    xs = ins.from_x..ins.to_x
    ys = ins.from_y..ins.to_y
    op = ops.fetch(ins.action)
    xs.each do |x|
      row = grid[x]
      ys.each { |y| row[y] = op.call(row[y]) }
    end
  end
  grid.sum(&:sum)
end

example <<~INPUT, part1: 998_996
  turn on 0,0 through 999,999
  toggle 0,0 through 999,0
  turn off 499,499 through 500,500
INPUT
