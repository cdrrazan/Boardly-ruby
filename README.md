<div align="center">

# 🤖💎 Boardly (Ruby edition)

### Put your GitHub Projects board on autopilot — now in Ruby.

A config-driven GitHub Action that automates **GitHub Projects (v2)** — sprint rollover, stale-card nudges, sub-issue gating, digests, standups, priority sorting, and Slack/email notifications — all from one YAML file.

This repository is the **official Ruby port** of Boardly. It ships as a **Docker container action** and is **byte-for-byte config compatible** with the original.

<br/>

[![Main project: cdrrazan/Boardly](https://img.shields.io/badge/Upstream-cdrrazan%2FBoardly-181717?logo=github&logoColor=white)](https://github.com/cdrrazan/Boardly)
[![Website](https://img.shields.io/badge/Website-boardly--gh.pages.dev-6d8bff?logo=cloudflare&logoColor=white)](https://boardly-gh.pages.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Made with Ruby](https://img.shields.io/badge/Ruby-3.x-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Docker action](https://img.shields.io/badge/GitHub%20Action-Docker-2496ED?logo=docker&logoColor=white)](./ruby/Dockerfile)
[![GitHub Projects v2](https://img.shields.io/badge/GitHub-Projects%20v2-181717?logo=github&logoColor=white)](https://docs.github.com/issues/planning-and-tracking-with-projects)
[![Tests](https://img.shields.io/badge/tests-27%20passing-brightgreen.svg)](./ruby/test)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-ff69b4.svg)](./CONTRIBUTING.md)
[![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-red.svg)](./OPEN_SOURCE.md)

**[🌐 boardly-gh.pages.dev](https://boardly-gh.pages.dev)** · **[⬆️ Main repo (TypeScript): cdrrazan/Boardly](https://github.com/cdrrazan/Boardly)**

[Getting started](./docs/GETTING_STARTED.md) · [Quick start](#-quick-start) · [Features](#-features) · [Use cases](#-use-cases) · [Config](#%EF%B8%8F-configuration) · [Ruby vs. TypeScript](#-ruby-edition-vs-typescript-edition) · [Roadmap](./ROADMAP.md) · [Contributing](./CONTRIBUTING.md) · [Sponsor](#-support-the-project)

</div>

---

> ### 💎 About this repository
>
> **Boardly** lives in two actively-maintained editions:
>
> - **[cdrrazan/Boardly](https://github.com/cdrrazan/Boardly)** — the original **TypeScript** action (`node20`). This is the **main project** where features and the roadmap are driven.
> - **[cdrrazan/Boardly-ruby](https://github.com/cdrrazan/Boardly-ruby)** — this repo: a **full-Ruby** port shipped as a Docker container action.
>
> Both editions read the **same** `.github/project-automation.yml` and produce the same behaviour, so you can switch between them without changing your config. We maintain the Ruby edition in parallel with the main project — issues and PRs for the Ruby port are welcome here.

## ✨ What it does

You point the action at a Project (v2), describe your rules in `.github/project-automation.yml`, and schedule it. On every run it reads the board, applies your enabled features, and writes an **audit trail** to the Actions job summary so you can see exactly what happened.

```mermaid
flowchart LR
    cron([⏰ Schedule / manual]) --> action[🤖 Boardly · Ruby]
    cfg[[📄 project-automation.yml]] --> action
    action -->|GraphQL| gh[(🗂️ GitHub Project v2)]
    gh --> action
    action --> f1[🔁 Rollover]
    action --> f2[🔔 Stale nudges]
    action --> f3[🧩 Sub-issue gate]
    action --> f4[🏁 Digest]
    action --> f5[🗓️ Standup]
    action --> f6[🔼 Priority sort]
    f1 & f2 & f3 & f4 & f5 & f6 --> audit[[📋 Audit trail → Job Summary]]
```

## 🚀 Features

| | Feature | What it does |
|:--:|---------|--------------|
| 🔁 | **Sprint rollover** | When an iteration ends, move unfinished items into the next iteration so nothing is stranded in a closed sprint. Optionally tag each rolled card with the new sprint's label (created if missing). |
| ▶️ | **Sprint start** | When a sprint becomes active, promote cards you pre-parked in it (e.g. **Backlog → Ready**). Only touches cards parked *before* the sprint started, so a deliberate mid-sprint move back is respected. |
| 🔔 | **Stale-card nudges** | @-mention owners when a card sits in a status past a threshold. De-duped so it never spams. |
| 🧩 | **Sub-issue gating + roll-up** | Block a card from staying **Done** while it has open sub-issues; optionally write completion % into a progress field. |
| 🏁 | **Sprint digest** | At iteration end, post completed-vs-carried-over counts and velocity. |
| 🗓️ | **Daily standup** | Post what moved in the last _N_ hours, grouped by assignee. |
| 🔼 | **Priority auto-sort** | Reorder the board so higher-priority cards float to the top. |
| 📣 | **Slack & email notifications** | Also deliver digests, standups, and stale alerts to a Slack channel and/or over email — not just GitHub comments. |
| 📋 | **Audit trail** | Every action (or, in `dry-run`, every _intended_ action) is written to the job summary. |

## 📚 Use cases

Every feature comes with a standalone, copy-pasteable recipe — **who it's for**, the **config**, and **what happens**. The config is identical across both editions, so these recipes apply verbatim. Browse them all in [`docs/use-cases`](./docs/use-cases), or jump straight in:

| # | Use case | Feature(s) |
|:--:|----------|-----------|
| 01 | [Carry unfinished work into the next sprint](./docs/use-cases/01-sprint-rollover.md) | 🔁 Rollover |
| 02 | [Nudge owners about stale cards](./docs/use-cases/02-stale-card-nudges.md) | 🔔 Stale nudges |
| 03 | [Stop premature "Done" on parent issues](./docs/use-cases/03-sub-issue-gating.md) | 🧩 Sub-issue gate |
| 04 | [Show live epic progress on the board](./docs/use-cases/04-progress-rollup.md) | 🧩 Sub-issue roll-up |
| 05 | [Auto-post a sprint retro digest](./docs/use-cases/05-sprint-digest.md) | 🏁 Digest |
| 06 | [Async daily standup for a distributed team](./docs/use-cases/06-daily-standup.md) | 🗓️ Standup |
| 07 | [Keep the backlog sorted by priority](./docs/use-cases/07-priority-sort.md) | 🔼 Priority sort |
| 08 | [Preview everything safely with dry-run](./docs/use-cases/08-dry-run-preview.md) | 📋 All + audit |
| 09 | [Automate a project spanning many repos](./docs/use-cases/09-multi-repo-project.md) | ⚙️ All |
| 10 | [Different schedules per feature](./docs/use-cases/10-per-feature-schedules.md) | ⚙️ All |
| 11 | [Solo maintainer / personal project board](./docs/use-cases/11-personal-project.md) | ⚙️ All |
| 12 | [Escalate cards ignored after a nudge](./docs/use-cases/12-escalation-with-revert.md) | 🔔 Stale + 🧩 gate |
| 13 | [Send digests & alerts to Slack and email](./docs/use-cases/13-notifications.md) | 📣 Notifications |
| 14 | [Promote pre-parked cards when a sprint starts](./docs/use-cases/14-sprint-start.md) | ▶️ Sprint start |

> New here? Start with [01 · Sprint rollover](./docs/use-cases/01-sprint-rollover.md) and [08 · Dry-run preview](./docs/use-cases/08-dry-run-preview.md).

## ⚡ Quick start

> **New here?** The [**Getting started guide**](./docs/GETTING_STARTED.md) is a full, linear zero-to-running walkthrough (~15 min). The steps below are the condensed version.

```mermaid
flowchart TD
    A[1 · Create a token<br/>Projects + Issues scope] --> B[2 · Add config<br/>.github/project-automation.yml]
    B --> C[3 · Add workflow<br/>.github/workflows/project-automation.yml]
    C --> D[4 · Dry-run to preview] --> E[5 · Flip dry-run off 🎉]
```

1. **Create a token.** The default `GITHUB_TOKEN` generally can't read org Projects. Create a fine-grained PAT or GitHub App token with **Projects: read & write** and **Issues: read & write**, and save it as a secret (e.g. `PROJECT_AUTOMATION_TOKEN`).

2. **Add config** at `.github/project-automation.yml` — start from [`ruby/project-automation.example.yml`](./ruby/project-automation.example.yml).

3. **Add a workflow.** This edition is a **Docker container action**, so it must run on a **Linux runner**:

   ```yaml
   jobs:
     automate:
       runs-on: ubuntu-latest   # Docker actions require a Linux runner
       steps:
         - uses: cdrrazan/Boardly-ruby@v1
           with:
             token: ${{ secrets.PROJECT_AUTOMATION_TOKEN }}
             config-path: .github/project-automation.yml
             dry-run: "true"   # preview first; remove once it looks right
   ```

> **Prefer the TypeScript action?** Use [`cdrrazan/Boardly@v1`](https://github.com/cdrrazan/Boardly) instead — same inputs, same config, and it runs on any runner OS.

> **Versioning:** pin to **`@v1`** to always get the latest `v1.x` (bug-fixes and features, no breaking changes), or **`@v1.0.0`** to freeze an exact version.

### 🔑 Secrets you'll need

Set these as repository (or org) **Actions secrets**, then map them into the workflow. Only the token is required.

| Secret | Required? | What it is | Needed when |
|--------|-----------|------------|-------------|
| `PROJECT_AUTOMATION_TOKEN` | **Yes** | Fine-grained PAT / GitHub App token — **Projects: read & write** + **Issues: read & write** | Always (the default `GITHUB_TOKEN` can't read org Projects) |
| `SLACK_WEBHOOK_URL` | No | Slack Incoming Webhook URL | You enable `notifications.slack` |
| `SMTP_USER` | No | SMTP username | You enable `notifications.email` with auth |
| `SMTP_PASS` | No | SMTP password | You enable `notifications.email` with auth |

The token is passed via the `token:` input; the notification secrets are passed via the workflow's `env:` (referenced in config **by env-var name**, never inlined). See [Notifications](#-notifications-slack--email).

## 🏢 Using it in an organization

Boardly-ruby is a **published Docker container action** — there's nothing to install, fork, or host. Any repo in your org just references `cdrrazan/Boardly-ruby@v1` (on a Linux runner). To roll it out across a team:

1. **Allowlist the Action** (only if your org restricts Actions). Org admin → **Settings → Actions → General → Allow select actions** → add `cdrrazan/Boardly-ruby@*`. Skip if your org already permits all or marketplace actions.
2. **Create one token** with access to the org's Project (v2) — a **GitHub App token** (recommended for teams; not tied to a single person) or an **org-scoped fine-grained PAT**, with **Projects: read & write** + **Issues: read & write**.
3. **Store it once as an org-level secret** named `PROJECT_AUTOMATION_TOKEN` (**Org Settings → Secrets and variables → Actions**) and share it to the repos that need it — one secret, many repos.
4. **Host the workflow in a single repo.** A Project (v2) is owned by the **org or user**, not a repo, and the config targets it by `owner` + `number` — so the scheduled workflow lives in **one** repo, even when the board spans many. It does not need to be added to every repo.
5. **Point the config at the org project** and dry-run first:

   ```yaml
   # .github/project-automation.yml
   project:
     owner: my-org     # your org login
     type: org
     number: 7         # from the project URL: /orgs/my-org/projects/7
   ```

For a board that pulls issues from several repositories, see the [multi-repo recipe](./docs/use-cases/09-multi-repo-project.md).

## 🧾 Inputs & outputs

| Input | Default | Description |
|-------|---------|-------------|
| `token` | — _(required)_ | Token with `project` + `issues` access to the target project. |
| `config-path` | `.github/project-automation.yml` | Path to the config file. |
| `only` | `""` | Run just one feature: `rollover`, `sprint-start`, `stale-nudge`, `sub-issue-gate`, `digest`, `standup`, `priority-sort`. Empty runs every enabled feature. |
| `dry-run` | `false` | Log every intended action to the audit trail without making changes. |

**Output:** `actions-count` — number of mutating actions taken (or that would be taken in dry-run).

## ⚙️ Configuration

Everything is declared in one YAML file, shared with the TypeScript edition. Minimal example:

```yaml
project:
  owner: my-org
  type: org        # or "user"
  number: 5
fields:
  status: Status
  iteration: Sprint
  priority: Priority
doneStatuses: ["Done"]
features:
  rollover:
    enabled: true
  staleNudge:
    enabled: true
    rules:
      - status: "In Progress"
        days: 3
        notify: assignees
```

Full reference: [`ruby/project-automation.example.yml`](./ruby/project-automation.example.yml).

## 📣 Notifications (Slack & email)

By default, digests, standups, and stale alerts are posted to GitHub. You can **also** deliver them to a Slack channel and/or over email by adding a `notifications` block. Secrets are referenced by **environment-variable name** — never inline the webhook URL or SMTP password in config; pass them from encrypted secrets via the workflow's `env:`.

```yaml
# in project-automation.yml
notifications:
  slack:
    enabled: true
    webhookEnv: SLACK_WEBHOOK_URL      # env var with a Slack Incoming Webhook URL
  email:
    enabled: true
    host: smtp.example.com
    port: 587
    secure: false                      # true for port 465
    userEnv: SMTP_USER
    passwordEnv: SMTP_PASS
    from: "Boardly <bot@example.com>"
    to: ["team@example.com"]
```

```yaml
# in your workflow — map the secrets into the environment
- uses: cdrrazan/Boardly-ruby@v1
  with:
    token: ${{ secrets.PROJECT_AUTOMATION_TOKEN }}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    SMTP_USER: ${{ secrets.SMTP_USER }}
    SMTP_PASS: ${{ secrets.SMTP_PASS }}
```

Both channels are optional and independent — enable either, both, or neither. A channel failure is logged as a warning and never aborts the run, and nothing is sent under `dry-run`. See the [notifications recipe](./docs/use-cases/13-notifications.md).

> **Configured but paused?** To keep your creds and settings in place but stop sending, just set that channel's `enabled: false`. The webhook/SMTP config stays untouched — no delivery happens until you flip it back to `true`. You don't need to remove secrets to go quiet.

## 🧠 How it decides things

- **"Time in status"** is approximated by when the Status field value was last changed (Projects v2 exposes each field value's `updatedAt`). It is not a full status-history walk.
- **Iterations** come from the iteration field's configuration. Rollover and digest act on the most recently *completed* iteration; new work rolls into the first *active* iteration.
- **Sub-issues** use the native GitHub sub-issues API (`subIssuesSummary`), requested with the `sub_issues` GraphQL feature header.
- **Priority sort** uses `updateProjectV2ItemPosition`. Manual order only shows on a board view whose sort is set to **manual** — a field-sorted view overrides it.

## 💎 Ruby edition vs. TypeScript edition

Both editions are functionally equivalent and read the same config. They differ only in how they're built and run:

| | 💎 This repo — [`cdrrazan/Boardly-ruby`](https://github.com/cdrrazan/Boardly-ruby) | ⬆️ Main repo — [`cdrrazan/Boardly`](https://github.com/cdrrazan/Boardly) |
|--|--|--|
| Language | Ruby 3.x | TypeScript (strict) |
| Runtime | **Docker container action** (`ruby:3.3` image) | **`node20`** bundled action |
| Runner OS | Linux only | Any (Linux/macOS/Windows) |
| HTTP | `Net::HTTP` (stdlib) | `@octokit/graphql` + `@actions/github` |
| Dependencies | stdlib + `mail` gem | `@actions/*`, `zod`, `js-yaml`, … |
| Build step | none (image built at run) | committed `dist/` bundle (`ncc`) |
| Config | **identical** `.github/project-automation.yml` | **identical** `.github/project-automation.yml` |

The Ruby port lives in [`ruby/`](./ruby) and is self-contained — see [`ruby/README.md`](./ruby/README.md) for details specific to that folder.

## 🛠️ Development

```bash
cd ruby
bundle install
bundle exec rake test          # Minitest suite (27 tests)
docker build -t Boardly-ruby .   # build the action image
```

**Built with:** Ruby 3.3 · standard library (HTTP/JSON/YAML) · `mail` gem (SMTP) · Minitest — see the full [**Tech Stack**](./TECH_STACK.md) and [**Architecture**](./docs/ARCHITECTURE.md).

## 🗺️ Roadmap

Working-days awareness, escalation ladders, iteration auto-assignment, capacity warnings, and more — see [**ROADMAP.md**](./ROADMAP.md). The roadmap is shared with the [main project](https://github.com/cdrrazan/Boardly).

## 🤝 Contributing

Contributions are very welcome! Read the [**Contributing Guide**](./CONTRIBUTING.md) and our [**Code of Conduct**](./CODE_OF_CONDUCT.md) to get started. Found a security issue? See [**SECURITY.md**](./SECURITY.md).

## ❤️ Support the project

Boardly is free and open source. If it saves your team time, please consider sponsoring — it directly funds maintenance of both the TypeScript and Ruby editions.

<div align="center">

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/cdrrazan)
[![Buy Me a Momo](https://img.shields.io/badge/Buy%20Me%20a%20Momo-FF7139?logo=buymeacoffee&logoColor=white)](https://buymemomo.com/rajan)

⭐ **Starring the repo also helps a lot.**

</div>

## 📄 License

Released under the [MIT License](./LICENSE) — see also our [open-source note](./OPEN_SOURCE.md).

<div align="center">
<sub>Built with ❤️ for teams who'd rather ship than babysit a board.</sub>
</div>
