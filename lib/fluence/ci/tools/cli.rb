# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'fluence/ci/tools/version'
require 'fluence/ci/tools/runner'

module Fluence
  module Ci
    module Tools
      # Thor CLI exposed via `exe/fluence-ci`. Every method of
      # {Fluence::Ci::Tools::Steps} is exposed as a top-level Thor
      # command so the CLI surface mirrors the catalog 1-1: adding a
      # new step group to the mixin makes it appear here automatically.
      #
      # Every keyword argument of a Steps method is auto-exposed as a
      # CLI option of the same name: `--report` (the boolean used by
      # every group), `--paths "app lib"` for `codequality`,
      # `--command "my-runner"` for `tests`, etc. Adding a kwarg to a
      # Steps method makes it appear as a CLI flag with no edit here.
      #
      # Plus two utility commands:
      #   * `install` — generate `lib/tasks/fluence_ci.rake` (gem)
      #   * `version` — print the gem version
      class CLI < Thor
        TEMPLATES = File.expand_path('../../../generators/fluence_ci/templates', __dir__)

        # Tell Thor to exit non-zero when a `Thor::Error` is raised
        # instead of just printing the message and returning 0.
        # @return [Boolean] always true here
        # @api public
        def self.exit_on_failure?
          true
        end

        # Per-Steps-method commands, defined dynamically so the CLI
        # picks up new group methods (and new kwargs on existing ones)
        # on `bundle update`.
        Fluence::Ci::Tools::Steps.instance_methods(false).each do |group|
          # Capture the parameter list once at class-definition time so
          # the dispatch closure below doesn't have to re-introspect
          # Steps on every CLI invocation.
          parameters = Fluence::Ci::Tools::Steps.instance_method(group).parameters
          desc group.to_s, "Run the #{group} catalog group"

          parameters.each do |type, name|
            # Only `key` / `keyreq` map to Thor flags; positional args
            # and `**overrides` (the keyrest on `Steps#all`) cannot be
            # exposed through Thor without a per-method shim.
            next unless %i[key keyreq].include?(type)

            if name == :report
              option :report, type: :boolean, default: false,
                              desc: 'Emit machine-readable artefact instead of console output'
            else
              option name, type: :string,
                           desc: "Forward `#{name}:` kwarg to Steps##{group}"
            end
          end

          define_method(group) do
            runner = Fluence::Ci::Tools::Runner.new
            # Forward only options the user actually set: skip nil
            # (string flag absent) and false (boolean flag absent — the
            # default for `report`). Unset kwargs let the Steps method
            # apply its own default.
            kwargs = parameters.each_with_object({}) do |(type, name), acc|
              next unless %i[key keyreq].include?(type)

              value = options[name.to_s]
              next if value.nil? || value == false

              acc[name] = value
            end
            runner.public_send(group, **kwargs)
            runner.report!
          end
        end

        desc 'install',
             'Generate lib/tasks/fluence_ci.rake (Rails apps: use `bin/rails generate fluence_ci:install`)'
        option :force, type: :boolean, default: false, desc: 'Overwrite existing destination file'
        # Copy the gem rake-task template into the consumer at
        # `lib/tasks/fluence_ci.rake`.
        # @return [void]
        # @api public
        def install
          target = 'lib/tasks/fluence_ci.rake'
          if File.exist?(target) && !options[:force]
            say "#{target} already exists — pass --force to overwrite", :red
            exit 1
          end

          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(File.join(TEMPLATES, 'fluence_ci.rake'), target)
          say "Generated #{target} (run with `bundle exec rake fluence_ci:check`)", :green
        end

        desc 'version', 'Print the fluence-ci-tools version'
        # Print the gem version to stdout.
        # @return [void]
        # @api public
        def version
          puts "fluence-ci-tools #{Fluence::Ci::Tools::VERSION}"
        end
      end
    end
  end
end
