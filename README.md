# Advent of Code in Ruby

Solutions for [Advent of Code](https://adventofcode.com/) challenges in Ruby.

Solutions live in year/day files, such as `2024/02.rb`. The local runner is only here to reduce friction: create day files, download/cache inputs, run examples before the real input, and execute solutions through `ruby` or `rake`.

## Setup

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

## Create a day

```sh
ruby aoc.rb new 2024 2
```

Or:

```sh
rake 'new[2024,2]'
```

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
