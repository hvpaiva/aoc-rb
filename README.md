# Advent of Code in Ruby

Solutions for [Advent of Code](https://adventofcode.com/) challenges in Ruby.

Solutions live in year/day files, such as `2024/02.rb`. The runner in `runner/` is an internal support tool: it creates day files, downloads/caches inputs, runs examples before real input, and executes solutions through `ruby` or `rake`.

## Stars

Updated by CI on every push to `main` (`rake readme`).

<!-- aoc-overview -->
<!-- /aoc-overview -->

## Setup

Requires Ruby 4.0+. The checked-in `.ruby-version` pins the local development version.

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

Optional environment variables:

- `AOC_ASCII=1` swaps the emoji icons for plain ASCII (`*`, `!`, `>`, ...). Useful for terminals without Unicode glyphs.
- `AOC_DEBUG=1` prints the full backtrace when a solution raises instead of the first 5 lines.
- `AOC_CONFIG_DIR` overrides the default config directory (`~/.config/aoc-rb`).

## Create a day

```sh
rake 'new[2024,2]'
```

Scaffolding supports 25 days for years through 2024 and 12 days for 2025 onward.

To scaffold an alternative solution (a *variant*) for the same day, pass a slug:

```sh
rake 'new[2024,2,bitset]'   # creates 2024/02_bitset.rb
```

Variants are sibling files (`2024/02_bitset.rb` beside `2024/02.rb`) that share the canonical input. They are runnable, creatable, and linted, but never count toward stars or `rake 'all[YYYY]'`. Slugs match `/\A[a-z0-9]+\z/`; `base` is reserved.

## Run a day

```sh
ruby 2024/02.rb
```

Or:

```sh
rake 2024:02
```

To run a variant instead of the canonical file:

```sh
ruby 2024/02_bitset.rb
rake '2024:02[bitset]'
```

## Run all existing days for a year

```sh
rake 'all[2024]'
```

## Compare a day's variants

```sh
rake 'all[2024,2]'
```

Runs the canonical file and every variant of day 2 against the real input only (no examples) and prints a per-variant table with per-part timing. Answers that disagree across variants are flagged, and a variant that fails is marked without aborting its siblings. With no variants present, this is a one-row table: a quick way to time the real input without examples.

## Progress overview

```sh
rake all
```

`rake all` without a year shows global progress. `rake 'all[YYYY]'` runs the real inputs for existing days in that year.

## Studying the solutions

`rake check` lints the day files (and variants) with [Standard](https://github.com/standardrb/standard), pointing out idiom and slow-pattern improvements:

```sh
rake check
```

## Checks and tests

Standard is the single linter for the whole repo; the solutions and the runner share the same rules:

```sh
rake runner:test    # run the runner test suite (alias: rake test)
rake runner:lint    # syntax + Standard over runner/, Gemfile, Rakefile
rake runner:check   # runner:lint + runner:test
rake ci             # full gate: runner:check + rake check (what CI runs)
```

`rake ci` is the complete gate used by CI: Standard must pass on the whole repo and the runner tests must be green. The runner test suite uses SimpleCov; coverage reports are written to `coverage/` after each run.

## Day file format

```ruby
# frozen_string_literal: true

require_relative "../runner/aoc"

def parsed = @parsed ||= input.lines(chomp: true)

def part1
  raise "part1 not implemented"
end

example <<~INPUT, part1: 2
  ...
INPUT
```

When Part 2 exists, define it below `part1` and extend the example block:

```ruby
def part2
  ...
end

example <<~INPUT, part1: 2, part2: 4
  ...
INPUT
```

Do not define `part2` before starting Part 2.

## Runner structure

The Rakefile is a thin interface for public commands. Runner internals live under `runner/aoc/`, with `runner/aoc.rb` as the entry point used by challenge files. Tests for the runner live under `runner/test/`.

For a walkthrough of the runner's design (modules, boot lifecycle, error contract, network contract), see [`runner/ARCHITECTURE.md`](runner/ARCHITECTURE.md).
