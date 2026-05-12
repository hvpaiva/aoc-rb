require "digest"

require_relative "../aoc"

example <<~INPUT, part1: 609043
  abcdef
INPUT

example <<~INPUT, part1: 1048970
  pqrstuv
INPUT

def part1 = mine(5)
def part2 = mine(6)

def mine(zeros)
  secret = input.chomp
  needle = "0" * zeros
  (1..).find { |i| Digest::MD5.hexdigest("#{secret}#{i}").start_with?(needle) }
end
