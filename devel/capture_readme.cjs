const { mkdir } = require('node:fs/promises');
const { resolve } = require('node:path');
const { chromium } = require('playwright');

const baseUrl = (process.argv[2] || 'http://127.0.0.1:3000').replace(/\/$/, '');
const outputDir = resolve(process.argv[3] || '/tmp/webwork_renderer_readme');
const executablePath = process.env.CHROMIUM_EXECUTABLE_PATH;

async function openSample(page) {
  await page.goto(`${baseUrl}/`, { waitUntil: 'networkidle' });
  await page.locator('#sourceFilePath').fill('private/sample.pg');
  await page.locator('#problemSeed').fill('1234');
  await page.locator('#load-problem').click();
  await page.locator('#render-status').filter({ hasText: /loaded/i }).waitFor();
  await page.locator('#render-button').click();
  const preview = page.frameLocator('#rendered-problem');
  await page.locator('#render-status').filter({ hasText: /rendered successfully/i }).waitFor();
  await preview.locator('#problem_body').getByText(/the structure of DNA/i).waitFor();
  await page.evaluate(() => document.fonts.ready);
  await preview.locator('body').evaluate(() => document.fonts.ready);
  const source = page.locator('.cm-scroller');
  await source.evaluate((scroller) => {
    // Start just above the sample's $topic setting used in the README walkthrough.
    const lineHeight = scroller.querySelector('.cm-line').getBoundingClientRect().height;
    scroller.scrollTop = 80 * lineHeight;
  });
}

async function openLibrarySample(page) {
  await page.goto(`${baseUrl}/opl`, { waitUntil: 'networkidle' });
  const files = page.locator('#file-list');
  await files.selectOption({ label: 'private' });
  await page.locator('#FileBrowserForm').getByRole('button').click();
  await files.locator('option', { hasText: 'sample.pg' }).waitFor();
  await files.selectOption({ label: 'sample.pg' });
  await page.locator('#FileBrowserForm').getByRole('button').click();
  await page.locator('#opl-status').filter({ hasText: /loaded.*sample.pg/i }).waitFor();
  const preview = page.frameLocator('#rendered-problem');
  await preview.locator('#problem_body').filter({
    hasText: 'Which one of the following statements is FALSE about the structure of DNA?'
  }).waitFor();
  await preview.locator('input[type="radio"]').nth(4).waitFor();
  await preview.locator('input:not([type])').waitFor({ state: 'detached' });
  await page.evaluate(() => document.fonts.ready);
  await preview.locator('body').evaluate(() => document.fonts.ready);
}

async function main() {
  await mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch(executablePath ? { executablePath } : {});
  try {
    const editor = await browser.newPage({ viewport: { width: 1360, height: 790 }, deviceScaleFactor: 1 });
    await openSample(editor);
    await editor.screenshot({ path: resolve(outputDir, 'renderer_editor.png'), fullPage: true });
    await editor.close();

    const library = await browser.newPage({ viewport: { width: 1600, height: 1000 }, deviceScaleFactor: 1 });
    await openLibrarySample(library);
    await library.screenshot({ path: resolve(outputDir, 'renderer_library.png') });
    await library.close();
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
