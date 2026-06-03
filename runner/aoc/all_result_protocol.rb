# frozen_string_literal: true

require "json"

module AOC
  # Wire protocol between a day file running in AOC_RUN_MODE=all and the
  # parent process that aggregates results (AOC::Commands.run_year).
  #
  # The child emits one MARKER-prefixed JSON line per solved part on stdout;
  # the parent scans stdout for the prefix and parses each match into a Result.
  module AllResultProtocol
    MARKER = "AOC_ALL_RESULT "

    # `variant` is the originating file's slug, or nil for the canonical file.
    Result = Data.define(:day, :part, :answer, :elapsed, :variant) do
      def initialize(variant: nil, **rest) = super(**rest, variant: variant)
    end

    module_function

    def emit(io, result)
      io.puts "#{MARKER}#{JSON.generate(result.to_h)}"
    end

    def parse(stdout)
      stdout.each_line.filter_map do |line|
        next unless line.start_with?(MARKER)

        payload = JSON.parse(line.delete_prefix(MARKER), symbolize_names: true)
        Result.new(**payload)
      end
    end
  end
end
