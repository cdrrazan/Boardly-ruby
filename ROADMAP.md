# 🗺️ Roadmap

This is a living document — priorities shift based on community feedback. Have an idea or a vote? Open an [issue](https://github.com/cdrrazan/Boardly/issues) or a [discussion](https://github.com/cdrrazan/Boardly/discussions).

Legend: ✅ shipped · 🛠️ in progress · 🔭 planned · 💡 idea / needs discussion

## ✅ v1.0 — Foundation (shipped)

The first stable release: a config-driven Action with the core feature set plus notifications.

- ✅ Sprint rollover
- ✅ Stale-card nudges (with de-dup)
- ✅ Sub-issue Done-gating + progress roll-up
- ✅ Sprint digest (completed / carried-over / velocity)
- ✅ Daily standup summary
- ✅ Priority auto-sort
- ✅ Slack & email notifications
- ✅ Audit trail → job summary + `dry-run`

## 🔭 v1.1 — Correctness & trust

Making the existing features smarter and safer to adopt.

- 🔭 **Working-days & holiday awareness** — a shared calendar so "X days" in rollover/stale/standup skips weekends and configured holidays.
- 🔭 **Escalation ladder** — multi-step stale handling: nudge → label → escalate to a lead → reassign, with per-step thresholds.
- 🔭 **Iteration auto-assignment** — drop newly-added items into the current active iteration automatically.
- 🔭 **Richer templating** — more placeholders and per-rule formatting for nudge/digest/standup messages.

## 🔭 v1.2 — Planning signals

Helping teams plan, not just tidy.

- 🔭 **Missing-metadata guard** — before a sprint starts, flag cards lacking estimate / assignee / priority.
- 🔭 **Overcommit / capacity warning** — warn when an iteration's total estimate exceeds a configured team capacity.
- 🔭 **Multi-sprint velocity trend** — the digest shows a rolling velocity chart across the last N sprints.
- 🔭 **Blocked-time tracking** — surface how long items have sat in a Blocked status, in standups and digests.

## 💡 Under consideration

Ideas we like but haven't committed to. Feedback especially welcome here.

- ✅ **Slack & email notifications** — delivered for digests, standups, and stale alerts. _(shipped)_
- 💡 **More notification channels** — Discord and Microsoft Teams delivery.
- 💡 **Lifecycle status sync** — auto-move cards as issues/PRs open, get reviewed, merge, or close.
- 💡 **Auto-add + auto-triage** — add new issues/PRs to the project and set fields from label rules (round-robin assignment).
- 💡 **WIP limits** — warn when a column exceeds N cards.
- 💡 **SLA / time-in-status metrics** — flag cards exceeding a configured time in any column.
- 💡 **Cross-project sync** — mirror an item's status across multiple boards.
- 💡 **Config presets** — shareable rule bundles ("Scrum", "Kanban", "solo maintainer").

## 🧱 Engineering / project health

Not user-facing, but on the list.

- ✅ CI running the Minitest suite (`bundle exec rake test`) + Docker image build on pull requests.
- ✅ Published changelog + release automation (the `v1` alias auto-moves on publish).
- 🔭 Keep behaviour and config in parity with the [main TypeScript project](https://github.com/cdrrazan/Boardly).
- 🔭 Integration smoke test against a sandbox project in `dry-run`.
- 💡 GitHub Marketplace listing.

## Beyond v1.0

`v1.0` is out. Within the `v1.x` line the config schema and action inputs stay backward-compatible; any breaking change to them waits for a `v2`. Priorities are driven by real usage — feedback in [issues](https://github.com/cdrrazan/Boardly/issues) and [discussions](https://github.com/cdrrazan/Boardly/discussions) shapes what lands next.

---

_Dates are intentionally omitted — this is a community project and scope is driven by real usage. The ordering above reflects rough priority, not a fixed schedule._
