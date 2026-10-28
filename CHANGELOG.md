# Changelog

All notable changes to this project will be documented in this file.
## [2026.10.28.182143] - 2026-10-28

### Build

- build(gemspec): drop allowed_push_host

### CI

- ci: add the Claude PR review workflow
- ci: release dated versions
- ci: bump workflows to ci-workflows@v7
- ci: publish releases to rubygems.org

### Other

- chore(gemspec): move the Thor comment above the thor dependency

### Refactored

- refactor: drop Fluence branding from the tool's own wording
- refactor!: write report-mode artefacts under tmp/guardian-report
- refactor(cli)!: rename fluence-ci executable and generator to guardian-ci
- refactor!: rename gem to guardian-ci under Guardian::Ci

## [0.6.1] - 2026-10-05

### Build

- build: raise brakeman, reek, rubocop and rubocop-rspec floors
- build!: require Ruby >= 3.3

### CI

- ci: bump actions/checkout to v7
- ci: deploy the YARD docs to GitHub Pages
- ci: forward the release bot key on codequality-pr
- ci: keep codequality-pr without the release bot key
- ci: forward the release bot key on codequality-pr
- ci: migrate to ci-workflows@v6 config file
- ci(workflows): bump ci-workflows pins from @v2 to @v5 + drop github.actor
- ci: bump ci-workflows to @v5 (multi-gem-capable reusables)

### Documentation

- docs: align the YARD config with the gems family
- docs: refresh CONTRIBUTING.md after ci-workflows@v5 migration
- docs(readme): split SimpleCov snippet into rails/gem variants
- docs(readme): document .yardopts, .yardstick.yml and cliff.toml
- docs(readme): document SimpleCov spec_helper snippet

### Other

- chore: migrate to ci-workflows v4 (FLUENCE_*_BOT_* naming)

## [0.6.0] - 2026-04-29

### Added

- feat(docs): add --build mode for HTML site generation

### Refactored

- refactor(cli): extract dynamic command registration into class methods

### Style

- style(cli): use if/else block instead of multi-line ternary

## [0.5.1] - 2026-04-28

### Added

- feat(cli): forward all Steps kwargs as Thor options, not just --report

### Documentation

- docs(readme): document v0.5 CLI surface (--report, per-group commands)

## [0.5.0] - 2026-04-28

### Added

- feat(steps): align codequality + docs report mode with ci-workflows v3

### CI

- ci(main): gate matrix steps with if:, not job-level

### Refactored

- refactor(yardstick_runner): drop unused parity helpers

### Tests

- test(yardstick_runner): cover happy path, threshold failure, missing yml

## [0.4.0] - 2026-04-28

### Added

- feat(steps,cli): expose per-group commands with --report flag
- feat(generator): bin/fluence-ci supports per-group sub-commands
- feat(generator): drop config/ci.rb inject in favor of bin/fluence-ci

### CI

- ci: skip rubocop and main matrix on release PRs

## [0.3.0] - 2026-04-28

### Added

- feat: ship install generator, fluence-ci CLI, and Steps/Runner catalog (Phase 2)

### CI

- ci: activate consumer-style quality gates and 100% YARD coverage

### Tests

- test: add multi-Rails matrix and integration specs for CLI + generator
- test: configure SimpleCov + Undercover formatter in spec_helper

## [0.2.0] - 2026-04-28

### Build

- build: add benchmark runtime dep for undercover on Ruby 3.5+

### CI

- ci: grant `packages: read` on @v2 wrappers (fix startup_failure)
- ci: add workflow_dispatch to publish.yml for manual republish
- ci: forward RELEASE_APP_PRIVATE_KEY to release.yml

### Documentation

- docs: refresh README pins + add CONTRIBUTING.md

## [0.1.1] - 2026-04-28

### Other

- chore: add cliff.toml for changelog generation
- chore: pin remaining tool versions

### Style

- style: convert string literals from double to single quotes

## [0.1.0] - 2026-04-28

### Other

- chore: initial commit

