# Runner Architecture

The `runner/` directory is an internal support tool for Advent of Code solutions. This document explains the design so someone reading the code cold has a map.

## Module map

```
runner/
  aoc.rb                      # Entry point. Wires everything up, then triggers Boot.
  aoc/
    errors.rb                 # AOC::Error, UserError, CommandFailed taxonomy.
    calendar.rb               # max_day_for(year) and year/day validation.
    paths.rb                  # Path geometry: root, day_path, input_path, cache_dir, day_files, variants.
    config.rb                 # AOC_SESSION, AOC_USER_AGENT, AOC_MIN_INTERVAL_SECONDS resolution.
    downloader.rb             # HTTP fetch of input files with throttle + cache stamp.
    input_store.rb            # read(year, day): from cache, else delegate to downloader.
    dsl.rb                    # `example` and `input` installed onto the top-level binding.
    ui.rb                     # Aggregator that requires ui/ansi.rb, ui/format.rb, ui/renderer.rb.
    ui/ansi.rb                # COLORS, ICONS, ASCII_ICONS, color(), icon(). Pure.
    ui/format.rb              # value() and ms() formatters. Pure.
    ui/renderer.rb            # Stateful Renderer class: holds output + env, public render API.
    solution_status.rb        # Detect which parts are implemented (Prism-based for source paths).
    scaffolder.rb             # Generates day files from a template.
    runner.rb                 # Solves parts: examples + real input, or all-mode JSON emission.
    all_result_protocol.rb    # MARKER + Data.define Result (incl. variant) + emit/parse for AOC_RUN_MODE=all.
    commands.rb               # Public Rake-facing commands: help, new_day, run_day, all, run_day_comparison, check (solutions), ci, runner_check, lint_runner, test.
    boot.rb                   # Installs DSL and registers the at_exit auto-runner for day files.
  test/
    test_helper.rb            # Loads aoc.rb and support/fakes.rb. Defines RunnerTestSupport helpers.
    support/fakes.rb          # FakeHTTP, FakeHTTPClient, FakeInputStore, FakePaths, FakeSleeper.
    *_test.rb                 # Per-module tests.
    ui/*_test.rb              # Per-UI-module tests (ansi, format, renderer).
```

## Day file contract

A day file (`YYYY/NN.rb`) looks like this:

```ruby
# frozen_string_literal: true

require_relative "../runner/aoc"

def parsed = @parsed ||= input.lines(chomp: true)

def part1
  parsed.size
end

example <<~INPUT, part1: 3
abc
def
ghi
INPUT
```

`require_relative "../runner/aoc"` loads the runner and registers an `at_exit` hook. The day file then defines `part1`/`part2` at the top level and declares one or more `example` calls. After the script body finishes, the `at_exit` hook runs the solver against the examples and then the real input.

The file shape is the runner's public contract. Internals can change freely; day files cannot.

## Variants and the recognition seam

A *variant* is an alternative solution for a day, living in a sibling file next to the canonical one: `2015/06_bitset.rb` beside `2015/06.rb`. Variants are first-class to run, create, and lint, but invisible to stars, the overview, and `rake all[YYYY]`. They share the canonical input (`inputs/2015/06.txt`); there is no per-variant input.

Variants work by keeping two notions of "day file" separate where they would otherwise coincide:

- **Recognition**: *is this file executable as a day?* Governed by `Paths::DAY_FILE_PATTERN` and `Paths.day_file?` (the Boot auto-runner gate) plus `Paths#infer_year_day`. The pattern admits an optional `[_-]<slug>` suffix and still captures the two-digit day, so `06_bitset.rb` is recognized and resolves to `[2015, 6]`. Recognition is the lenient notion.
- **Counting**: *does this file earn a star / enter `all[YYYY]`?* Governed by the strict `[0-9][0-9].rb` glob in `Paths#day_files` (consumed by `Commands.run_year`) and the canonical `day_path` in `SolutionStatus.year_stars`. Counting is the strict notion: variants do not match the strict glob, so they stay out of star counting and year aggregation. `rake check` adds a separate variant glob so variants are still syntax- and style-checked.

Helpers built on recognition: `Paths#variant_path`, `Paths#day_variants` (canonical first, then sorted variants, the basis of comparison mode), and `Paths#infer_variant` (slug or nil).

Slugs are created as `NN_<slug>.rb` with `slug` matching `/\A[a-z0-9]+\z/`; `base` is reserved (the canonical file is the base). Recognition is more lenient than creation: it also tolerates a `-` separator for files authored by hand.

### Comparison mode: `rake 'all[YYYY,DD]'`

`Commands.all` progresses by arity: no args → overview; one arg → year; two args → `run_day_comparison`. Comparison runs the canonical file and every variant of one day against the real input only (no examples), in `AOC_RUN_MODE=all` subprocesses, and renders a per-variant table (one star line per row, mirroring the year table but with a variant-label column). It flags any part whose answer differs across variants.

Comparison is the one aggregation path that must tolerate a failing file: `run_day_comparison` uses `run_all_day_capturing`, which returns `[results, ok]` instead of raising on a non-zero subprocess (unlike `run_all_day`, used by `run_year`, which raises `CommandFailed` on the first failure). A failing variant is marked errored and its siblings still run. Comparison is a Rake-only concept; `ruby <file>` is always a focused single-file run.

## Object pollution (intentional trade-off)

Top-level `def part1` in Ruby adds a private method to `Object`. The runner depends on this:

- `Runner#solve` does `Object.new.extend(DSL::RuntimeInput)` and calls `part1`/`part2` on the new instance. This only works because `Object` was polluted when the day file was required.
- `SolutionStatus.available_parts` introspects `Object` to find which parts the loaded day file defined.

This is a Ruby idiom for top-level scripts but normally undesirable as a library design. The runner accepts it because the alternative would require day files to wrap solutions in `class` / `do...end` blocks, which the project rejects.

Two mitigations keep the cost manageable:

1. The overview path uses Prism, not `Object.method_defined?`. `SolutionStatus.part_complete?` parses the source statically, so `rake all` does not need to load every day file in-process (which would pollute `Object` across all years).
2. Solve uses `Object.new`, not the main object, so `@parsed` memoization does not leak across runs in the same process.

Tests work around `Object` pollution by removing `part1`/`part2` in `teardown`.

## Boot lifecycle

1. A day file (or `Rakefile`, or a test) calls `require_relative '.../runner/aoc'`.
2. `runner/aoc.rb` requires all submodules in order.
3. The bottom of `aoc.rb` calls `AOC::Boot.install!`.
4. `Boot.install_dsl` installs `example` and `input` onto `TOPLEVEL_BINDING.receiver`. Idempotent.
5. `Boot.install_auto_runner` checks if `$PROGRAM_NAME` is a day file. If yes, it registers an `at_exit` block (once per process).
6. Day file body executes: defines `part1`/`part2`, records `example` declarations.
7. Ruby fires the registered `at_exit`. `failure: -> { $! }` is evaluated lazily: if the process is unwinding from an unhandled exception, the lambda returns the exception, the `at_exit` block returns early via `next`, and the original error preserves its exit semantics.
8. Otherwise the block instantiates `Runner` and calls `run!` (human output) or `run_all_day!` (when `AOC_RUN_MODE=all`).

`Boot.reset!` is exposed for tests that want to verify the install-once behavior.

## Two render paths

Both paths produce human-readable output to a terminal. The difference is *who renders*: the child process (`run!`) or the parent process via aggregation (`run_all_day!`). The renderer is `AOC::UI::Renderer` in both cases.

### Direct render: `run!`

Used by `ruby 2024/02.rb` and `rake 2024:02`. The child process renders directly to its own stdout. Sequence:

1. `title(year, day)` header.
2. If `available_parts` is empty: print configuration error, exit non-zero.
3. `run_examples!` iterates declared examples, calling `solve(part, example.input)` for each expected `(part, value)` pair. A mismatch marks the run as failed but the remaining examples still execute; an exception aborts immediately via `catch(:stop)` / `throw :stop`. Either way it returns false.
4. When all examples passed, `run_real_input!` reads the cached input (or downloads it), solves each available part, and prints aligned results. Otherwise the runner prints `Stopped before real input.` and exits non-zero.

### Aggregated render: `run_all_day!` (`AOC_RUN_MODE=all`)

Used by `rake all[YYYY]`. The parent (`Commands.run_year`) spawns one Ruby subprocess per existing day file. The children do not render: they emit machine-parseable lines that the parent collects, then the parent renders the aggregated table.

Each child emits via `AllResultProtocol.emit(@output, Result.new(...))`:

```
AOC_ALL_RESULT {"day":2,"part":1,"answer":"cba","elapsed":0.125,"variant":null}
```

`variant` carries the originating file's slug (or null for the canonical file); it defaults to nil so the year-run path and existing callers ignore it, while comparison mode keys its table on it. The parent calls `AllResultProtocol.parse(stdout)` to recover an array of `Result` Data objects, then renders them via `Renderer#print_year_results` (year run) or `Renderer#print_day_comparison` (comparison). The `answer` field carries the raw string (`answer.to_s`); display formatting (`inspect`, truncation) happens at render time, not in the protocol.

The protocol exists only as a child/parent boundary. The user sees the same human-readable style as `run!`, just produced from a different process.

## Error contract

```
AOC::Error
├── AOC::UserError              # User-facing problems, abort with message via Rake.
│   ├── AOC::Calendar errors    # "Year and day must be integers", "Day must be between..."
│   ├── AOC::Downloader errors  # "Configure AOC_SESSION", "Network error...", "Session expired..."
│   ├── AOC::Config errors      # "AOC_MIN_INTERVAL_SECONDS must be a non-negative integer..."
│   ├── AOC::DSL errors         # "example requires part1: and/or part2:."
│   └── AOC::Runner::InvalidPartSignatureError
├── AOC::CommandFailed          # Subprocess or external command failure. Exit non-zero, no message.
└── AOC::DSL::InputNotReadyError # Internal: `input` called before assignment.
```

The Rakefile is the single catch site:

```ruby
def run_aoc
  yield
rescue AOC::CommandFailed
  exit(false)
rescue AOC::UserError => e
  abort e.message
end
```

`CommandFailed` exits silently because the underlying subprocess has already printed its own output. `UserError` aborts with a friendly message. Everything else (including bugs in the runner itself) escapes with a full backtrace.

## Network contract

`Downloader#download(year, day)` orchestrates:

1. Pull `session` and `user_agent` via `Config#session!` / `Config#user_agent!` (raise `UserError` if missing).
2. `throttle!` enforces `AOC_MIN_INTERVAL_SECONDS` (default 300) between requests. The cache stamp is written before the request: a failed request still counts against the rate limit, to be polite to adventofcode.com.
3. HTTP GET with `open_timeout: 10`, `read_timeout: 30`, `write_timeout: 10`.
4. Network exceptions (`SocketError`, `Net::OpenTimeout`, `OpenSSL::SSL::SSLError`, etc.) are wrapped as `UserError`.
5. `Net::HTTPRedirection` (typically 302 to the login page) is treated as session expired and surfaces a message telling the user to refresh the cookie.
6. On success the response body is written to the cached input path.

`InputStore` is the cache layer: if the input file exists locally, return it; otherwise delegate to `Downloader`. Cached inputs never trigger network access.

## UI layer

Three files, three responsibilities:

- **`Ansi`** owns ANSI color codes and icon glyphs. Pure functions that respect TTY, `NO_COLOR`, `TERM=dumb`, and `AOC_ASCII`.
- **`Format`** owns `value` (inspect + escape + truncate at 160 chars) and `ms` (timing formatter). No I/O, no env.
- **`Renderer`** is the only stateful piece: a class that captures `output` and `env` at construction. All `puts` go through it. Public methods are the render API used by `Runner` and `Commands`.

The split keeps `Renderer` testable (instantiate with a `StringIO`) and `Ansi`/`Format` reusable from anywhere.

## Dependency injection

Each public class takes its collaborators as keyword arguments with sensible defaults:

- `Runner.new(paths:, input_store:, ui:, output:, clock:, exiter:)`
- `Downloader.new(paths:, config:, http:, sleeper:, clock:)`
- `InputStore.new(paths:, downloader:)`
- `Scaffolder.new(paths:, output:, error:)`
- `Config.new(paths:, env:)`
- `Paths.new(root:, config_dir:, env:)`
- `Renderer.new(output:, env:)`

`Commands` module functions accept the same shape (`paths:`, `command_runner:`, etc.) so callers can substitute fakes. The test suite uses named fakes from `runner/test/support/fakes.rb` instead of ad-hoc anonymous objects.

## Testing posture

- Tests live in `runner/test/`, mirror the production layout, and run via `rake runner:test` (aliased as `rake test`) or as part of `rake runner:check` / `rake ci`.
- Each module has a focused test file. `UI` is split into `ui/ansi_test.rb`, `ui/format_test.rb`, `ui/renderer_test.rb`.
- Network is never hit: `Downloader` tests inject `FakeHTTP` and `FakeSleeper`.
- Subprocess tests (`Commands.run_all_day`, end-to-end day execution) shell out via `Open3.capture3` using `run_ruby` from `RunnerTestSupport`. These cost more wall time but exercise the real boot path.
- Tests that exercise `def part1`/`def part2` clean those methods off `Object` in `teardown`. That cleanup is the cost of keeping day files free of class wrappers (see "Object pollution" above).

## Linting

Standard is the single linter for the whole repo. The solutions and the runner share the same rules. Linting is a blocking gate: `rake ci` requires Standard to pass on the entire repo and the runner tests to be green.

The commands are split by what you run when:

- `rake check` lints the solutions (`20NN/NN.rb` + variants): the surface you run while studying.
- `rake runner:lint` lints the runner (`runner/**`, `Gemfile`, `Rakefile`); `rake runner:check` adds the test suite.
- `rake ci` = `runner:check` + `check`. Both call the shared `Commands.lint` helper (`ruby -c` per file, then `standardrb`) over `runner_files` and `solution_files` respectively.

`.standard.yml` only ignores `vendor/` and `coverage/`.
