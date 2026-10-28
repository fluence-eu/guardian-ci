# frozen_string_literal: true

require_relative 'ci/version'

module Guardian
  # Top-level namespace for the meta-gem. The actual catalog lives
  # under `Guardian::Ci::Steps` and is consumed by the rake task
  # / Rails generator scaffolds shipped in `lib/generators/fluence_ci/`.
  module Ci
  end
end

# Auto-wire the install generator into Rails' generator lookup when the
# host application is a Rails app. Pure gems load `Guardian::Ci::Steps`
# and `Guardian::Ci::Runner` directly via `require` from their
# generated rake task — they never see this file path.
require 'guardian/ci/railtie' if defined?(Rails::Railtie)
