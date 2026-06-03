# frozen_string_literal: true

require_relative "../runner/aoc"

MASK = 0xffff

Variable = Data.define(:name)
Unary = Data.define(:op, :operand)
Binary = Data.define(:op, :lhs, :rhs)

WIRE_A = Variable.new(:a)

def instructions = @instructions ||= input.lines(chomp: true).to_h { parse(it) }

def parse(line)
  expression, wire = line.split(" -> ")

  node =
    case expression.split
    in [name]
      operand_for(name)
    in ["NOT", operand]
      Unary.new(:not, operand_for(operand))
    in [lhs, "AND" | "OR" | "LSHIFT" | "RSHIFT" => op, rhs]
      Binary.new(op.downcase.to_sym, operand_for(lhs), operand_for(rhs))
    else
      raise "Parse error: #{line.inspect}"
    end

  [wire.to_sym, node]
end

def operand_for(token)
  Integer(token, exception: false) || Variable.new(token.to_sym)
end

class Evaluator
  def initialize(instructions, wires = {})
    @instructions = instructions
    @wires = wires
  end

  def evaluate(node)
    case node
    in Integer then node
    in Variable(name:) then get_or_eval(name)
    in Unary(op:, operand:) then evaluate_unary(op, evaluate(operand))
    in Binary(op:, lhs:, rhs:) then evaluate_binary(op, evaluate(lhs), evaluate(rhs))
    else raise "Unknown node: #{node.inspect}"
    end
  end

  private

  def get_or_eval(name)
    @wires.fetch(name) { @wires[name] = evaluate(@instructions.fetch(name)) }
  end

  def evaluate_binary(op, lhs, rhs)
    case op
    when :and then lhs & rhs
    when :or then lhs | rhs
    when :rshift then lhs >> rhs
    when :lshift then (lhs << rhs) & MASK
    else raise "Unknown binary operation: #{op}"
    end
  end

  def evaluate_unary(op, operand)
    raise "Unknown unary operation: #{op}" unless op == :not

    ~operand & MASK
  end
end

def part1 = Evaluator.new(instructions).evaluate(WIRE_A)
def part2 = Evaluator.new(instructions, b: part1).evaluate(WIRE_A)

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
