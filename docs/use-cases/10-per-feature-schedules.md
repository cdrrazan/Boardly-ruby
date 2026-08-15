# 10 · Different schedules per feature

**Feature:** All (via `only`) · **Who it's for:** teams that want each automation on its own cadence.

## The problem

A standup should run once every weekday morning. Priority sort can run hourly. Rollover should only fire at the sprint boundary. One schedule can't express all three.

## The setup

Use the `only` input to run a single feature per job, each with its own `cron`:

```yaml
name: Project automation
on:
  schedule:
    - cron: "0 7 * * 1-5"    # standup
    - cron: "0 * * * *"      # priority sort
    - cron: "0 6 * * 1"      # rollover + digest

permissions:
  contents: read
  issues: write

jobs:
  standup:
    if: github.event.schedule == '0 7 * * 1-5'
    runs-on: ubuntu-latest
    steps:
      - uses: cdrrazan/Boardly@v1
        with: { token: "${{ secrets.PROJECT_AUTOMATION_TOKEN }}", only: standup }

  sort:
    if: github.event.schedule == '0 * * * *'
    runs-on: ubuntu-latest
    steps:
      - uses: cdrrazan/Boardly@v1
        with: { token: "${{ secrets.PROJECT_AUTOMATION_TOKEN }}", only: priority-sort }

  sprint-boundary:
    if: github.event.schedule == '0 6 * * 1'
    runs-on: ubuntu-latest
    steps:
      - uses: cdrrazan/Boardly@v1
        with: { token: "${{ secrets.PROJECT_AUTOMATION_TOKEN }}", only: rollover }
      - uses: cdrrazan/Boardly@v1
        with: { token: "${{ secrets.PROJECT_AUTOMATION_TOKEN }}", only: digest }
```

## What happens

Each job runs exactly one feature. Valid `only` values: `rollover`, `sprint-start`, `sprint-runway`, `auto-assign`, `stale-nudge`, `sub-issue-gate`, `digest`, `standup`, `priority-sort`.

## Tips

- Leave `only` empty in a simpler setup to run **all** enabled features on one schedule.
- `only` runs the feature even if `enabled: false` in config (with a warning), which is handy for one-off manual runs via **Run workflow**.
