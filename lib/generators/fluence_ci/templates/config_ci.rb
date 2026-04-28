# frozen_string_literal: true

# Run using bin/ci.
#
# `Fluence::Ci::Tools::Steps` is a mixin: extending it inside the
# `CI.run do` block exposes `lint`, `security`, `codequality`, `docs`,
# `tests` and the aggregate `all`. New step groups added to the gem
# appear in `all` automatically — no edit to this file required.
#
# Defaults auto-detect `app/` (Rails) and `spec/spec_helper.rb` /
# `test/test_helper.rb`. Override only when your project deviates:
#   all(codequality: { paths: 'custom' }, tests: { command: 'my-runner' })

require 'fluence/ci/tools/steps'

CI.run do
  extend Fluence::Ci::Tools::Steps

  step 'Setup', 'bin/setup --skip-server'

  all
end
