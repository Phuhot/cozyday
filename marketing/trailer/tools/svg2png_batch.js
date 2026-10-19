// node svg2png_batch.js <list.txt>: mỗi dòng "in.svg<TAB>out.png", nền trong suốt.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('fs');
(async () => {
  const lines = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean);
  const browser = await chromium.launch();
  const N = 6;
  let idx = 0;
  async function worker() {
    const page = await browser.newPage({ deviceScaleFactor: 1 });
    while (idx < lines.length) {
      const [inp, out] = lines[idx++].split('\t');
      const svg = fs.readFileSync(inp, 'utf8');
      const m = svg.match(/width="(\d+)" height="(\d+)"/);
      const w = +m[1], h = +m[2];
      await page.setViewportSize({ width: w, height: h });
      await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
      await page.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h }, omitBackground: true });
    }
  }
  await Promise.all(Array.from({ length: N }, worker));
  await browser.close();
})();
