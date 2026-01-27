# Changelog

## 2026-01-27
- Redact JWT-like strings in `script/lint_pg_via_renderer_api.py` output to keep logs readable.
- Strip hidden JWT input tags from `script/lint_pg_via_renderer_api.py` output.
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
- Add [docs/RENDERER_API_USAGE.md](docs/RENDERER_API_USAGE.md) with HTTP API usage and pglint notes.
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
- Add an instructor-focused [docs/USAGE.md](docs/USAGE.md) guide for local testing.
- Link the instructor guide from `README.md`.
