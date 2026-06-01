# frozen_string_literal: true

require_relative '../test_helper'

class AnsiTest < Minitest::Test
  def test_ascii_icons_match_compact_ui_contract
    assert_equal(
      {
        tree: '',
        ok: '*',
        fail: '!',
        star: '*',
        empty_star: '-',
        skip: '>',
        boom: 'x'
      },
      AOC::UI::Ansi::ASCII_ICONS
    )
  end

  def test_icon_unicode_glyphs_match_compact_ui_contract
    assert_equal(
      {
        tree: '🎄',
        ok: '✅',
        fail: '❌',
        star: '⭐',
        empty_star: '☆',
        skip: '⏩',
        boom: '💥'
      },
      AOC::UI::Ansi::ICONS
    )
  end

  def test_icon_uses_ascii_map_when_enabled
    env = { 'AOC_ASCII' => '1', 'NO_COLOR' => '1' }

    assert_equal '*', AOC::UI::Ansi.icon(:ok, env: env)
    assert_equal '!', AOC::UI::Ansi.icon(:fail, env: env)
    assert_equal 'x', AOC::UI::Ansi.icon(:boom, env: env)
  end

  def test_icon_uses_unicode_by_default
    assert_equal '🎄', AOC::UI::Ansi.icon(:tree, env: {})
    assert_equal '⭐', AOC::UI::Ansi.icon(:star, env: {})
  end

  def test_color_respects_tty_and_no_color_rules
    tty = tty_stream
    not_tty = non_tty_stream

    assert_equal "\e[31mboom\e[0m", AOC::UI::Ansi.color(31, 'boom', output: tty, env: { 'TERM' => 'xterm-256color' })
    assert_equal 'boom', AOC::UI::Ansi.color(31, 'boom', output: tty, env: { 'NO_COLOR' => '1' })
    assert_equal 'boom', AOC::UI::Ansi.color(31, 'boom', output: tty, env: { 'TERM' => 'dumb' })
    assert_equal 'boom', AOC::UI::Ansi.color(31, 'boom', output: not_tty, env: { 'TERM' => 'xterm-256color' })
  end

  def test_named_colors_match_color_codes
    tty = tty_stream
    env = { 'TERM' => 'xterm-256color' }

    AOC::UI::Ansi::COLORS.each do |name, code|
      assert_equal "\e[#{code}m#{name}\e[0m", AOC::UI::Ansi.public_send(name, name.to_s, output: tty, env: env)
    end
  end

  private

  def tty_stream
    StringIO.new.tap { |s| s.define_singleton_method(:tty?) { true } }
  end

  def non_tty_stream
    StringIO.new.tap { |s| s.define_singleton_method(:tty?) { false } }
  end
end
