# Contributing

Thanks for contributing! Here's how to get started:

1. Open an issue to discuss the proposed change
2. Create a branch from `main`
3. Implement the change
4. Make sure tests and linting pass
5. Open a pull request targeting `main`

---

## Setup

```bash
git clone git@github.com:fluence-eu/fluence-ci-tools.git
cd fluence-ci-tools
bin/setup
```

Requires Ruby 3.2+.

## Development

```bash
bundle exec rspec             # tests
bundle exec rubocop           # linting
bundle exec rubocop -a        # auto-fix linting
```

This gem is mostly a gemspec — its job is to declare a curated set of dev-tool dependencies and ship them to consumers via a single Gemfile entry. There is no application code to write under `lib/` (yet — see Phase 2 in `README.md`). The bulk of contributions therefore land in `fluence-ci-tools.gemspec`.

### Bumping or adding a tool

1. Edit `fluence-ci-tools.gemspec` (`spec.add_dependency` lines).
2. Run `bundle install` to verify the new constraint resolves.
3. Run `gem build fluence-ci-tools.gemspec` to confirm the gem still builds.
4. Update the « What's included » table in `README.md` if pin or tool list changed.
5. Open the PR.

After merge, cut a release via the standard flow (see below). Consumers pick up the new pin with `bundle update fluence-ci-tools`.

### Interactive console

```bash
bin/console
```

---

## Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <description>

[body]

[footer(s)]
```

### Types

| Type | Description |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only changes |
| `style` | Formatting changes (whitespace, commas, etc.) — no logic |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `build` | Changes to build system or dependencies |
| `ci` | CI/CD configuration changes |
| `chore` | Other changes that don't modify source or tests |
| `revert` | Revert a previous commit |

### Scope

Optional — indicates the area affected:

- `chore(gemspec): pin reek to ~> 6.6`
- `docs(readme): add migration example for Rails apps`
- `ci: bump release.yml to ci-workflows@v3`

### Description

- Imperative mood ("add", not "adds" or "added")
- No capital letter at the start
- No period at the end
- Maximum 72 characters

### Body (optional)

- Explains *why* — the diff already shows *what*
- Wrapped at 72 columns
- Separated from the description by a blank line

### Footers (optional)

- `Refs #123` to reference an issue
- `BREAKING CHANGE: <description>` if the change is incompatible
- And/or a `BREAKING CHANGE:` footer in the body

---

## Pull Request Convention

### PR Title

- Same format as commits: `<type>(<scope>): <description>`
- Under 72 characters

### Rules

- One topic per PR — don't mix unrelated changes
- Run `bundle exec rspec` and `bundle exec rubocop` locally before pushing
- Never commit secrets or credentials
- Don't commit `Gemfile.lock` or `*.gem` build artifacts (both gitignored)

---

## Architecture

```
fluence-ci-tools.gemspec                 # The whole point of this gem — 13 add_dependency lines
lib/fluence/ci/tools.rb                  # Module stub
lib/fluence/ci/tools/version.rb          # Semantic version (bumped by release workflow)
cliff.toml                               # git-cliff config for CHANGELOG generation
.github/workflows/                       # See « CI » below
```

There is intentionally no production code under `lib/`. Phase 2 will add a Thor + Railtie generator (CLI + scaffolds) — until then, this gem ships only its gemspec dependencies.

## Code Conventions

- `frozen_string_literal: true` on every Ruby file
- Strings: single quotes (unless interpolation is needed)
- RuboCop: no rule disabling without justification
- Version in `lib/fluence/ci/tools/version.rb` — do not modify unless for an explicit release

## CI

GitHub Actions workflows under `.github/workflows/`, all wired through `fluence-eu/ci-workflows@v2` reusables:

- **rubocop-pr.yml** — runs RuboCop on every PR, posts a sticky comment with offense delta vs `main`
- **rubocop-measure.yml** — establishes the `main` baseline (artifact `rubocop-report`)
- **prepare-release.yml** — manual dispatch (`patch` / `minor` / `major`) opens a release PR
- **release.yml** — on merge of a release PR, creates the tag + GitHub Release
- **publish.yml** — on Release published, pushes the gem to GitHub Packages (also dispatchable manually with a `tag` input for republishing past versions)

The release App secret `RELEASE_APP_PRIVATE_KEY` is forwarded to `release.yml` so the GitHub Release is created with an App-issued token — required for the `publish.yml` chain to fire (see fluence-eu/ci-workflows#12 for the rationale).

---

## AI-Assisted Contributions

When using AI tools (Claude, Copilot, etc.) to generate commits or PRs:

- **Classify first** — determine if the change is critical, major, minor, or trivial
- **Focus on the "why"** — the diff already shows the "what"
- **Skip boilerplate** — don't add empty sections or placeholder text

The person opening the PR takes full responsibility for the code. Before submitting:

- [ ] I have read and understood every line of code in this PR
- [ ] I can explain why each change was made
- [ ] I have tested the changes locally

Do **not** add AI co-author lines (`Co-Authored-By`), "Generated with" footers, or any AI attribution in commits or PR descriptions.
