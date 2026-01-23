# Changelog

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
