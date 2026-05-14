# frozen_string_literal: true

module AOC
  Example = Data.define(:input, :expected, :name)

  module DSL
    UNSET = Object.new.freeze

    class InputNotReadyError < AOC::Error; end

    module RuntimeInput
      def input
        return @__aoc_input if instance_variable_defined?(:@__aoc_input)

        raise InputNotReadyError, "input is not available yet"
      end

      def __aoc_input=(value)
        @__aoc_input = value
      end

      private :input, :__aoc_input=
    end

    class << self
      def examples
        @examples ||= []
      end

      def reset!
        @examples = []
      end

      def install!(target = TOPLEVEL_BINDING.receiver)
        target.define_singleton_method(:example) do |input, part1: UNSET, part2: UNSET, name: nil|
          AOC::DSL.add_example(input, part1: part1, part2: part2, name: name)
        end

        target.define_singleton_method(:input) do
          raise InputNotReadyError, "input is not available yet"
        end

        target.singleton_class.send(:private, :example, :input)
      end

      def add_example(input, part1: UNSET, part2: UNSET, name: nil)
        expected = {}
        expected[1] = part1 unless part1.equal?(UNSET)
        expected[2] = part2 unless part2.equal?(UNSET)

        raise UserError, "example requires part1: and/or part2:." if expected.empty?

        examples << Example.new(input: input, expected: expected, name: name)
      end
    end
  end
end
