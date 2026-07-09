# Tech Stack

This repository is the **Ruby edition** of Boardly — the official Ruby port of the main project, [**cdrrazan/Boardly**](https://github.com/cdrrazan/Boardly) (TypeScript). It packages the GitHub Action as a Docker container and is intentionally dependency-light. The marketing site (`web/`) is shared with the main project.

> Looking for the TypeScript stack? See the [main repo's TECH_STACK](https://github.com/cdrrazan/Boardly/blob/main/TECH_STACK.md).

## 🤖 The Action (Ruby)

| Layer | Choice | Notes |
|-------|--------|-------|
| Language | **Ruby 3.x** (`frozen_string_literal`) | Targets Ruby ≥ 3.1; the action image pins `ruby:3.3` |
| Runtime | **Docker container action** | Ships as a Docker action (`ruby/action.yml` → `ruby/Dockerfile`); Linux runners only |
| GitHub API | **`Net::HTTP`** (stdlib) | Projects v2 via GraphQL; issues/comments via REST — no Octokit dependency |
| Action I/O | Environment variables + job-summary file | Inputs mapped to `BOARDLY_*` env vars; audit trail written to `$GITHUB_STEP_SUMMARY` |
| Config | **YAML** (stdlib `yaml`) with a hand-written validator | One `.github/project-automation.yml`, mirroring the TS zod schema |
| Email | **`mail`** gem | SMTP delivery for digests/standups/alerts |
| Slack | **`Net::HTTP`** | Incoming Webhook POST |
| Tests | **Minitest** | 27 unit tests against a fake client/channel |
| Task runner | **Rake** | `rake test` |

**Source layout** (in [`ruby/`](./ruby))

```
lib/
  boardly.rb              # entry point: inputs → config → fetch → dispatch → audit
  boardly/
    config.rb             # YAML load + validation (defaults match the TS zod schema)
    model.rb              # normalized structs (ProjectGraph, ProjectItem, …)
    github/               # GraphQL queries, Net::HTTP client, normalization
    features/             # one module per feature (rollover, stale_nudge, …)
    notify/               # Slack + email channels + Notifier
    util/                 # dates + field accessors
    audit.rb              # job-summary audit trail
bin/boardly               # container entrypoint
test/                     # Minitest specs + fake client/channel (27 tests)
```

See [ARCHITECTURE.md](./docs/ARCHITECTURE.md) for how the pieces fit together.

## 🌐 The website (`web/`)

| Layer | Choice |
|-------|--------|
| Stack | Plain **HTML + CSS + vanilla JS** — no framework, **no build step** |
| Fonts | **Google Sans** (Google Fonts) with Roboto/system fallback |
| Hosting | **Cloudflare Pages** (static, Git-integration deploy) |
| Security | CSP + security headers via `_headers` |
| Theme | Dark-only |

## 🔧 CI/CD & repo automation

Repo automation is driven by **GitHub Actions**, run against the Ruby suite (`bundle exec rake test`) and the Docker image build.

## Principles

- **Minimal dependencies** — the standard library plus the `mail` gem; no heavy frameworks.
- **No hosted infrastructure** — the Action runs inside the adopter's own GitHub; the site is static.
- **Everything auditable** — the Action records every action; the site is fully client-side.
- **Config parity** — the same `.github/project-automation.yml` runs on both the Ruby and TypeScript editions.

## License

[MIT](./LICENSE).
