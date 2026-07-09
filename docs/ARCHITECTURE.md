# Architecture

A tour of how the **Ruby edition** of Boardly is put together, for contributors. The design mirrors the main TypeScript project, [cdrrazan/Boardly](https://github.com/cdrrazan/Boardly) — same shape, translated to idiomatic Ruby. Source lives in [`ruby/`](../ruby).

## High-level flow

```mermaid
flowchart TD
    idx[boardly.rb] -->|load + validate| cfg[config.rb<br/>YAML + validation]
    idx -->|new| client[github/client.rb<br/>ProjectClient]
    client -->|fetch_project · paged GraphQL| graph[(ProjectGraph<br/>model.rb)]
    idx -->|build RunContext| ctx{{RunContext}}
    ctx --> feats
    subgraph feats [features/*]
      f1[rollover]
      f2[stale_nudge]
      f3[sub_issue_gate]
      f4[digest]
      f5[standup]
      f6[priority_sort]
    end
    feats -->|record| audit[audit.rb]
    feats -->|mutations| client
    audit -->|flush| summary[[Actions job summary]]
```

## Responsibilities

| Module | Responsibility |
|--------|----------------|
| `boardly.rb` | Entry point. Reads Action inputs (from `BOARDLY_*` env vars), loads config, fetches the project once, builds `RunContext`, dispatches enabled features via the `RUNNERS` map, flushes the audit trail. One failing feature is logged and marked failed but doesn't abort the others. |
| `boardly/config.rb` | The single source of truth for the config shape — YAML load plus a hand-written validator with defaults that mirror the upstream `zod` schema (same field names, same defaults, same error style). |
| `boardly/model.rb` | The normalized `ProjectGraph` / `ProjectItem` / `ProjectField` structs. Everything downstream works against this, never raw GraphQL JSON. |
| `boardly/github/queries.rb` | GraphQL documents (project read query + the field/position mutations). |
| `boardly/github/client.rb` | `ProjectClient` — pages the project into a `ProjectGraph`, normalizes raw nodes (`normalize.rb`), and exposes mutation + comment helpers over `Net::HTTP`. Sends the `sub_issues` feature header. |
| `boardly/features/*` | One module per feature, each exposing `run(ctx)`. Pure logic over the fetched graph; side effects go through `ctx.client`. |
| `boardly/util/project.rb` | Accessors that map configured **field names** to values on an item (`status_of`, `iteration_of`, `priority_of`, `done?`, `option_id`, …). |
| `boardly/util/dates.rb` | Small, dependency-free date math (`days_between`, `iteration_has_ended?`, …). |
| `boardly/audit.rb` | `Audit` — accumulates every action and renders the job-summary table; also the seam where `dry-run` is reflected. |

## Key design choices

- **Fetch once, act many.** The project is read a single time into an in-memory graph; every feature operates on that snapshot. This keeps API usage low and makes features trivially unit-testable.
- **Fields are referenced by name.** Users name their own Status/Priority/Iteration fields, so config maps names → the action resolves them to ids at runtime via `util/project.rb`. Missing fields produce a helpful error listing what *is* available.
- **`dry-run` is centralized.** Features check `ctx.dry_run` right before each mutation and always call `ctx.audit.record(...)` first, so the audit trail is identical whether or not changes are applied.
- **De-duplication via hidden markers.** Nudges and gate warnings embed an HTML comment marker; before commenting, the feature scans existing comments and skips if it already acted during the current status "stint" (comment newer than the status's `updatedAt`).
- **"Time in status"** is approximated by each field value's `updatedAt` (exposed by the Projects v2 API) rather than a full timeline walk — cheaper, and accurate enough for nudges/standups.

## Testing

The test suite (`ruby/test/`) builds `ProjectGraph`s by hand and provides a fake client that records every mutation, plus a fake notification channel. Feature tests call the real `run` methods against fabricated boards and assert on the recorded calls — no network, full logic coverage. Run them with `bundle exec rake test`.

## Adding a feature

See the step-by-step in [CONTRIBUTING.md](../CONTRIBUTING.md#adding-a-new-feature). In short: add a `features/<name>.rb` exposing `run(ctx)`, extend the config validation in `config.rb`, register it in `boardly.rb`'s `RUNNERS` map, record actions through the audit trail, honor `dry-run`, and add tests + a use-case page. Where practical, mirror the change in the [main TypeScript project](https://github.com/cdrrazan/Boardly) to keep the editions in parity.
