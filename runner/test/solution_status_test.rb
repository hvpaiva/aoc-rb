# frozen_string_literal: true

require_relative "test_helper"

class SolutionStatusTest < Minitest::Test
  def test_detects_implemented_and_placeholder_parts
    source = <<~RUBY
      def part1
        42
      end

      def part2
        raise "part2 not implemented"
      end
    RUBY

    assert_equal true, AOC::SolutionStatus.part_complete?(source, 1)
    assert_equal false, AOC::SolutionStatus.part_complete?(source, 2)
  end

  def test_missing_part_is_not_complete
    assert_nil AOC::SolutionStatus.part_complete?("def part1 = 1\n", 2)
  end

  def test_day_stars_reads_file_and_reports_each_part
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join("02.rb")
      path.write(<<~RUBY)
        # frozen_string_literal: true

        def part1 = 1

        def part2
          raise "part2 not implemented"
        end
      RUBY

      assert_equal [true, false], AOC::SolutionStatus.day_stars(path)
    end
  end
end
