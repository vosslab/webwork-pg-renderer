# Repository Guidelines

## Project Structure & Scope
- Purpose: a lightweight PG/PGML renderer/editor only; no LMS/grading or cloud deployment. K8s manifests are legacy/optional.
- App glue: `lib/RenderApp.pm` plus `lib/RenderApp/*` controllers/models. Treat `lib/PG` and `lib/WeBWorK` as vendored engine code.
- UI: `templates/` for Mojolicious views/layouts, `public/` for static assets (CodeMirror, navbar CSS/JS). Default editor text lives in `templates/columns/editorUI.html.ep`.
- Runtime: user-editable problems under `local_pg_files/` (mounted as `private/`), logs in `logs/`, config defaults in `render_app.conf.dist` (copy to `render_app.conf` locally).
- Entrypoints: `script/render_app` (morbo/hypnotoad), `docker-compose.yml` + `run.sh` for containers, `Dockerfile_with_OPL` only if you need OPL content.

## Build, Run, and Smoke Tests
- Local dev (no containers): `MOJO_MODE=development morbo script/render_app -l http://*:3000`.
- Daemon: `hypnotoad -f script/render_app`.
- Containers: `podman-compose build --no-cache && podman-compose up -d`; stop with `podman-compose down`.
- Smoke (server running): `perl script/smoke.pl` uses `Mojo::UserAgent` to hit `/health` and `/render-api` (avoids curl version flags). `./script/smoke.sh` remains for curl-based checks.
- Manual render example: `curl -X POST http://localhost:3000/render-api -H 'Content-Type: application/json' -d '{"sourceFilePath":"private/myproblem.pg","problemSeed":1234,"outputFormat":"classic"}'`.

## Coding Style & Conventions
- Perl with `strict`/`warnings`; prefer early returns and lexical variables. Keep package names in sync with file paths (`RenderApp::Controller::Render` → `lib/RenderApp/Controller/Render.pm`).
- Match nearby indentation (4-space preferred in new code), avoid large refactors inside vendored PG/WeBWorK unless necessary.
- Run `perltidy -pro=lib/PG/.perltidyrc <file>` when touching PG-side code.

## Testing Expectations
- No formal suite; always verify `GET /health` returns JSON and that `POST /render-api` renders `private/myproblem.pg` (or your file in `local_pg_files/`).
- When adjusting API params or defaults (seed, template, outputFormat), document the change in `README.md` and add a short reproduction snippet to the PR.
- Add small scripted checks under `script/` instead of altering vendored PG when you need coverage.

## Commits, PRs, and Safety
- Use short imperative subjects; keep unrelated changes split. PRs should include purpose, key changes, manual verification commands, and screenshots for UI tweaks.
- Never commit secrets; rely on `render_app.conf` and env vars (`MOJO_MODE`, `SITE_HOST`, `CORS_ORIGIN`, JWT secrets). Keep writable paths to `local_pg_files/` and `logs/`.

## Coding Style
See Python coding style in docs/PYTHON_STYLE.md.
See Markdown style in docs/MARKDOWN_STYLE.md.
See repo style in docs/REPO_STYLE.md.
When making edits, document them in docs/CHANGELOG.md.
Agents may run programs in the tests folder, including smoke tests and pyflakes/mypy runner scripts.

## Environment
Codex must run Python using `/opt/homebrew/opt/python@3.12/bin/python3.12` (use Python 3.12 only).
On this user's macOS (Homebrew Python 3.12), Python modules are installed to `/opt/homebrew/lib/python3.12/site-packages/`.
When in doubt, implement the changes the user asked for rather than waiting for a response; the user is not the best reader and will likely miss your request and then be confused why it was not implemented or fixed.
When changing code always run tests, documentation does not require tests.
