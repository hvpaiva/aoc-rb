# frozen_string_literal: true

require "date"

task default: :help

task :help do
  puts <<~TEXT
    Usage:
      rake 'new[2024,2]'  # create 2024/02.rb
      rake 2024:02        # run 2024/02.rb
      rake 'all[2024]'    # run all existing days for a year
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
  year = (args[:year] || Date.today.year).to_s
  paths = Dir[File.join(year, "[0-9][0-9].rb")].sort

  abort "No days found for #{year}." if paths.empty?

  paths.each do |path|
    run_command "ruby", path
  end
end

task :check do
  files = ["aoc.rb", "Rakefile", *Dir[File.join("[0-9][0-9][0-9][0-9]", "[0-9][0-9].rb")].sort]

  files.each do |path|
    run_command "ruby", "-c", path
  end

  run_command "standardrb", *files
end

(2015..Date.today.year).each do |year|
  namespace year.to_s.to_sym do
    (1..25).each do |day|
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

def require_year_day!(args)
  year = args[:year]
  day = args[:day]

  abort "Usage: rake 'new[2024,2]'" unless year && day

  [year.to_s, day.to_s]
end

def day_path(year, day)
  File.join(year.to_s, format("%02d.rb", day.to_i))
end
