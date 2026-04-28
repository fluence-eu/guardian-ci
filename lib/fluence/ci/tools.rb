# frozen_string_literal: true

require_relative 'tools/version'

module Fluence
  module Ci
    # Top-level namespace for the meta-gem. The actual catalog lives
    # under `Fluence::Ci::Tools::Steps` and is consumed by the rake task
    # / Rails generator scaffolds shipped in `lib/generators/fluence_ci/`.
    module Tools
    end
  end
end

# Auto-wire the install generator into Rails' generator lookup when the
# host application is a Rails app. Pure gems load `Fluence::Ci::Tools::Steps`
# and `Fluence::Ci::Tools::Runner` directly via `require` from their
# generated rake task — they never see this file path.
require 'fluence/ci/tools/railtie' if defined?(Rails::Railtie)
