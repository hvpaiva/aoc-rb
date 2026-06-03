# frozen_string_literal: true

module AOC
  module Boot
    class << self
      def install!(
        program_name: $PROGRAM_NAME,
        env: ENV,
        at_exit_handler: Kernel.method(:at_exit),
        runner_factory: Runner.method(:new),
        failure: -> { $! }
      )
        install_dsl
        install_auto_runner(
          program_name: program_name,
          env: env,
          at_exit_handler: at_exit_handler,
          runner_factory: runner_factory,
          failure: failure
        )
      end

      def reset!
        @auto_runner_installed = false
      end

      private

      def install_dsl
        DSL.install!
      end

      def install_auto_runner(program_name:, env:, at_exit_handler:, runner_factory:, failure:)
        return if @auto_runner_installed
        return unless Paths.day_file?(program_name)

        @auto_runner_installed = true

        at_exit_handler.call do
          # `failure` is evaluated at at_exit time: $! is non-nil only when the
          # process is unwinding from an unhandled exception. In that case we
          # skip the auto-run so the original error keeps its exit semantics.
          next if failure.call

          runner = runner_factory.call
          (env["AOC_RUN_MODE"] == "all") ? runner.run_all_day! : runner.run!
        end
      end
    end
  end
end
