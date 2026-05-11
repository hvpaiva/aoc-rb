# Advent of Code in Ruby

Solutions for [Advent of Code](https://adventofcode.com/) challenges in Ruby.

Solutions live in year/day files, such as `2024/02.rb`. The local runner is only here to reduce friction: create day files, download/cache inputs, run examples before the real input, and execute solutions through `ruby` or `rake`.

## Setup

Requires Ruby 4.0+. The checked-in `.ruby-version` pins the local development version; patch updates such as Ruby 4.0.3 are supported by the project requirement.

Install development dependencies:

```sh
bundle install
```

Configure your session cookie and User-Agent:

```sh
mkdir -p ~/.config/aoc-rb

printf 'YOUR_SESSION_COOKIE' > ~/.config/aoc-rb/session
printf 'github.com/your-user/your-repo by your-email@example.com' > ~/.config/aoc-rb/user_agent
```

Or use environment variables:

```sh
export AOC_SESSION='YOUR_SESSION_COOKIE'
export AOC_USER_AGENT='github.com/your-user/your-repo by your-email@example.com'
```

Inputs are cached under `inputs/`. Cached inputs are reused locally and do not trigger HTTP requests. New downloads are throttled to one request every 300 seconds by default; override with `AOC_MIN_INTERVAL_SECONDS` when needed.

## Create a day

```sh
rake 'new[2024,2]'
```

Scaffolding supports 25 days for years through 2024 and 12 days for 2025 onward.

## Run a day

```sh
ruby 2024/02.rb
```

Or:

```sh
rake 2024:02
```

## Run all existing days for a year

```sh
rake 'all[2024]'
```

## Day file format

```ruby
require_relative "../aoc"

example <<~INPUT, part1: 2
  ...
INPUT

def parsed
  @parsed ||= input.lines(chomp: true)
end

def part1
  raise "part1 not implemented"
end
```

When Part 2 exists:

```ruby
example <<~INPUT, part1: 2, part2: 4
  ...
INPUT

def part2
  ...
end
```

Do not define `part2` before starting Part 2.
