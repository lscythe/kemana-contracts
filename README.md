# kemana-contracts

Shared protobuf contracts and the bundle schema for a multi-operator transit app. Other repositories consume this one as a git submodule, so the contracts have a single source of truth.

## Layout

- `proto/`: the buf module. Directories mirror package names, for example `proto/kemana/bundle/v1/manifest.proto` declares `kemana.bundle.v1`.
- `buf.yaml`: buf v2 configuration (STANDARD lint, FILE breaking rules).
- `.github/`: CI, templates and the commit header check.

## Checks

Install the tools with [mise](https://mise.jdx.dev), then:

```sh
mise install
mise run check   # buf format --diff --exit-code, buf lint, buf build
mise run test    # commit scope tests
mise run format  # buf format -w
```

`mise install` also installs the git hooks (through a `postinstall` hook that runs `hk install --mise`): format and lint staged files on commit, check the commit header, and run `mise run check` and `mise run test` on push. All tool versions live in `mise.toml`; CI reads them from there. See [CONTRIBUTING](.github/CONTRIBUTING.md) for the branch flow and commit rules.

## Using it as a submodule

```sh
git submodule add https://github.com/lscythe/kemana-contracts.git contracts
git submodule update --init
```

Point your buf or protoc configuration at `contracts/proto`. To move to a newer revision:

```sh
git -C contracts fetch && git -C contracts checkout <tag-or-commit>
git add contracts
```

## License

Apache-2.0, see [LICENSE](LICENSE).
