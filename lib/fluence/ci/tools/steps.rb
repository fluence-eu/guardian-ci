# frozen_string_literal: true

module Fluence
  module Ci
    module Tools
      # Mixin that adds the curated check groups to anything exposing a
      # `step(label, command)` method. Mirrors the centralised CI
      # workflows in `fluence-eu/ci-workflows`. Two hosts use it:
      #
      #   * Inside `CI.run do ... end` (Rails 8's
      #     `ActiveSupport::ContinuousIntegration`): `extend` the module
      #     so `lint`, `security`, etc. delegate to the block's `step`.
      #   * {Fluence::Ci::Tools::Runner} (pure gems): `include`s this
      #     module so the runner instance exposes the same methods.
      #
      # @example Rails — extend the CI block
      #   require 'fluence/ci/tools/steps'
      #   CI.run do
      #     extend Fluence::Ci::Tools::Steps
      #     all
      #   end
      #
      # @example Gem — include in a runner
      #   runner = Fluence::Ci::Tools::Runner.new
      #   runner.all
      #   runner.report!
      module Steps
        # Run the rubocop lint step.
        # @return [void]
        # @api public
        def lint
          step 'Style: rubocop', 'bundle exec rubocop'
        end

        # Run the security audit suite (brakeman, bundler-audit, ruby_audit).
        # @return [void]
        # @api public
        def security
          step 'Security: brakeman',
               'bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error'
          step 'Security: bundler-audit', 'bundle exec bundler-audit check --update'
          step 'Security: ruby_audit',    'bundle exec ruby-audit check'
        end

        # Run the code-smell suite (reek, flog, flay).
        #
        # Defaults to `lib`, or `app lib` if an `app/` directory exists
        # (Rails app / engine). Override explicitly when neither
        # heuristic applies.
        #
        # @param paths [String, nil] space-separated source paths to scan
        # @return [void]
        # @api public
        def codequality(paths: nil)
          paths ||= Dir.exist?('app') ? 'app lib' : 'lib'
          step 'Quality: reek', "bundle exec reek --no-progress #{paths}"
          step 'Quality: flog', "bundle exec flog -m -s #{paths}"
          step 'Quality: flay', "bundle exec flay #{paths}"
        end

        # Validate that the YARD documentation builds cleanly. Coverage
        # measurement (yardstick) lives in the gem's Rakefile —
        # consumers run `bundle exec rake doc:measure` /
        # `doc:verify` for that, and the centralised CI workflow
        # `ruby-gem-docs-measure` invokes those rake tasks directly.
        # @return [void]
        # @api public
        def docs
          step 'Docs: yard', 'bundle exec yard doc --no-output --no-stats'
        end

        # Run the project's test suite(s).
        #
        # Detects which test framework(s) the project uses based on the
        # canonical helper files and emits one `step` per framework. A
        # repo with both `spec/spec_helper.rb` and `test/test_helper.rb`
        # gets two test steps (legacy minitest + rspec is a real case
        # in long-lived Rails apps).
        #
        # Pass `command:` explicitly to bypass detection — a single step
        # is registered with that command (useful for custom runners).
        #
        # @param command [String, nil] explicit test command; bypasses detection
        # @return [void]
        # @api public
        def tests(command: nil)
          if command
            step 'Tests', command
            return
          end

          step 'Tests: rspec', 'bundle exec rspec' if File.exist?('spec/spec_helper.rb')
          return unless File.exist?('test/test_helper.rb')

          minitest_command = File.exist?('bin/rails') ? 'bin/rails test' : 'bundle exec rake test'
          step 'Tests: minitest', minitest_command
        end

        # Run every step group in the catalog. Adding a new group
        # method to this module makes it appear automatically in
        # `all`, so consumers don't have to edit their `config/ci.rb`
        # / rake task on every fluence-ci-tools release.
        #
        # @param overrides [Hash{Symbol => Hash}] per-group keyword
        #   arguments. Keys are step group method names; values are
        #   hashes forwarded as keyword args.
        # @return [void]
        # @example Override one group
        #   all(codequality: { paths: 'app lib spec/support' })
        # @example Override two groups
        #   all(codequality: { paths: 'app lib' },
        #       tests:       { command: 'bin/rails test' })
        # @api public
        def all(**overrides)
          Steps.instance_methods(false).reject { |m| m == :all }.each do |method_name|
            args = overrides[method_name] || {}
            args.empty? ? public_send(method_name) : public_send(method_name, **args)
          end
        end
      end
    end
  end
end
