# frozen_string_literal: true

require 'simplecov'
require 'undercover/simplecov_formatter'

SimpleCov.start do
  add_filter '/spec/'
  # Bumped by the release workflow on every release, which makes
  # undercover flag it as "changed and uncovered" on every PR whose
  # coverage baseline predates the release commit. Contains only
  # the VERSION constant — nothing to test.
  add_filter '/lib/fluence/ci/tools/version.rb'
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Undercover
    ]
  )
end

require 'fluence/ci/tools'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
