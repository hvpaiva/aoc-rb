# frozen_string_literal: true

module AOC
  module UI
    # Pure value formatters. No I/O, no ANSI, no env. Deterministic functions
    # safe to call from anywhere in the renderer.
    module Format
      MAX_VALUE_LENGTH = 160
      VALUE_TRUNCATION_TAIL = '...'

      module_function

      def value(object)
        text = object.inspect.gsub("\n", '\\n')
        return text if text.length <= MAX_VALUE_LENGTH

        text[0, MAX_VALUE_LENGTH - VALUE_TRUNCATION_TAIL.length] + VALUE_TRUNCATION_TAIL
      end

      def ms(elapsed)
        milliseconds = elapsed * 1000

        if milliseconds < 10
          format('%.2fms', milliseconds)
        else
          format('%.1fms', milliseconds)
        end
      end
    end
  end
end
