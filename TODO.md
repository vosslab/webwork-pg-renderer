# TODO / Stability & Maintenance

A grab-bag of things that would make the renderer less fragile, easier to debug, and more pleasant to work on.

---

## 1. Frontend robustness (submit flow, iframe, editor)

- **Submit / form handling**
  - [ ] Server-side detection for missing submit controls: if rendered HTML has no submit buttons, emit a warning in the JSON debug block and log it.
  - [ ] In the iframe client, surface submit errors as UI toasts instead of only `console.warn` (e.g., “Submit failed: no submit button found”).
  - [ ] Log clearly (in console) when:
    - [ ] The main problem form cannot be found.
    - [ ] The submit handler fails to bind.
    - [ ] A fetch to `/render-api` rejects or times out.

- **Debug tooling**
  - [ ] Keep `window.dumpProblemDebug()` (or similar) available in development:
    - [ ] Dump presence of main form, all submit controls, and the last clicked button.
    - [ ] Optionally show a small on-page status panel (dev-only) with:
      - Last render status
      - Last submit status
      - Whether submit buttons were detected

- **CodeMirror + editor UI**
  - [ ] Periodically confirm CodeMirror version is still current for the 5.x line (right now: 5.65.19/20).
  - [ ] Add a lightweight “editor self-test”:
    - [ ] Load a known PG snippet into the editor.
    - [ ] Trigger render.
    - [ ] Assert the iframe reflects updated content (manual or automated test).
  - [ ] Debounce the “Render contents” button to avoid overlapping POSTs if the user double-clicks.

- **Iframe lifecycle**
  - [ ] Disable “Submit Answers” while a render is in-flight; re-enable on success/failure.
  - [ ] Handle iframe load errors (e.g. network failures) with user-visible messaging.

---

## 2. Health checks & smoke tests

- **/health improvements**
  - [ ] Extend `/health` to:
    - [ ] Confirm jQuery and jQuery UI versions by parsing the actual bundled files (already partially done).
    - [ ] Verify presence of key static assets (CodeMirror core, PG mode, MathQuill, navbar.js) and report missing/404 as warnings.
    - [ ] Report whether TikZImage loaded successfully (`tikzimage: true/false`) with a clear reason if false.

- **Smoke scripts**
  - [ ] Keep `script/smoke.sh` but:
    - [ ] Rely on HTTP/1.1 (no forced 1.0) and fail fast with good error messages.
    - [ ] Verify `/health` JSON includes expected fields (jquery, jquery_ui, codemirror, pg, tikzimage).
    - [ ] Exercise `/render-api` with:
      - [ ] A known-good PG file.
      - [ ] A problem that uses TikZ/Images (once available).
  - [ ] Consider a small **Perl** or **Python** smoke test using Mojolicious or `requests` that:
    - [ ] GETs `/`.
    - [ ] Renders a sample problem.
    - [ ] Submits an answer and checks that the response HTML contains the “results” region.

---

## 3. Docker / run.sh / environment

- **Container build**
  - [ ] Make sure the Dockerfile:
    - [ ] Copies `lib/PG/TikZImage.pm` into a path on `@INC` and verifies it (`perl -MTikZImage -e 'print "ok\n"'`) during build.
    - [ ] Fails the build if TikZImage (or any required PG shim) can’t load.
  - [ ] Keep maintainer metadata up to date:
    - [ ] Label with `Neil Voss` and GitHub URL instead of an email.
  - [ ] Avoid unnecessary `--no-cache` rebuilds:
    - [ ] Split Dockerfile so code changes rebuild only the upper layer, not base packages.

- **run.sh**
  - [ ] Keep the “long-running, Ctrl-C to stop” behavior:
    - [ ] Start `podman-compose up`.
    - [ ] On Ctrl-C, call `podman-compose down` to avoid zombie containers.
  - [ ] Add options:
    - [ ] `./run.sh fast` → skip image rebuild, just `podman-compose up`.
    - [ ] `./run.sh rebuild` → full rebuild (current behavior).
  - [ ] Print a short summary on startup:
    - [ ] Health endpoint URL.
    - [ ] Sample PG path.
    - [ ] Current deps as reported by `/health`.

---

## 4. Automated tests (UI + server)

- **Integration tests**
  - [ ] Add a headless browser test suite (Playwright / Cypress / Selenium):
    - [ ] Scenario: load `/`, type a known PG path, click Render, assert the iframe updates.
    - [ ] Scenario: type an answer, click Submit, assert:
      - A POST to `/render-api` with `submitAnswers` is made.
      - The response includes a recognizable result (e.g., “Correct” or “Incorrect”).
  - [ ] Add a CLI test to render a batch of sample PG files:
    - [ ] Use the existing `sample*.pg` set.
    - [ ] Fail fast if any render returns an error or non-200.

- **Unit-ish tests**
  - [ ] Extract `/health` logic into a small module that can be tested outside of Mojolicious.
  - [ ] Add tests for:
    - [ ] Version parsing from JS/CSS headers.
    - [ ] TikZImage detection.

---

## 5. Dependency hygiene (jQuery, jQuery UI, CodeMirror, PG)

- **JS library sanity**
  - [ ] Periodically re-evaluate:
    - [ ] jQuery 1.12.4 → keep for now, but document that it’s “legacy, pinned for compatibility”.
    - [ ] jQuery UI 1.12.1 → same treatment.
    - [ ] CodeMirror 5.65.x → track only patch updates (e.g., 5.65.20) unless we explicitly migrate to CodeMirror 6.
  - [ ] Keep a single source of truth for these versions:
    - [ ] `/health` output.
    - [ ] README.
    - [ ] Dockerfile comments.

- **PG / TikZImage**
  - [ ] Document TikZImage behavior:
    - [ ] Where it lives (`lib/PG/TikZImage.pm`).
    - [ ] How `/health` decides `tikzimage: true/false`.
  - [ ] If PG or TikZ support is optional:
    - [ ] Make failure explicit in `/health` (and not just logs).

---

## 6. Developer ergonomics

- **Docs**
  - [ ] Expand `README.md` with:
    - [ ] “Quick dev loop” instructions (edit code → `./run.sh fast` → browser).
    - [ ] How to debug submit issues (console, Network tab, `dumpProblemDebug()`).
    - [ ] Explanation of `/health` output fields.
  - [ ] Add a short **“Conventions”** section:
    - [ ] How JS assets are versioned.
    - [ ] Where to add new health checks.
    - [ ] How to add a new PG macro shim like TikZImage.

- **Logging**
  - [ ] Normalize server logs for render vs submit:
    - [ ] Prepend `[RENDER]` or `[SUBMIT]` to log messages based on presence of `submitAnswers`.
  - [ ] Optionally add a `debug` flag in config to increase verbosity for a single session (helpful when chasing weird bugs).

---

## 7. Nice-to-haves (later)

- [ ] Consider a “safe mode” that renders problems without any external JS/CSS (no MathQuill, no fancy widgets) for debugging PG issues.
- [ ] Add a tiny status badge on the UI that reflects `/health` (green/yellow/red based on deps and TikZ availability).
- [ ] Explore switching from handwritten JS glue to a small module that owns the whole “render + submit + iframe” state machine.
