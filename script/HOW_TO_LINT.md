# HOW TO LINT

This guide covers lint-related workflows in `script/` and how to use the renderer
API as a lint target when you need line-level diagnostics.

## Host-side Perl syntax checks

Run the host-safe lint that checks the core app, safe controllers/models, and a
PG shim without requiring a full PG/WeBWorK runtime:

```bash
./script/lint.sh
```

What it does (from `script/lint.sh`):
- Sets `PERL5LIB` to include repo and vendored paths.
- Installs `cpanfile` deps locally if `cpanm` is available (optional).
- Requires `Future::AsyncAwait` 0.52+ on the host.
- Runs `perl -c` on core app modules and safe controllers/models.
- Skips modules that require the full PG/WeBWorK stack.
- Optionally runs `shellcheck` on `run.sh` and `script/smoke.sh` if installed.

Common failure: missing `Future::AsyncAwait` 0.52+ on the host. If you hit this,
install it (for example via `cpanm`) or run the container lint described below.

## Full Perl syntax checks (container)

Run the full lint inside the container where PG/WeBWorK are available:

```bash
podman exec pg-test ./script/lint-full.sh
```

What it does (from `script/lint-full.sh`):
- Expects `PG_ROOT` and `WEBWORK_ROOT` (defaults to `/usr/app/lib/PG` and
  `/usr/app/lib/WeBWorK`).
- Sets `PERL5LIB` to include PG/WeBWorK libs.
- Runs `perl -c` across `.pm` files, with a special pass for `AnswerIO.pm` that
  preloads `ww_strict` and `PGUtil`.

If you are already inside the container, you can run:

```bash
./script/lint-full.sh
```

## Linting against the renderer API (localhost:3000)

If you are using the renderer as a lint target, post to `/render-api` and parse
the JSON response. The workflow and recommended error detection rules live in
[docs/RENDERER_API_USAGE.md](../docs/RENDERER_API_USAGE.md).

The helper script `script/pg_lint.py` wraps this flow for a local PG/PGML file,
prints the seed it uses, and defaults to a random seed when `--seed` is not set.

Example lint run with a random seed:

```bash
/opt/homebrew/opt/python@3.12/bin/python3.12 script/pg_lint.py \
  -i private/myproblem.pg
```

Example lint run with an explicit seed:

```bash
/opt/homebrew/opt/python@3.12/bin/python3.12 script/pg_lint.py \
  -i private/myproblem.pg -s 1234
```

Example request against a local server:

```bash
curl -X POST "http://localhost:3000/render-api" \
  -H "Content-Type: application/json" \
  -d '{
    "sourceFilePath": "private/myproblem.pg",
    "problemSeed": 1234,
    "outputFormat": "classic"
  }'
```

Suggested parsing order (per the API doc):
1) Check `flags.error_flag`.
2) Scan `debug.pg_warn`.
3) Scan `debug.internal` and `debug.debug`.
4) If needed, scan `renderedHTML` for warning blocks.

## Smoke checks (not lint)

These are quick server checks, not lint passes:
- `script/smoke.sh` hits `/health` and `POST /render-api` (set `BASE_URL`).
- `script/pg-smoke.pl` posts a render request (set `SMOKE_BASE_URL`).
