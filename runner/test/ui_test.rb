# frozen_string_literal: true

require_relative "test_helper"

class UITest < Minitest::Test
  def test_ascii_icons_match_compact_ui_contract
    assert_equal(
      {
        tree: "",
        ok: "*",
        fail: "!",
        star: "*",
        empty_star: "-",
        skip: ">",
        boom: "x"
      },
      {
        tree: AOC::UI.ascii_icon(:tree),
        ok: AOC::UI.ascii_icon(:ok),
        fail: AOC::UI.ascii_icon(:fail),
        star: AOC::UI.ascii_icon(:star),
        empty_star: AOC::UI.ascii_icon(:empty_star),
        skip: AOC::UI.ascii_icon(:skip),
        boom: AOC::UI.ascii_icon(:boom)
      }
    )
  end

  def test_icon_uses_ascii_map_when_enabled
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}

    assert_equal "*", AOC::UI.icon(:ok, env: env)
    assert_equal "!", AOC::UI.icon(:fail, env: env)
    assert_equal "x", AOC::UI.icon(:boom, env: env)
  end

  def test_year_title_prints_header
    stdout, = capture_io { AOC::UI.year_title(2024) }

    assert_includes stdout, "Ruby Advent of Code 2024"
  end

  def test_value_truncates_long_output
    value = AOC::UI.value("a" * 200)

    assert_equal 160, value.length
    assert value.end_with?("...")
  end

  def test_elapsed_time_formats_larger_values
    assert_equal "12.3ms", AOC::UI.ms(0.01234)
  end

  def test_print_year_results_formats_each_result_and_footer
    stdout, = capture_io do
      AOC::UI.print_year_results(
        2024,
        [{"day" => 2, "part" => 1, "answer" => "\"cba\"", "elapsed" => 0.001}]
      )
    end

    assert_includes stdout, "Ruby Advent of Code 2024"
    assert_includes stdout, "day 02"
    assert_includes stdout, "part 1"
    assert_includes stdout, "answer: \"cba\""
    assert_includes stdout, "1 stars"
    assert_includes stdout, "49 missing"
  end

  def test_color_respects_tty_and_no_color_rules
    tty = StringIO.new
    tty.define_singleton_method(:tty?) { true }
    not_tty = StringIO.new
    not_tty.define_singleton_method(:tty?) { false }

    assert_equal "\e[31mboom\e[0m", AOC::UI.color(31, "boom", output: tty, env: {"TERM" => "xterm-256color"})
    assert_equal "boom", AOC::UI.color(31, "boom", output: tty, env: {"NO_COLOR" => "1"})
    assert_equal "boom", AOC::UI.color(31, "boom", output: tty, env: {"TERM" => "dumb"})
    assert_equal "boom", AOC::UI.color(31, "boom", output: not_tty, env: {"TERM" => "xterm-256color"})
  end

  def test_overview_helpers_use_injected_ascii_env
    env = {"AOC_ASCII" => "1", "NO_COLOR" => "1"}

    assert_equal 12, AOC::UI.overview_cell_width(env: env)
    assert_equal "*", AOC::UI.overview_star(true, env: env)
    assert_equal "-", AOC::UI.overview_star(false, env: env)
  end
end
