# frozen_string_literal: true

# Conventional entry point Bundler resolves when a consumer declares
# `gem 'guardian-ci'` without `require: false`. Delegates to the
# namespaced module file under `guardian/ci.rb`. The hyphenated
# filename is required by the convention and excluded from
# `Naming/FileName` in `.rubocop.yml`.
require 'guardian/ci'
