# frozen_string_literal: true

module AOC
  module Boot
    module_function

    def install!(program_name: $PROGRAM_NAME, env: ENV, at_exit_handler: Kernel.method(:at_exit), runner_factory: Runner.method(:new), failure: -> { $! })
      DSL.install!
      return if @installed

      @installed = true
      return unless Paths.day_file?(program_name)

      at_exit_handler.call do
        next if failure.call

        runner = runner_factory.call

        if env["AOC_RUN_MODE"] == "all"
          runner.run_all_day!
        else
          runner.run!
        end
      end
    end
  end
end
