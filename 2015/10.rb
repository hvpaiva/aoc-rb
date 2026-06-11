# frozen_string_literal: true

require_relative "../runner/aoc"

def look_and_say(value)
  value.gsub(/(.)\1*/) { "#{$&.size}#{$1}" }
end

def length_after(steps)
  steps.times.reduce(input) { |value, _| look_and_say(value) }.size
end

def part1 = length_after(40)
def part2 = length_after(50)

example "1", part1: 82350
