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
- Run `perl script/smoke.pl` (server running) for `/health` + render checks without curl version quirks; `script/smoke.sh` is kept for curl users
- See `ARCHITECTURE.md` for a walkthrough of the app flow and components

### Health Check
`GET /health` returns JSON including mode, status, and detected jQuery/UI versions. A `tikzimage` flag verifies `TikZImage.pm` is loadable inside the container.

---

## 📝 License

[MIT License](LICENSE.md)  
Original source: [drdrew42/renderer](https://github.com/drdrew42/renderer) and [openwebwork/WeBWorK2](https://github.com/openwebwork/WeBWorK2)
