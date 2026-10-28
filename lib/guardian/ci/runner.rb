# frozen_string_literal: true

require 'guardian/ci/steps'

module Guardian
  module Ci
    # Minimal orchestrator that mirrors the `step(label, command)`
    # interface of `ActiveSupport::ContinuousIntegration` so the same
    # {Guardian::Ci::Steps} mixin composes against either
    # host. Used by the rake task installed in pure gems (where
    # `ActiveSupport::ContinuousIntegration` isn't available).
    #
    # @example Run the full catalog from a rake task
    #   require 'guardian/ci/runner'
    #   namespace :guardian_ci do
    #     task :check do
    #       runner = Guardian::Ci::Runner.new
    #       runner.all
    #       runner.report!
    #     end
    #   end
    class Runner
      include Steps

      # Build a fresh runner with no recorded steps yet.
      # @param io [IO] stream for human-readable progress output
      # @api public
      def initialize(io: $stdout)
        @io = io
        @failures = []
      end

      # Run a single command as a CI step. Tracks success/failure in
      # `@failures` so {#report!} can decide whether to exit 1.
      #
      # @param label [String] short human-readable name of the step
      # @param command [String] shell command to execute via `system`
      # @return [void]
      # @api public
      def step(label, command)
        @io.puts "==> #{label}"
        @io.puts "    $ #{command}"
        system(command) || (@failures << label)
        @io.puts
      end

      # Whether every recorded step succeeded so far.
      # @return [Boolean] true when every recorded step succeeded
      # @api public
      def success?
        @failures.empty?
      end

      # Print the final report and raise `SystemExit(1)` on failure
      # so the rake task / CLI propagates a non-zero exit status to
      # CI. No-op return on success.
      #
      # @return [void]
      # @raise [SystemExit] when at least one step failed
      # @api public
      def report!
        if success?
          @io.puts '✓ All checks passed'
        else
          @io.puts "✗ Failed: #{@failures.join(', ')}"
          exit 1
        end
      end
    end
  end
end
