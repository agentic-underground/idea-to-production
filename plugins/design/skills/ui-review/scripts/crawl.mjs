#!/usr/bin/env node
/**
 * crawl.mjs — target-agnostic UI snapshot for DESIGN's /ui-review.
 *
 * Discovers the navigable surface of ANY running web app and photographs each route at one or more
 * viewports, then writes a self-contained gallery the reviewer reads with built-in vision (no API key).
 * This is the committed-snapshot fallback; the primary live path is the chrome-devtools MCP (mcp__chrome-devtools__*).
 *
 *   BASE_URL=http://localhost:5173 node crawl.mjs
 *
 * Config (all env vars, all optional except BASE_URL):
 *   BASE_URL    required — the running app's base URL (no default; never assume a port).
 *   ROUTES      comma-separated paths to visit instead of auto-discovery, e.g. "/,/dashboard,/settings".
 *   OUT         output dir (default: docs/guide/design/review/<YYYY-MM-DD>).
 *   VIEWPORTS   "desktop,mobile" (default) — desktop=1440×900, mobile=375×812.
 *   MAX_ROUTES  cap on auto-discovered routes (default 25) — avoids crawling an unbounded app.
 *   WAIT_MS     settle time after navigation (default 600).
 *
 * No hardcoded panels, selectors, or ports — it reads the DOM's own same-origin links. Bring your own
 * Playwright: it is loaded from the target project's node_modules, or a global install.
 */

import { mkdir, writeFile } from 'fs/promises';
import { createRequire } from 'module';
import { join } from 'path';

const BASE_URL = process.env.BASE_URL;
if (!BASE_URL) {
  console.error('DESIGN crawl: set BASE_URL to the running app (e.g. BASE_URL=http://localhost:5173). No port is assumed.');
  process.exit(2);
}
const today = new Date().toISOString().slice(0, 10);
const OUT = process.env.OUT || join('doc', 'design', 'review', today);
const SHOTS = join(OUT, 'screenshots');
const WAIT_MS = Number(process.env.WAIT_MS || 600);
const MAX_ROUTES = Number(process.env.MAX_ROUTES || 25);
const VIEWPORTS = (process.env.VIEWPORTS || 'desktop,mobile').split(',').map(s => s.trim()).filter(Boolean);
const SIZES = { desktop: { width: 1440, height: 900 }, mobile: { width: 375, height: 812 } };
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Load Playwright from wherever the target project has it installed.
async function loadChromium() {
  for (const base of [process.cwd(), join(process.cwd(), 'node_modules')]) {
    try { return createRequire(join(base, 'package.json'))('@playwright/test').chromium; } catch (_) { /* try next */ }
  }
  try { return (await import('playwright')).chromium; } catch (_) { /* fall through */ }
  console.error('DESIGN crawl: Playwright not found. Install it in the target project (npm i -D @playwright/test && npx playwright install chromium), or use the chrome-devtools MCP live path.');
  process.exit(3);
}

const slug = p => (p.replace(/^https?:\/\/[^/]+/, '') || '/').replace(/[^a-z0-9]+/gi, '-').replace(/^-|-$/g, '') || 'home';

async function discoverRoutes(page) {
  if (process.env.ROUTES) return process.env.ROUTES.split(',').map(s => s.trim()).filter(Boolean);
  const origin = new URL(BASE_URL).origin;
  const hrefs = await page.$$eval('a[href]', as => as.map(a => a.href));
  const paths = new Set(['/']);
  for (const h of hrefs) {
    try {
      const u = new URL(h);
      if (u.origin !== origin) continue;
      if (/\.(pdf|png|jpe?g|zip|csv|json)$/i.test(u.pathname)) continue;
      // Keep HashRouter routes (#/dashboard) as distinct routes; drop bare in-page anchors (#section),
      // which point at the same page and would only duplicate screenshots / waste the route budget.
      const hashRoute = u.hash.startsWith('#/') ? u.hash : '';
      paths.add(u.pathname + hashRoute);
    } catch (_) { /* skip malformed */ }
  }
  return [...paths].slice(0, MAX_ROUTES);
}

async function main() {
  const chromium = await loadChromium();
  await mkdir(SHOTS, { recursive: true });
  console.log(`DESIGN crawl — ${today}\n  base:   ${BASE_URL}\n  out:    ${OUT}\n  views:  ${VIEWPORTS.join(', ')}`);

  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  const gallery = [];

  try {
    await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 20000 });
    const routes = await discoverRoutes(page);
    console.log(`  routes: ${routes.length}${process.env.ROUTES ? ' (explicit)' : ' (discovered)'}`);

    for (const route of routes) {
      const url = new URL(route, BASE_URL).href;
      const name = slug(route);
      const shots = [];
      for (const vp of VIEWPORTS) {
        const size = SIZES[vp] || SIZES.desktop;
        await page.setViewportSize(size);
        try {
          await page.goto(url, { waitUntil: 'networkidle', timeout: 20000 });
          await sleep(WAIT_MS);
          const file = `${name}.${vp}.png`;
          await page.screenshot({ path: join(SHOTS, file), fullPage: false });
          shots.push({ vp, file });
        } catch (e) {
          console.warn(`  ⚠ ${route} [${vp}]: ${String(e.message).split('\n')[0]}`);
        }
      }
      if (shots.length) { gallery.push({ route, shots }); console.log(`  ✓ ${route}`); }
    }
  } finally {
    await browser.close();
  }

  const md = [
    `# UI snapshot — ${today}`,
    '',
    `Captured from \`${BASE_URL}\`. Run \`/ui-review\` to critique these against the design canon.`,
    '',
    ...gallery.flatMap(({ route, shots }) => [
      `## \`${route}\``,
      '',
      ...shots.map(s => `![${route} — ${s.vp}](screenshots/${s.file})`),
      '',
    ]),
  ].join('\n');
  await writeFile(join(OUT, 'README.md'), md, 'utf-8');
  console.log(`\n✓ ${gallery.length} routes captured → ${join(OUT, 'README.md')}`);
}

main().catch(err => { console.error('\nDESIGN crawl error:', err.message); process.exit(1); });
