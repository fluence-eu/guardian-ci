# frozen_string_literal: true

module Fluence
  module Ci
    module Tools
      # Mixin that adds the curated check groups to anything exposing a
      # `step(label, command)` method. Mirrors the centralised CI
      # workflows in `fluence-eu/ci-workflows`.
      #
      # Each group method takes a `report:` boolean kwarg. With
      # `report: false` (the default) the underlying tools print
      # human-readable output to the console — what devs want for
      # local pre-push runs. With `report: true` the same tools are
      # invoked with their machine-output flags and write to a
      # standardised path under the project root, so the centralised
      # CI workflows can pick the artefact up for baseline diffs:
      #
      #   * lint        → tmp/fluence-report/rubocop.json
      #   * security    → tmp/fluence-report/{brakeman.json,audit.txt,ruby_audit.txt}
      #   * codequality → tmp/fluence-report/{reek,flog,flay}.txt
      #   * docs        → doc/yardstick_report.txt (via `rake doc:measure`,
      #     path controlled by the consumer's Rakefile + `.yardstick.yml`)
      #
      # `tests` does not take `report:` — coverage is captured as a
      # side effect by SimpleCov's spec_helper integration, the same
      # `coverage/coverage.json` file is produced regardless of mode.
      module Steps
        # Path under the project root where every machine-readable
        # report lands when `report: true`. Conventionally gitignored
        # (Ruby projects already gitignore `tmp/`).
        REPORT_DIR = 'tmp/fluence-report'

        # Run the rubocop lint step.
        # @param report [Boolean] when true, write JSON report to `tmp/fluence-report/rubocop.json`
        # @return [void]
        # @api public
        def lint(report: false)
          Steps.ensure_report_dir if report
          if report
            step 'Style: rubocop', "bundle exec rubocop --format json --out #{REPORT_DIR}/rubocop.json"
          else
            step 'Style: rubocop', 'bundle exec rubocop'
          end
        end

        # Run the security audit suite (brakeman, bundler-audit, ruby_audit).
        # @param report [Boolean] when true, write reports under `tmp/fluence-report/`
        # @return [void]
        # @api public
        def security(report: false)
          Steps.ensure_report_dir if report
          if report
            step 'Security: brakeman',
                 "bundle exec brakeman --no-pager --format json --output #{REPORT_DIR}/brakeman.json"
            step 'Security: bundler-audit',
                 "bundle exec bundler-audit check --update | tee #{REPORT_DIR}/audit.txt"
            step 'Security: ruby_audit',
                 "bundle exec ruby-audit check | tee #{REPORT_DIR}/ruby_audit.txt"
          else
            step 'Security: brakeman',
                 'bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error'
            step 'Security: bundler-audit', 'bundle exec bundler-audit check --update'
            step 'Security: ruby_audit',    'bundle exec ruby-audit check'
          end
        end

        # Run the code-smell suite (reek, flog, flay).
        #
        # Defaults `paths` to `lib`, or `app lib` if an `app/` directory
        # exists (Rails app / engine). Override explicitly otherwise.
        #
        # @param paths [String, nil] space-separated source paths to scan
        # @param report [Boolean] when true, write reports under `tmp/fluence-report/`
        # @return [void]
        # @api public
        def codequality(paths: nil, report: false)
          paths ||= Dir.exist?('app') ? 'app lib' : 'lib'
          Steps.ensure_report_dir if report
          if report
            step 'Quality: reek', "bundle exec reek --no-progress #{paths} | tee #{REPORT_DIR}/reek.txt"
            step 'Quality: flog', "bundle exec flog -m -s #{paths} | tee #{REPORT_DIR}/flog.txt"
            step 'Quality: flay', "bundle exec flay #{paths} | tee #{REPORT_DIR}/flay.txt"
          else
            step 'Quality: reek', "bundle exec reek --no-progress #{paths}"
            step 'Quality: flog', "bundle exec flog -m -s #{paths}"
            step 'Quality: flay', "bundle exec flay #{paths}"
          end
        end

        # Create `tmp/fluence-report/` if it doesn't already exist.
        # Idempotent. Each report-mode group method calls this before
        # registering its `step` calls, so the shell commands don't
        # need a `mkdir -p` prefix each time.
        # @return [void]
        # @api private
        def self.ensure_report_dir
          require 'fileutils'
          FileUtils.mkdir_p(REPORT_DIR)
        end

        # Validate documentation. Default mode runs `yard doc` to ensure
        # the docs build cleanly. Report mode runs `rake doc:measure`
        # which honours `.yardstick.yml` and writes the coverage report
        # to `doc/yardstick_report.txt`.
        #
        # @param report [Boolean] when true, run yardstick measurement
        # @return [void]
        # @api public
        def docs(report: false)
          if report
            step 'Docs: yardstick', 'bundle exec rake doc:measure'
          else
            step 'Docs: yard', 'bundle exec yard doc --no-output --no-stats'
          end
        end

        # Run the project's test suite(s). Detects rspec / minitest
        # presence via `spec/spec_helper.rb` / `test/test_helper.rb`.
        # Coverage (`coverage/coverage.json`) is captured automatically
        # by SimpleCov when configured in the consumer's spec_helper.
        #
        # Pass `command:` explicitly to bypass detection.
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
        # method makes it appear automatically. Override per-group
        # kwargs via a hash keyed by method name.
        #
        # @param report [Boolean] when true, propagate `report: true` to every
        #   group method that accepts it (lint, security, codequality, docs)
        # @param overrides [Hash{Symbol => Hash}] per-group keyword args
        #   that take precedence over the propagated `report:` flag
        # @return [void]
        # @example Report mode for the whole catalog
        #   all(report: true)
        # @example Mix global report mode + a specific override
        #   all(report: true, codequality: { paths: 'app lib' })
        # @api public
        def all(report: false, **overrides)
          Steps.instance_methods(false).reject { |m| m == :all }.each do |method_name|
            args = Steps.send(:resolve_args, self, method_name, report: report, overrides: overrides)
            args.empty? ? public_send(method_name) : public_send(method_name, **args)
          end
        end

        # Compute the kwargs hash to forward when `all` calls a step
        # group. Per-method overrides win; otherwise propagate `report:`
        # to methods that accept it; otherwise call with no args.
        # @return [Hash]
        # @api private
        def self.resolve_args(host, method_name, report:, overrides:)
          custom = overrides[method_name] || {}
          return custom if custom.any?

          accepts_report = host.method(method_name).parameters.any? do |type, name|
            %i[key keyreq].include?(type) && name == :report
          end
          report && accepts_report ? { report: true } : {}
        end
      end
    end
  end
end
