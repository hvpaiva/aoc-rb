# frozen_string_literal: true

require_relative "../runner/aoc"

MASK = 0xffff

Wire = Data.define(:name)
Unary = Data.define(:op, :operand)
Binary = Data.define(:op, :lhs, :rhs)

def parse(line)
  expression, wire = line.split(" -> ")

  node =
    case expression.split
    in [token]
      operand_for(token)
    in ["NOT", operand]
      Unary.new(:not, operand_for(operand))
    in [lhs, "AND" | "OR" | "LSHIFT" | "RSHIFT" => op, rhs]
      Binary.new(
        op.downcase.to_sym,
        operand_for(lhs),
        operand_for(rhs)
      )
    else
      raise "Parse error: #{line.inspect}"
    end

  [wire.to_sym, node]
end

def operand_for(token)
  Integer(token, exception: false) || Wire.new(token.to_sym)
end

class Evaluator
  def initialize(instructions, wires = {})
    @instructions = instructions
    @wires = wires.dup
  end

  def signal(name)
    evaluate(Wire.new(name))
  end

  private

  def evaluate(node)
    case node
    in Integer then node
    in Wire(name:) then wire(name)
    in Unary(op:, operand:) then ~evaluate(operand) & MASK
    in Binary(op:, lhs:, rhs:) then binary(op, evaluate(lhs), evaluate(rhs))
    else raise "Unknown node: #{node.inspect}"
    end
  end

  def wire(name)
    @wires.fetch(name) { @wires[name] = evaluate(@instructions.fetch(name)) }
  end

  def binary(op, lhs, rhs)
    case op
    when :and then lhs & rhs
    when :or then lhs | rhs
    when :rshift then lhs >> rhs
    when :lshift then (lhs << rhs) & MASK
    else raise "Unknown binary operation: #{op}"
    end
  end
end

def instructions = @instructions ||= input.lines(chomp: true).to_h { parse(it) }

def part1 = Evaluator.new(instructions).signal(:a)
def part2 = Evaluator.new(instructions, b: part1).signal(:a)

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
