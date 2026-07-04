---
name: Performance Standards
description: Performance review guidance for rendering, data fetching, bundles, queries, and Core Web Vitals.
applyTo: "**"
---

# Performance Standards

Apply when a change affects page rendering, data fetching, API latency, bundle size, images, caching, database queries, large lists, or user-visible loading behavior.

## Rationalizations

Excuses that precede a skipped measurement, paired with the answer. If you think the left, the right applies.

- "It's fast on my machine." -> Your machine is not the p75 user. Check field data and throttle to mid-tier mobile.
- "I'll add the index later." -> An unindexed query degrades with data growth. Later is an incident, not a task.
- "Memoize everything to be safe." -> Memoization costs too. Without a profile it adds overhead, not speed.
- "The bundle's only a bit bigger." -> Bloat compounds. Read the analyzer and name the KB before adding the dependency.
- "It looks instant locally." -> Local has no network or CPU throttle. Unverified under realistic conditions is unverified.

## Check

- Critical path: know what blocks first render, route transition, interaction response, or API result, and keep it short.
- Data fetching: avoid duplicate requests, waterfalls, unbounded queries, and fetching fields the view does not use.
- Caching: reuse existing framework, CDN, app, or database cache patterns, and define invalidation before adding a cache.
- Rendering: keep expensive computation out of render paths unless memoization or precomputation is justified by evidence.
- Bundle size: do not add a dependency for a small utility, and check whether code runs on the client or the server.
- Images and media: responsive sizes, stable dimensions, lazy loading where appropriate, and no oversized source assets.
- Lists and tables: paginate, virtualize, or otherwise bound large collections, and keep filters and sorts close to the data source.
- Database: check indexes, query shape, N+1 patterns, transaction scope, and payload size.

## Core Web Vitals

- LCP: do not block hero content on slow client-side work or unnecessary requests.
- CLS: reserve stable dimensions for images, embeds, cards, tables, and dynamic controls.
- INP: keep event handlers short and defer non-critical work off the interaction path.
- Loading, error, and empty states: show progress for slow or remote work without skeletons that shift layout, and make retry cheap.

## Avoid

- N+1 queries; prefer joins, includes, or batched loading.
- Unbounded queries; always paginate or add a limit.
- Missing indexes on filter and sort columns.
- Layout thrashing; batch DOM reads, then writes.
- Large bundles; split code, tree-shake, and audit dependencies.
- Main-thread blocking from long tasks; break them up or move work off the handler.
- Unoptimized images and unbounded memory growth from uncleaned listeners or references.

## Verify

- Prefer targeted measurement over speculation: build output, bundle analyzer, database explain plan, runtime logs, or a browser profile.
- For UI changes, smoke-test desktop and mobile viewports when a dev server is practical.
- For API changes, capture baseline and changed latency when the risk justifies it.
- State residual uncertainty if performance was reasoned about but not measured.
