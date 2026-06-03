# frozen_string_literal: true

module AOC
  module UI
    # Renders runner output to a stream. The only stateful piece of the UI
    # layer: it captures `output` and `env` at construction time so
    # individual render methods stay parameter-free for callers.
    #
    # Honors the same display knobs as {Ansi}: `NO_COLOR` and `TERM=dumb`
    # disable colors, `AOC_ASCII` switches to ASCII icons, and `AOC_DEBUG`
    # makes {print_backtrace} emit the full backtrace instead of the first
    # 5 lines.
    class Renderer
      OVERVIEW_COLUMNS = 4
      OVERVIEW_CELL_WIDTH_UNICODE = 22
      OVERVIEW_CELL_WIDTH_ASCII = 12
      MAX_BACKTRACE_LINES = 5

      # @param output [IO] target stream (defaults to `$stdout`).
      # @param env [Hash, ENV] environment hash used to resolve color and
      #   ASCII preferences (defaults to `ENV`).
      def initialize(output: $stdout, env: ENV)
        @output = output
        @env = env
      end

      # ----- headers --------------------------------------------------------

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

      # ----- example outcomes ----------------------------------------------

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

      # ----- real input outcomes -------------------------------------------

      def real_results(results)
        answer_width = results.map { |_, answer, _| value(answer).length }.max || 0

        results.each do |part, answer, elapsed|
          real_part(part, answer, elapsed, answer_width)
        end
      end

      def real_part(part, answer, elapsed, answer_width)
        padded = value(answer).ljust(answer_width)
        puts "  #{yellow(icon(:star))} #{part_title(part)} answer: #{padded}  #{elapsed_time(elapsed)}"
      end

      def real_exception(part, exception, elapsed)
        puts "  #{red(icon(:boom))} #{part_title(part)} #{red("raised #{exception.class}")}  #{elapsed_time(elapsed)}"
        puts "     #{exception.message}"
        print_backtrace(exception)
      end

      # ----- top-level errors ----------------------------------------------

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
        lines = Array(exception.backtrace)
        lines = lines.first(MAX_BACKTRACE_LINES) unless @env["AOC_DEBUG"]

        lines.each { |line| puts "     #{dim(line)}" }
      end

      # ----- aggregate views -----------------------------------------------

      def print_year_results(year, results)
        total = Calendar.max_day_for(year.to_i) * 2
        missing = total - results.length

        year_title(year)
        puts

        answer_width = results.map { |result| value(result.answer).length }.max || 0
        results.each { |result| print_all_result(result, answer_width) }

        puts
        print_all_footer(results.length, missing, total)
      end

      # Renders one star line per variant, flagging parts whose answers diverge
      # and variants that errored.
      #
      # @param variants [Array(String, Array<AllResultProtocol::Result>, Boolean)]
      #   `[label, results, ok]` per file, canonical (`"base"`) first.
      def print_day_comparison(year, day, variants)
        title(year, day)
        puts

        label_width = variants.map { |label, _results, _ok| label.length }.max || 0
        answer_width = variants.flat_map { |_label, results, _ok| results.map { |r| value(r.answer).length } }.max || 0
        diverging = comparison_diverging_parts(variants)

        variants.each { |variant| print_comparison_variant(variant, label_width, answer_width, diverging) }

        print_comparison_footer(diverging)
      end

      def print_overview(overview)
        overview_title
        print_overview_grid(overview)

        stars = overview.sum { |_year, year_stars| year_stars.count(true) }
        total = overview.sum { |_year, year_stars| year_stars.length }
        print_all_footer(stars, total - stars, total)
      end

      # ----- accessors used by Runner --------------------------------------

      def value(object)
        Format.value(object)
      end

      private

      # ----- internal renderers --------------------------------------------

      def print_all_result(result, answer_width)
        day = blue("day #{format("%02d", result.day)}")
        part_label = part_title(result.part)
        answer = value(result.answer).ljust(answer_width)
        puts "#{yellow(icon(:star))} #{day} · #{part_label} · answer: #{answer}  #{elapsed_time(result.elapsed)}"
      end

      def print_comparison_variant(variant, label_width, answer_width, diverging)
        label, results, ok = variant
        sorted = results.sort_by(&:part)

        if sorted.empty?
          puts comparison_status_line(label, label_width, ok)
          return
        end

        sorted.each do |result|
          puts comparison_result_line(label, label_width, result, answer_width, diverging.include?(result.part))
        end

        puts comparison_status_line(label, label_width, ok) unless ok
      end

      def comparison_result_line(label, label_width, result, answer_width, diverging)
        marker = diverging ? red(icon(:fail)) : yellow(icon(:star))
        name = blue(label.ljust(label_width))
        answer = value(result.answer).ljust(answer_width)

        "#{marker} #{name} · #{part_title(result.part)} · answer: #{answer}  #{elapsed_time(result.elapsed)}"
      end

      def comparison_status_line(label, label_width, ok)
        name = blue(label.ljust(label_width))
        return "#{yellow(icon(:skip))} #{name} · #{dim("no parts implemented")}" if ok

        "#{red(icon(:boom))} #{name} · #{red("errored (run it directly for the trace)")}"
      end

      def comparison_diverging_parts(variants)
        by_part = Hash.new { |hash, part| hash[part] = [] }

        variants.each do |_label, results, ok|
          next unless ok

          results.each { |result| by_part[result.part] << result.answer }
        end

        by_part.select { |_part, answers| answers.uniq.length > 1 }.keys.sort
      end

      def print_comparison_footer(diverging)
        return if diverging.empty?

        puts
        parts = diverging.map { |part| "part #{part}" }.join(" and ")
        puts red("Variants disagree on #{parts}.")
      end

      def print_all_footer(stars, missing, total)
        star = yellow(icon(:star))
        empty_star = dim(icon(:empty_star))

        puts "#{star} #{stars} stars · #{empty_star} #{missing} missing · #{total} total"
      end

      def print_overview_grid(overview)
        overview.each_slice(OVERVIEW_COLUMNS) do |row|
          cards = row.map { |year, stars| overview_card(year, stars) }
          height = cards.map(&:length).max

          height.times do |line_index|
            puts cards.map { |card| pad_overview_cell(card[line_index] || "") }.join("    ").rstrip
          end

          puts
        end
      end

      def overview_card(year, stars)
        rows = stars.each_slice(10).map do |row|
          "  #{row.map { |star| overview_star(star) }.join}"
        end

        [bold(year.to_s), *rows]
      end

      def overview_star(done)
        return yellow(icon(:star)) if done

        star = dim(icon(:empty_star))
        @env["AOC_ASCII"] ? star : "#{star} "
      end

      def pad_overview_cell(text)
        text + (" " * [overview_cell_width - visible_width(text), 0].max)
      end

      def overview_cell_width
        @env["AOC_ASCII"] ? OVERVIEW_CELL_WIDTH_ASCII : OVERVIEW_CELL_WIDTH_UNICODE
      end

      # Approximates terminal column width: strips ANSI escapes and treats the
      # star icon as width 2 (the only wide glyph that appears in the grid).
      def visible_width(text)
        text.gsub(/\e\[[\d;]*m/, "").chars.sum { |char| (char == icon(:star)) ? 2 : 1 }
      end

      # ----- ANSI / format delegates ---------------------------------------

      Ansi::COLORS.each_key do |name|
        define_method(name) { |text| Ansi.public_send(name, text, output: @output, env: @env) }
      end

      def icon(name)
        Ansi.icon(name, env: @env)
      end

      def example_title(label, part)
        "#{blue(label)} · #{part_title(part)}"
      end

      def part_title(part)
        text = "part #{part}"
        (part == 1) ? yellow(text) : magenta(text)
      end

      def elapsed_time(elapsed)
        dim("(#{Format.ms(elapsed)})")
      end

      def puts(text = "")
        @output.puts(text)
      end
    end
  end
end
