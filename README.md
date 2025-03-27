# webwork-pg-renderer

A standalone PG problem renderer and editor derived from [WeBWorK](https://github.com/openwebwork/WeBWorK2), built for lightweight use cases like PG development, previewing, and local problem testing. This version includes a self-contained copy of PG (v2.17), local CodeMirror themes, and no submodules.

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

### 4. Open the web interface
```bash
open "http://localhost:3000/"
```

### 5. Test a problem

A test file is already included: `private/myproblem.pg`
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
│   └── PG/                      # Embedded PG 2.17 (no submodule)
├── templates/                  # Mojolicious HTML templates
├── public/                     # Static assets
├── script/
│   └── render_app              # App entrypoint
├── Dockerfile                  # Container build file
├── docker-compose.yml          # Container setup
├── run.sh                      # Launch script
└── local_pg_files/             # Your local PG problems
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
| `outputFormat`   | string   | `static`, `practice`, `classic`, etc. |
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
- No submodules — just copy and go
- Renderer listens on port `3000`

---

## 📝 License

[MIT License](LICENSE.md)  
Original source: [drdrew42/renderer](https://github.com/drdrew42/renderer) and [openwebwork/WeBWorK2](https://github.com/openwebwork/WeBWorK2)
