# guardian-ci

Curated dev/CI tooling deps for Ruby projects. One Gemfile entry pulls in the full set used by the [`fluence-eu/ci-workflows`](https://github.com/fluence-eu/ci-workflows) reusable workflows, with version pins kept consistent across all consumers.

Solves the « 13 lines of dev gems × 4 repos » bookkeeping problem: when a new tool is added or a pin is bumped, only this gem changes — consumers run `bundle update guardian-ci` and they're aligned.

## Installation

In the consumer's `Gemfile`:

```ruby
source 'https://rubygems.pkg.github.com/fluence-eu' do
  gem 'guardian-ci', require: false, group: %i[development test]
end
```

Then `bundle install`. Authentication to GitHub Packages is the same as for the other Fluence gems (PAT or `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` env var with `read:packages` scope).

### Configure SimpleCov in the consumer's spec_helper

Coverage is collected as a SimpleCov side-effect during `bundle exec guardian-ci tests`, so the consumer must wire SimpleCov before any application or library code is loaded. Without this snippet, the `tests` step still runs green but no `coverage/coverage.json` is produced and the `ruby-gem-coverage-{measure,pr}` reusables have nothing to upload or diff.

**Where to put it.** Add the block at the very top of `spec/spec_helper.rb`, **before any other `require`**. The default RSpec setup includes `--require spec_helper` in `.rspec`, so `spec_helper.rb` is loaded first for every test process — Rails apps included, where `rails_helper.rb` itself re-requires `spec_helper.rb`. Putting SimpleCov in `rails_helper.rb` instead would miss any spec that only requires `spec_helper` (e.g. fast non-Rails specs in a Rails app), resulting in partial coverage.

**Rails app** — use the built-in `'rails'` profile, which filters `/config/`, `/db/`, `/spec/`, etc. automatically:

```ruby
require 'simplecov'
require 'undercover/simplecov_formatter'

SimpleCov.start 'rails' do
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Undercover
    ]
  )
end
```

**Pure gem** — use the default profile and filter the spec tree explicitly:

```ruby
require 'simplecov'
require 'undercover/simplecov_formatter'

SimpleCov.start do
  add_filter '/spec/'
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Undercover
    ]
  )
end
```

The `Undercover` formatter writes `coverage/coverage.json` — the file the centralised coverage workflows pick up. The `HTMLFormatter` writes `coverage/index.html` for local browsing. Add `coverage/` to `.gitignore` if not already present.

Repos that want to enforce an absolute threshold (rather than only PR-diff coverage) can extend the block with `minimum_coverage` / `minimum_coverage_by_file` — see [SimpleCov's docs](https://github.com/simplecov-ruby/simplecov#minimum-coverage).

### Configure yard (gems running the docs workflows)

`bundle exec guardian-ci docs` invokes `yard` against the consumer's source tree; without a `.yardopts` at the repo root, yard falls back to its global defaults (no markup parsing, no api filtering, output under `./doc` regardless of intent). Add a minimal `.yardopts` so the parse step and the HTML site produced by `guardian-ci docs --build` (consumed by `ruby-gem-docs-deploy.yml`) are both predictable:

```
--markup markdown
--no-private
--hide-api private
--output-dir doc
--readme README.md
lib/**/*.rb
-
CHANGELOG.md
CONTRIBUTING.md
LICENSE.txt
```

`--no-private` + `--hide-api private` mean only methods tagged `@api public` end up in the rendered docs — pairs with the `@api` enforcement in `.yardstick.yml` below. Adjust the source glob (`lib/**/*.rb`) if your gem ships code under a different path.

Rails apps that don't consume the `ruby-gem-docs-*` reusables can skip this file.

### Configure yardstick threshold (gems running the docs workflows)

`guardian-ci docs --report` runs `Guardian::Ci::YardstickRunner`, which reads `.yardstick.yml` at the repo root to know what rules to enforce and what coverage threshold to gate on. Without it, the docs measure job posts no meaningful report (and the threshold check is a no-op). Minimal config — adjust `threshold` to your target percentage:

```yaml
---
threshold: 100
require_exact_threshold: false
verbose: true
path:
  - 'lib/**/*.rb'
rules:
  ApiTag::Presence:
    enabled: true
  ApiTag::Inclusion:
    enabled: true
  ReturnTag:
    enabled: true
  Summary::Presence:
    enabled: true
```

See [`guardian-ci`'s own `.yardstick.yml`](https://github.com/fluence-eu/guardian-ci/blob/main/.yardstick.yml) for the full set of toggles (`Summary::Length`, `Summary::Delimiter`, `ExampleTag`, etc. are all off by default and can be enabled per-repo).

Rails apps that don't consume the `ruby-gem-docs-*` reusables can skip this file.

### Configure git-cliff (consumers using the release automation)

The `app-prepare-release.yml` reusable runs [`orhun/git-cliff-action`](https://github.com/orhun/git-cliff-action) to generate `CHANGELOG.md` entries from conventional commits. It expects a `cliff.toml` at the repo root; without one, the action fails or produces empty changelog sections.

Copy [`guardian-ci/cliff.toml`](https://github.com/fluence-eu/guardian-ci/blob/main/cliff.toml) as a starting point and adjust the `commit_parsers` section for your project (e.g. add repo-specific `{ message = "^chore: bump version", skip = true }` rules for commits you don't want to surface). The header / body templates can usually be kept verbatim — they emit the Keep-a-Changelog format expected by the release workflow.

Consumers that don't use `prepare-release.yml` / `release.yml` (no release automation) can skip this file.

## What's included

| Tool | Version pin | Purpose |
|---|---|---|
| `rubocop` | `~> 1.86` | Style + correctness lint |
| `rubocop-rails-omakase` | `~> 1.1` | Omakase rules for Rails apps |
| `rubocop-rspec` | `~> 3.10` | RSpec-specific cops |
| `brakeman` | `~> 8.1` | Rails static security analysis |
| `bundler-audit` | `~> 0.9` | Gem CVE scanner |
| `ruby_audit` | `~> 3.1` | Ruby/RubyGems CVE scanner |
| `reek` | `~> 6.6` | Design-smell detector |
| `flog` | `~> 4.9` | Cyclomatic complexity scorer |
| `flay` | `~> 2.14` | Code-duplication scorer |
| `yard` | `~> 0.9` | Documentation generator |
| `yardstick` | `~> 0.9` | Documentation-coverage gate |
| `simplecov` | `~> 0.22` | Test-coverage collector |
| `undercover` | `~> 0.8` | Coverage delta vs base branch |
| `benchmark` | `~> 0.4` | Required by `undercover` on Ruby 3.5+ where it left the stdlib |

Every dependency is pinned at major.minor. Same rationale as the centralised workflows: `~> X.Y` keeps the baseline/delta numbers reported by the sticky CI comments stable across runs while still letting patch-level fixes through. To bump a tool, change it here once and all consumers receive the new version on `bundle update guardian-ci`.

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
+    gem 'guardian-ci', require: false
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

A pure gem like `fluence-gateway-client` won't actually invoke `brakeman` (Rails-specific) but the gem is still installed in its bundle. Disk + install-time cost is small enough not to matter; if it ever does, the tooling can be split into `guardian-ci-gem` / `guardian-ci-rails` sub-gems.

## Generator and CLI

The gem ships a `guardian-ci` executable plus a Rails generator that scaffolds the local CI orchestration. Both delegate to the same `Guardian::Ci::Steps` catalog, so the local pre-push run mirrors what the centralised CI workflows execute.

### Installing the local CI scaffold

**Rails app**:
```bash
bin/rails generate guardian_ci:install
bin/guardian-ci                           # full catalog
bin/ci && bin/guardian-ci                 # Or chain with Rails native
```
Writes a standalone executable `bin/guardian-ci` that runs the catalog via `Guardian::Ci::Runner`. **Does not touch `config/ci.rb`** — Rails 8's native `bin/ci` keeps running its defaults (rubocop, brakeman, bundler-audit) untouched, and `bin/guardian-ci` adds the extra checks (ruby_audit, codequality, docs, tests) side-by-side. No duplication.

**Pure gem**:
```bash
bundle exec guardian-ci install
bundle exec rake guardian_ci:check        # full catalog
bundle exec rake guardian_ci:lint         # single group
```
Writes `lib/tasks/guardian_ci.rake` with one task per step group plus a `guardian_ci:check` aggregate.

### Running checks ad-hoc

```bash
bundle exec guardian-ci all               # full catalog
bundle exec guardian-ci lint              # single group
bundle exec guardian-ci version
```

Each group command (and `all`) accepts `--report` to switch from human-readable console output to machine-readable artefacts under standardised paths — the same files the centralised [`fluence-eu/ci-workflows`](https://github.com/fluence-eu/ci-workflows) reusables consume:

```bash
bundle exec guardian-ci lint --report         # tmp/guardian-report/rubocop.json
bundle exec guardian-ci security --report     # tmp/guardian-report/{brakeman.json,audit.txt,ruby_audit.txt}
bundle exec guardian-ci codequality --report  # tmp/guardian-report/{reek.json,flog.txt,flay.txt}
bundle exec guardian-ci docs --report         # doc/yardstick_report.txt (in-process measure + threshold check)
bundle exec guardian-ci all --report          # propagates --report to every group that accepts it
```

`docs` additionally exposes `--build` to produce the HTML site under `doc/` (used by the centralised `ruby-gem-docs-deploy.yml` workflow):

```bash
bundle exec guardian-ci docs --build          # bundle exec yard doc → doc/index.html
```

Coverage for `tests` is captured automatically by SimpleCov when configured in the consumer's `spec_helper`, so `tests` does not take `--report`.

### Step groups

| Group | Default mode | `--report` mode | Other flags |
|---|---|---|---|
| `lint` | `rubocop` | `rubocop --format json --out tmp/guardian-report/rubocop.json` | — |
| `security` | `brakeman` + `bundler-audit` + `ruby-audit` | same trio, machine-readable outputs under `tmp/guardian-report/` | — |
| `codequality` | `reek` + `flog` + `flay` | same trio, JSON / text outputs under `tmp/guardian-report/` | `--paths "app lib"` |
| `docs` | `yard doc --no-output --no-stats` (parse smoke test) | in-process `Guardian::Ci::YardstickRunner` — reads `.yardstick.yml`, writes `doc/yardstick_report.txt`, exits 1 below threshold (no consumer Rakefile dependency) | `--build` → `yard doc` (HTML site under `doc/`) |
| `tests` | `rspec` (overridable to `bin/rails test`) | n/a — coverage is produced as a SimpleCov side effect | `--command "bundle exec rake test"` |

To customise, edit the generated `bin/guardian-ci` (Rails) or `lib/tasks/guardian_ci.rake` (gem). Both files are plain Ruby — instantiate the Runner and call individual groups directly instead of `runner.all`, or pass per-group overrides like `runner.all(codequality: { paths: 'app lib' })`.

#### Replacing custom Rakefile boilerplate

Now that the `docs` group covers all three rake-task responsibilities (`--report` runs the threshold check that was `rake doc:verify`, `--build` produces the HTML site that was `rake doc:build`, and the default mode does the parse smoke test), consumers can drop the entire `namespace :doc` block from their Rakefile. The centralised `ruby-gem-docs-{measure,deploy}` workflows invoke the matching `guardian-ci docs --{report,build}` commands directly.

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
