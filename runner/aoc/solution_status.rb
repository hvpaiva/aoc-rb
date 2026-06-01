# frozen_string_literal: true

require 'prism'

module AOC
  # Reports which day files have implemented part1 and part2. Used by both
  # the runtime path (via `Object` introspection after a day file is loaded)
  # and the overview path (via static source analysis with Prism).
  #
  # A part is considered incomplete when it raises the placeholder generated
  # by Scaffolder, i.e. `raise "partN not implemented"`. Any other body is
  # treated as implemented.
  module SolutionStatus
    PART_NAMES = { 1 => :part1, 2 => :part2 }.freeze

    module_function

    def available_parts
      PART_NAMES.filter_map do |part, name|
        next unless Object.method_defined?(name) || Object.private_method_defined?(name)

        part
      end
    end

    def year_stars(year, paths: Paths.default)
      (1..Calendar.max_day_for(year)).flat_map do |day|
        path = paths.day_path(year, day)
        path.exist? ? day_stars(path) : [false, false]
      end
    end

    def day_stars(path)
      source = path.read
      [part_complete?(source, 1), part_complete?(source, 2)]
    end

    def part_complete?(source, part)
      method_node = find_part_method(source, PART_NAMES.fetch(part))
      return false unless method_node

      !placeholder?(method_node, part)
    end

    def find_part_method(source, name)
      result = Prism.parse(source)
      return nil unless result.success?

      collect_def_nodes(result.value).find { |node| node.name == name }
    end

    def collect_def_nodes(node, acc = [])
      acc << node if node.is_a?(Prism::DefNode)
      node.compact_child_nodes.each { |child| collect_def_nodes(child, acc) }
      acc
    end

    def placeholder?(def_node, part)
      body = def_node.body
      return false unless body.is_a?(Prism::StatementsNode)

      statements = body.body
      return false unless statements.length == 1

      call = statements.first
      return false unless call.is_a?(Prism::CallNode) && call.name == :raise

      arguments = call.arguments&.arguments || []
      return false unless arguments.length == 1

      literal = string_literal(arguments.first)
      literal == "part#{part} not implemented"
    end

    def string_literal(node)
      case node
      when Prism::StringNode
        node.unescaped
      when Prism::InterpolatedStringNode
        return nil unless node.parts.all?(Prism::StringNode)

        node.parts.map(&:unescaped).join
      end
    end
  end
end
