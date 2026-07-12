# 15 · Auto-assign tickets by label

**Feature:** Auto-assign · **Who it's for:** teams with clear label-to-owner conventions (`UI` is always Zach's, `security` is always Rajan's).

## The problem

A new sprint's tickets land in **Ready**, unassigned. Someone has to remember that every `UI` card goes to Zach and every `security` card goes to Rajan, then hand-assign them one by one. It's mechanical, and it's easy to forget.

## The setup

```yaml
fields:
  status: Status
features:
  autoAssign:
    enabled: true
    onlyStatuses: ["Ready"]     # only assign tickets sitting in these statuses
    rules:
      - label: "UI"
        assignees: ["zachgrande"]   # GitHub usernames — not display names
      - label: "security"
        assignees: ["cdrrazan"]
```

Run it on the same schedule as the rest of your automation — hourly, or right at the sprint boundary:

```yaml
on:
  workflow_dispatch:
  schedule:
    - cron: "0 * * * *"
```

## What happens

Each run, for every ticket that is **all** of:

- in one of `onlyStatuses` (here, `Ready`),
- **not already assigned** to anyone, and
- carrying a label named in a rule,

Boardly assigns the rule's users. A ticket whose labels match **no** rule is left alone — this feature never assigns a random owner, only the ones you mapped.

- A `UI` card → assigned to `@zachgrande`.
- A card labelled **both** `UI` and `security` → assigned to **both** (`@zachgrande`, `@cdrrazan`) — matches are unioned.
- A card someone already owns → skipped. Boardly never overrides a human's choice.
- A card in `Backlog` (not a listed status) → skipped.

Because a ticket is skipped once it has an assignee, the feature is idempotent — safe to run every hour.

## Pairs with sprint start

Chain it with [sprint start](./14-sprint-start.md): a sprint flips → `sprintStart` promotes your pre-parked cards **Backlog → Ready** → `autoAssign` then assigns those now-Ready cards to their label owners, all in the same run. Monday morning the new sprint is groomed *and* staffed with zero manual clicks.

## Tips

- **Label matching is case-insensitive.** `UI`, `ui`, `uI`, `Ui` in the config all match a board label of any casing — write it however you like.
- `assignees` are GitHub **logins** (`zachgrande`), not display names ("Zach Grande"). A login that isn't a repo collaborator is silently ignored by GitHub.
- Want it to also cover other columns? Widen `onlyStatuses: ["Ready", "Todo"]`, or set it to `[]` to consider every non-done ticket.
- Multiple owners per label is fine — list them all under `assignees`.
- Test with `dry-run: "true"` first — see [use case 08](./08-dry-run-preview.md).
