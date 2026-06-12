# frozen_string_literal: true

require "json"

require_relative "../runner/aoc"

# Part 1 began as a regex scan, but once part 2 required walking the JSON,
# both parts converged on the same recursive traversal.

# def part1 = input.scan(/-?\d+/).sum(&:to_i)

def part1 = sum_numbers(JSON.parse(input))
def part2 = sum_numbers(JSON.parse(input)) { it.value?("red") }

def sum_numbers(node, &skip)
  case node
  when Integer then node
  when Array then node.sum { sum_numbers(it, &skip) }
  when Hash then skip&.call(node) ? 0 : node.values.sum { sum_numbers(it, &skip) }
  else 0
  end
end

example "[1,2,3]", part1: 6, part2: 6
example '{"a":{"b":4},"c":-1}', part1: 3, part2: 3
example '[1,{"c":"red","b":2},3]', part2: 4
example '{"d":"red","e":[1,2,3,4],"f":5}', part2: 0
example '[1,"red",5]', part2: 6
