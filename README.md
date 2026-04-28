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
| `benchmark` | `~> 0.4` | Required by `undercover` on Ruby 3.5+ where it left the stdlib |

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

## Generator and CLI

The gem ships an `fluence-ci` executable plus a Rails generator that scaffolds the local CI orchestration. Both delegate to the same `Fluence::Ci::Tools::Steps` catalog, so the local pre-push run mirrors what the centralised CI workflows execute.

### Installing the local CI scaffold

**Rails app**:
```bash
bin/rails generate fluence_ci:install
bin/fluence-ci                            # Fluence catalog
bin/ci && bin/fluence-ci                  # Or chain with Rails native
```
Writes a standalone executable `bin/fluence-ci` that runs the Fluence catalog via `Fluence::Ci::Tools::Runner`. **Does not touch `config/ci.rb`** — Rails 8's native `bin/ci` keeps running its defaults (rubocop, brakeman, bundler-audit) untouched, and `bin/fluence-ci` adds the Fluence-specific checks (ruby_audit, codequality, docs, tests) side-by-side. No duplication.

**Pure gem**:
```bash
bundle exec fluence-ci install
bundle exec rake fluence_ci:check         # full catalog
bundle exec rake fluence_ci:lint          # single group
```
Writes `lib/tasks/fluence_ci.rake` with one task per step group plus a `fluence_ci:check` aggregate.

### Running checks ad-hoc

```bash
bundle exec fluence-ci check              # full catalog
bundle exec fluence-ci check lint         # single group
bundle exec fluence-ci version
```

### Step groups

| Group | What it runs |
|---|---|
| `lint` | `rubocop` |
| `security` | `brakeman` + `bundler-audit` + `ruby-audit` |
| `codequality` | `reek` + `flog` + `flay` |
| `docs` | `yard` + `yardstick` |
| `tests` | `rspec` (overridable to `bin/rails test`) |

To customise, edit the generated `bin/fluence-ci` (Rails) or `lib/tasks/fluence_ci.rake` (gem). Both files are plain Ruby — instantiate the Runner and call individual groups directly instead of `runner.all`, or pass per-group overrides like `runner.all(codequality: { paths: 'app lib' })`.

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
