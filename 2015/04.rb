# frozen_string_literal: true

require "digest"

require_relative "../runner/aoc"

def part1 = mine(5)
def part2 = mine(6)

def mine(zeros)
  secret = input.chomp
  needle = "0" * zeros
  (1..).find { |i| Digest::MD5.hexdigest("#{secret}#{i}").start_with?(needle) }
end

example "abcdef", part1: 609_043
example "pqrstuv", part1: 1_048_970
