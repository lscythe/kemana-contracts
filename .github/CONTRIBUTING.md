# Contributing

Thank you for contributing. Keep changes focused, tested and easy to review.

## Before you start

1. Search existing issues and pull requests.
2. For a new contract or a change to an existing one, open an issue first so the shape can be agreed.
3. Run `mise install` and `hk install --mise` so the git hooks run locally.

## Branch flow

```text
feature/*, fix/*  →  develop  →  release/*  →  main
hotfix/*          →  main
```

| Branch | Created from | Merged into | Merge method |
|---|---|---|---|
| `feature/*` | `develop` | `develop` | Squash |
| `fix/*` | `develop` | `develop` | Squash |
| `release/*` | `develop` | `main`, then back into `develop` | Merge commit into `main` |
| `hotfix/*` | `main` | `main`, then back into `develop` | Merge commit into `main` |

`develop` and `main` are protected: changes go through pull requests, and force pushes and deletions are blocked. Merged branches are deleted automatically.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org) and are checked by the `commit-msg` hook:

```text
type(scope): summary
```

- **Types:** `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `revert`. Add `!` after the scope for a breaking change.
- **Scope:** a directory under `proto/`, joined with colons, such as `kemana:bundle:v1` or `kemana:bundle` (for a change across a whole directory), or one of the areas `build`, `ci`, `deps`, `tooling`, `docs`, `release`. The scope is optional for `ci` and `docs`.
- **Summary:** imperative, starts with a lowercase letter, no trailing period. The whole header is at most 72 characters.

Examples:

```text
feat(kemana:bundle:v1): add bundle manifest
fix(kemana:bundle:v1): correct the size field type
docs: describe the release flow
```

## Pull requests

- Use the pull request template.
- The pull request title must be a valid commit header: it becomes the squash commit on `develop`.
- One pull request is one complete change: the contract and its checks together. Keep unrelated changes out.
- A change that breaks wire or source compatibility must say so in the description and use the `!` marker in the title.
- Resolve all review conversations before merging.

## Contract style

- Contracts live under `proto/`, in a directory that mirrors the package name, for example `proto/kemana/bundle/v1/manifest.proto`.
- Formatting is done by `buf format`, run on commit. Run `mise run format` to format manually.
- Follow the buf STANDARD lint rules. Add a new version package (`v2`) instead of breaking an existing one.

## Local verification

```sh
mise run check
mise run test
```

`mise run check` runs `buf format --diff --exit-code`, `buf lint` and `buf build`. `mise run test` runs the commit scope tests. The `pre-push` hook runs both.

On every pull request CI runs the format check, lint, build and commit scope tests, plus `buf breaking` against the base branch. CI must pass before a pull request is merged.

## Secrets

Never commit tokens or personal data.
