# frozen_string_literal: true

require 'thor'
require 'fileutils'
require 'guardian/ci/version'
require 'guardian/ci/runner'

module Guardian
  module Ci
    # Thor CLI exposed via `exe/guardian-ci`. Every method of
    # {Guardian::Ci::Steps} is exposed as a top-level Thor
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
    #   * `install` — generate `lib/tasks/guardian_ci.rake` (gem)
    #   * `version` — print the gem version
    class CLI < Thor
      TEMPLATES = File.expand_path('../../generators/guardian_ci/templates', __dir__)

      # Steps kwargs that map to a Thor boolean flag rather than a
      # string. Extend this when a new boolean kwarg is added to a
      # Steps method (Ruby's reflection doesn't expose default
      # values, so the type can't be auto-derived from
      # `instance_method(...).parameters`).
      BOOLEAN_KWARGS = %i[report build].freeze

      # Tell Thor to exit non-zero when a `Thor::Error` is raised
      # instead of just printing the message and returning 0.
      # @return [Boolean] always true here
      # @api public
      def self.exit_on_failure?
        true
      end

      # Register one Thor command per Steps method, with one Thor
      # option per kwarg. Boolean type comes from {BOOLEAN_KWARGS};
      # everything else is `:string`.
      # @param group [Symbol] name of the Steps method to expose
      # @return [void]
      # @api private
      def self.register_group_command(group)
        parameters = Guardian::Ci::Steps.instance_method(group).parameters
        desc group.to_s, "Run the #{group} catalog group"
        parameters.each { |type, name| register_option(group, type, name) }
        define_dispatch_method(group, parameters)
      end

      # Declare a single Thor option for one Steps kwarg.
      # @return [void]
      # @api private
      def self.register_option(group, type, name)
        return unless %i[key keyreq].include?(type)

        if BOOLEAN_KWARGS.include?(name)
          option name, type: :boolean, default: false, desc: option_desc(group, name)
        else
          option name, type: :string, desc: "Forward `#{name}:` kwarg to Steps##{group}"
        end
      end

      # Description text for a boolean option. `--report` gets a
      # human-friendly tagline; other booleans default to the
      # standard "forward kwarg" message.
      # @return [String]
      # @api private
      def self.option_desc(group, name)
        return 'Emit machine-readable artefact instead of console output' if name == :report

        "Forward `#{name}: true` to Steps##{group}"
      end

      # Define the Thor command body that forwards CLI options to the
      # corresponding Steps method on a fresh {Runner} instance.
      # @return [void]
      # @api private
      def self.define_dispatch_method(group, parameters)
        define_method(group) do
          runner = Guardian::Ci::Runner.new
          kwargs = parameters.each_with_object({}) do |(type, name), acc|
            next unless %i[key keyreq].include?(type)

            value = options[name.to_s]
            acc[name] = value unless value.nil? || value == false
          end
          runner.public_send(group, **kwargs)
          runner.report!
        end
      end

      # Auto-pickup catalog: every Steps method becomes a top-level
      # Thor command so adding a group on `bundle update` requires no
      # edit here.
      Guardian::Ci::Steps.instance_methods(false).each { |group| register_group_command(group) }

      desc 'install',
           'Generate lib/tasks/guardian_ci.rake (Rails apps: use `bin/rails generate guardian_ci:install`)'
      option :force, type: :boolean, default: false, desc: 'Overwrite existing destination file'
      # Copy the gem rake-task template into the consumer at
      # `lib/tasks/guardian_ci.rake`.
      # @return [void]
      # @api public
      def install
        target = 'lib/tasks/guardian_ci.rake'
        if File.exist?(target) && !options[:force]
          say "#{target} already exists — pass --force to overwrite", :red
          exit 1
        end

        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(File.join(TEMPLATES, 'guardian_ci.rake'), target)
        say "Generated #{target} (run with `bundle exec rake guardian_ci:check`)", :green
      end

      desc 'version', 'Print the guardian-ci version'
      # Print the gem version to stdout.
      # @return [void]
      # @api public
      def version
        puts "guardian-ci #{Guardian::Ci::VERSION}"
      end
    end
  end
end
