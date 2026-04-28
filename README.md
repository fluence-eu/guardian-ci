# fluence-ci-tools

Curated dev/CI tooling deps for Fluence Ruby projects. One Gemfile entry pulls in the full set used by the [`fluence-eu/ci-workflows`](https://github.com/fluence-eu/ci-workflows) reusable workflows, with version pins kept consistent across all consumers.

Solves the « 13 lines of dev gems × 4 repos » bookkeeping problem: when a new tool is added or a pin is bumped, only this gem changes — consumers run `bundle update fluence-ci-tools` and they're aligned.

## Installation

In the consumer's `Gemfile`:

```ruby
source 'https://rubygems.pkg.github.com/fluence-eu' do
  gem 'fluence-ci-tools', require: false, group: %i[development test]
end
```

Then `bundle install`. Authentication to GitHub Packages is the same as for the other Fluence gems (PAT or `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` env var with `read:packages` scope).

## What's included

| Tool | Version pin | Purpose |
|---|---|---|
| `rubocop` | `~> 1.21` | Style + correctness lint |
| `rubocop-rails-omakase` | (latest) | Omakase rules for Rails apps |
| `rubocop-rspec` | (latest) | RSpec-specific cops |
| `brakeman` | (latest) | Rails static security analysis |
| `bundler-audit` | (latest) | Gem CVE scanner |
| `ruby_audit` | `~> 3.1` | Ruby/RubyGems CVE scanner |
| `reek` | `~> 6.5` | Design-smell detector |
| `flog` | `~> 4.9` | Cyclomatic complexity scorer |
| `flay` | `~> 2.14` | Code-duplication scorer |
| `yard` | `~> 0.9` | Documentation generator |
| `yardstick` | `~> 0.9` | Documentation-coverage gate |
| `simplecov` | (latest) | Test-coverage collector |
| `undercover` | (latest) | Coverage delta vs base branch |

Pins follow the same rationale as the centralized workflows: `~> X.Y` keeps the baseline/delta numbers reported by the sticky CI comments stable across runs while still letting patch-level fixes through.

## Mapping to ci-workflows reusables

| Tool | Reusable that runs it |
|---|---|
| rubocop | `ruby-gem-rubocop-{measure,pr}` |
| brakeman, bundler-audit, ruby_audit | `rails-security-{measure,pr}` |
| reek, flog, flay | `ruby-gem-codequality-{measure,pr}` |
| yard, yardstick | `ruby-gem-docs-{measure,pr,deploy}` |
| simplecov, undercover | `ruby-gem-coverage-{measure,pr}` |

## Project type vs. tools

A pure gem like `fluence-gateway-client` won't actually invoke `brakeman` (Rails-specific) but the gem is still installed in its bundle. Disk + install-time cost is small enough not to matter; if it ever does, the tooling can be split into `fluence-ci-tools-gem` / `fluence-ci-tools-rails` sub-gems.

## Generator (Phase 2)

A future release will ship a Thor + Railtie generator that scaffolds project-local binstubs (`bin/rubocop`, `bin/ruby-audit`, …) and a `bin/ci` wrapper that mirrors the CI checks. Track [Phase 2](https://github.com/fluence-eu/fluence-ci-tools/issues) for progress.

## Development

```bash
bin/setup
bundle exec rspec
bundle exec rubocop
```

Releases are cut via the centralized release flow:
1. **Prepare Release PR** workflow (manual dispatch, choose `patch`/`minor`/`major`).
2. Merge the auto-generated release PR.
3. **Release** workflow auto-tags + creates a GitHub Release.
4. **Publish Gem** workflow auto-publishes to GitHub Packages on Release publish.

## License

MIT — see `LICENSE.txt`.
