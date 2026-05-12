# frozen_string_literal: true

require "date"
require "json"
require "open3"

require_relative "aoc"

task default: :help

task :help do
  puts <<~TEXT
    Usage:
      rake 'new[2024,2]'  # create 2024/02.rb
      rake 2024:02        # run 2024/02.rb
      rake all            # show global progress
      rake 'all[2024]'    # run real inputs for a year
      rake check          # validate Ruby syntax and style

    Direct execution also works:
      ruby 2024/02.rb
  TEXT
end

task :new, [:year, :day] do |_task, args|
  year, day = require_year_day!(args)

  run_command "ruby", "aoc.rb", "new", year, day
end

task :all, [:year] do |_task, args|
  unless args[:year]
    run_all_overview
    next
  end

  year = args[:year].to_s
  paths = Dir[File.join(year, "[0-9][0-9].rb")].sort

  abort "No days found for #{year}." if paths.empty?

  run_all(year, paths)
end

task :check do
  files = ["Gemfile", "Rakefile", *Dir["*.rb"].sort, *Dir[File.join("[0-9][0-9][0-9][0-9]", "[0-9][0-9].rb")].sort]

  files.each do |path|
    run_command "ruby", "-c", path
  end

  run_command "bundle", "exec", "standardrb", *files
end

(2015..Date.today.year).each do |year|
  namespace year.to_s.to_sym do
    (1..AOC::Calendar.max_day_for(year)).each do |day|
      task format("%02d", day).to_sym do
        path = day_path(year, day)

        unless File.exist?(path)
          abort "File not found: #{path}. Create it with: rake 'new[#{year},#{day}]'"
        end

        run_command "ruby", path
      end
    end
  end
end

def run_command(*command)
  exit(false) unless system(*command)
end

def run_all(year, paths)
  results = paths.flat_map { |path| run_all_day(path) }
  answer_width = results.map { |result| result.fetch("answer").length }.max || 0
  total = AOC::Calendar.max_day_for(year.to_i) * 2
  missing = total - results.length

  AOC::UI.year_title(year)
  puts

  results.each do |result|
    print_all_result(result, answer_width)
  end

  puts
  print_all_footer(results.length, missing, total)
end

def run_all_overview
  years = (2015..Date.today.year).to_a
  overview = years.map { |year| [year, all_year_stars(year)] }
  stars = overview.sum { |_year, year_stars| year_stars.count(true) }
  total = overview.sum { |_year, year_stars| year_stars.length }

  puts "#{AOC::UI.icon(:tree)} #{AOC::UI.bold("Ruby Advent of Code")}"
  puts

  print_overview_grid(overview)

  print_all_footer(stars, total - stars, total)
end

def all_year_stars(year)
  (1..AOC::Calendar.max_day_for(year)).flat_map do |day|
    path = day_path(year, day)

    File.exist?(path) ? scan_day_stars(path) : [false, false]
  end
end

def scan_day_stars(path)
  source = File.read(path)

  [part_complete?(source, 1), part_complete?(source, 2)]
end

def part_complete?(source, part)
  method_source = source[/^\s*def\s+part#{part}\b.*?(?=^\s*def\s|\z)/m]

  method_source && !method_source.match?(/raise\s+["']part#{part} not implemented["']/)
end

def print_overview_grid(overview)
  overview.each_slice(4) do |row|
    cards = row.map { |year, stars| overview_card(year, stars) }
    height = cards.map(&:length).max

    height.times do |index|
      puts cards.map { |card| pad_overview_cell(card[index] || "") }.join("    ").rstrip
    end

    puts
  end
end

def overview_card(year, stars)
  rows = stars.each_slice(10).map do |row|
    "  #{row.map { |star| overview_star(star) }.join}"
  end

  [AOC::UI.bold(year.to_s), *rows]
end

def pad_overview_cell(text)
  text + (" " * [overview_cell_width - visible_width(text), 0].max)
end

def overview_cell_width
  ENV["AOC_ASCII"] ? 12 : 22
end

def visible_width(text)
  text.gsub(/\e\[[\d;]*m/, "").chars.sum do |char|
    (char == AOC::UI.icon(:star)) ? 2 : 1
  end
end

def overview_star(done)
  return AOC::UI.yellow(AOC::UI.icon(:star)) if done

  star = AOC::UI.dim(AOC::UI.icon(:empty_star))
  ENV["AOC_ASCII"] ? star : "#{star} "
end

def run_all_day(path)
  stdout, stderr, status = Open3.capture3({"AOC_RUN_MODE" => "all"}, "ruby", path)

  unless status.success?
    $stdout.write(stdout)
    $stderr.write(stderr)
    exit(false)
  end

  stdout.each_line.filter_map do |line|
    next unless line.start_with?("AOC_ALL_RESULT ")

    JSON.parse(line.delete_prefix("AOC_ALL_RESULT "))
  end
end

def print_all_result(result, answer_width)
  day = AOC::UI.blue("day #{format("%02d", result.fetch("day"))}")
  part = AOC::UI.part_title(result.fetch("part"))
  answer = result.fetch("answer").ljust(answer_width)
  elapsed = AOC::UI.elapsed_time(result.fetch("elapsed"))

  puts "#{AOC::UI.yellow(AOC::UI.icon(:star))} #{day} · #{part} · answer: #{answer}  #{elapsed}"
end

def print_all_footer(stars, missing, total)
  star = AOC::UI.yellow(AOC::UI.icon(:star))
  empty_star = AOC::UI.dim(AOC::UI.icon(:empty_star))

  puts "#{star} #{stars} stars · #{empty_star} #{missing} missing · #{total} total"
end

def require_year_day!(args)
  year = args[:year]
  day = args[:day]

  abort "Usage: rake 'new[2024,2]'" unless year && day

  [year.to_s, day.to_s]
end

def day_path(year, day)
  File.join(year.to_s, format("%02d.rb", day.to_i))
end
