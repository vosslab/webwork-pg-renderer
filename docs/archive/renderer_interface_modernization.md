# Plan: Modernize the WeBWorK renderer interface

## Context

Refresh the editor, problem library and tagging screen, generated problem pages, and HTML
errors. The renderer supplies accessible defaults that individual problems can override with
their own styles and assets.

## Objectives

- Make desktop and narrow workspaces usable with a keyboard and touch controls.
- Bundle the Atkinson fonts required by [FONT_STYLE.md](../FONT_STYLE.md).
- Preserve render, answer submission, load, save, browse, and tag workflows.
- Complete delivery through automated checks and independent agent assessments.

## Design philosophy

Apply **Keep it simple (KISS)**. Use a light workspace, deep navy navigation, white panels, and
a prominent Render action. Let normal document flow, Grid, Flexbox, and native controls do the
layout and interaction work. Keep style and behavior ownership local to each surface.

## Scope

- Update first-party templates, CSS, and browser JavaScript.
- Apply the defaults to standalone and JSON-derived problem HTML.
- Verify the complete interface in a disposable renderer checkout.

## Non-goals

PG evaluation, API schemas, framework migrations, and deployment policy stay with their existing
components.

## Milestone plan

| M | Title | Summary | Goal |
| --- | --- | --- | --- |
| 1 | Provision the renderer | Runtime owner provisions a scratch checkout using the existing container setup or isolated native dependencies. | A real sample renders, and health returns JSON. |
| 2 | Capture the baseline | Test owner installs the isolated Playwright runner while M1 proceeds. | Record route behavior and baseline captures after M1. |
| 3 | Bundle the fonts | Asset owner pins and licenses Next upright and italic and Mono upright in `public/fonts/`. | The asset build serves the three faces with system fallback stacks. |
| 4 | Build the shared shell | Shell owner uses the fonts and shared tokens, with named routes and landmarks. Depends on M3. | Both routes expose navigation and a visible focus state. |
| 5 | Reflow the editor | Editor owner uses a bounded editor and iframe in a normal-flow grid. Depends on M4. | Side-by-side from `60rem` and stacked below it, with reachable content. |
| 6 | Modernize render controls | Editor owner pairs native template and option controls with request handling. Depends on M5. | Keyboard selection, seed management, preview, and submission work. |
| 7 | Verify editor file operations | Editor owner preserves source encoding and load/save contracts. Depends on M6. | Unicode round trips, and failures preserve active source and preview. |
| 8 | Reflow the problem library | Library owner implements one, two, and three columns at the planned thresholds. Depends on M4. | Catalog navigation works with keyboard, click, and double-click. |
| 9 | Verify metadata and tags | Library owner uses plain-text metadata and synchronizes taxonomy. Depends on M8. | A tag change persists on a disposable problem. |
| 10 | Apply problem defaults | Render template owner loads scoped defaults ahead of authored assets. Depends on M3. | Direct and iframe HTML load local fonts and honor an authored override. |
| 11 | Replace the error screen | Shell owner supplies a static semantic page with escaped text. Depends on M4. | A real HTML error preserves status and is readable without JavaScript. |
| 12 | Verify the integrated build | Independent agents assess behavior, rendered layout, contrast, and repository checks. Depends on M7, M9, M10, and M11. | Required cases pass and regressions are corrected. |
| 13 | Close the handoff | Manager updates README instructions, screenshot, and changelog. Depends on M12. | Record evidence and close the plan locally. |

**Parallel-plan ready: yes.** Runtime, test setup, and fonts start independently. The editor,
library, generated HTML, and error work have explicit edit ownership. The manager gives each
failed case to its owner and reruns it with a fresh reviewer or tester assessment.

## Test and verification strategy

- Use the tracked `private/sample.pg` at seed `1234`. Copy it into scratch writable paths for file
  and tagging checks. Supply a small taxonomy and a stylesheet override fixture there.
- Keep the test server on loopback, capture diagnostics, and stop it after use. If the configured
  Podman runtime is unavailable, use isolated Perl dependencies, Node 24, and the pinned public
  PG source archive at `a29b85f259fac1924688a2a6f8b80b9715c4bc55`.
- Check health, API render, standalone and iframe HTML, editor save/load, answer submission,
  catalog and tag behavior, URL prefixing, and problem CSS precedence.
- Use Chromium, Firefox, and WebKit for rendered evidence. Check keyboard focus, zoom, pane
  geometry, loaded and blocked fonts, contrast, and readable error states. A separate reviewer
  evaluates desktop and narrow captures for hierarchy, readability, and unclipped controls.
- Run the asset build, syntax checks, and repository tests in a scratch checkout. Compare
  failures with the baseline before classifying them.

## Documentation close-out requirements

Update the editor instructions and quality-90 WebP screenshot. Record font provenance,
verification, and the visible changes in [CHANGELOG.md](../CHANGELOG.md). Remove temporary
test probes when their evidence is recorded. Archive the plan after the manager closes the work.

## Verification record

- Built the pinned public assets with Node 24. JavaScript syntax checks and `git diff --check`
  passed. Modern Web Guidance reported zero deterministic findings in `public/js` and
  `public/css`, down from two DOM clears in the JavaScript baseline.
- API smoke passed at the root and at `/renderer`. The tracked sample passed in default, static,
  and debug modes. All eight selected PG and PGML examples supplied by the user rendered. A
  failed file load returned a readable HTML 404 without JavaScript.
- Chromium, Firefox, and WebKit verified save and reload, answer submission, browsing and tag
  persistence, author CSS precedence in the preview, and desktop, tablet, and phone layouts.
  Chromium also verified author CSS in standalone HTML and font loading on the static
  installation check page at both base paths. A user-supplied example rendered six MathJax SVG
  equations under `/renderer`.
- A separate Chromium check verified a supplementary Unicode character through save and load.
  A failed load preserved the draft, and a translator error preserved the preview. A CSS 200%
  zoom simulation kept both editor panels usable without horizontal overflow.
- A delayed-render test confirmed that pending editor actions keep keyboard focus, prevent
  overlapping requests, and release controls after the response.
- The shell and editor loaded both bundled families. With font requests blocked, the editor and
  library reflowed at 320 CSS pixels and retained keyboard focus. Sampled interface text and
  controls measured at least 5.51:1. An independent review inspected the desktop and phone views.
- The repository test run recorded 1,147 passes and the baseline's five unrelated hygiene
  failures. The specialized `raw` and `outputFormat=json` API requests also reproduced baseline
  HTTP 500s. Direct HTML, regular JSON with `renderedHTML`, and `ptx` responses passed.
- Live verification used isolated native Perl dependencies and a scratch-only process-memory
  fallback for the macOS sandbox. The fallback was confined to the test checkout.
