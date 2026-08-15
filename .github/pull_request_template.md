<!-- Thanks for contributing to Boardly! Please fill this out so we can review quickly. -->

## What & why

<!-- What does this change do, and what problem does it solve? Link any related issue: "Closes #123". -->

## Type of change

- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 📝 Docs only
- [ ] ♻️ Refactor / chore

## Checklist

- [ ] `bundle exec rake test` passes from `ruby/`
- [ ] `docker build -t boardly-ruby .` succeeds from the repo root — that image *is* the shipped action
- [ ] Added/updated **tests** for the change
- [ ] Config shape, defaults, and validation stay in **parity with the [TypeScript edition](https://github.com/cdrrazan/Boardly)**, including dual `snake_case`/`camelCase` keys
- [ ] Rebuilt and committed **`dist/`** if the root `src/` reference edition changed (CI enforces this)
- [ ] Updated **docs** (README feature table and/or a `docs/use-cases` recipe) if behavior changed
- [ ] Commits follow the `type: summary` convention

## Notes for reviewers

<!-- Anything worth calling out: tradeoffs, follow-ups, screenshots of a run's audit trail, etc. -->
