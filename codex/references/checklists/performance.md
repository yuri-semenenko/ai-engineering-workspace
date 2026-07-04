# Performance Checklist

Use this reference when a change affects page rendering, data fetching, API latency, bundle size, images, caching, database queries, lists, maps, search, checkout, or user-visible loading behavior.

## Rationalizations

Excuses that precede a skipped measurement, paired with the answer. If you think the left, the right applies.

- "It's fast on my machine." -> Your machine is not the p75 user. Check field data and throttle to mid-tier mobile.
- "I'll add the index later." -> An unindexed query degrades with data growth. Later is an incident, not a task.
- "Memoize everything to be safe." -> Memoization costs too. Without a profile it adds overhead, not speed.
- "The bundle's only a bit bigger." -> Bloat compounds. Read the analyzer and name the KB before adding the dependency.
- "It looks instant locally." -> Local has no network or CPU throttle. Unverified under realistic conditions is unverified.

## Review Focus

- Critical path: identify what blocks first render, route transition, interaction, or API response.
- Data fetching: avoid duplicate requests, waterfalls, unbounded queries, and fetching fields the view does not use.
- Caching: use existing framework, CDN, app, or database cache patterns. Define invalidation before adding cache.
- Rendering: keep expensive computation out of render paths unless memoization or precomputation is justified by evidence.
- Bundle size: avoid adding dependencies for small utilities. Check whether code runs on client or server.
- Images and media: use responsive sizes, stable dimensions, lazy loading where appropriate, and avoid oversized source assets.
- Lists and tables: paginate, virtualize, or bound large collections. Keep filters and sorts close to the data source when practical.
- Database: check indexes, query shape, N+1 patterns, transaction scope, and payload size.

## Web Vitals And UX

- LCP: avoid blocking hero content on slow client-side work or unnecessary requests.
- CLS: reserve stable dimensions for images, ads, embeds, cards, tables, and dynamic controls.
- INP: keep event handlers short and defer non-critical work.
- Loading states: show progress for slow or remote work, but avoid skeletons that shift layout.
- Error and empty states: make retry or recovery cheap for the user.

## Verification

- Prefer targeted measurements over speculation: build output, bundle analyzer, database explain plan, runtime logs, browser profile, or framework metrics.
- For UI changes, smoke-test desktop and mobile viewports when a dev server is practical.
- For API changes, capture baseline and changed latency only when the risk justifies it.
- State residual uncertainty if performance was reasoned about but not measured.
