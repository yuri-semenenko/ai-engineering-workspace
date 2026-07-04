---
name: Security Standards
description: Security review and hardening guidance for auth, input, secrets, data, and LLM features.
applyTo: "**"
---

# Security Standards

Apply when a change touches authentication, authorization, user input, external calls, secrets, payments, personal data, file uploads, database access policies, or server-side actions.

## Rationalizations

Excuses that precede a skipped control, paired with the answer. If you think the left, the right applies.

- "Internal endpoint, no auth needed." -> Internal is a network assumption, not a guarantee. Authn + authz still apply.
- "Just an MVP, harden later." -> Auth, secrets, and injection are table stakes, not later-work.
- "Input comes from our own frontend." -> The frontend is not a trust boundary. The API is. Validate at the boundary.
- "It's behind a login, so it's safe." -> Authn is not authz. IDOR lives here: check owner/role on every resource.
- "The framework auto-escapes output." -> Verify the sink. Raw HTML, raw SQL, and template bypasses exist.

## Check

- Trust boundaries: know the source of every input and whether it crosses from user, browser, webhook, third party, or internal service into privileged code.
- Authorization on the server, not just gated UI. Verify actor, tenant, ownership, role, and object-level access before reading or mutating data.
- Input validation at the boundary: shape, type, range, encoding, and allowed values before use in SQL, file paths, shell, redirects, templates, or API calls. Prefer allowlists.
- Secrets stay out of code, logs, and responses. Never print tokens, connection strings, cookies, private keys, or signed URLs.
- Output safety: do not leak internal errors, stack traces, access tokens, personal data, or other tenants' data in responses, logs, or analytics.
- Postgres/Supabase: row-level security on every table, least-privileged client on the server (anon vs service-role), and ownership checks not left to RLS alone in trusted server paths.
- Dependencies: prefer existing ones. For new packages check maintenance, transitive risk, and postinstall scripts, and watch for typosquatting.
- LLM/AI calls: treat model output as untrusted (no direct eval, SQL, shell, innerHTML, or file paths), enforce permissions in code rather than the system prompt, and keep secrets and cross-user data out of the context window.

## Avoid

- Missing server-side authorization behind protected UI.
- Trusting tenant or user IDs sent from the client.
- Insecure direct object references in routes, storage keys, or queries (IDOR).
- Open redirects from unvalidated next, returnTo, or callback parameters.
- Rendering untrusted HTML, markdown, or CMS content without sanitization.
- File uploads without checks on type, extension, size, and content.
- Webhooks without signature verification, replay protection, or idempotency.
- Server-side fetches to client-controlled URLs without an allowlist (SSRF).
- Logging raw request bodies, headers, cookies, or third-party payloads.

## Verify

- Add focused tests for authorization boundaries and rejected inputs where the repo has a natural test location.
- For Supabase/Postgres, confirm RLS policies and least-privileged client usage on server and browser.
- For external callbacks or webhooks, test invalid signature, replay, duplicate delivery, and partial failure.
- For UI changes, confirm sensitive data is absent from rendered HTML, client bundles, logs, and analytics.
