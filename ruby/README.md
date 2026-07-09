# Boardly (Ruby edition) 🤖💎

A **full-Ruby** port of [Boardly](https://github.com/cdrrazan/Boardly) — a config-driven GitHub Action that automates **GitHub Projects (v2)**: sprint rollover, stale-card nudges, sub-issue gating, digests, standups, priority sorting, and Slack/email notifications, all from one YAML file.

Because GitHub Actions has no native Ruby runtime, this ships as a **Docker container action** (a `ruby:3.3` image). Behaviour and config are identical to the TypeScript version, which is the main project — both editions are actively maintained.

> This folder is self-contained: copy its contents to the root of a new repository to publish it as its own action. In this repository it is published as [`cdrrazan/boardly-ruby`](https://github.com/cdrrazan/boardly-ruby).

## 🔗 Related repositories

Boardly is maintained in two editions that share the same config and behaviour:

| Repo | Edition | Runtime |
|------|---------|---------|
| ⬆️ **[cdrrazan/Boardly](https://github.com/cdrrazan/Boardly)** — the **main project** | TypeScript | `node20` bundled action |
| 💎 **[cdrrazan/boardly-ruby](https://github.com/cdrrazan/boardly-ruby)** — this repo | Ruby | Docker container action |

Feature design and the roadmap are driven in the main project; this Ruby port is kept in parity and maintained alongside it. Issues and PRs specific to the Ruby edition are welcome here — anything cross-cutting is best raised upstream in [cdrrazan/Boardly](https://github.com/cdrrazan/Boardly).

## Features

| Feature | What it does |
|---------|--------------|
| Sprint rollover | Move unfinished items into the next iteration when a sprint ends. |
| Stale-card nudges | @-mention owners when a card sits in a status too long (de-duped). |
| Sub-issue gating + roll-up | Block "Done" while sub-issues are open; write completion % to a field. |
| Sprint digest | Completed vs carried-over + velocity at iteration end. |
| Daily standup | What moved in the last N hours, grouped by assignee. |
| Priority auto-sort | Reorder the board by a configured priority order. |
| Slack & email | Deliver digests/standups/alerts to Slack and inboxes. |
| Audit trail | Every action written to the job summary; `dry-run` mode. |

## Usage

```yaml
# .github/workflows/boardly.yml
on:
  schedule: [{ cron: "0 8 * * 1-5" }]
permissions:
  contents: read
  issues: write
jobs:
  automate:
    runs-on: ubuntu-latest   # Docker actions require a Linux runner
    steps:
      - uses: cdrrazan/boardly-ruby@v1
        with:
          token: ${{ secrets.PROJECT_AUTOMATION_TOKEN }}
          config-path: .github/project-automation.yml
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

Config lives in `.github/project-automation.yml` — see [`project-automation.example.yml`](./project-automation.example.yml). It is byte-for-byte compatible with the TypeScript edition.

### Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `token` | — _(required)_ | Token with `project` + `issues` access. |
| `config-path` | `.github/project-automation.yml` | Path to the config file. |
| `only` | `""` | Run one feature: `rollover`, `stale-nudge`, `sub-issue-gate`, `digest`, `standup`, `priority-sort`. |
| `dry-run` | `false` | Log intended actions without making changes. |

**Output:** `actions-count`.

## Architecture

```
lib/
  boardly.rb              # entry point: inputs → config → fetch → dispatch → audit
  boardly/
    config.rb             # YAML load + validation (defaults match the TS zod schema)
    model.rb              # normalized structs (ProjectGraph, ProjectItem, …)
    github/               # GraphQL queries, Net::HTTP client, normalization
    features/             # one module per feature
    notify/               # Slack + email channels + Notifier
    util/                 # dates + field accessors
    audit.rb              # job-summary audit trail
bin/boardly               # container entrypoint
test/                     # Minitest specs + fake client/channel (27 tests)
```

**Stack:** Ruby 3.3, standard library for HTTP/JSON/YAML, `mail` gem for SMTP, Minitest for tests. No web framework, minimal dependencies.

## Development

```bash
cd ruby
bundle install
bundle exec rake test          # or: ruby -Ilib -Itest test/features_test.rb
docker build -t boardly-rb .   # build the action image
```

## Notes vs. the TypeScript edition

- **Runtime:** Docker container action (Linux runners only) instead of a bundled `node20` action. Slightly slower cold start; no `dist/` to commit.
- **HTTP:** `Net::HTTP` (stdlib) for both GraphQL and REST — no Octokit dependency.
- **Config validation:** hand-written to mirror the zod schema (same field names, same defaults, same error style).

See the [main project](https://github.com/cdrrazan/Boardly) for the TypeScript edition.

## License

[MIT](./LICENSE) — same as the [main Boardly project](https://github.com/cdrrazan/Boardly).
