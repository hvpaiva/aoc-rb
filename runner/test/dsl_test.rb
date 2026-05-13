# frozen_string_literal: true

require_relative "test_helper"

class DSLTest < Minitest::Test
  def setup
    AOC::DSL.reset!
  end

  def teardown
    AOC::DSL.reset!
  end

  def test_add_example_records_expected_parts_and_name
    AOC::DSL.add_example("abc", part1: 3, part2: 4, name: "sample")

    example = AOC::DSL.examples.fetch(0)
    assert_equal "abc", example.input
    assert_equal({1 => 3, 2 => 4}, example.expected)
    assert_equal "sample", example.name
  end

  def test_add_example_requires_at_least_one_expected_part
    error = assert_raises(AOC::UserError) { AOC::DSL.add_example("abc") }

    assert_equal "example requires part1: and/or part2:.", error.message
  end

  def test_runtime_input_raises_before_assignment
    runner = Object.new
    runner.extend(AOC::DSL::RuntimeInput)

    error = assert_raises(RuntimeError) { runner.__send__(:input) }

    assert_equal "input is not available yet", error.message
  end

  def test_install_adds_top_level_style_methods_to_target
    target = Object.new
    AOC::DSL.install!(target)

    target.instance_eval do
      example "abc", part1: 3
    end

    assert_equal 1, AOC::DSL.examples.length

    error = assert_raises(RuntimeError) do
      target.instance_eval { input }
    end
    assert_equal "input is not available yet", error.message
  end
end
