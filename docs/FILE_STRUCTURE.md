# File structure

## Top-level layout
- `AGENTS.md` defines repo workflow and agent instructions.
- `README.md` describes purpose, usage, and API parameters.
- `LICENSE.md` contains the project license text.
- `TODO.md` tracks local backlog items.
- `docs/` stores documentation files.
- `lib/` holds the Mojolicious app and vendored PG/WeBWorK code.
- `templates/` contains Mojolicious views and layouts.
- `public/` contains static CSS/JS assets for the UI.
- `script/` provides app entry points and tooling scripts.
- `tests/` contains test helper scripts.
- `local_pg_files/` stores user-editable PG problems (mounted as `private/` in containers).
- `logs/` stores runtime logs.
- `render_app.conf.dist` provides default configuration (copy to `render_app.conf`).
- `cpanfile` lists Perl dependencies.
- `Dockerfile`, `docker-compose.yml`, and `run.sh` define container build and run workflows.

## Key subtrees
- `lib/RenderApp/` contains the application code.
- `lib/RenderApp/Controller/` implements HTTP handlers (rendering, IO, UI pages).
- `lib/RenderApp/Model/` holds the problem model.
- `lib/PG/` is the vendored PG engine and assets.
- `lib/WeBWorK/` is the vendored WeBWorK runtime and assets.
- `templates/columns/`, `templates/pages/`, and `templates/layouts/` organize UI views.

## Generated artifacts
- Local config overrides in `render_app.conf` are ignored.
- Runtime outputs under `private/`, `tmp/`, and `logs/*.log` are ignored.
- Render artifacts under `lib/WeBWorK/htdocs/tmp/renderer/` and JSON under
  `lib/WeBWorK/htdocs/DATA/*.json` are ignored.
- Dependency caches and build outputs such as `node_modules/`, `.cpan/`, `.cpanm/`, `local/`,
  `*.o`, `*.pm.tdy`, and `*.bs` are ignored.
- OS and editor artifacts like `.DS_Store`, `.idea/`, `*.swp`, and `*.swo` are ignored.

## Documentation map
- Documentation lives under `docs/` and follows [docs/MARKDOWN_STYLE.md](MARKDOWN_STYLE.md) and
  [docs/REPO_STYLE.md](REPO_STYLE.md).
- Root docs include [README.md](../README.md), [AGENTS.md](../AGENTS.md),
  [LICENSE.md](../LICENSE.md), and [TODO.md](../TODO.md).
- Change history lives in [docs/CHANGELOG.md](CHANGELOG.md).

## Where to add new work
- Add app logic in `lib/RenderApp.pm`, `lib/RenderApp/Controller/`, and `lib/RenderApp/Model/`.
- Add UI templates in `templates/` and static assets in `public/`.
- Add scripts in `script/` and test helpers in `tests/`.
- Add local PG problems in `local_pg_files/` (served as `private/`).
- Add documentation in `docs/` with ALL CAPS filenames per [docs/REPO_STYLE.md](REPO_STYLE.md).
- Avoid edits to `lib/PG/` and `lib/WeBWorK/` unless engine changes are required.
