const { mkdir, readFile } = require('node:fs/promises');
const { resolve } = require('node:path');
const { chromium } = require('playwright');

const sourceRoot = resolve(process.argv[2] || process.env.BIOLOGY_PROBLEMS_ROOT || '');
const baseUrl = (process.argv[3] || 'http://127.0.0.1:3000').replace(/\/$/, '');
const outputDir = resolve(process.argv[4] || '/tmp/webwork_renderer_gallery');
const executablePath = process.env.CHROMIUM_EXECUTABLE_PATH;
const fixtures = [
  ['fischer', 'problems/biochemistry-problems/carbs/classify_fischer.pgml'],
  ['ladder', 'problems/biochemistry-problems/electrophoresis/kaleidoscope_ladder/kaleidoscope_ladder_unknown_band.pgml'],
  ['inhibitor', 'problems/biochemistry-problems/enzymes/inhibitor_michaelis_menten_graph.pgml'],
  ['kinetics_table', 'problems/biochemistry-problems/enzymes/michaelis_menten_table_km.pgml'],
  ['transporter', 'problems/biochemistry-problems/membranes/identify_transporter_type.pgml'],
  ['amino_matching', 'problems/matching_sets/amino_acids_properties-matching.pgml']
];

async function renderProblem(relativePath) {
  const problemSource = await readFile(resolve(sourceRoot, relativePath), 'utf8');
  const response = await fetch(`${baseUrl}/render-api`, {
    method: 'POST', headers: { Accept: 'text/html', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
    body: new URLSearchParams({ problemSource, problemSeed: '1234', outputFormat: 'default' })
  });
  if (!response.ok) throw new Error(`${relativePath}: renderer returned ${response.status}`);
  return response.text();
}

async function waitForProblem(page) {
  await page.locator('body').waitFor();
  await page.waitForFunction(() => document.body.innerText.trim().length > 50);
  await page.waitForFunction(() => document.querySelectorAll('input, select, textarea, button').length > 0);
  await page.waitForFunction(() => [...document.images].every((image) => image.complete));
  await page.locator('body').evaluate(async () => {
    await document.fonts.ready;
    await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)));
  });
}

async function main() {
  if (!process.argv[2] && !process.env.BIOLOGY_PROBLEMS_ROOT) throw new Error('Usage: node devel/capture_problem_gallery.cjs /path/to/biology-problems [base-url] [output-dir]');
  await mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch(executablePath ? { executablePath } : {});
  try {
    for (const [name, relativePath] of fixtures) {
      const html = await renderProblem(relativePath);
      const context = await browser.newContext({ viewport: { width: 1100, height: 1000 }, deviceScaleFactor: 1 });
      await context.route(`${baseUrl}/gallery-render/${name}.html`, (route) => route.fulfill({ body: html, contentType: 'text/html; charset=utf-8' }));
      const page = await context.newPage();
      await page.goto(`${baseUrl}/gallery-render/${name}.html`, { waitUntil: 'networkidle' });
      await waitForProblem(page);
      await page.locator('body > .container-fluid').screenshot({ path: resolve(outputDir, `gallery_${name}.png`) });
      await context.close();
    }
  } finally { await browser.close(); }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
