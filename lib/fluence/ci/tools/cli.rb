# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'fluence/ci/tools/version'

module Fluence
  module Ci
    module Tools
      # Thor CLI exposed via `exe/fluence-ci`. Two distinct paths:
      # the gem-side `install` command does a direct file copy (no
      # generator framework needed), while Rails apps are pointed at
      # `bin/rails generate fluence_ci:install`. The `check` command
      # runs the catalog locally via `Fluence::Ci::Tools::Runner`.
      class CLI < Thor
        TEMPLATES = File.expand_path('../../../generators/fluence_ci/templates', __dir__)

        def self.exit_on_failure?
          true
        end

        desc 'install', 'Generate lib/tasks/fluence_ci.rake (Rails apps: use `bin/rails generate fluence_ci:install`)'
        option :force, type: :boolean, default: false, desc: 'Overwrite existing destination file'
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
        def version
          puts "fluence-ci-tools #{Fluence::Ci::Tools::VERSION}"
        end

        private

        def install_gem_rake_task
          target = 'lib/tasks/fluence_ci.rake'
          if File.exist?(target) && !options[:force]
            say "#{target} already exists — pass --force to overwrite", :red
            exit 1
          end

          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(File.join(TEMPLATES, 'fluence_ci.rake'), target)
          say "Generated #{target} (run with `bundle exec rake fluence_ci:check`)", :green
        end
      end
    end
  end
end
