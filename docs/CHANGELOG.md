# Changelog

## 2026-08-08

### Fixes and Maintenance
- Build the main Podman image with Node.js 24 LTS instead of Ubuntu 24.04's
  Node.js 18 package so the current ESM-based asset dependencies can load.
- Migrate `public/generate-assets.js` from CommonJS to native ESM and use the
  current yargs parser API required by yargs 18.
- Refresh the public asset lockfile and use `npm ci` during the image build so
  `./run.sh` installs the dependency versions recorded in the repository.
- Add `devel/dist_clean.sh` with a safe preview mode for removing rebuildable
  dependency trees, generated renderer assets, and cross-language build caches
  while preserving runtime problems, logs, and Git metadata.

## 2026-04-22

### Behavior or Interface Changes
- `script/lint_pg_via_renderer_api.py --json` now drops the auth-token keys
  `JWT`, `sessionJWT`, `answerJWT`, and `problemJWT` from the response before
  printing, rather than masking each token with `<REDACTED_JWT>`. The
  previously observed ~2 KB of base64 at the top of the JSON dump (the
  2-part `problem` token inside the `JWT` wrapper that the three-dot regex
  could not match) is gone. Breaking change for any downstream caller that
  parsed those keys out of `--json` output; none are expected. `redact_tree`
  remains as a string-level backstop for any stray inline JWT in other
  fields, and continues to strip `<input name="...JWT" ...>` tags embedded
  inside `renderedHTML`.
- Added `--no-html` flag that, in `--json` mode, additionally drops the
  `renderedHTML` key from the output for workflows that only need the
  structured lint fields. Errors at argparse time if combined with `--html`
  or lint mode.
- `script/lint_pg_via_renderer_api.py` now sends `_format=json` on every render
  request so structured lint fields (`flags.error_flag`, `debug.pg_warn`,
  `debug.internal`, `debug.debug`) populate. The prose lint report in default
  mode becomes richer as a result.
- Added mutually exclusive `--json` and `--html` mode flags. Default (no mode
  flag) is still the human-readable lint report. `--json` prints the full
  renderer response, pretty-printed and JWT-redacted, for agents and
  automation. `--html` prints `response["renderedHTML"]`, JWT-redacted.
- Renamed `-o/--output-format` to `-t/--template` and restricted values to
  `static`, `default`, and `debug`. The default template changes from
  `classic` to `debug` to maximize diagnostic output in a linting workflow.
  This is a breaking behavior change for callers that relied on the previous
  default, independent of the flag rename.
- The `Using random seed: <int>` notice is suppressed in `--json` and
  `--html` modes so their stdout is clean, parseable payload. It still
  prints in lint mode.
- Mirrored the updated script to the `webwork-writer` skill copy at
  `vosslab-skills/skills/webwork-writer/references/scripts/lint_pg_via_renderer_api.py`;
  the two files are byte-identical.

### Removals and Deprecations
- Removed `-r/--render`, `-n/--no-render`, `-o/--output-format`, and
  `-b/--base-url` from `script/lint_pg_via_renderer_api.py`. Wrappers,
  Makefiles, CI jobs, and agent prompts that used those flags must update:
  `-r` becomes `--html`; `-n` drops entirely (it only named the default);
  `-o classic|ptx|raw` drops or remaps to `-t static|default|debug`;
  `-b` drops (the script now targets `http://localhost:3000` directly).

### Fixes and Maintenance
- Updated `script/HOW_TO_LINT.md` to reflect the new CLI and JSON-first
  response shape.
- Updated `vosslab-skills/skills/webwork-writer/references/linting.md` to
  document `--json`, `--html`, and the structured response fields.

## 2026-03-05

### Fixes and Maintenance
- Add http/https scheme validation to `script/pg-smoke.py` before `urlopen` to fix bandit B310 finding.

## 2026-01-29
- Remove lib/PG git submodule; now cloned directly in Dockerfile at PG-2.17+ tag.
- Add lib/PG/ to .gitignore since it is no longer tracked as a submodule.
- Update Dockerfile and Dockerfile_with_OPL to clone lib/PG during image build.
- Update README.md LOCAL INSTALL section to reflect direct PG clone instead of submodule.
- Remove PG submodule check from run.sh since lib/PG is now built into the container.

## 2026-01-28
- Normalize hash-based answers before safety filtering to fix RadioButtons grading in the PG 2.17 renderer.

## 2026-01-27
- Redact JWT-like strings in `script/lint_pg_via_renderer_api.py` output to keep logs readable.
- Strip hidden JWT input tags from `script/lint_pg_via_renderer_api.py` output.
- Refocus `script/HOW_TO_LINT.md` on HTML-first lint guidance, with JSON as a fallback.
- Restore the Show hints checkbox in the editor render controls.
- Wire PG 2.17 hint/solution display flags and permission levels so hints and solutions render during testing.

## 2026-01-26
- Add `script/HOW_TO_LINT.md` with host, container, and API lint guidance.
- Add `script/pg-smoke.py` as a Python 3.12 alternative to the Perl smoke check.
- Add `script/lint_pg_via_renderer_api.py` to lint or render local PG/PGML files via the renderer API.
- Note `script/lint_pg_via_renderer_api.py` in the lint guide.
- Align `script/lint_pg_via_renderer_api.py` argparse flags and imports with Python style rules.
- Default `script/lint_pg_via_renderer_api.py` to a random seed when none is provided.
- Document the random seed behavior in `script/HOW_TO_LINT.md`.
- Expand `script/HOW_TO_LINT.md` with TL;DR, decision table, prereqs, examples, and common errors.
- Move host/container Perl lint sections to a maintainer-only block in `script/HOW_TO_LINT.md`.
- Copy `lib/PG/htdocs/third-party-assets.json` into the container so PG 2.17+ asset generation succeeds.
- Copy the full `lib/PG/htdocs/` tree into the container to tolerate PG 2.17 and 2.19 asset layouts.
- Add a `lib/WeBWorK/PG.pm` shim so PG 2.17 renders can run without the upstream module.
- Make `lib/PG/lib/PGEnvironment.pm` load standalone defaults reliably and allow reads under `RENDER_ROOT`.
- Add a minimal `lib/WeBWorK/Constants.pm` stub and lazy-load the image generator so PG 2.17 can render without webwork2 constants.
- Default `PGEnvironment` DATA dir to the tmp folder for standalone runs.
- Treat PG 2.17 renders as standalone by clearing `MOJO_MODE` during translator setup.
- Add a `lib/WeBWorK/PG/Localize.pm` shim so module loading works across PG 2.17 and 2.19.
- Fall back to returning untranslated text when `maketext` fails in `lib/WeBWorK/Localize.pm`.
- Guard `AnswerHash::stringify_hash` when correct_value is not an object to avoid context-method errors in PG 2.17.
- Default `sourceFilePath` from the problem path or source URL to avoid missing probFileName warnings.
- Use a non-empty fallback (`private/inline.pg`) when the source has no path to suppress probFileName warnings.
- Default `CORS_ORIGIN` to `http://localhost:3000` instead of `*` in `render_app.conf.dist`.
- Prebuild `lib/PG/lib/chromatic/color` in the container to avoid runtime compiler warnings.

## 2026-01-23
- Truncate debug pretty-print output for sessionJWT, problemJWT, and problemSource values.
- Extend debug pretty-print truncation to answerJWT.
- Truncate any debug pretty-print fields ending in JWT, plus problemSource.
- Replace dice emoji in changelog entry with ASCII text for compliance.

## 2026-01-21
- Add randomize seed button (dice icon) next to seed input in navbar
- Reduce seed input width from 130px to 80px and apply monospace font
- Increase file path input maximum width by adjusting navbar space calculation

## 2026-01-15
- Add [RENDERER_API_USAGE.md](RENDERER_API_USAGE.md) with HTTP API usage and pglint notes.
- Expand the API usage doc with response examples, JWT flow, and lint key guidance.
- Document common parameter defaults and `problemSourceURL` response expectations.
- Add form-encoded and base64 `problemSource` examples to the API usage doc.
- Add `MIGRATION_FILES/LEGACY_TEMPLATE_PORT_PLAN.md` for porting preserved templates.
- Document lint-critical response schema and UI payloads in the API usage doc.
- Add pglint CLI behavior and parsing details to the API usage doc.
- Add lint error detection pseudo-flow guidance to the API usage doc.
- Add a pglint vs UI payload note for JSON vs form-data usage.
- Note container path requirements and recommend `problemSource` for pglint runs.
- Update pglint documentation to match the current root script defaults.
- Remove pglint-specific details from the API usage doc and keep general lint guidance.
- Merge JSON request bodies into render parameters (JSON overrides form/query).
- Document JSON request support and precedence in the API usage doc.
- Reformat `MIGRATION_FILES/LEGACY_TEMPLATE_PORT_PLAN.md` to match the legacy port plan style and include merge guidance.
- Record decision to keep canonical templates and skip legacy merges.

## 2026-01-13
- Update `docs/CODE_ARCHITECTURE.md` to reflect the current architecture and workflows.
- Add `docs/FILE_STRUCTURE.md` with the current repo layout and generated artifacts.
- Update `README.md` to align smoke/testing references and architecture doc links.
- Add a short "How rendering works" section to `README.md`.
- Remove emoji from `README.md` headings.
- Add an instructor-focused [USAGE.md](USAGE.md) guide for local testing.
- Link the instructor guide from `README.md`.
