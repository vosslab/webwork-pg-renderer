# Architecture Overview

This repo’s sole purpose is to locally render and test WeBWorK PG/PGML problems. It is not a full WeBWorK stack; deployment artifacts (e.g., k8 manifests) are optional and not maintained as first-class targets.

## High-Level Layout
- **Entry & Routing**: `script/render_app` boots Mojolicious. `lib/RenderApp.pm` wires routes, helpers, env defaults, and passes requests to controllers.
- **App Logic**: `lib/RenderApp/Controller/*` handles endpoints. `RenderProblem` orchestrates rendering; `IO` covers file reads/writes/uploads/search; `FormatRenderedProblem` shapes HTML output per template.
- **Domain Model**: `lib/RenderApp/Model/Problem` abstracts a PG problem (paths, contents, seed, render/save).
- **PG Engine**: `lib/PG` and `lib/WeBWorK` bundle the math rendering engine/macros (including TikZ support). Treat as vendor code unless you know PG internals.
- **UI**: `templates/` (navbar/layout) + `public/` (JS/CSS assets, CodeMirror). The editor posts to `/render-api`, `/render-api/can`, `/render-api/tap`, etc.
- **Runtime Assets**: `local_pg_files/` is the writable mount for user problems (exposed as `private/` in the UI/API); `logs/` holds render logs; `render_app.conf.dist` is the base config (copy to `render_app.conf`).
- **Health/Observability**: `/health` returns JSON (mode, status, jQuery/UI versions, TikZImage availability) and is the quickest way to confirm dependencies are loaded inside the container.

## Request Flow (Render API)
1) Client/Editor `POST /render-api` with `sourceFilePath` or base64 `problemSource`, `problemSeed`, `outputFormat`, flags. Default output format is `classic`; seed defaults to a random int if omitted.
2) `RenderApp::Controller::RenderProblem::process_pg_file` resolves the source, merges defaults, and invokes `process_problem`.
3) `standaloneRenderer` (inside `RenderProblem`) builds a fake course/user env, sets display options, and calls `WeBWorK::PG->new` with the PG engine.
4) `FormatRenderedProblem` maps the PG result into an HTML template (`WebworkClient/*_format.pl`) and returns JSON (rendered HTML + metadata).

## File IO Flows
- **Load**: `/render-api/tap` -> `IO::raw` -> `Model::Problem->load` from `read_path` rooted in `private/` (`local_pg_files/` on disk).
- **Save**: `/render-api/can` -> `IO::writer` -> `Model::Problem->save`; writes are constrained to `private/` paths.
- **Catalog/Search**: `/render-api/cat` and `/render-api/find` spawn subprocess traversals rooted in `private/` or OPL paths with depth guards.

## Configuration & Defaults
- Env vars set in `RenderApp.pm` (`RENDER_ROOT`, `WEBWORK_ROOT`, `OPL_DIRECTORY`, `MOJO_CONFIG`). Copy `render_app.conf.dist` to override (CORS, JWT secrets, baseURL/formURL, cache headers).
- Service defaults: `MOJO_MODE=development`, port `3000`, `outputFormat=classic`, random seed if missing.
- Non-goals: LMS integration, grading pipelines, or production deployment; k8 manifests are legacy/optional. Bundled assets (jQuery/UI, CodeMirror) are local to keep the renderer offline-friendly.
- Perl load path: `PERL5LIB` must include `/usr/app/lib/PG:/usr/app/lib/WeBWorK/lib:/usr/app/lib` (set in both `Dockerfile` and `docker-compose.yml`) so `TikZImage.pm` and other PG shims load for `/health`.
- Client UI: navbar JS now binds submit clicks to any submit control rendered inside the iframe (not only `.btn-primary`) to ensure `submitAnswers` posts reliably across formats.
- Visual styling: `public/navbar.css` handles the top toolbar; PG iframe buttons are restyled via `public/pg-modern.css` (added through `$extra_css_files`).

## Operational Notes
- For dev without containers: `MOJO_MODE=development morbo -l http://*:3000 script/render_app`.
- Smoke: `perl script/smoke.pl` (uses `Mojo::UserAgent`); `script/smoke.sh` is available if you prefer curl.
- Vendor PG/WeBWorK code is heavy; prefer wrapping rather than editing unless you need engine changes.
