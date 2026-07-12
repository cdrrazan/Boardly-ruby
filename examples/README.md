# Worked example

A realistic, end-to-end Boardly setup for a fictional team — so you can see the
whole thing wired up, not just the schema. For the terse option-by-option
reference, see [`project-automation.example.yml`](../project-automation.example.yml).

## The scenario

**Nimbus Labs** is a 5-person product team running two-week sprints on GitHub
Project #7. They want the board to run itself:

| Person | Login | Area |
|--------|-------|------|
| Maya | `maya-oss` | Frontend / reviewer |
| Dev | `dev-kohl` | Backend |
| Tomasz | `tomasz-w` | Infra |
| Priya | `priya-r` | Security |
| (PM) | `eng-manager` | Escalations |

What the config sets up:

- **Rollover** — unfinished cards move into the new sprint, tagged with its label; the stale `pulled-in` marker is stripped.
- **Sprint start** — cards pre-parked in `Backlog` are promoted to `Ready`.
- **Sprint runway** — warns if fewer than 2 future sprints are planned.
- **Auto-assign** — new `Ready` tickets are assigned by area label (`frontend` → Maya, etc.).
- **Stale nudges** — `In Progress` after 4d, `In Review` after 2d (pings the reviewer too), `Blocked` after 1d (pings assignees **and** the PM).
- **Sub-issue gate** — a parent can't sit in `Done`/`Released` while sub-issues are open; it's reverted to `In Progress`, and completion % is written to `Progress`.
- **Digest** — posted to the standing "Sprint reports" issue (#128) at sprint end.
- **Standup** — a fresh, labelled issue each run summarising the last 24h.
- **Priority sort** — board ordered `Urgent → High → Medium → Low`.
- **Slack + email** — digests, standups, and stale alerts mirrored to `#eng-board` and the team mailing list.

## Files

| File | Goes to | What it is |
|------|---------|------------|
| [`project-automation.yml`](./project-automation.yml) | `.github/project-automation.yml` | The config above. |
| [`boardly.yml`](./boardly.yml) | `.github/workflows/boardly.yml` | Runs Boardly weekday mornings + on demand. |

## Try it safely

Copy both files into your repo, swap `nimbus-labs` / Project `7` / the logins
for your own, then flip `dry-run: "true"` in the workflow for the first run —
Boardly will log every action it *would* take without changing the board.
