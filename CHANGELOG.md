# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_Nothing yet._

## [1.0.0] — 2026-07-09

First stable release of the **Ruby edition**: a full-Ruby port of [Boardly](https://github.com/cdrrazan/Boardly), shipped as a Docker container action for GitHub Projects (v2). Behaviour and config are identical to the TypeScript edition.

### Features
- **Sprint rollover** — carry unfinished items into the next iteration.
- **Stale-card nudges** — @-mention owners when a card sits in a status too long (de-duped).
- **Sub-issue gating + roll-up** — block "Done" while sub-issues remain open; write completion % into a progress field.
- **Sprint digest** — completed vs carried-over counts and velocity at iteration end.
- **Daily standup** — what moved in the last _N_ hours, grouped by assignee.
- **Priority auto-sort** — reorder the board by a configured priority order.
- **Slack & email notifications** — also deliver digests, standups, and stale alerts to a Slack Incoming Webhook and/or over SMTP email. Secrets are referenced by environment-variable name.
- **Audit trail** — every action written to the Actions job summary, plus a `dry-run` mode.
- YAML configuration with schema validation, an example config, and a consumer workflow.

### Documentation
- README, 13 use-case recipes, architecture, contributing, security, code of conduct, and roadmap.

### Tooling
- **Docker container action** — packaged as a `ruby:3.3` image (`ruby/Dockerfile` + `ruby/action.yml`); no `dist/` bundle to commit.
- **Minitest suite** of 27 unit tests covering feature logic, normalization, notifications, config, and util helpers — run with `bundle exec rake test`.
- **CI** — runs the Ruby test suite and builds the action image on pull requests.

[Unreleased]: https://github.com/cdrrazan/boardly-ruby/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/cdrrazan/boardly-ruby/releases/tag/v1.0.0
