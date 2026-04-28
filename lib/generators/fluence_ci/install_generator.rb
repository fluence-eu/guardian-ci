# frozen_string_literal: true

require 'rails/generators/base'

module FluenceCi
  # Rails generator invoked via `bin/rails generate fluence_ci:install`.
  # Discovered by Rails through the conventional path
  # `lib/generators/<namespace>/install_generator.rb`. The Railtie
  # registers it at boot time so consumers don't need any extra wiring.
  #
  # Two strategies depending on whether `config/ci.rb` already exists:
  #
  #   * Greenfield (no config/ci.rb): copy the full self-contained
  #     template via `copy_file`.
  #   * Existing file (e.g. Rails 8.1+ default): inject `extend
  #     Fluence::Ci::Tools::Steps` + `all(...)` via `inject_into_file`,
  #     leaving the Rails defaults intact. Idempotent. Future step
  #     groups added to the gem are picked up by `all` automatically,
  #     so consumers don't need an `update` command.
  class InstallGenerator < Rails::Generators::Base
    # Path inside the host Rails app where the CI definition lives.
    TARGET = 'config/ci.rb'

    source_root File.expand_path('templates', __dir__)

    # Copy or inject the Fluence CI scaffold into the host app. Picks
    # the right strategy based on whether `config/ci.rb` already
    # exists. Idempotent on subsequent runs.
    #
    # @return [void]
    # @api public
    def install
      if File.exist?(File.join(destination_root, TARGET))
        inject_fluence_steps
      else
        copy_file 'config_ci.rb', TARGET
      end
    end

    private

    # Inject the Fluence steps into an existing config/ci.rb. Skips
    # when the file already references the Steps mixin.
    # @return [void]
    # @api private
    def inject_fluence_steps
      content = File.read(File.join(destination_root, TARGET))
      if content.include?('Fluence::Ci::Tools::Steps')
        say "#{TARGET} already references Fluence::Ci::Tools::Steps — nothing to do", :yellow
        return
      end

      inject_into_file TARGET, "require 'fluence/ci/tools/steps'\n\n",
                       before: /^CI\.run do$/
      inject_into_file TARGET, fluence_block, before: /^end$/
    end

    # The Ruby block injected into the consumer's config/ci.rb.
    # @return [String]
    # @api private
    def fluence_block
      <<~RUBY

        # Added by fluence-ci-tools (run with `bin/ci`).
        # `all` runs the whole curated catalog with auto-detected
        # defaults (paths, test runner). New step groups added to
        # fluence-ci-tools appear here automatically. Override via:
        #   all(codequality: { paths: 'custom' })
        extend Fluence::Ci::Tools::Steps
        all
      RUBY
    end
  end
end
