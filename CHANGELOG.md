# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Sprint start** — when an iteration becomes active, promote cards pre-parked in it (e.g. `Backlog → Ready`). Only cards parked *before* the sprint started are touched, so a deliberate mid-sprint move back is respected.
- **Auto-assign by label** — a CODEOWNERS-style `label → owner` map assigns unassigned tickets in a given status. Opt-in, case-insensitive matching, and it never overrides an existing assignee.
- **Sprint runway warning** — GitHub never auto-creates iterations, so Boardly warns (job summary + workflow annotation) when too few future sprints are planned, before rollover and sprint-start run dry.
- **Sprint label hygiene on rollover** — `addSprintLabel` tags each rolled card with the new sprint's label (creating it once per repo if missing), and `removeLabels` strips stale markers like `pulled-in` as the card carries over.
- **`reviewers` notify token for stale nudges** — resolves to the *pending* review requests on the card's PR (or the PR that closes the issue), falling back to the assignees when no review is outstanding. Works bare or mixed into a `notify:` list alongside literal logins.
- New `only:` values for the added features: `sprint-start`, `sprint-runway`, `auto-assign`.

### Changed
- **The Ruby action now ships from the repo root.** `action.yml` and the `Dockerfile` moved out of `ruby/`, so the documented `uses: cdrrazan/Boardly-ruby@v1` resolves to the Ruby container action. That reference previously resolved to the root *TypeScript* manifest — the parity reference, not the port this repo exists for. Ruby sources still live in `ruby/`; the image now builds from the repo root with `ruby/`-prefixed paths.

### Documentation
- Three new use-case recipes — [14 · Sprint start](./docs/use-cases/14-sprint-start.md), [15 · Auto-assign](./docs/use-cases/15-auto-assign.md), [16 · Sprint runway](./docs/use-cases/16-sprint-runway.md) — bringing the cookbook to 16.
- A worked end-to-end sample under [`examples/`](./examples) — a full config plus the workflow that runs it, with Slack and email enabled.
- Marketing site refreshed: eleven automations, the reviewer-aware nudge story, and an animated config walkthrough.

### Tooling
- **CI** — a `.github/` that runs the Minitest suite, builds *and boots* the action image, keeps the TypeScript reference in sync, gates pull requests behind an aggregate "PR ready to merge" check, lints PR titles, and moves the `v1` alias on release. Plus issue/PR templates and funding links.
- Minitest suite grown to 43 tests, covering the new features and their dry-run paths.
- **Dependency refresh** — `Gemfile.lock` picks up patch/minor updates to the `mail` gem's transitive deps (`net-smtp` 0.5.2, `net-protocol` 0.4.0, `net-imap` 0.6.8, `date` 3.6.0) and now records gem checksums.
- **CI runtime refresh** — workflows move to `actions/checkout@v5` and `actions/setup-node@v5` (Node 24 action runtime), and the TypeScript reference job runs on Node 22 LTS now that Node 20 is end-of-life.
- **Ruby 3.4 runtime** — the action image now builds from `ruby:3.4-slim` (was `ruby:3.3-slim`), and CI tests on Ruby 3.4 to match. The supported floor stays Ruby ≥ 3.1.

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
