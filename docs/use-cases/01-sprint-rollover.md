# 01 · Carry unfinished work into the next sprint

**Feature:** Sprint rollover · **Who it's for:** any team running fixed-length iterations.

## The problem

Your sprint ends Friday. A handful of tickets aren't finished. On Monday they're still tagged to last week's (now closed) iteration, invisible on the current board, and someone has to hand-move each one.

## The setup

```yaml
fields:
  status: Status
  iteration: Sprint
doneStatuses: ["Done", "Released"]
features:
  rollover:
    enabled: true
    onlyStatuses: []          # empty = every non-done item rolls over
    addSprintLabel: false     # also tag each rolled card with the new sprint's label
    sprintLabelColor: "772fd1" # color used if that label must be created
```

Run it right after the iteration boundary:

```yaml
on:
  schedule:
    - cron: "0 6 * * 1"   # Monday 06:00 UTC, just after the sprint flips
```

## What happens

When the action runs, it finds the **most recently completed** iteration and the **current active** one. Every item still assigned to the completed iteration that isn't in a `doneStatuses` column is moved to the current iteration. Done items are left behind (they belong to the finished sprint's record).

## Tagging the new sprint with a label

Some teams also track sprints with a plain issue **label** (e.g. `2026-S06`) so work can be filtered outside the board. Set `addSprintLabel: true` and rollover, in the same pass, adds a label **named after the iteration it moves cards into** to every card it rolls. If the repo doesn't have that label yet, Boardly creates it once (color `sprintLabelColor`, default `772fd1`). This is **additive** — existing labels like `pulled-in` are never removed, and a card that already carries the sprint label is skipped.

```yaml
features:
  rollover:
    enabled: true
    addSprintLabel: true
    sprintLabelColor: "772fd1"
```

So when Sprint `2026-S05` closes into `2026-S06`, each carried-over card lands in the new iteration *and* gets the `2026-S06` label — no manual labelling, no label bookkeeping.

## Stripping stale labels (e.g. `pulled-in`)

Teams that tag mid-sprint pull-ins with a `pulled-in` label want it cleared when the work rolls into the next sprint. Add `removeLabels` and rollover strips those from every card it carries:

```yaml
features:
  rollover:
    enabled: true
    removeLabels: ["pulled-in", "pull-in"]
```

Matching **ignores case and treats spaces, hyphens, and underscores as equivalent** — so a single `pulled-in` entry also clears `Pulled In`, `PULLED_IN`, `pulledin`, etc. Because `pull` and `pulled` are different words (they normalize differently), list both stems if your team uses both spellings — `["pulled-in", "pull-in"]` covers `pulled-in`, `pulled in`, `pull in`, and `pull-in` in any case. Labels you didn't list are never touched.

## Tips

- Only want to roll certain columns? Set `onlyStatuses: ["In Progress", "Todo"]` — a card in "Blocked" then stays put for you to review.
- `sprintLabelColor` is a 6-digit hex **without** the leading `#`. It only applies the first time the label is created; an existing label keeps its color.
- Pair with the [sprint digest](./05-sprint-digest.md) so the same run that carries work over also reports what got carried.
- Test with `dry-run: "true"` first — see [use case 08](./08-dry-run-preview.md).
