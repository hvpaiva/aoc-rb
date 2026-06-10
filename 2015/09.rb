# frozen_string_literal: true

require_relative "../runner/aoc"

DISTANCE = /\A(?<from>\w+) to (?<to>\w+) = (?<value>\d+)\z/

def distances
  @distances ||= input.lines(chomp: true).each_with_object(Hash.new { |h, k| h[k] = {} }) do |line, dist|
    m = line.match(DISTANCE)
    raise ArgumentError, "unparsable line: #{line.inspect}" unless m

    dist[m[:from]][m[:to]] = dist[m[:to]][m[:from]] = m[:value].to_i
  end
end

def route_lengths
  @route_lengths ||= begin
    first, *rest = distances.keys
    rest.permutation.map do |tail|
      [first, *tail].each_cons(2).sum { |a, b| distances[a][b] }
    end
  end
end

def part1 = route_lengths.min
def part2 = route_lengths.max

example <<~INPUT, part1: 605, part2: 659
  London to Dublin = 464
  London to Belfast = 518
  Dublin to Belfast = 141
INPUT
