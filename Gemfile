# frozen_string_literal: true

source 'https://rubygems.org'

# All dev/CI tooling lives in the gemspec — the gem is a meta-gem
# that pulls in rubocop, brakeman, bundler-audit, ruby_audit, reek,
# flog, flay, yard, yardstick, simplecov and undercover for downstream
# consumers, and dogfoods them on its own CI.
gemspec

gem 'irb'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.0'

# Generates per-Rails-version Gemfiles under gemfiles/ so CI can run
# the generator integration tests against multiple Rails versions.
# See `Appraisals`.
gem 'appraisal', require: false

# Required by the install generator integration tests
# (`spec/generators/fluence_ci/install_generator_spec.rb`) which load
# `rails/generators/base`. The root Gemfile uses the latest stable Rails
# with no version lock so Appraisal-generated gemfiles can override
# without conflict.
gem 'rails'
