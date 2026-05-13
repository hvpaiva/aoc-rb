# frozen_string_literal: true

module AOC
  module UI
    module_function

    def title(year, day)
      puts "#{icon(:tree)} #{bold("Ruby Advent of Code")} #{year} day #{format("%02d", day)}"
    end

    def year_title(year)
      puts "#{icon(:tree)} #{bold("Ruby Advent of Code")} #{year}"
    end

    def overview_title
      puts "#{icon(:tree)} #{bold("Ruby Advent of Code")}"
      puts
    end

    def examples_header
      puts
      puts cyan("Examples")
    end

    def real_header
      puts
      puts cyan("Real input")
    end

    def example_ok(label, part, actual)
      puts "  #{green(icon(:ok))} #{example_title(label, part)}  #{dim("expected = got = #{value(actual)}")}"
    end

    def example_fail(label, part, expected, actual)
      puts "  #{red(icon(:fail))} #{example_title(label, part)}"
      puts "     expected: #{value(expected)}"
      puts "          got: #{value(actual)}"
      puts
      puts red("Stopped before real input.")
    end

    def example_exception(label, part, exception)
      puts "  #{red(icon(:boom))} #{example_title(label, part)}  #{red("raised #{exception.class}")}"
      puts "     #{exception.message}"
      print_backtrace(exception)
      puts
      puts red("Stopped before real input.")
    end

    def example_skip(label, part)
      puts "  #{yellow(icon(:skip))} #{example_title(label, part)}  #{dim("skipped (def part#{part} not defined)")}"
    end

    def real_part(part, answer, elapsed, answer_width)
      answer = value(answer)

      puts "  #{yellow(icon(:star))} #{part_title(part)} answer: #{answer.ljust(answer_width)}  #{elapsed_time(elapsed)}"
    end

    def real_exception(part, exception, elapsed)
      puts "  #{red(icon(:boom))} #{part_title(part)} #{red("raised #{exception.class}")}  #{elapsed_time(elapsed)}"
      puts "     #{exception.message}"
      print_backtrace(exception)
    end

    def config_error(message)
      puts red("Configuration error:")
      puts "  #{message}"
    end

    def error(exception)
      puts red("Error:")
      puts "  #{exception.class}: #{exception.message}"
      print_backtrace(exception)
    end

    def print_backtrace(exception)
      Array(exception.backtrace).first(5).each do |line|
        puts "     #{dim(line)}"
      end
    end

    def value(object)
      text = object.inspect.gsub("\n", "\\n")
      return text if text.length <= 160

      "#{text[0, 157]}..."
    end

    def example_title(label, part)
      "#{blue(label)} · #{part_title(part)}"
    end

    def part_title(part)
      text = "part #{part}"
      (part == 1) ? yellow(text) : magenta(text)
    end

    def elapsed_time(elapsed)
      dim("(#{ms(elapsed)})")
    end

    def ms(elapsed)
      milliseconds = elapsed * 1000

      if milliseconds < 10
        format("%.2fms", milliseconds)
      else
        format("%.1fms", milliseconds)
      end
    end

    def print_year_results(year, results)
      answer_width = results.map { |result| result.fetch("answer").length }.max || 0
      total = Calendar.max_day_for(year.to_i) * 2
      missing = total - results.length

      year_title(year)
      puts

      results.each do |result|
        print_all_result(result, answer_width)
      end

      puts
      print_all_footer(results.length, missing, total)
    end

    def print_overview(overview, env: ENV)
      overview_title
      print_overview_grid(overview, env: env)

      stars = overview.sum { |_year, year_stars| year_stars.count(true) }
      total = overview.sum { |_year, year_stars| year_stars.length }
      print_all_footer(stars, total - stars, total)
    end

    def print_overview_grid(overview, env: ENV)
      overview.each_slice(4) do |row|
        cards = row.map { |year, stars| overview_card(year, stars, env: env) }
        height = cards.map(&:length).max

        height.times do |index|
          puts cards.map { |card| pad_overview_cell(card[index] || "", env: env) }.join("    ").rstrip
        end

        puts
      end
    end

    def overview_card(year, stars, env: ENV)
      rows = stars.each_slice(10).map do |row|
        "  #{row.map { |star| overview_star(star, env: env) }.join}"
      end

      [bold(year.to_s, env: env), *rows]
    end

    def pad_overview_cell(text, env: ENV)
      text + (" " * [overview_cell_width(env: env) - visible_width(text, env: env), 0].max)
    end

    def overview_cell_width(env: ENV)
      env["AOC_ASCII"] ? 12 : 22
    end

    def visible_width(text, env: ENV)
      text.gsub(/\e\[[\d;]*m/, "").chars.sum do |char|
        (char == icon(:star, env: env)) ? 2 : 1
      end
    end

    def overview_star(done, env: ENV)
      return yellow(icon(:star, env: env), env: env) if done

      star = dim(icon(:empty_star, env: env), env: env)
      env["AOC_ASCII"] ? star : "#{star} "
    end

    def print_all_result(result, answer_width)
      day = blue("day #{format("%02d", result.fetch("day"))}")
      part = part_title(result.fetch("part"))
      answer = result.fetch("answer").ljust(answer_width)
      elapsed = elapsed_time(result.fetch("elapsed"))

      puts "#{yellow(icon(:star))} #{day} · #{part} · answer: #{answer}  #{elapsed}"
    end

    def print_all_footer(stars, missing, total)
      star = yellow(icon(:star))
      empty_star = dim(icon(:empty_star))

      puts "#{star} #{stars} stars · #{empty_star} #{missing} missing · #{total} total"
    end

    def icon(name, env: ENV)
      return ascii_icon(name) if env["AOC_ASCII"]

      {
        tree: "🎄",
        ok: "✅",
        fail: "❌",
        star: "⭐",
        empty_star: "☆",
        skip: "⏩",
        boom: "💥"
      }.fetch(name)
    end

    def ascii_icon(name)
      {
        tree: "",
        ok: "*",
        fail: "!",
        star: "*",
        empty_star: "-",
        skip: ">",
        boom: "x"
      }.fetch(name)
    end

    def green(text, output: $stdout, env: ENV) = color(32, text, output: output, env: env)

    def red(text, output: $stdout, env: ENV) = color(31, text, output: output, env: env)

    def yellow(text, output: $stdout, env: ENV) = color(33, text, output: output, env: env)

    def cyan(text, output: $stdout, env: ENV) = color(36, text, output: output, env: env)

    def blue(text, output: $stdout, env: ENV) = color(34, text, output: output, env: env)

    def magenta(text, output: $stdout, env: ENV) = color(35, text, output: output, env: env)

    def bold(text, output: $stdout, env: ENV) = color(1, text, output: output, env: env)

    def dim(text, output: $stdout, env: ENV) = color(2, text, output: output, env: env)

    def color(code, text, output: $stdout, env: ENV)
      return text unless output.tty?
      return text if env["NO_COLOR"] || env["TERM"] == "dumb"

      "\e[#{code}m#{text}\e[0m"
    end
  end
end
