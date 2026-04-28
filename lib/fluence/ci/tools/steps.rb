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
      #   * `Fluence::Ci::Tools::Runner` (pure gems): `include`s this
      #     module so the runner instance exposes the same methods.
      module Steps
        def lint
          step 'Style: rubocop', 'bundle exec rubocop'
        end

        def security
          step 'Security: brakeman',
               'bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error'
          step 'Security: bundler-audit', 'bundle exec bundler-audit check --update'
          step 'Security: ruby_audit',    'bundle exec ruby-audit check'
        end

        # Defaults to `lib`, or `app lib` if an `app/` directory exists
        # (Rails app / engine). Override explicitly when neither
        # heuristic applies.
        def codequality(paths: nil)
          paths ||= Dir.exist?('app') ? 'app lib' : 'lib'
          step 'Quality: reek', "bundle exec reek --no-progress #{paths}"
          step 'Quality: flog', "bundle exec flog -m -s #{paths}"
          step 'Quality: flay', "bundle exec flay #{paths}"
        end

        def docs
          step 'Docs: yard',      'bundle exec yard doc --no-output --no-stats'
          step 'Docs: yardstick', 'bundle exec yardstick measure'
        end

        # Detects which test framework(s) the project uses based on the
        # canonical helper files and emits one `step` per framework. A
        # repo with both `spec/spec_helper.rb` and `test/test_helper.rb`
        # gets two test steps (legacy minitest + rspec is a real case
        # in long-lived Rails apps).
        #
        # Pass `command:` explicitly to bypass detection — a single step
        # is registered with that command (useful for custom runners).
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
        # Override per-group args via a hash keyed by method name:
        #
        #   all(codequality: { paths: 'app lib' },
        #       tests:       { command: 'bin/rails test' })
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
