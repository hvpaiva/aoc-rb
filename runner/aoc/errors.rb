# frozen_string_literal: true

module AOC
  class Error < StandardError; end

  class UserError < Error; end

  class CommandFailed < UserError; end
end
