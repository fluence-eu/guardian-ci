# frozen_string_literal: true

# Run everything with `bundle exec rake fluence_ci:check`, or invoke an
# individual group like `bundle exec rake fluence_ci:lint`.
#
# `Guardian::Ci::Runner` includes `Guardian::Ci::Steps`, so
# the runner instance exposes `lint`, `security`, `codequality`, `docs`,
# `tests` and the aggregate `all`. New step groups added to the gem
# appear in `all` automatically — no edit to this file required.

require 'guardian/ci/runner'

namespace :fluence_ci do
  desc 'Run all Fluence CI checks (whole catalog)'
  task :check do
    runner = Guardian::Ci::Runner.new
    runner.all
    runner.report!
  end

  Guardian::Ci::Steps.instance_methods(false).reject { |m| m == :all }.each do |group|
    desc "Run only the #{group} step group"
    task group do
      runner = Guardian::Ci::Runner.new
      runner.public_send(group)
      runner.report!
    end
  end
end
