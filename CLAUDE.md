# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Boardly is a config-driven GitHub Action that automates **GitHub Projects (v2)**: sprint rollover, stale-card nudges, sub-issue Done-gating, digests, standups, priority sort, and Slack/email notifications — all driven by one YAML file.

This repository holds **two implementations of the same tool**:

- **`ruby/`** — the **Ruby port**, and the thing this repo actually ships. It is a **Docker container action** (`ruby/action.yml` → `ruby/Dockerfile`). Almost all work happens here.
- **root `src/`** (TypeScript, `dist/`, `package.json`, `tsconfig.json`) — the **upstream TypeScript original**, kept for reference and parity. The Ruby port is deliberately **byte-for-byte config-compatible** with it. Change TS only when explicitly porting a feature or checking parity; the canonical upstream lives at `github.com/cdrrazan/Boardly`.

When a task says "Boardly" without qualification, assume **`ruby/`**.

## Commands

Ruby port (run from `ruby/`):

```bash
bundle install                       # install deps (mail gem + dev: minitest, rake)
rake test                            # run all tests (minitest)
rake                                 # default task == test
ruby -Ilib -Itest test/config_test.rb          # run a single test file
ruby -Ilib -Itest test/config_test.rb -n /slack/   # single test by name pattern
docker build -t boardly-ruby .       # build the container action image
```

There is **no lint/format tool wired up** and **no `.gemspec`** — this is a script-style app run via `bin/boardly`, not a published gem. Tests are **Minitest**, not RSpec (unusual for this owner — do not "fix" it to RSpec).

TypeScript original (run from repo root):

```bash
npm run test        # node --test over test/*.test.ts
npm run typecheck   # tsc --noEmit
npm run build       # ncc bundle src/index.ts -> dist/
npm run all         # typecheck + test + build
```

## How the Ruby port runs

Entry point is `bin/boardly` → `Boardly.run` (`lib/boardly.rb`). It is **driven entirely by ENV vars**, which `action.yml` maps from Action inputs:

- `BOARDLY_TOKEN` (required) ← `token`
- `BOARDLY_CONFIG_PATH` ← `config-path` (default `.github/project-automation.yml`)
- `BOARDLY_ONLY` ← `only` (run a single feature)
- `BOARDLY_DRY_RUN` ← `dry-run`

Run sequence in `Boardly.run`:
1. Load + validate YAML config (`Config.load_file`).
2. Fetch the whole project **once** via GraphQL, paged, normalized into a `ProjectGraph` (`GitHub::Client#fetch_project`).
3. Build an `Audit` (the action trail) and a `Notifier` (external channels).
4. Assemble a single `RunContext` and run either the one feature named by `only` or every enabled feature, in `RUNNERS` order.
5. Each feature runs inside its own `::group::` and is isolated: a feature raising `StandardError` logs `::error::`, sets `failed`, and the run continues; process exits 1 at the end if any feature failed.
6. `audit.flush` writes a Markdown table to the job summary; `actions-count` is written to `GITHUB_OUTPUT`.

## Architecture (Ruby, `lib/boardly/`)

- **`model.rb`** — plain `Struct`s (`keyword_init`) that mirror the TS `types.ts` model: `ProjectGraph`, `ProjectItem`, `ProjectField`, `FieldValue`, `IssueContent`, `RunContext`, etc. This normalized model is the boundary — everything downstream of `fetch_project` works on these structs, never on raw GraphQL JSON.
- **`config.rb`** — hand-written validator mirroring the TS **zod** schema. Deep-symbolizes the YAML, accumulates errors, raises `ConfigError` with all of them at once. **Accepts both `snake_case` and `camelCase` keys** for every option (e.g. `only_statuses`/`onlyStatuses`) so configs are portable between the Ruby and TS editions. Defaults must match the TS version.
- **`github/`**
  - `client.rb` — **stdlib-only** (`net/http`, `json`, `uri`) wrapper over GitHub GraphQL + REST. No octokit. Sub-issue fields need the `GraphQL-Features: sub_issues` header (`SUB_ISSUE_HEADER`).
  - `queries.rb` — GraphQL query/mutation strings.
  - `normalize.rb` — raw GraphQL nodes → the `model.rb` structs.
- **`features/`** — one module per feature (`rollover`, `stale_nudge`, `sub_issue_gate`, `digest`, `standup`, `priority_sort`). Each is a `module_function` module exposing `run(ctx)`. Registered in the `RUNNERS` map in `lib/boardly.rb`; `Boardly.enabled?` decides whether config turned it on. **Adding a feature = add the file, add to `RUNNERS`, add an `enabled?` branch, add config validation.**
- **`notify/`** — `notifier.rb` fans a `Report` out to `SlackChannel` / `EmailChannel`. Never lets one channel's failure abort the run or other channels; records each delivery in the audit.
- **`audit.rb`** — records every intended mutation **before** it happens (so the trail is identical under dry-run) and renders the job-summary table.
- **`util/`** — `project.rb` (field lookup, status/iteration/done helpers over the model), `dates.rb`.

## Conventions specific to this codebase

- **Dry-run is first-class.** Features record every action through `ctx.audit`/`ctx.notifier` and check `ctx.dry_run?` before mutating. New mutating code must record its action to the audit *before* the API call and skip the call when dry-run.
- **Secrets come from ENV, never config.** Config only names the env var (e.g. `webhook_env`, `password_env`, `user_env`); the notifier reads the actual secret from `env`. Keep it that way.
- **Config parity with the TS edition is a hard requirement.** When changing config shape, defaults, or validation, mirror it in `src/` (or note the divergence) and keep dual snake/camel key support.
- **GitHub Actions log conventions** are used for control flow output: `::group::`/`::endgroup::`, `::warning::`, `::error::`. Preserve them — CI relies on them.
- Test doubles live in `ruby/test/test_helper.rb` (`FakeClient`, `FakeChannel`, `Builders`); write feature tests by building a `ctx` with these rather than hitting the network.
