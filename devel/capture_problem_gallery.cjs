const { mkdir, readFile } = require('node:fs/promises');
const { resolve } = require('node:path');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const { chromium } = require('playwright');

const sourceRoot = resolve(process.argv[2] || process.env.BIOLOGY_PROBLEMS_ROOT || '');
const baseUrl = (process.argv[3] || 'http://127.0.0.1:3000').replace(/\/$/, '');
const outputDir = resolve(process.argv[4] || '/tmp/webwork_renderer_gallery');
const executablePath = process.env.CHROMIUM_EXECUTABLE_PATH;
const demoMode = process.argv.includes('--enzyme-demo');
const editorPreviewMode = process.argv.includes('--editor-previews');
const execFileAsync = promisify(execFile);
const detailPreviews = {
  kinetics_table: { width: 840, height: 557 },
  amino_matching: { width: 660, height: 340 }
};
const fixtures = [
  ['fischer', 'problems/biochemistry-problems/carbs/classify_fischer.pgml'],
  ['ladder', 'problems/biochemistry-problems/electrophoresis/kaleidoscope_ladder/kaleidoscope_ladder_unknown_band.pgml'],
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

async function captureEnzymeDemo(browser) {
  const name = 'enzyme_demo';
  const relativePath = 'problems/biochemistry-problems/enzymes/enzyme_simulation.pgml';
  const html = await renderProblem(relativePath);
  const frameDir = resolve(outputDir, 'enzyme_demo_frames');
  await mkdir(frameDir, { recursive: true });
  const context = await browser.newContext({ viewport: { width: 1100, height: 760 }, deviceScaleFactor: 1 });
  try {
    await context.route(`${baseUrl}/gallery-render/${name}.html`, (route) => route.fulfill({ body: html, contentType: 'text/html; charset=utf-8' }));
    const page = await context.newPage();
    await page.goto(`${baseUrl}/gallery-render/${name}.html`, { waitUntil: 'networkidle' });
    await page.locator('#esim_beaker, #esim_graph').first().waitFor();
    const simulation = page.locator('.enzyme-sim-wrap');
    await simulation.waitFor();
    await page.locator('#esim_run').click();
    for (let index = 0; index < 60; index += 1) {
      await simulation.screenshot({ path: resolve(frameDir, `frame-${String(index).padStart(3, '0')}.png`) });
      await page.waitForTimeout(1000 / 12);
    }
  } finally {
    await context.close();
  }
  const palettePath = resolve(frameDir, 'palette.png');
  const gifPath = resolve(outputDir, 'gallery_enzyme_demo.gif');
  await execFileAsync('ffmpeg', ['-y', '-framerate', '12', '-i', resolve(frameDir, 'frame-%03d.png'), '-vf', 'palettegen=stats_mode=diff', palettePath]);
  await execFileAsync('ffmpeg', ['-y', '-framerate', '12', '-i', resolve(frameDir, 'frame-%03d.png'), '-i', palettePath, '-lavfi', 'paletteuse=dither=bayer:bayer_scale=3', '-loop', '-1', gifPath]);
}

async function captureEditorPreviews(browser) {
  const editorFixtures = [
    ['fischer_editor', 'problems/biochemistry-problems/carbs/classify_fischer.pgml', 700, 'Part 1'],
    ['ladder_editor', 'problems/biochemistry-problems/electrophoresis/kaleidoscope_ladder/kaleidoscope_ladder_unknown_band.pgml', 590, 'Gel results:'],
    ['transporter_editor', 'problems/biochemistry-problems/membranes/identify_transporter_type.pgml', 540, 'Part A']
  ];
  for (const [name, relativePath, height, previewText] of editorFixtures) {
    const source = await readFile(resolve(sourceRoot, relativePath), 'utf8');
    const context = await browser.newContext({ viewport: { width: 1100, height: 820 }, deviceScaleFactor: 1 });
    try {
      await context.route(`${baseUrl}/render-api/tap`, (route) => route.fulfill({ body: source, contentType: 'text/plain; charset=utf-8' }));
      const page = await context.newPage();
      await page.goto(`${baseUrl}/`, { waitUntil: 'networkidle' });
      await page.locator('#sourceFilePath').fill(`private/${name}.pg`);
      await page.locator('#problemSeed').fill('1234');
      await page.locator('#load-problem').click();
      await page.locator('#render-status').filter({ hasText: /loaded/i }).waitFor();
      const beginOffset = source.indexOf('BEGIN_PGML');
      await page.locator('.cm-content').evaluate((content, ratio) => {
        const view = content.cmView?.view || content.closest('.cm-editor')?.cmView?.view;
        const position = view?.state.doc.toString().indexOf('BEGIN_PGML') ?? -1;
        if (view && position >= 0) view.dispatch({ selection: { anchor: position }, scrollIntoView: true });
        const scroller = content.closest('.cm-scroller');
        scroller.scrollTop = Math.max(0, ratio * (scroller.scrollHeight - scroller.clientHeight));
      }, Math.min(1, Math.max(0, beginOffset) / source.length + 0.025));
      await page.waitForTimeout(100);
      await page.locator('#render-button').click();
      await page.locator('#render-status').filter({ hasText: /rendered successfully/i }).waitFor();
      const frame = page.frameLocator('#rendered-problem');
      await frame.locator('#problem_body').waitFor();
      await page.addStyleTag({ content: `
        .editor-workspace > h1, .editor-pane-header, .preview-pane-header { display: none !important; }
        .editor-content, .preview-content { block-size: ${height}px !important; }
      ` });
      if (name === 'fischer_editor') {
        await frame.locator('body').evaluate(() => window.scrollTo(0, 0));
      } else {
        const previewTarget = name === 'transporter_editor'
          ? frame.locator('svg').first()
          : frame.getByText(previewText, { exact: false }).first();
        await previewTarget.evaluate((element) => window.scrollBy(0, element.getBoundingClientRect().top - 10));
      }
      await page.evaluate(() => document.fonts.ready);
      await frame.locator('body').evaluate(() => document.fonts.ready);
      const editorContent = page.locator('.editor-content');
      const previewContent = page.locator('.preview-content');
      const editorBox = await editorContent.boundingBox();
      const previewBox = await previewContent.boundingBox();
      if (!editorBox || !previewBox) throw new Error(`Could not measure editor panes for ${name}`);
      await page.screenshot({
        path: resolve(outputDir, `gallery_${name}.png`),
        clip: { x: editorBox.x, y: Math.min(editorBox.y, previewBox.y), width: previewBox.x + previewBox.width - editorBox.x, height }
      });
    } finally {
      await context.close();
    }
  }
}

async function main() {
  if (!process.argv[2] && !process.env.BIOLOGY_PROBLEMS_ROOT) {
    throw new Error('Usage: node devel/capture_problem_gallery.cjs /path/to/biology-problems [base-url] [output-dir] [--editor-previews | --enzyme-demo]');
  }
  await mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch(executablePath ? { executablePath } : {});
  try {
    if (demoMode) {
      await captureEnzymeDemo(browser);
      return;
    }
    if (editorPreviewMode) {
      await captureEditorPreviews(browser);
      return;
    }
    for (const [name, relativePath] of fixtures) {
      const html = await renderProblem(relativePath);
      const context = await browser.newContext({ viewport: { width: 1100, height: 1000 }, deviceScaleFactor: 1 });
      await context.route(`${baseUrl}/gallery-render/${name}.html`, (route) => route.fulfill({ body: html, contentType: 'text/html; charset=utf-8' }));
      const page = await context.newPage();
      await page.goto(`${baseUrl}/gallery-render/${name}.html`, { waitUntil: 'networkidle' });
      await waitForProblem(page);
      await page.locator('body > .container-fluid').screenshot({ path: resolve(outputDir, `gallery_${name}.png`) });
      const detail = detailPreviews[name];
      if (detail) {
        await page.setViewportSize({ width: detail.width, height: 1000 });
        await page.screenshot({
          path: resolve(outputDir, `gallery_${name}_preview.png`),
          clip: { x: 0, y: 0, ...detail }
        });
      }
      await context.close();
    }
  } finally { await browser.close(); }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
