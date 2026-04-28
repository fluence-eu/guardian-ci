# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'fluence/ci/tools/version'

module Fluence
  module Ci
    module Tools
      # Thor CLI exposed via `exe/fluence-ci`. The `install` command
      # generates the gem-side rake task (`lib/tasks/fluence_ci.rake`)
      # via a direct file copy — Rails apps should use
      # `bin/rails generate fluence_ci:install` for the native `bin/ci`
      # path. The `check` command runs the catalog locally via
      # {Fluence::Ci::Tools::Runner}.
      class CLI < Thor
        # Path to the generator template directory shipped inside the
        # gem. Resolved relative to this file so it survives gem
        # packaging (no `__dir__` chdir surprises).
        TEMPLATES = File.expand_path('../../../generators/fluence_ci/templates', __dir__)

        # Tell Thor to exit non-zero when a `Thor::Error` is raised
        # (instead of just printing the message and returning 0).
        # @return [Boolean] always true here
        # @api public
        def self.exit_on_failure?
          true
        end

        desc 'install', 'Generate lib/tasks/fluence_ci.rake (Rails apps: use `bin/rails generate fluence_ci:install`)'
        option :force, type: :boolean, default: false, desc: 'Overwrite existing destination file'
        # Copy the gem rake-task template into the consumer at
        # `lib/tasks/fluence_ci.rake`. Refuses to overwrite without
        # `--force`.
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

        desc 'check [GROUP]', 'Run the full Fluence catalog (no arg) or a single group from `Fluence::Ci::Tools::Steps`'
        # Run the curated catalog locally. With no argument, runs every
        # group via `Runner#all`. With a group name, runs just that
        # group; raises `Thor::Error` if the name doesn't match a
        # public method of {Fluence::Ci::Tools::Steps}.
        #
        # @param group [String, nil] step group name; full catalog when nil
        # @return [void]
        # @raise [Thor::Error] when `group` doesn't match a Steps method
        # @api public
        def check(group = nil)
          require 'fluence/ci/tools/runner'
          runner = Fluence::Ci::Tools::Runner.new

          if group.nil?
            runner.all
          else
            available = Fluence::Ci::Tools::Steps.instance_methods(false) - %i[all]
            raise Thor::Error, "Unknown group #{group.inspect}" unless available.include?(group.to_sym)

            runner.public_send(group.to_sym)
          end

          runner.report!
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
