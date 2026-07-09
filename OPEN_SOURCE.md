# Open Source Note

Boardly is **free and open source software**, released under the [MIT License](./LICENSE). It is built in the open, and it always will be.

This repository is the **Ruby edition** of Boardly — the official Ruby port of the main project, [**cdrrazan/Boardly**](https://github.com/cdrrazan/Boardly) (TypeScript). Both editions are actively maintained.

## What this means for you

- ✅ **Free to use** — personal, commercial, internal, or as part of a larger product.
- ✅ **Free to modify** — fork it, adapt it, wire it into your own workflows.
- ✅ **Free to redistribute** — subject only to keeping the MIT copyright and license notice.
- ✅ **No lock-in** — it's a self-contained GitHub Action driven by a plain YAML file you own.

There is no paid tier, no telemetry, and no "open core" bait-and-switch. The version you see here is the whole thing.

## Our principles

- **Transparency.** Every automated action is recorded in the run's [audit trail](./README.md#-features). The bot never does anything you can't see.
- **Least privilege.** The action only ever uses the token *you* provide, with the scopes *you* grant. See [SECURITY.md](./SECURITY.md).
- **Community first.** Roadmap and design happen in public issues. See [ROADMAP.md](./ROADMAP.md) and [CONTRIBUTING.md](./CONTRIBUTING.md).

## Sustainability

Open source takes real time to maintain. If this project helps your team, you can keep it healthy by:

- ⭐ **Starring** the repository (helps others discover it)
- 🐛 **Reporting bugs** and 📝 **improving docs**
- 💬 **Sharing** how you use it (great [use-cases](./docs/use-cases) come from real teams)
- ❤️ **Sponsoring** — see [Support the project](./README.md#-support-the-project)

## Third-party dependencies

The Ruby edition is deliberately dependency-light — it leans on the Ruby standard library for HTTP, JSON, and YAML, plus:

- [`mail`](https://github.com/mikel/mail) (MIT) — SMTP delivery for the notifications feature
- [`minitest`](https://github.com/minitest/minitest) (MIT) — test suite _(development)_
- [`rake`](https://github.com/ruby/rake) (MIT) — task runner _(development)_

It also builds on the excellent [Ruby](https://www.ruby-lang.org/) language and standard library. Thank you to all their maintainers. 🙏
