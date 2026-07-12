# 14 · Promote pre-parked cards when a sprint starts

**Feature:** Sprint start · **Who it's for:** teams that plan ahead by assigning tickets to a future sprint.

## The problem

Mid-way through **S07**, you already know some tickets belong in **S08**, so you assign them to the S08 iteration now. Because S08 hasn't started, they sit in **Backlog**. When S08 finally becomes the active sprint on Monday, someone has to walk the board and drag each of those pre-planned cards from **Backlog → Ready** so the team can pick them up.

## The setup

```yaml
fields:
  status: Status
  iteration: Sprint
features:
  sprintStart:
    enabled: true
    fromStatuses: ["Backlog"]   # statuses treated as "not started yet"
    toStatus: "Ready"           # promote pre-parked cards to this
```

Run it at the sprint boundary — the same schedule you'd use for [rollover](./01-sprint-rollover.md):

```yaml
on:
  schedule:
    - cron: "0 6 * * 1"   # Monday 06:00 UTC, just after the sprint flips
```

## What happens

Each run, the action finds the **current active iteration** — the soonest iteration whose start date has arrived. For every card assigned to it that is still in a `fromStatuses` column, it sets the card to `toStatus`.

The catch that keeps it safe: a card is only promoted if its status was last changed **before** the sprint's start date — i.e. it was genuinely *pre-parked*. So:

- ✅ A ticket you dropped into S08's Backlog last week → promoted to Ready when S08 starts.
- ⛔ A card you deliberately moved **back** to Backlog *during* S08 (deprioritized) → left alone; it won't be dragged back to Ready on the next run.
- ⛔ Nothing happens at all until the iteration's start date actually arrives — assigning to a future sprint early doesn't trigger it.

Because a promoted card is no longer in `fromStatuses`, the feature is naturally idempotent — running it every hour is harmless.

## Tips

- Pair it with [rollover](./01-sprint-rollover.md): rollover carries *unfinished* work forward at sprint end, sprint-start promotes *pre-planned* work at sprint start. Together the board is correct on Monday morning with no manual dragging.
- Multiple "not yet started" columns? List them all: `fromStatuses: ["Backlog", "Triage"]`.
- `toStatus` must be a real option on your Status field — if it isn't, the run fails with an error listing the options that *do* exist.
- Test with `dry-run: "true"` first — see [use case 08](./08-dry-run-preview.md).
