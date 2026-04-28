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
| `rubocop-rails-omakase` | `~> 1.1` | Omakase rules for Rails apps |
| `rubocop-rspec` | `~> 3.0` | RSpec-specific cops |
| `brakeman` | `~> 8.0` | Rails static security analysis |
| `bundler-audit` | `~> 0.9` | Gem CVE scanner |
| `ruby_audit` | `~> 3.1` | Ruby/RubyGems CVE scanner |
| `reek` | `~> 6.5` | Design-smell detector |
| `flog` | `~> 4.9` | Cyclomatic complexity scorer |
| `flay` | `~> 2.14` | Code-duplication scorer |
| `yard` | `~> 0.9` | Documentation generator |
| `yardstick` | `~> 0.9` | Documentation-coverage gate |
| `simplecov` | `~> 0.22` | Test-coverage collector |
| `undercover` | `~> 0.8` | Coverage delta vs base branch |

Every dependency is pinned at major.minor. Same rationale as the centralised workflows: `~> X.Y` keeps the baseline/delta numbers reported by the sticky CI comments stable across runs while still letting patch-level fixes through. To bump a tool, change it here once and all consumers receive the new version on `bundle update fluence-ci-tools`.

## Migrating from individual gems

If your repo currently lists these tools individually in its `Gemfile` (typical for the existing Fluence gems), you can replace the lot with a single line:

```diff
 group :development, :test do
-  gem 'rubocop', '~> 1.21'
-  gem 'rubocop-rails-omakase'
-  gem 'rubocop-rspec'
-  gem 'brakeman', require: false
-  gem 'bundler-audit', require: false
-  gem 'ruby_audit', require: false
-  gem 'reek', '~> 6.5', require: false
-  gem 'flog', '~> 4.9', require: false
-  gem 'flay', '~> 2.14', require: false
-  gem 'yard', '~> 0.9', require: false
-  gem 'yardstick', '~> 0.9', require: false
-  gem 'simplecov', require: false
-  gem 'undercover', require: false
+  source 'https://rubygems.pkg.github.com/fluence-eu' do
+    gem 'fluence-ci-tools', require: false
+  end
 end
```

After `bundle install`, the resolved versions in `Gemfile.lock` should be the same or newer. If a stricter pin clashes with a constraint your project absolutely needs, the workaround is to keep that one tool inline and let Bundler's resolver take the intersection.

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
