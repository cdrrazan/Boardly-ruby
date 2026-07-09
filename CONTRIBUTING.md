# Contributing to Boardly (Ruby edition)

First off — thank you! 🎉 This project is open source and community-driven, and contributions of every size are welcome: bug reports, docs fixes, new use-cases, and features.

This repository is the **Ruby port** of Boardly. The main project — where the roadmap and feature design happen — lives at [**cdrrazan/Boardly**](https://github.com/cdrrazan/Boardly) (TypeScript). Both editions are actively maintained and share the same config and behaviour, so when you change behaviour here, please consider whether the same change belongs upstream too (and vice-versa).

By participating you agree to abide by our [Code of Conduct](./CODE_OF_CONDUCT.md).

## Ways to contribute

- 🐛 **Report a bug** — open an issue with steps to reproduce, your config (redact tokens!), and what you expected.
- 💡 **Suggest a feature** — check the [roadmap](./ROADMAP.md) first, then open an issue describing the workflow you're trying to automate.
- 📝 **Improve docs** — READMEs, [use-cases](./docs/use-cases), and inline comments all count.
- 🔧 **Send a PR** — see below.

## Development setup

```bash
git clone https://github.com/cdrrazan/boardly-ruby.git
cd boardly-ruby/ruby
bundle install
```

Requires **Ruby ≥ 3.1** (the action image pins `ruby:3.3`).

### Everyday commands

Run these from the [`ruby/`](./ruby) folder.

| Command | What it does |
|---------|--------------|
| `bundle exec rake test` | Run the Minitest suite (27 tests) |
| `ruby -Ilib -Itest test/features_test.rb` | Run a single test file |
| `docker build -t boardly-rb .` | Build the Docker action image |

## Project layout

The Ruby port lives in [`ruby/`](./ruby):

```
lib/
  boardly.rb              # entrypoint: loads config, dispatches features
  boardly/
    config.rb             # YAML load + validation (mirrors the TS zod schema)
    model.rb              # normalized ProjectGraph / ProjectItem structs
    github/               # GraphQL queries + Net::HTTP client + normalization
    features/             # one module per feature (rollover, stale_nudge, …)
    notify/               # Slack + email channels + Notifier
    util/                 # date math, field accessors
    audit.rb              # job-summary audit trail
bin/boardly               # container entrypoint
test/                     # Minitest specs + fake client/channel
```

## Pull request checklist

1. **Branch** from `main` (or the current default branch).
2. **Add or update tests** in `ruby/test/` for any behavior change — the fake client/channel make this easy without hitting the real API.
3. **Run `bundle exec rake test`** — it must pass.
4. **Keep behaviour in parity** with the [main TypeScript project](https://github.com/cdrrazan/Boardly). The config schema, defaults, and outputs should stay identical across editions.
5. **Keep commits focused** and write clear messages (we loosely follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
6. **Update docs** — if you add a feature, add a [use-case](./docs/use-cases) and update the README feature table.

## CI & required checks

Pull requests run the Ruby suite (`bundle exec rake test`) and build the Docker image. Keep both green before requesting review, and please write [Conventional Commit](https://www.conventionalcommits.org/) PR titles — e.g. `feat: add X`, `fix(config): handle Y`.

## Adding a new feature

1. Create `ruby/lib/boardly/features/your_feature.rb` exposing a `run(ctx)` entry point.
2. Add its config shape (defaults + validation) to `ruby/lib/boardly/config.rb`, matching the upstream zod schema.
3. Register it in the feature dispatch in `ruby/lib/boardly.rb`.
4. Record every action via the audit trail and honor `dry-run` (never mutate when it's true).
5. Add tests and a use-case page.
6. Where practical, mirror the change in the [main TypeScript project](https://github.com/cdrrazan/Boardly) so both editions stay in sync.

## Reporting security issues

Please **do not** open a public issue for vulnerabilities — follow [SECURITY.md](./SECURITY.md) instead.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
