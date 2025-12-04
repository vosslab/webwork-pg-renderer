# Repository Guidelines

## Project Structure & Module Organization
- App wiring lives in `lib/RenderApp.pm` and `lib/RenderApp/*` (controllers, model); PG/WeBWorK engine is vendored under `lib/PG` and `lib/WeBWorK` (treat as third-party).
- UI: `templates/` (layout/navbar) and `public/` (JS/CSS, CodeMirror, navbar defaults).
- Config: `render_app.conf.dist` is the base; copy to `render_app.conf` for local overrides. Runtime: `logs/` for render logs, `local_pg_files/` for user problems.
- Entrypoints: `script/render_app` for `morbo`/`hypnotoad`; containers via `docker-compose.yml`, `Dockerfile`, `Dockerfile_with_OPL`. k8 manifests are legacy/optional and not required for the PG tester.
- Architecture reference: `ARCHITECTURE.md` for request flow and component roles.

## Build, Test, and Development Commands
- `podman build -t pg-renderer .` builds the image; `podman-compose up -d` starts the app on `localhost:3000` (logs via `podman logs -f pg-test`); `podman-compose down` stops and cleans up.
- Hot-reload development: `MOJO_MODE=development morbo script/render_app -l http://*:3000` (serves locally without containers).
- Production-like daemon: `hypnotoad -f script/render_app` (used in the compose service).
- Sample render check: `curl -X POST http://localhost:3000/render-api -d '{"sourceFilePath":"private/myproblem.pg","problemSeed":1234,"outputFormat":"static"}'`.
- Smoke check: with the server running, `./script/smoke.sh` (uses `/health` and `/render-api`; defaults to HTTP/1.0 for curl compatibility).

## Coding Style & Naming Conventions
- Perl 5.10+ with `strict`/`warnings` is the norm; prefer lexical `my` variables and early returns on guard clauses.
- Match surrounding indentation (tabs appear in existing files; align to 4-space columns when adding new code) and keep line lengths reasonable.
- Controllers and helpers live under `RenderApp::*`; keep filenames and package names in sync (e.g., `RenderApp::Controller::IO` in `RenderApp/Controller/IO.pm`).
- For PG internals touched under `lib/PG`, follow the bundled `.perltidyrc` by running `perltidy -pro=lib/PG/.perltidyrc <file>`.

## Testing Guidelines
- There is no automated suite; validate changes by hitting `GET /health` and rendering a known PG file (`private/myproblem.pg`) through the UI or the `curl` example above.
- When modifying API parameters or output, document the change in `README.md` and include a short reproduction note in the PR description.
- Use `script/smoke.sh` for a quick pass; add focused scripts under `script/` for new endpoints rather than changing vendored PG code.
- Scope reminder: this project exists only to render/test PG/PGML locally; don’t add LMS/gradebook or deployment complexity here.

## Commit & Pull Request Guidelines
- Use short, imperative commit subjects (recent history favors concise titles like “updated”, “new build system”); group related changes per commit.
- PRs should include: purpose, key changes, manual verification steps (commands/output), and screenshots/GIFs for UI-affecting work.
- Link issues or tickets when applicable and call out breaking API or configuration changes explicitly.

## Configuration & Security Tips
- Do not commit secrets; create `render_app.conf` locally from `render_app.conf.dist` and use environment overrides (`MOJO_MODE`, `baseURL`, `SITE_HOST`, `CORS_ORIGIN`, JWT secrets).
- Logs write to `logs/`; ensure writable permissions in local dev. Mount `local_pg_files/` for any sample or user-authored problems instead of editing embedded PG assets.
