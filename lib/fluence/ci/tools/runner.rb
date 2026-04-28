# frozen_string_literal: true

require 'fluence/ci/tools/steps'

module Fluence
  module Ci
    module Tools
      # Minimal orchestrator that mirrors the `step(label, command)`
      # interface of `ActiveSupport::ContinuousIntegration` so the same
      # `Fluence::Ci::Tools::Steps` mixin composes against either
      # host. Used by the rake task installed in pure gems (where
      # `ActiveSupport::ContinuousIntegration` isn't available).
      class Runner
        include Steps

        def initialize(io: $stdout)
          @io = io
          @failures = []
        end

        def step(label, command)
          @io.puts "==> #{label}"
          @io.puts "    $ #{command}"
          system(command) || (@failures << label)
          @io.puts
        end

        def success?
          @failures.empty?
        end

        # Print the final report and raise SystemExit(1) on failure so
        # the rake task / CLI propagates a non-zero exit status to CI.
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
end
