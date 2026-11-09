# Local CI

Verily has no hosted CI. `tool/local_ci.dart` runs the repository's check
lanes on a developer machine and posts one GitHub commit status per lane, so
a ruleset on `main` can require them before a pull request merges. It follows
the local CI that gates KickJump.

## Running it

Push the branch, keep the working tree clean, then from the repository root:

```sh
dart run tool/local_ci.dart
```

| Option          | Effect                                                                               |
| --------------- | ------------------------------------------------------------------------------------ |
| `--lane=<lane>` | Run only this lane (repeatable). Every lane that is not opt-in runs by default.      |
| `--also=<sha>`  | Post the same result on an ancestor commit, such as a lower layer of the same stack. |
| `--no-post`     | Run without posting statuses, for example before pushing.                            |

The tool refuses to run on a working tree with changes, so a run always
describes a commit. To post, it also checks that `origin` (a GitHub remote)
has exactly the checked-out commit for the branch, posts `pending` for every
lane, then `success` or `failure` for each as it finishes; interrupting it
posts `error`. A lane also fails if it changed the working tree or moved
`HEAD`. Statuses are posted through the `gh` login, so anyone who can push
can post them: the gate is the same trust boundary as the pre-push hook, not
a sandbox.

Logs are kept per commit under `.git/local-ci/logs/<sha>/` (the shared git
directory, so every worktree sees them), and `.git/local-ci/run.lock` allows
one run at a time.

## Lanes

Each lane is one devenv script, run as `devenv shell <lane>`, and its status
context is the script name. The default lanes cover `lint:all` and everything
`test:all` runs; a unit test (`test/tool/local_ci_test.dart`) fails when
`test:all` gains a script the lanes do not run.

| Lane                | What it checks                                                                          |
| ------------------- | --------------------------------------------------------------------------------------- |
| `lint:all`          | Formatting, Dart analysis, Pina and Clippy lints, escrow migrations, native lint, `lk lint` on `verily_kit` |
| `test:tools`        | Repository tooling, including this tool's lane table                                    |
| `test:lints`        | The Verily analyzer plugin's rules                                                      |
| `test:flutter`      | Flutter unit and widget tests for the app and brand packages                            |
| `test:server`       | Serverpod unit and integration tests and the shared evidence package, on local Postgres |
| `test:escrow`       | The escrow program's unit and Mollusk suites                                            |
| `test:server-image` | Opt-in: the linux/amd64 server image (below)                                            |
| `test:escrow:e2e`   | Opt-in: the escrow program on a throwaway validator, end to end against Postgres        |

Opt-in lanes run only when named, for example
`dart run tool/local_ci.dart --lane=test:escrow:e2e`. `test:escrow:e2e`
starts its own `solana-test-validator` and is slow; run it on any change to
the escrow program, its client, or the server's Solana gateway.

### The server image lane

`test:server-image` needs a running Docker or Podman machine (Docker,
OrbStack, or `podman machine`); without one it fails at once and says so. It
stays opt-in: Podman runs one machine at a time, so another project's VM can
block it, and a cold build under emulation takes 22 to 45 minutes. Run it on
any change to the Dockerfile, the compose file, the server's dependencies or
native libraries, the migrations, or the local-check replay.

On this Mac the machine is `verily-linux` (6 CPUs, 8 GiB). Podman's default
connection may name another machine, so select it explicitly:

```sh
podman machine start verily-linux
CONTAINER_CONNECTION=verily-linux dart run tool/local_ci.dart --lane=test:server-image
podman machine stop verily-linux
```

Production runs on Linux x64, the only Linux platform the MediaPipe runtime
is published for, so the image is pinned to `linux/amd64`. Apple Silicon
hosts build and run it under emulation: Podman's VM uses QEMU user emulation
(it disables Rosetta on kernel 6.13 and newer). That is slow but runs the
same binaries that deploy. With the build cached, the lane takes about 3.5
minutes. The lane:

1. Builds `verily_server/Dockerfile` twice from the same build stage: the
   `production` target (the default, what deploys) and `local-check-replay`,
   the production runtime plus the MediaPipe replay suite
   (`mp_local_check_replayer_test.dart`) compiled with `dart build cli`
   against the same native libraries.
2. Runs `local-check-replay`, which replays the pinned public fixtures (a
   thumbs-up photo, a cat-and-dog photo, and a speech clip, each checked by
   SHA-256) with the image's bundled MediaPipe and OpenCV libraries, its
   ffmpeg, and its baked models. Inside the image a missing piece fails the
   suite instead of skipping it, and each replay prints its scores.
3. Boots the production image in production mode with
   `VERILY_APPLY_MIGRATIONS=true` against the PostGIS service in
   `verily_server/docker-compose.yaml` (the `server` profile), with
   throwaway secrets and free local ports, and waits for `/healthz`.
4. Runs `tool/verify_schema_contracts.dart` against the migrated database,
   then removes the containers and their volume.

## Gating pull requests

Add a ruleset on `main` that requires the default lanes' statuses
(`lint:all`, `test:tools`, `test:lints`, `test:flutter`, `test:server`,
`test:escrow`), then run the tool on each pushed pull request branch.
Statuses belong to commits, so pushing again means running it again.

For a stack, run the tool on the top layer and pass each lower layer's head
with `--also`; those statuses name the commit that actually ran. Merge such a
stack as a whole, so `main` never stops at a layer that was not tested on its
own. To merge a lower layer alone, check it out and run local CI on it.
