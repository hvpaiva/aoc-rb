# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"

module AOC
  ROOT = Pathname(__dir__)
  INPUTS = ROOT.join("inputs")
  CACHE = ROOT.join(".cache")
  CONFIG = Pathname(ENV.fetch("AOC_CONFIG_DIR", File.join(Dir.home, ".config", "aoc-rb")))
  UNSET = Object.new.freeze

  Example = Struct.new(:input, :expected, :name, keyword_init: true)

  @examples = []

  class << self
    attr_reader :examples
  end

  module DSL
    def example(input, part1: UNSET, part2: UNSET, name: nil)
      expected = {}
      expected[1] = part1 unless part1.equal?(UNSET)
      expected[2] = part2 unless part2.equal?(UNSET)

      raise "example requires part1: and/or part2:." if expected.empty?

      AOC.examples << Example.new(input: input, expected: expected, name: name)
    end

    def input
      return @__aoc_input if instance_variable_defined?(:@__aoc_input)

      raise "input is not available yet"
    end

    def __aoc_input=(value)
      @__aoc_input = value
    end

    private :example, :input, :__aoc_input=
  end

  Object.include(DSL)

  module UI
    module_function

    def title(year, day)
      puts "#{icon(:tree)} #{bold("Ruby Advent of Code")} #{year} day #{format("%02d", day)}"
    end

    def year_title(year)
      puts "#{icon(:tree)} #{bold("Ruby Advent of Code")} #{year}"
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
      puts "  #{red(icon(:boom))} #{example_title(label, part)} raised #{exception.class}"
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
      puts "  #{red(icon(:boom))} #{part_title(part)} raised #{exception.class}  #{elapsed_time(elapsed)}"
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

    def icon(name)
      return ascii_icon(name) if ENV["AOC_ASCII"]

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
        tree: "AOC",
        ok: "[ok]",
        fail: "[fail]",
        star: "*",
        empty_star: "-",
        skip: "[skip]",
        boom: "[error]"
      }.fetch(name)
    end

    def green(text)
      color(32, text)
    end

    def red(text)
      color(31, text)
    end

    def yellow(text)
      color(33, text)
    end

    def cyan(text)
      color(36, text)
    end

    def blue(text)
      color(34, text)
    end

    def magenta(text)
      color(35, text)
    end

    def bold(text)
      color(1, text)
    end

    def dim(text)
      color(2, text)
    end

    def color(code, text)
      return text unless $stdout.tty?
      return text if ENV["NO_COLOR"] || ENV["TERM"] == "dumb"

      "\e[#{code}m#{text}\e[0m"
    end
  end

  module_function

  def run!
    year, day = infer_year_day($PROGRAM_NAME)
    parts = available_parts

    UI.title(year, day)

    if parts.empty?
      UI.config_error("Define def part1 and/or def part2 in the day file.")
      exit(false)
    end

    run_examples!(parts)
    run_real_input!(year, day, parts)
  rescue SystemExit
    raise
  rescue => e
    UI.error(e)
    exit(false)
  end

  def run_examples!(parts)
    return if examples.empty?

    UI.examples_header

    examples.each_with_index do |example, index|
      label = example.name || "example #{format("%2d", index + 1)}"

      example.expected.each do |part, expected|
        unless parts.include?(part)
          UI.example_skip(label, part)
          next
        end

        begin
          actual = solve(part, example.input)
        rescue => e
          UI.example_exception(label, part, e)
          exit(false)
        end

        if actual == expected
          UI.example_ok(label, part, actual)
        else
          UI.example_fail(label, part, expected, actual)
          exit(false)
        end
      end
    end
  end

  def run_real_input!(year, day, parts)
    UI.real_header

    real_input = input_for(year, day)
    results = []

    parts.each do |part|
      started = monotonic_time

      begin
        answer = solve(part, real_input)
        elapsed = monotonic_time - started
      rescue => e
        elapsed = monotonic_time - started
        UI.real_exception(part, e, elapsed)
        exit(false)
      end

      results << [part, answer, elapsed]
    end

    answer_width = results.map { |_part, answer, _elapsed| UI.value(answer).length }.max || 0

    results.each do |part, answer, elapsed|
      UI.real_part(part, answer, elapsed, answer_width)
    end
  end

  def run_all_day!
    year, day = infer_year_day($PROGRAM_NAME)
    real_input = input_for(year, day)

    available_parts.each do |part|
      started = monotonic_time
      answer = solve(part, real_input)
      elapsed = monotonic_time - started

      puts "AOC_ALL_RESULT #{JSON.generate(day: day, part: part, answer: UI.value(answer), elapsed: elapsed)}"
    end
  rescue SystemExit
    raise
  rescue => e
    UI.error(e)
    exit(false)
  end

  def solve(part, raw_input)
    runner = Object.new
    runner.__send__(:__aoc_input=, raw_input.dup)

    method = runner.method(:"part#{part}")

    unless method.arity.zero?
      raise "def part#{part} must receive zero arguments; use input inside your methods."
    end

    method.call
  end

  def available_parts
    [1, 2].select do |part|
      Object.private_method_defined?(:"part#{part}") ||
        Object.method_defined?(:"part#{part}")
    end
  end

  def infer_year_day(path)
    normalized = Pathname(path).to_s.tr("\\", "/")
    match = normalized.match(%r{(?:^|/)(20\d{2})/(?:day_?)?(\d{1,2})\.rb\z})

    unless match
      raise "Could not infer year/day from #{path.inspect}. Use a structure like 2024/02.rb."
    end

    year = match[1].to_i
    day = match[2].to_i

    validate_year_day!(year, day)

    [year, day]
  end

  def day_file?(path)
    Pathname(path).to_s.tr("\\", "/").match?(%r{(?:^|/)(20\d{2})/(?:day_?)?\d{1,2}\.rb\z})
  end

  def input_for(year, day)
    path = INPUTS.join(year.to_s, format("%02d.txt", day))
    return path.read if path.exist?

    download_input(year, day, path)
  end

  def download_input(year, day, path)
    session = config_value("session")
    user_agent = config_value("user_agent")

    raise "Configure AOC_SESSION or #{CONFIG.join("session")}." unless present?(session)
    raise "Configure AOC_USER_AGENT or #{CONFIG.join("user_agent")}." unless present?(user_agent)

    session = session.sub(/\Asession=/, "")

    throttle!

    uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Cookie"] = "session=#{session}"
      request["User-Agent"] = user_agent
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to download input for #{year}/#{day}: HTTP #{response.code} #{response.message}"
    end

    FileUtils.mkdir_p(path.dirname)
    path.write(response.body)

    response.body
  end

  def config_value(name)
    env_name = "AOC_#{name.upcase}"
    value = ENV[env_name]&.strip
    return value if present?(value)

    file = CONFIG.join(name)
    return nil unless file.exist?

    value = file.read.strip
    present?(value) ? value : nil
  end

  def throttle!
    min_interval = Integer(ENV.fetch("AOC_MIN_INTERVAL_SECONDS", "300"))
    return if min_interval <= 0

    FileUtils.mkdir_p(CACHE)
    stamp = CACHE.join("last_request_at")

    if stamp.exist?
      elapsed = Time.now.to_i - stamp.read.to_i
      sleep(min_interval - elapsed) if elapsed < min_interval
    end

    stamp.write(Time.now.to_i.to_s)
  end

  def new!(year, day)
    year, day = normalize_year_day!(year, day)

    path = ROOT.join(year.to_s, format("%02d.rb", day))
    display_path = path.relative_path_from(Pathname.pwd)

    if path.exist?
      warn "Already exists: #{display_path}"
      return path
    end

    FileUtils.mkdir_p(path.dirname)

    path.write(<<~RUBY)
      require_relative "../aoc"

      def parsed = @parsed ||= input.lines(chomp: true)

      def part1
        raise "part1 not implemented"
      end

      # example <<~INPUT, part1: 0
      # INPUT
    RUBY

    puts "Created: #{display_path}"
    path
  end

  def cli!(argv)
    command, year, day = argv

    case command
    when "new"
      raise "Usage: ruby aoc.rb new 2024 1" unless year && day

      new!(year, day)
    else
      raise "Usage: ruby aoc.rb new 2024 1"
    end
  rescue => e
    warn e.message
    exit(false)
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def normalize_year_day!(year, day)
    year = Integer(year)
    day = Integer(day)

    validate_year_day!(year, day)

    [year, day]
  rescue ArgumentError
    raise "Year and day must be integers."
  end

  def validate_year_day!(year, day)
    raise "Year must be 2015 or later." if year < 2015

    max_day = max_day_for(year)
    raise "Day must be between 1 and #{max_day} for #{year}." unless (1..max_day).cover?(day)
  end

  def max_day_for(year)
    Calendar.max_day_for(year)
  end

  def present?(value)
    value && !value.empty?
  end

  module Calendar
    module_function

    def max_day_for(year)
      (year >= 2025) ? 12 : 25
    end
  end
end

if File.expand_path($PROGRAM_NAME) == File.expand_path(__FILE__)
  AOC.cli!(ARGV)
elsif AOC.day_file?($PROGRAM_NAME)
  at_exit do
    if ENV["AOC_RUN_MODE"] == "all"
      AOC.run_all_day! unless $!
    else
      AOC.run! unless $!
    end
  end
end
