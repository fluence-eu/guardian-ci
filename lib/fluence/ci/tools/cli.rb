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
      # Each group command accepts `--report` to switch the underlying
      # tool from human-readable console output to machine-readable
      # files under standardised paths — that's how the centralised
      # ci-workflows reusables consume the catalog.
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
        # picks up new group methods on `bundle update`.
        Fluence::Ci::Tools::Steps.instance_methods(false).each do |group|
          desc group.to_s, "Run the #{group} catalog group"
          option :report, type: :boolean, default: false,
                          desc: 'Emit machine-readable artefact instead of console output'
          define_method(group) do
            runner = Fluence::Ci::Tools::Runner.new
            params = runner.method(group).parameters
            if options[:report] && params.any? { |type, name| %i[key keyreq].include?(type) && name == :report }
              runner.public_send(group, report: true)
            else
              runner.public_send(group)
            end
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
