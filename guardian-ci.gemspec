# frozen_string_literal: true

require_relative 'lib/guardian/ci/version'

Gem::Specification.new do |spec|
  spec.name = 'guardian-ci'
  spec.version = Guardian::Ci::VERSION
  spec.authors = ['Jonathan PHILIPPE']
  spec.email = ['jphilippe@fluence.eu']

  spec.summary = 'Curated dev/CI tooling deps for Fluence Ruby projects'
  spec.description = 'Single Gemfile entry that bundles rubocop, brakeman, ' \
                     'bundler-audit, ruby_audit, reek, flog, flay, yard, ' \
                     'yardstick, simplecov and undercover with the version ' \
                     'pins used by the fluence-eu/ci-workflows reusables.'
  spec.homepage = 'https://github.com/fluence-eu/guardian-ci'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/fluence-eu'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/fluence-eu/guardian-ci'
  spec.metadata['changelog_uri'] = 'https://github.com/fluence-eu/guardian-ci/blob/main/CHANGELOG.md'
  spec.metadata['github_repo'] = 'https://github.com/fluence-eu/guardian-ci'
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml sig/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Tools shipped to the consumer's :development, :test bundle. Every
  # tool is pinned at major.minor to keep the baseline/delta numbers
  # the centralised CI workflows surface stable across runs — same
  # rationale as rubocop's ~> 1.86 pin.
  # Required by undercover on Ruby 3.5+ where benchmark left the stdlib.
  # Declared here so consumers don't have to add it themselves.
  spec.add_dependency 'benchmark', '~> 0.4'
  spec.add_dependency 'brakeman', '~> 8.1'
  spec.add_dependency 'bundler-audit', '~> 0.9'
  spec.add_dependency 'flay', '~> 2.14'
  spec.add_dependency 'flog', '~> 4.9'
  spec.add_dependency 'reek', '~> 6.6'
  spec.add_dependency 'rubocop', '~> 1.86'
  spec.add_dependency 'rubocop-rails-omakase', '~> 1.1'
  spec.add_dependency 'rubocop-rspec', '~> 3.10'
  spec.add_dependency 'ruby_audit', '~> 3.1'
  spec.add_dependency 'simplecov', '~> 0.22'
  # Powers the install generator (Thor::Group) and the `fluence-ci`
  # CLI exe. Kept loose at major because Thor's surface API barely
  # changes — we use only `Thor`, `Thor::Group`, `Thor::Actions`.
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'undercover', '~> 0.8'
  spec.add_dependency 'yard', '~> 0.9'
  spec.add_dependency 'yardstick', '~> 0.9'
end
