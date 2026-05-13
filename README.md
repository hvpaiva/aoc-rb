# Advent of Code in Ruby

Solutions for [Advent of Code](https://adventofcode.com/) challenges in Ruby.

Solutions live in year/day files, such as `2024/02.rb`. The runner in `runner/` is an internal support tool: it creates day files, downloads/caches inputs, runs examples before real input, and executes solutions through `ruby` or `rake`. The challenge solutions are the focus of the repository; the runner is not a gem, product, or public library.

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

## Progress overview

```sh
rake all
```

`rake all` without a year shows global progress. `rake 'all[YYYY]'` runs the real inputs for existing days in that year.

## Checks

```sh
rake check
```

This validates Ruby syntax, runs Standard Ruby, and executes the runner test suite under `runner/test/`.

## Day file format

```ruby
# frozen_string_literal: true

require_relative "../runner/aoc"

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

## Runner structure

The Rakefile is a thin interface for public commands. Runner internals live under `runner/aoc/`, with `runner/aoc.rb` as the entry point used by challenge files. Tests for the runner live under `runner/test/`.
