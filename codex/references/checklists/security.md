# Security Checklist

Use this reference when a change touches authentication, authorization, user input, external calls, secrets, payments, personal data, uploads, database policies, or server-side actions.

## Rationalizations

Excuses that precede a skipped control, paired with the answer. If you think the left, the right applies.

- "Internal endpoint, no auth needed." -> Internal is a network assumption, not a guarantee. Authn + authz still apply.
- "Just an MVP, harden later." -> Auth, secrets, and injection are table stakes, not later-work.
- "Input comes from our own frontend." -> The frontend is not a trust boundary. The API is. Validate at the boundary.
- "It's behind a login, so it's safe." -> Authn is not authz. IDOR lives here: check owner/role on every resource.
- "The framework auto-escapes output." -> Verify the sink. Raw HTML, raw SQL, and template bypasses exist.

## Review Focus

- Trust boundaries: identify the source of every input and whether it crosses from user, browser, webhook, third party, or internal service into privileged code.
- Authorization: verify the operation checks the actor, tenant, ownership, role, and object-level access before reading or mutating data.
- Authentication: avoid assuming a session exists because UI is gated. Check the server-side boundary.
- Input handling: validate shape, type, range, encoding, and allowed values before using input in SQL, filesystem paths, shell commands, redirects, templates, or API calls.
- Output handling: avoid leaking secrets, internal errors, access tokens, personal data, pricing rules, or tenant data in responses, logs, analytics, or client state.
- Persistence: check RLS, constraints, transactions, idempotency, auditability, and safe rollback behavior.
- Secrets: never commit credentials. Do not print tokens, connection strings, cookies, private keys, or signed URLs.
- Dependencies: prefer existing dependencies. For new packages, check maintenance, transitive risk, and whether the repo already has a safer primitive.
- LLM/AI calls: treat model output as untrusted (no direct eval, SQL, shell, innerHTML, or file paths), enforce permissions in code rather than the system prompt, and keep secrets and cross-user data out of the context window.

## Common Web Risks

- Missing server-side authorization behind protected UI.
- Tenant or user ID accepted from the client and trusted directly.
- Insecure direct object references in routes, API handlers, storage keys, or database queries.
- Open redirects from unvalidated `next`, `returnTo`, or callback parameters.
- Unsafe HTML rendering, markdown rendering, or CMS content without sanitization.
- File upload paths, MIME types, extensions, size limits, and content scanning left unchecked.
- Webhook handlers without signature verification, replay protection, or idempotency.
- Logging raw request bodies, headers, cookies, or third-party payloads.

## Verification

- Add focused tests for authorization boundaries and rejected inputs when the repo has a natural test location.
- For Supabase/Postgres, verify RLS policies and use the least privileged client on the server and browser.
- For external callbacks or webhooks, test invalid signature, replay, duplicate delivery, and partial failure paths.
- For UI changes, verify sensitive data is not present in rendered HTML, client bundles, logs, or analytics payloads.
