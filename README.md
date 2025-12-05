# webwork-pg-renderer

A standalone PG problem renderer and editor derived from [WeBWorK](https://github.com/openwebwork/WeBWorK2), built for lightweight PG development, previewing, and local problem testing. This repo bundles PG 2.17, CodeMirror themes, and required JS/CSS so it can run offline.

**Scope:** Only render/test PG/PGML locally. It is not a full WeBWorK deployment; deployment/k8s artifacts are legacy/optional.

---

## 🔧 Features

- Web-based editor with live PG rendering
- API for automated problem rendering
- Embedded PG 2.17 engine (no submodules)
- CodeMirror themes served locally
- Lightweight Docker container using `podman-compose`

---

## 🚀 Quick Start (with Podman)

### 1. Clone the repo
```bash
git clone https://github.com/vosslab/webwork-pg-renderer.git
cd webwork-pg-renderer
```

### 2. Create a folder for local PG problems
```bash
mkdir local_pg_files
```

### 3. Build and run the container
```bash
podman build -t pg-renderer .
podman-compose down
podman-compose build --no-cache
podman-compose up -d
```

> Tip: `./run.sh` wraps the build/up/log tail steps if you prefer a single command.

### 4. Open the web interface
```bash
open "http://localhost:3000/"
```

### 5. Test a problem

A test file is already included: `private/myproblem.pg` (from `local_pg_files/`).
Use that path in the editor to load and render the PG problem.

### 6. Check logs (optional)
podman logs pg-test

### 7. Cleanup (optional)

```bash
podman-compose down
podman image prune
```

---

## 📁 Project Structure

```bash
webwork-pg-renderer/
├── lib/
│   ├── PG/                      # Embedded PG 2.17 (no submodule)
│   └── WeBWorK/                 # Vendored WeBWorK runtime pieces
├── templates/                  # Mojolicious HTML templates
├── public/                     # Static assets
├── script/
│   └── render_app              # App entrypoint
├── Dockerfile                  # Container build file
├── docker-compose.yml          # Container setup
├── run.sh                      # Launch script
└── local_pg_files/             # Your local PG problems (mounted as private/)
```

---

## 🧪 Editor UI

- Load a `.pg` problem from `private/yourfile.pg`
- Set a problem seed (e.g. `1234`)
- Select output format (see below)
- Edit and render in real-time
- Save edits back to the local file

![editor-ui](https://user-images.githubusercontent.com/3385756/129100124-72270558-376d-4265-afe2-73b5c9a829af.png)

---

## 🔌 Render API

### `POST /render-api`

Render PG problems programmatically using JSON POST requests.

### Common Parameters

| Key              | Type     | Description |
|------------------|----------|-------------|
| `sourceFilePath` | string   | Path to `.pg` file (e.g. `private/hello.pg`) |
| `problemSource`  | base64   | Inline encoded source (optional) |
| `problemSeed`    | number   | Random seed |
| `outputFormat`   | string   | `classic` (default), `static`, `practice`, etc. |
| `permissionLevel`| number   | 0 = student, 10 = prof, 20 = admin |
| `showHints`      | boolean  | Show hints |
| `showSolutions`  | boolean  | Show solutions |

### Output Formats

| Key       | Description |
|-----------|-------------|
| `static`  | Read-only, no buttons |
| `practice`| Show answers, check answers |
| `classic` | Preview and submit buttons |
| `simple`  | Show answers + preview + submit |
| `single`  | Single submit button |
| `nosubmit`| Editable but no buttons |

---

## 📦 Development Notes

- PG version: **2.17**
- CodeMirror version: **5.65.19**
- All required `.css` and `.js` assets are bundled locally
- jQuery: **1.12.4** (`lib/WeBWorK/htdocs/js/vendor/jquery/jquery-1.12.4.min.js`)
- jQuery UI: **1.12.1** (`lib/WeBWorK/htdocs/js/vendor/jquery/jquery-ui-1.12.1.min.js`, theme CSS in `.../jquery-ui-1.12.1/css/jquery-ui.css`)
- No submodules — just copy and go
- Renderer listens on port `3000`
- Default render format is `classic`; a random `problemSeed` is generated when none is provided
- Perl search path (inside the container): `/usr/app/lib/PG:/usr/app/lib/WeBWorK/lib:/usr/app/lib` (set via `PERL5LIB` in `Dockerfile` and `docker-compose.yml`)
- TikZ health check: `lib/PG/TikZImage.pm` is a minimal shim to satisfy `require TikZImage;` for `/health`
- Submit reliability: the client now binds clicks to all submit controls inside the rendered iframe (not just Bootstrap-styled buttons) so `submitAnswers` posts consistently
- Run `perl script/smoke.pl` (server running) for `/health` + render checks without curl version quirks; `script/smoke.sh` is kept for curl users
- See `ARCHITECTURE.md` for a walkthrough of the app flow and components
- Local lint/sanity: `script/lint.sh` runs `perl -c` across modules/scripts and shellcheck (if available) against `run.sh` and `script/smoke.sh`
- Tests: `prove -lr t` (includes `t/health.t`), `perl script/pg-smoke.pl` for a quick render canary
- Host note: `script/lint.sh` expects `Future::AsyncAwait 0.52+`; install via cpanm/apt/brew or run the lint inside the container (`podman exec pg-test ./script/lint.sh`)
- Dependencies: see `cpanfile` for CPAN module requirements; install locally with `cpanm --installdeps .` (e.g., `PERL_CPANM_HOME=$PWD/.cpanm PERL_CPANM_OPT='-L local' cpanm --installdeps .`)
  - `script/lint.sh` will attempt `cpanm --installdeps .` automatically if `cpanm` is available on the host.
- Quick env setup: `source script/dev-env.sh` to set `PERL5LIB` and cpanm paths for local work; this is handy before manual `cpanm` calls.
- Lint scope: host lint checks RenderApp core + safe controllers/models + TikZ shim; full PG/WeBWorK lint should be run inside the container via `podman exec pg-test ./script/lint-full.sh`
- Container lint/full-stack: `script/lint-full.sh` sets `PERL5LIB` for PG/WeBWorK trees and is intended to run inside the container (`podman exec pg-test ./script/lint-full.sh || true`)
- Docker deps split: apt for OS/XS-heavy Perl libs; `cpanfile`/`cpanm` for app-level Perl deps (installed into `/usr/app/local`) per Dockerfile comments
- UI polish: `public/navbar.css` themes the top bar; `public/pg-modern.css` restyles PG iframe buttons (just CSS, PG logic untouched)

### Health Check
`GET /health` returns JSON including mode, status, and detected jQuery/UI versions. A `tikzimage` flag verifies `TikZImage.pm` is loadable inside the container.

---

## 📝 License

[MIT License](LICENSE.md)  
Original source: [drdrew42/renderer](https://github.com/drdrew42/renderer) and [openwebwork/WeBWorK2](https://github.com/openwebwork/WeBWorK2)
