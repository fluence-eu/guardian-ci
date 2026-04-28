# frozen_string_literal: true

# Run everything with `bundle exec rake fluence_ci:check`, or invoke an
# individual group like `bundle exec rake fluence_ci:lint`.
#
# `Fluence::Ci::Tools::Runner` includes `Fluence::Ci::Tools::Steps`, so
# the runner instance exposes `lint`, `security`, `codequality`, `docs`,
# `tests` and the aggregate `all`. New step groups added to the gem
# appear in `all` automatically — no edit to this file required.

require 'fluence/ci/tools/runner'

namespace :fluence_ci do
  desc 'Run all Fluence CI checks (whole catalog)'
  task :check do
    runner = Fluence::Ci::Tools::Runner.new
    runner.all
    runner.report!
  end

  Fluence::Ci::Tools::Steps.instance_methods(false).reject { |m| m == :all }.each do |group|
    desc "Run only the #{group} step group"
    task group do
      runner = Fluence::Ci::Tools::Runner.new
      runner.public_send(group)
      runner.report!
    end
  end
end
