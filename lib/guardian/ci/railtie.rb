# frozen_string_literal: true

require 'rails/railtie'

module Guardian
  module Ci
    # Wires the install generator into Rails' generator lookup so
    # consumers can run `bin/rails generate fluence_ci:install`. Loaded
    # automatically by `lib/guardian/ci.rb` when `Rails::Railtie`
    # is in scope; pure gems never see this file.
    class Railtie < ::Rails::Railtie
      generators do
        require 'generators/fluence_ci/install_generator'
      end
    end
  end
end
