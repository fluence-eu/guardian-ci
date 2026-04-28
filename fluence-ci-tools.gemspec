# frozen_string_literal: true

require_relative 'lib/fluence/ci/tools/version'

Gem::Specification.new do |spec|
  spec.name = 'fluence-ci-tools'
  spec.version = Fluence::Ci::Tools::VERSION
  spec.authors = ['Jonathan PHILIPPE']
  spec.email = ['jphilippe@fluence.eu']

  spec.summary = 'Curated dev/CI tooling deps for Fluence Ruby projects'
  spec.description = 'Single Gemfile entry that bundles rubocop, brakeman, ' \
                     'bundler-audit, ruby_audit, reek, flog, flay, yard, ' \
                     'yardstick, simplecov and undercover with the version ' \
                     'pins used by the fluence-eu/ci-workflows reusables.'
  spec.homepage = 'https://github.com/fluence-eu/fluence-ci-tools'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/fluence-eu'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/fluence-eu/fluence-ci-tools'
  spec.metadata['changelog_uri'] = 'https://github.com/fluence-eu/fluence-ci-tools/blob/main/CHANGELOG.md'
  spec.metadata['github_repo'] = 'https://github.com/fluence-eu/fluence-ci-tools'
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

  # Tools shipped to the consumer's :development, :test bundle. Pins
  # match those of the fluence-eu/ci-workflows reusables so the local
  # runs and CI runs hit the same tool versions.
  spec.add_dependency 'brakeman'
  spec.add_dependency 'bundler-audit'
  spec.add_dependency 'flay', '~> 2.14'
  spec.add_dependency 'flog', '~> 4.9'
  spec.add_dependency 'reek', '~> 6.5'
  spec.add_dependency 'rubocop', '~> 1.21'
  spec.add_dependency 'rubocop-rails-omakase'
  spec.add_dependency 'rubocop-rspec'
  spec.add_dependency 'ruby_audit', '~> 3.1'
  spec.add_dependency 'simplecov'
  spec.add_dependency 'undercover'
  spec.add_dependency 'yard', '~> 0.9'
  spec.add_dependency 'yardstick', '~> 0.9'
end
