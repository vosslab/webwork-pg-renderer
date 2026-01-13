# Code architecture

## Overview
- This repo builds a Mojolicious (Perl) web app that renders PG/PGML problems via a JSON API and
  optional UI.
- The primary workflow accepts a render request, loads PG source from a file or inline content,
  invokes the vendored PG engine, and returns formatted HTML plus metadata.

## Major components
- `script/render_app` boots Mojolicious and starts the `RenderApp` application.
- `lib/RenderApp.pm` initializes environment defaults, loads config, registers routes, and exposes
  `/health` plus `/render-api`.
- `lib/RenderApp/Controller/Render.pm` parses request parameters and JWTs, optionally fetches remote
  source, and coordinates rendering.
- `lib/RenderApp/Controller/RenderProblem.pm` runs the PG render pipeline via `WeBWorK::PG` and
  assembles the response payload.
- `lib/RenderApp/Controller/FormatRenderedProblem.pm` formats PG output into HTML and metadata.
- `lib/RenderApp/Controller/IO.pm` implements read/write, catalog, search, and upload endpoints for
  `private/` and OPL paths.
- `lib/RenderApp/Model/Problem.pm` encapsulates problem paths, source, seed, and render/save logic
  with path validation.
- `lib/PG/` and `lib/WeBWorK/` provide the vendored PG engine, macros, and static assets.
- `templates/` and `public/` hold the UI templates and static JS/CSS assets.
- `render_app.conf.dist` supplies default configuration loaded by Mojolicious (override with
  `render_app.conf`).

## Data flow
1. A client posts to `/render-api` with `sourceFilePath` or `problemSource` plus render options.
2. `RenderApp::Controller::Render` validates inputs, merges JWT claims, and instantiates
   `RenderApp::Model::Problem`.
3. `RenderApp::Model::Problem->render` calls
   `RenderApp::Controller::RenderProblem::process_pg_file`, which constructs a course environment
   and invokes `WeBWorK::PG`.
4. `RenderApp::Controller::FormatRenderedProblem` turns the PG result into HTML and response
   metadata.
5. The controller returns JSON that includes `renderedHTML`, answer data, flags, and diagnostics.

## Testing and verification
- `script/pg-smoke.pl` posts a render request and checks for expected HTML content.
- `script/smoke.sh` performs `/health` and `/render-api` smoke checks with curl.
- `script/lint.sh` runs host-side Perl syntax checks; `script/lint-full.sh` targets the full
  PG/WeBWorK tree inside a container.
- `tests/run_pyflakes.sh` is available for Python linting when Python scripts are added.

## Extension points
- Add new HTTP endpoints in `lib/RenderApp.pm` and implement handlers under
  `lib/RenderApp/Controller/`.
- Extend render output shaping in `lib/RenderApp/Controller/RenderProblem.pm` and
  `lib/RenderApp/Controller/FormatRenderedProblem.pm`.
- Add UI views under `templates/` and static assets under `public/`.
- Add helper scripts under `script/` and test utilities under `tests/`.
- Prefer wrapper code over edits in `lib/PG/` and `lib/WeBWorK/` unless engine changes are required.

## Known gaps
- Verify whether `script/smoke.pl` should exist; it is referenced in `script/lint.sh` and docs.
- Verify the README reference to `ARCHITECTURE.md` and update it to point at
  `docs/CODE_ARCHITECTURE.md` if needed.
