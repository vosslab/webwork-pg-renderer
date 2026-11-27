# Playwright usage

How to use Playwright for browser automation and visual testing in this repo.

## Capture README screenshots

Start the renderer in development mode with [the README quick start](../README.md#quick-start).
For the library view, use a checkout where `private/` contains just the bundled `sample.pg`.
With Node.js and `cwebp` installed, run these commands from the repository root.

```bash
capture_dir=$(mktemp -d /tmp/webwork_readme.XXXXXX)
npm install --prefix "$capture_dir" --no-save --no-package-lock playwright
"$capture_dir/node_modules/.bin/playwright" install chromium
NODE_PATH="$capture_dir/node_modules" node devel/capture_readme.cjs \
  http://localhost:3000 "$capture_dir"

for view in renderer_editor renderer_library; do
  cwebp -q 90 "$capture_dir/$view.png" -o "$capture_dir/$view.webp"
  cp "$capture_dir/$view.webp" docs/screenshots/
done
```

The [capture script](../devel/capture_readme.cjs) opens the DNA question at seed `1234` in the
editor and library. Inspect both final WebPs before updating the README.

### Capture the problem gallery

The [gallery capture script](../devel/capture_problem_gallery.cjs) renders six questions from
[Biology Problems](https://github.com/vosslab/biology-problems) at seed `1234`. With the renderer
running, reuse `capture_dir` from the setup above. The first capture writes the complete problem
screenshots and tighter previews for the table and matching questions. The editor captures show
the PGML source beside its rendered question. The animation uses FFmpeg.

```bash
git clone https://github.com/vosslab/biology-problems.git "$capture_dir/biology-problems"
NODE_PATH="$capture_dir/node_modules" node devel/capture_problem_gallery.cjs \
  "$capture_dir/biology-problems" http://localhost:3000 "$capture_dir"

NODE_PATH="$capture_dir/node_modules" node devel/capture_problem_gallery.cjs \
  "$capture_dir/biology-problems" http://localhost:3000 "$capture_dir" --editor-previews

for png in "$capture_dir"/gallery_*.png; do
  webp="${png%.png}.webp"
  cwebp -q 90 "$png" -o "$webp"
  cp "$webp" docs/screenshots/
done

NODE_PATH="$capture_dir/node_modules" node devel/capture_problem_gallery.cjs \
  "$capture_dir/biology-problems" http://localhost:3000 "$capture_dir" --enzyme-demo
cp "$capture_dir/gallery_enzyme_demo.gif" docs/screenshots/
```

Inspect the code and rendered question in each editor capture. Play the GIF once to check the
motion in the beaker and the changes in the concentration graph.

## Install

Playwright is a dev dependency. If the repo does not already have a
`package.json`, create one first. Then install Playwright and its browsers:

```bash
npm init -y
npm install --save-dev playwright
npx playwright install
```

`npm init -y` creates a default `package.json` at the repo root. `npm install
--save-dev playwright` gets the `playwright` Node library and records it under
`devDependencies`. `npx playwright install` downloads browser binaries
(Chromium, Firefox, WebKit). If `package.json` already exists, skip
`npm init -y` and just run `npm install` (to pick up existing deps) followed
by `npx playwright install`.

## Key rule: scripts must run from the project root

Node resolves `import 'playwright'` by searching `node_modules/` starting from the
script's own directory and walking up. A script in `/tmp/` will not find the project's
`node_modules/`.

**Wrong:**

```bash
node /tmp/_test_game_ui.mjs
# Error: Cannot find module 'playwright'
```

**Right:**

```bash
cd /Users/vosslab/nsh/cell-culture-game-claude
node tests/test_game_ui.mjs
```

Put test scripts in `tests/` at the repo root, not in `/tmp/`.

## Packages

| Package | Purpose |
| --- | --- |
| `playwright` | Library/API for browser automation (what we use) |
| `@playwright/test` | Test runner with fixtures, assertions, reporters |
| `playwright-core` | Low-level core without bundled browsers (rarely needed) |

For "open a local HTML file, click things, take screenshots", use `playwright`.

## Script template

```javascript
import { chromium } from 'playwright';
import path from 'path';

const gamePath = path.resolve('cell_culture_game.html');
const url = `file://${gamePath}`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 900 } });
await page.goto(url);
await page.waitForTimeout(500);

// Interact with the page
await page.click('#welcome-start-btn');
await page.waitForTimeout(300);

// Screenshot
await page.screenshot({ path: 'test-results/screenshot.png' });

// Measure element positions
const box = await page.locator('#my-element').boundingBox();
console.log('Position:', box);

await browser.close();
```

Run with:

```bash
node tests/my_test.mjs
```

## Common patterns

### Click a hood item

Hood items use `data-item-id`:

```javascript
await page.click('[data-item-id="ethanol_bottle"]');
```

### Wait for animations

Use `waitForTimeout` after actions that trigger animations:

```javascript
await page.click('[data-item-id="flask"]');
await page.waitForTimeout(2500);  // aspiration takes ~2s
```

### Check element alignment

Use `boundingBox()` to compare positions of overlapping elements:

```javascript
const svgRect = await page.locator('#microscope-svg rect[fill="#e8f5e9"]').first().boundingBox();
const button = await page.locator('.quadrant-btn').first().boundingBox();
const dx = Math.abs(svgRect.x - button.x);
const dy = Math.abs(svgRect.y - button.y);
console.log(`Offset: dx=${dx.toFixed(1)} dy=${dy.toFixed(1)}`);
```

### Evaluate JavaScript in the page

```javascript
const result = await page.evaluate(() => {
    return document.querySelectorAll('.quadrant-btn').length;
});
console.log('Button count:', result);
```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `Cannot find module 'playwright'` | Run the script from the project root, not `/tmp/` |
| `browserType.launch: Executable doesn't exist` | Run `npx playwright install` |
| `npx playwright` works but `node script.mjs` fails | Different issue: npx resolves packages differently than Node require |
| Timeout clicking an element | Check the selector; use `data-item-id` not `data-item` for hood items |

## Verify install

```bash
npm ls playwright
```

Should show `playwright@x.x.x` under the project.

## File conventions

- Put Playwright scripts in `tests/` at the repo root. Mixing with pytest files
  (`test_*.py`) is fine; see [REPO_STYLE.md](REPO_STYLE.md).
- Use `.mjs` extension for ES module scripts (e.g., `tests/test_game_ui.mjs`).
- Put screenshots in `test-results/` (gitignored).
- `devel/` is reserved for one-off developer tools, not bulk test files.
