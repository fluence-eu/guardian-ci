# frozen_string_literal: true

require 'rails/generators/base'

module FluenceCi
  # Rails generator invoked via `bin/rails generate fluence_ci:install`.
  # Discovered by Rails through the conventional path
  # `lib/generators/<namespace>/install_generator.rb`. The Railtie
  # registers it at boot time so consumers don't need any extra wiring.
  #
  # Generates a standalone `bin/fluence-ci` executable that runs the
  # Fluence catalog via {Guardian::Ci::Runner}, side-by-side with
  # Rails 8's native `bin/ci`. No injection into `config/ci.rb` — the
  # two scripts run independently and never duplicate work:
  #
  #   * `bin/ci` runs Rails defaults (rubocop, brakeman, bundler-audit).
  #   * `bin/fluence-ci` runs Fluence-specific checks (ruby_audit,
  #     codequality, docs, tests).
  #
  # Devs chain them as needed (`bin/ci && bin/fluence-ci`) or run
  # whichever is relevant for their iteration.
  class InstallGenerator < Rails::Generators::Base
    # Path of the executable installed in the host Rails app.
    TARGET = 'bin/fluence-ci'

    source_root File.expand_path('templates', __dir__)

    # Copy the standalone Fluence runner script into `bin/fluence-ci`
    # and mark it executable.
    #
    # @return [void]
    # @api public
    def install
      copy_file 'fluence-ci', TARGET
      chmod TARGET, 0o755
    end
  end
end
