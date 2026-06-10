# frozen_string_literal: true

require_relative "../runner/aoc"

MASK = 0xffff
OPS = {"AND" => :&, "OR" => :|, "LSHIFT" => :<<, "RSHIFT" => :>>}.freeze

class Circuit
  def initialize(wiring, overrides = {})
    @wiring = wiring
    @signals = overrides.dup
  end

  def signal(wire)
    @signals[wire] ||= case @wiring.fetch(wire)
    in [token] then resolve(token)
    in ["NOT", token] then ~resolve(token) & MASK
    in [lhs, op, rhs] then resolve(lhs).public_send(OPS.fetch(op), resolve(rhs)) & MASK
    end
  end

  private

  def resolve(token) = token.match?(/\A\d+\z/) ? token.to_i : signal(token.to_sym)
end

def wiring
  @wiring ||= input.lines(chomp: true).to_h do |line|
    expression, wire = line.split(" -> ")
    [wire.to_sym, expression.split]
  end
end

def part1 = Circuit.new(wiring).signal(:a)
def part2 = Circuit.new(wiring, b: part1).signal(:a)

example <<~INPUT, part1: 114, part2: 28
  123 -> x
  456 -> b
  x AND b -> d
  x OR b -> e
  x LSHIFT 2 -> f
  b RSHIFT 2 -> a
  NOT x -> h
  NOT b -> i
INPUT

example <<~INPUT, part1: 65_534
  65535 -> x
  x LSHIFT 1 -> a
INPUT

example <<~INPUT, part1: 65_412
  123 -> x
  NOT x -> a
INPUT
