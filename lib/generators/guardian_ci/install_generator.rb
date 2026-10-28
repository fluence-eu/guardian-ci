# frozen_string_literal: true

require 'rails/generators/base'

module GuardianCi
  # Rails generator invoked via `bin/rails generate guardian_ci:install`.
  # Discovered by Rails through the conventional path
  # `lib/generators/<namespace>/install_generator.rb`. The Railtie
  # registers it at boot time so consumers don't need any extra wiring.
  #
  # Generates a standalone `bin/guardian-ci` executable that runs the
  # catalog via {Guardian::Ci::Runner}, side-by-side with
  # Rails 8's native `bin/ci`. No injection into `config/ci.rb` — the
  # two scripts run independently and never duplicate work:
  #
  #   * `bin/ci` runs Rails defaults (rubocop, brakeman, bundler-audit).
  #   * `bin/guardian-ci` runs the extra checks (ruby_audit,
  #     codequality, docs, tests).
  #
  # Devs chain them as needed (`bin/ci && bin/guardian-ci`) or run
  # whichever is relevant for their iteration.
  class InstallGenerator < Rails::Generators::Base
    # Path of the executable installed in the host Rails app.
    TARGET = 'bin/guardian-ci'

    source_root File.expand_path('templates', __dir__)

    # Copy the standalone runner script into `bin/guardian-ci`
    # and mark it executable.
    #
    # @return [void]
    # @api public
    def install
      copy_file 'guardian-ci', TARGET
      chmod TARGET, 0o755
    end
  end
end
