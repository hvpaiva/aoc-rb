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

    assert AOC::SolutionStatus.part_complete?(source, 1)
    refute AOC::SolutionStatus.part_complete?(source, 2)
  end

  def test_missing_part_is_not_complete
    refute AOC::SolutionStatus.part_complete?("def part1 = 1\n", 2)
  end

  def test_endless_part_method_is_recognized_as_complete
    source = "def part1 = input.count(\"(\")\n"

    assert AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_placeholder_in_string_does_not_mask_implementation
    source = <<~RUBY
      def part1
        # comment mentioning part1 not implemented
        "part1 not implemented"
      end
    RUBY

    assert AOC::SolutionStatus.part_complete?(source, 1),
      "a method whose body merely contains the placeholder string is still considered implemented"
  end

  def test_non_runtime_error_placeholder_is_still_complete
    source = <<~RUBY
      def part1
        raise NotImplementedError
      end
    RUBY

    assert AOC::SolutionStatus.part_complete?(source, 1),
      "only the exact Scaffolder placeholder counts as incomplete"
  end

  def test_helper_methods_do_not_confuse_detection
    source = <<~RUBY
      def parsed = @parsed ||= input.lines(chomp: true)

      def part1
        raise "part1 not implemented"
      end

      def shared_helper
        42
      end
    RUBY

    refute AOC::SolutionStatus.part_complete?(source, 1)
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

  def test_syntax_error_yields_no_complete_parts
    refute AOC::SolutionStatus.part_complete?("def part1\n", 1)
  end

  def test_empty_method_body_is_treated_as_complete
    # body is nil, not StatementsNode -> not the scaffolder placeholder.
    assert AOC::SolutionStatus.part_complete?("def part1; end\n", 1)
  end

  def test_method_with_rescue_clause_is_treated_as_complete
    # body is BeginNode, not StatementsNode -> not a placeholder.
    source = <<~RUBY
      def part1
        do_work
      rescue
        recover
      end
    RUBY

    assert AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_multiple_statements_in_body_is_treated_as_complete
    source = <<~RUBY
      def part1
        prep
        raise "part1 not implemented"
      end
    RUBY

    assert AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_raise_without_arguments_is_treated_as_complete
    assert AOC::SolutionStatus.part_complete?("def part1; raise; end\n", 1)
  end

  def test_raise_with_multiple_arguments_is_treated_as_complete
    source = "def part1; raise RuntimeError, \"part1 not implemented\"; end\n"

    assert AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_interpolated_placeholder_message_is_treated_as_complete
    # Interpolation produces a non-StringNode part, so the literal does not
    # match the exact scaffolder placeholder. We treat the method as
    # implemented because we cannot evaluate the interpolation statically.
    source = <<~'RUBY'
      def part1
        raise "part1 #{1} not implemented"
      end
    RUBY

    assert AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_adjacent_string_literals_concatenate_to_placeholder
    # Two adjacent string literals (`"a" "b"`) parse as InterpolatedStringNode
    # whose parts are all StringNode. The runner joins them and recognizes the
    # full placeholder text.
    source = "def part1; raise \"part1\" \" not implemented\"; end\n"

    refute AOC::SolutionStatus.part_complete?(source, 1)
  end

  def test_year_stars_uses_day_stars_for_existing_days
    Dir.mktmpdir do |dir|
      paths = AOC::Paths.new(root: dir, config_dir: File.join(dir, "config"))
      FileUtils.mkdir_p(paths.day_path(2024, 5).dirname)
      paths.day_path(2024, 5).write("def part1 = 1\n")

      stars = AOC::SolutionStatus.year_stars(2024, paths: paths)

      # Day 5 -> indexes 8 (part 1) and 9 (part 2) in the flat array.
      assert_equal true, stars[8]
      assert_equal false, stars[9]
      # Days without files default to [false, false].
      assert_equal false, stars[0]
      assert_equal false, stars[1]
    end
  end
end
