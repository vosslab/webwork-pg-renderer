# Phase D Plan - lib/** (Submodule + High-Risk Integration)

Date: 2026-01-14
Doc-Type: PLAN
Status: Draft (no changes executed)
Scope: lib/** planning only; no file edits in this phase.

## Objective
Resolve lib/** strategy with minimal risk:
- Keep `lib/PG` as a submodule (gitlink) aligned with upstream.
- Preserve upstream renderer layout.
- Decide whether any parts of `lib/WeBWorK` should be vendored, replaced, or augmented.

## Guardrails
- No direct edits to `lib/PG` contents (submodule only).
- No bulk copying from master into `lib/`.
- Any change to `lib/WeBWorK` must preserve upstream renderer runtime semantics.
- All changes must be reversible and committed atomically.

## Current known state
- `lib/PG` is a submodule pointing to `https://github.com/openwebwork/pg.git` (branch `main`).
- `lib/WeBWorK` is a vendored subset in upstream renderer (not a submodule).
- Upstream renderer does **not** include `lib/WeBWorK/htdocs`.

## Decision areas (Phase D tasks)
1) **PG submodule pinning**
   - Decide whether to follow upstream commit pin, track `main`, or pin a specific release.
   - Confirm how updates should be handled (explicit bump vs. floating).
   - **Optional clarity:** record the exact `lib/PG` gitlink commit hash in `PORT_NOTES.md` whenever the submodule is updated.

2) **WeBWorK vendoring policy**
   - Confirm the minimal subset needed for renderer runtime.
   - Decide whether to keep upstream's vendored subset unchanged.
   - If differences from master exist, identify the minimal safe deltas (if any).
   - **Optional clarity:** perform a diff-audit of upstream renderer `lib/WeBWorK` vs master-link and record any deltas (file + rationale) before deciding changes.
   - **Diff-audit output format:** one line per file: `<path> - keep (needed by runtime)` or `<path> - remove (not used)` + one-line justification.

3) **Config and assets**
   - Ensure `lib/PG/conf/pg_config.yml` presence and lifecycle (copy at build vs runtime mount).
   - Confirm asset pipeline expectations between `public/` and `lib/PG/htdocs`.

4) **Testing gates (Phase D)**
   - Renderer starts (development mode).
   - `/health` returns JSON with dynamic versions.
   - One render request succeeds (`private/myproblem.pg`).
   - One OPL page loads (if OPL is available).
   - **baseURL prefix gate:** run with a non-empty `baseURL` and verify `/health` and one render still work (manual check is sufficient).

## Optional: Legacy asset mapping (deferred from Phase C)
- Map a legacy asset only if:
  - A template still references it **after** canonicalization, or
  - It provides functionality missing from upstream pipeline.
- If mapping is approved, document each mapping: legacy path -> canonical pipeline path.

## Next step (waiting on User)
- User selects specific Phase D decisions or confirms no lib/** changes beyond submodule.
