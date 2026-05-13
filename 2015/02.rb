# frozen_string_literal: true

require_relative "../runner/aoc"

example <<~INPUT, part1: 101, part2: 48
  2x3x4
  1x1x10
INPUT

def presents = @presents ||= input.lines(chomp: true).map { |line| line.split("x").map(&:to_i) }

def part1
  presents.sum do |l, w, h|
    sides = [l * w, w * h, h * l]
    2 * sides.sum + sides.min
  end
end

def part2
  presents.sum do |dim|
    2 * dim.min(2).sum + dim.reduce(:*)
  end
end
