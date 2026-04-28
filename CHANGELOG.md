# Changelog

All notable changes to this project will be documented in this file.
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

