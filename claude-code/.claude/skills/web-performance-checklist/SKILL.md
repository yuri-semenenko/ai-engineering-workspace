---
name: web-performance-checklist
description: Web performance checklist — Core Web Vitals (LCP/INP/CLS), TTFB diagnosis, and frontend levers (JS/CSS/fonts/images/network/rendering) plus backend (DB N+1, API latency, caching, infra). Use when optimizing performance, diagnosing a slow page or unresponsive interaction, setting a performance budget, or reviewing a perf-sensitive change.
---

# Web Performance Checklist

A concrete checklist for diagnosing and improving web performance. Measure before and after — optimize against field data, not hunches.

## Rationalizations (read first)

Pre-written rebuttals to the excuses that precede a skipped measurement. If you catch yourself thinking the left column, the right column is the answer.

| Rationalization | Rebuttal |
|---|---|
| "It's fast on my machine." | Your machine isn't the p75 user. Check field data (CrUX/RUM) and throttle to mid-tier Android. |
| "I'll add the index later." | An unindexed query degrades with data growth — later is an incident, not a task. |
| "Memoize everything to be safe." | `useMemo`/`useCallback` cost too. Without a profile they add overhead, not speed. |
| "The bundle's only a bit bigger." | Bloat compounds. Read the analyzer, not your gut — name the KB before adding the dep. |
| "It looks instant locally." | Local has no network or CPU throttle. Unverified under realistic conditions = unverified. |

## Core Web Vitals targets

| Metric | Good | Needs improvement | Poor |
|---|---|---|---|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## TTFB diagnosis

When TTFB is too high (> 800ms), check each component in the Network panel:

- [ ] Slow DNS → add `<link rel="dns-prefetch">` or `preconnect` for known origins.
- [ ] Slow TCP/TLS handshake → enable HTTP/2, consider edge deployment, check keep-alive.
- [ ] Slow server processing → profile the backend, find slow queries, add caching.

## Frontend

### Images
- [ ] Modern formats (WebP, AVIF).
- [ ] Responsive sizing (`srcset` + `sizes`).
- [ ] Explicit `width`/`height` on `<img>` and `<source>` (prevents CLS).
- [ ] Below-the-fold images use `loading="lazy"` and `decoding="async"`.
- [ ] Hero/LCP images use `fetchpriority="high"` and are not lazy-loaded.

### JavaScript
- [ ] Initial bundle < 200 KB gzipped.
- [ ] Code splitting via dynamic `import()` for routes and heavy features.
- [ ] Tree shaking enabled (dependency ships ESM, marked `sideEffects: false`).
- [ ] No render-blocking JS in `<head>` (use `defer`/`async`).
- [ ] Heavy computation offloaded to Web Workers where applicable.
- [ ] `React.memo()` on expensive components that re-render with identical props.
- [ ] `useMemo()`/`useCallback()` only where profiling shows real benefit.
- [ ] Long tasks (> 50ms) broken up — the main lever for INP.
- [ ] `yieldToMain` inside long loops so input can run between iterations.
- [ ] Modern scheduling where available: `scheduler.yield()` (preferred), `scheduler.postTask()` with priorities, `isInputPending()`.
- [ ] `requestIdleCallback` for deferrable work (analytics, prefetch, cache warming).
- [ ] Non-critical work moved out of event handlers (analytics, logging) so it doesn't delay interaction response.
- [ ] Third-party scripts `async`/`defer`, size-checked, facaded if heavy (chat widgets, embeds).

### CSS
- [ ] Critical CSS inlined or preloaded.
- [ ] No render-blocking CSS for non-critical styles.
- [ ] No CSS-in-JS runtime cost in production (extract to static CSS).

### Fonts
- [ ] 2–3 families max, 2–3 weights each (each weight is a request).
- [ ] WOFF2 only (skip WOFF/TTF/EOT).
- [ ] Self-hosted where possible (third-party font CDNs add DNS + TCP + TLS).
- [ ] LCP-critical fonts preloaded: `<link rel="preload" as="font" type="font/woff2" crossorigin>`.
- [ ] `font-display: swap` (or `optional` for non-critical) to avoid FOIT.
- [ ] Subsetted via `unicode-range` to ship only needed glyphs.
- [ ] Variable fonts considered when many weights/styles are needed.
- [ ] Fallback metrics tuned with `size-adjust`, `ascent-override`, `descent-override` to cut CLS on font swap.
- [ ] System font stack considered before adding any custom font.

### Network
- [ ] Static assets cached long `max-age` + content-hashed filenames.
- [ ] API responses cached where appropriate (`Cache-Control`).
- [ ] HTTP/2 or HTTP/3 enabled.
- [ ] `preconnect` configured for known third-party domains.
- [ ] `fetchpriority` used for critical non-image resources (key `<link rel="preload">`, above-the-fold `<script>`).
- [ ] No unnecessary redirects.

### Rendering
- [ ] No layout thrashing / forced synchronous layout.
- [ ] Animations use only `transform` and `opacity` (GPU-accelerated).
- [ ] Long lists virtualized (e.g. `react-window`).
- [ ] No unnecessary full-page repaints.
- [ ] Off-screen sections use `content-visibility: auto` + `contain-intrinsic-size`.
- [ ] No `unload` handlers and no `Cache-Control: no-store` on HTML — keeps bfcache eligible.

## Backend

### Database
- [ ] No N+1 query patterns (use eager loading / JOINs).
- [ ] Queries have appropriate indexes.
- [ ] List endpoints paginate (never `SELECT * FROM table`).
- [ ] Connection pooling configured.
- [ ] Slow-query logging enabled.

### API
- [ ] Response time < 200ms (p95).
- [ ] No heavy synchronous computation in request handlers.
- [ ] Bulk operations instead of per-item call loops.
- [ ] Response compression (gzip/brotli) enabled.
- [ ] Appropriate caching (in-memory, Redis, CDN).

### Infrastructure
- [ ] CDN for static assets.
- [ ] Server close to users (or edge deployment).
- [ ] Horizontal scaling configured where needed.
- [ ] Health-check endpoint for the load balancer.

## Measurement

INP field-data workflow:

1. Check field data first — [CrUX Vis](https://developer.chrome.com/docs/crux/vis) or your RUM for real-user INP before optimizing.
2. Find slow interactions — DevTools → Performance → record, interact, look for long tasks triggered by clicks/keypresses.
3. Test on mid-tier Android — INP issues often show only on slow hardware; use a real device or 4–6× CPU throttling.

```bash
# Lighthouse CLI
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# Bundle analysis
npx webpack-bundle-analyzer stats.json   # or: npx vite-bundle-visualizer

# Bundle size gate
npx bundlesize
```

```javascript
// Web Vitals in code
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log); onINP(console.log); onCLS(console.log);

// INP with per-interaction attribution
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const { interactionTarget, inputDelay, processingDuration, presentationDelay } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

## Common anti-patterns

| Anti-pattern | Impact | Fix |
|---|---|---|
| N+1 queries | Linear DB load growth | JOIN, includes, or batch loading |
| Unbounded queries | Memory exhaustion, timeouts | Always paginate, add LIMIT |
| Missing indexes | Slow reads as data grows | Index filter/sort columns |
| Layout thrashing | Jank, dropped frames | Batch DOM reads, then writes |
| Unoptimized images | Slow LCP, wasted bandwidth | WebP, responsive sizes, lazy-load |
| Large bundles | Slow TTI | Code split, tree shake, audit deps |
| Main-thread blocking | Poor INP, unresponsive UI | Break long tasks (`scheduler.yield()`), Web Workers |
| Memory leaks | Growing memory, crashes | Clean up listeners, intervals, references |

## Done when

You measured before and after on field-comparable conditions (not just your machine), the target metric moved in the right direction, and you can show the numbers. Otherwise the change is unverified, not done.
