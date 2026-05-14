# frozen_string_literal: true

module AOC
  module UI
    # ANSI codes and icon glyphs. Pure functions; the caller threads
    # `output:` and `env:` to honor TTY detection and NO_COLOR/AOC_ASCII.
    module Ansi
      COLORS = {
        green: 32,
        red: 31,
        yellow: 33,
        cyan: 36,
        blue: 34,
        magenta: 35,
        bold: 1,
        dim: 2
      }.freeze

      ICONS = {
        tree: "🎄",
        ok: "✅",
        fail: "❌",
        star: "⭐",
        empty_star: "☆",
        skip: "⏩",
        boom: "💥"
      }.freeze

      ASCII_ICONS = {
        tree: "",
        ok: "*",
        fail: "!",
        star: "*",
        empty_star: "-",
        skip: ">",
        boom: "x"
      }.freeze

      module_function

      def color(code, text, output:, env:)
        return text unless output.tty?
        return text if env["NO_COLOR"] || env["TERM"] == "dumb"

        "\e[#{code}m#{text}\e[0m"
      end

      def icon(name, env:)
        env["AOC_ASCII"] ? ASCII_ICONS.fetch(name) : ICONS.fetch(name)
      end

      COLORS.each do |name, code|
        define_singleton_method(name) do |text, output:, env:|
          color(code, text, output: output, env: env)
        end
      end
    end
  end
end
