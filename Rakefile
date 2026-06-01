# frozen_string_literal: true

require "date"

require_relative "runner/aoc"

task default: :help

task :help do
  run_aoc { AOC::Commands.help }
end

task :new, [:year, :day, :variant] do |_task, args|
  run_aoc { AOC::Commands.new_day(*require_year_day!(args), args[:variant]) }
end

task :all, [:year, :day] do |_task, args|
  run_aoc { AOC::Commands.all(args[:year], args[:day]) }
end

task :check do
  run_aoc { AOC::Commands.check }
end

task :test do
  run_aoc { AOC::Commands.test }
end

(2015..Date.today.year).each do |year|
  namespace year.to_s.to_sym do
    (1..AOC::Calendar.max_day_for(year)).each do |day|
      task format("%02d", day).to_sym, [:variant] do |_task, args|
        run_aoc { AOC::Commands.run_day(year, day, variant: args[:variant]) }
      end
    end
  end
end

def require_year_day!(args)
  year = args[:year]
  day = args[:day]

  abort "Usage: rake 'new[2024,2]'" unless year && day

  [year.to_s, day.to_s]
end

def run_aoc
  yield
rescue AOC::CommandFailed
  exit(false)
rescue AOC::UserError => e
  abort e.message
end
