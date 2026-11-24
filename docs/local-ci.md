# Local CI

`tool/local_ci.sh` runs Verily's check lanes on a developer machine and posts
one GitHub commit status per lane through `gh`, so a ruleset on `main` can
require them before a pull request merges.

## Running it

Push the branch, keep the working tree clean, then from the repository root:

```sh
tool/local_ci.sh
```

| Option          | Effect                                                                               |
| --------------- | ------------------------------------------------------------------------------------ |
| `--lane=<lane>` | Run only this lane (repeatable). Every default lane runs when omitted.               |
| `--also=<sha>`  | Post the same result on an ancestor commit, such as a lower layer of the same stack. |
| `--no-post`     | Run without posting statuses, for example before pushing.                            |

The script refuses to run on a working tree with uncommitted changes, checks
that `origin` matches `HEAD` when posting, holds `.git/local-ci/run.lock`, and
writes per-lane logs under `.git/local-ci/logs/<sha>/`.

## Lanes

Each lane is one `devenv` script, run as `devenv shell <lane>`:

| Lane                | What it checks                                                                                       |
| ------------------- | ---------------------------------------------------------------------------------------------------- |
| `lint:all`          | `dprint`, `nixfmt`, `cargo fmt`, `cargo audit`, Clippy, Pina lint + migrations, `ktlint`/`swiftlint`, `lk lint` |
| `test:kit`          | `cargo check --bin verily-kit` and `cargo test --workspace` across `verily_kit/`                     |
| `test:escrow`       | `verily_escrow` unit tests, SBF build, Pina IDL refresh, and Mollusk SPL Token suite                 |
| `test:server-image` | Opt-in: builds `verily_kit/Dockerfile` (`linux/amd64`), boots it against PostGIS, verifies `/healthz` |

Opt-in lanes run only when named explicitly:

```sh
tool/local_ci.sh --lane=test:server-image
```
