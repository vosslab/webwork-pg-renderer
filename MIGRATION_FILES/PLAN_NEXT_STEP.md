# Migration plan (Execution checklist)
Doc-Type: EXEC_CHECKLIST
Authoritative checklist
Codex follows this file. MIGRATION_PLAN is context only.
Status: Plan only (no git commands by Codex)
Date: 2026-01-14
Owner: Dr. Voss
Repo baseline: openwebwork/renderer main
Version: 2026-01-14a
Last edited by: Codex
Read order: MIGRATION_PLAN first, then this file.
Stop conditions (execution gate): pause after each phase output artifact is produced; Codex runs no git commands.
Audience + Use: Read this when executing. Purpose: exact procedures + stop points.

## 1) Context and roles
- **User (Dr. Voss):** runs git commands, decides what is canonical, and approves any removals or workflow commits.
- **Codex:** edits files only, runs **no git commands**, and does not prompt for interaction.
This document is the **authoritative execution checklist**. `MIGRATION_PLAN.md` is an executive summary.

## 2) Objective
- Baseline is `openwebwork/renderer` `main`.
- Port selected non-`lib/` content from `webwork-pg-renderer-master-link` into the editable target.
- Preserve upstream-only files by default.
- Treat upstream asset pipeline as canonical unless explicitly overridden.

## 3) Inputs Codex must use (what they mean)
- **MANIFEST.master.txt:** filesystem list of master-link files (excluding `lib/` and excluded dirs) used to identify master-only and common files.
- **MANIFEST.target.txt:** filesystem list of target files used to identify target-only files and detect overlaps.
- **MASTER_ONLY_IMPORTED.txt:** list of files imported from master-link that do not exist in upstream; these are likely master additions.
- **TARGET_ONLY_RETAINED.txt:** list of files present in target but not in master; these are retained by default (no deletions).
- **PRESERVE_INDEX.txt:** mapping of overwritten files to preserved upstream snapshots under `preserve/upstream/`.
- **COMMON_DIFFS.md:** list of the 18 common-but-different files with diff magnitude, used to drive a focused review bundle.
- **UPSTREAM_vs_MASTER.md:** human-readable, feature-oriented comparison between upstream and master.
- **PORT_NOTES.md:** the running log of what was copied, preserved, restored, and excluded so far (canonical log name).

## 4) Constraints (MUST / MUST NOT)
- **MUST NOT** edit anything under `lib/**`.
- **MUST NOT** delete target-only files by default.
- **MUST** preserve upstream versions before overwriting any file.
- **MUST** quarantine master flat `public/*` assets as legacy unless explicitly mapped into upstream pipeline.
- **MUST** isolate workflow changes under `.github/workflows/` and mark them "optional" (gated by user script flags).
- **MUST NOT** run git commands.
- **MUST** merge template files one at a time, with a minimal check after each merge.

## 5) Execution phases (checklist)

### Phase A: Low-risk master-only additions
- **Scope:** master-only docs, scripts, tests, local helpers (`docs/**`, `script/**`, `tests/**`, `run.sh`, `docker-compose.yml`, `cpanfile`, `devel/**`, `private/**`).
- **Expected risk:** low (adds capability without changing core renderer structure).
- **Output artifacts:** updated `PORT_NOTES.md`, updated `MASTER_ONLY_IMPORTED.txt` if needed.
- **Pause point:** stop after additions; user reviews the added file list.
- **Acceptance check (minimal):** renderer starts, one OPL page loads, one editor page loads (plus container build if applicable).

### Phase B: Review bundle for 18 common-but-different files (no merges)
- **Scope:** only the 18 files listed in `COMMON_DIFFS.md`.
- **Expected risk:** medium/high (templates, root configs, script entrypoints).
- **Output artifacts:** a review bundle with one-paragraph "decision needed" note per file; no file merges yet.
- **Pause point:** stop after bundle creation; user decides per-file strategy.
- **Acceptance check (during merges):** after each **single template** merge, re-run the minimal check (renderer starts, one OPL page loads, one editor page loads).

### Phase C: Legacy public assets handling
- **Scope:** master flat `public/*` assets that conflict with upstream pipeline.
- **Expected risk:** high (can regress asset pipeline).
- **Output artifacts:** quarantine copies under `preserve/legacy-public/` plus an optional mapping plan to upstream pipeline sources.
- **Pause point:** stop after quarantine; user chooses whether to map or keep legacy assets isolated.
- **Mapping criterion:** map a legacy asset only if (a) a template still references it, or (b) it provides functionality missing from upstream.
- **Acceptance check (post-quarantine/mapping):** re-run the minimal check (renderer starts, one OPL page loads, one editor page loads).

## 6) Exact change procedure Codex must follow
For any file proposed to copy or overwrite:
1. If the target already has a different version, **first** write the current target (upstream) version to:
   - `preserve/upstream/<original-path>`
2. Then apply the master-link version to the target path.
3. Append an entry to `PORT_NOTES.md` with:
   - file
   - action (copied/overwritten/preserved/quarantined)
   - source (master or upstream)
   - reason
   - whether it touched canonical pipeline or legacy

4. Record manifest sanity info in `PORT_NOTES.md`:
   - total files in each manifest
   - total excluded/skipped count (sanity check that excludes are working as intended)

## 7) Go / No-Go checklist
- [ ] No `lib/**` edits
- [ ] No deletions
- [ ] Workflows isolated and optional
- [ ] Preservation paths defined and used before overwrite
- [ ] 18-file review bundle generated, **not merged**
- [ ] Legacy assets quarantined, **not mixed** into canonical paths
