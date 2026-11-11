# Review evaluation cases, v1

These fictional cases exercise `pr-review` and `pr-recheck`. Give a reviewer
only the selected case and the skill under evaluation; keep the answer key and
other cases out of the reviewer's context. Review is report-only: no posting,
thread resolution, approval, external API, or changes to the checkout.

## Development cases

### R1 — scenario fixed

Prior Important thread: `parseCount('0')` incorrectly rejects zero. New code:

```js
function parseCount(s) {
  const n = Number(s);
  if (s.trim() === '' || !Number.isInteger(n) || n < 0) throw Error('invalid');
  return n;
}
```

The added regression test asserts `parseCount('0') === 0`; an isolated run with
the original `if (!n)` guard restored fails that assertion.

### R2 — changed line, same cause

Prior Important thread: a zero count is rejected. The old code used
`if (!n) throw Error('invalid')`; the new code uses
`if (n === 0 || !n) throw Error('invalid')`. The author says it is fixed.

### R3 — test does not prove the fix

Prior Important thread: retries can be duplicated when a request times out.
The new implementation adds an idempotency key. The added test checks only
that the response is successful. In an isolated run with the key removed, the
test still passes. No other evidence of timeout behaviour is provided.

### R4 — false finding

Prior Important thread claims the following function fails for zero. The old
and new code are identical; a direct check shows `countLabel(0) === '0'`:

```js
function countLabel(count) { return String(count); }
```

The author replied that no code change is needed. No other failure scenario is
provided.

## Holdout cases

Do not use these for prompt tuning. Evaluate only after selecting a candidate.

### H1 — correct code that looks suspicious

Review this change: a user-facing counter displays `value ?? 10`. The intended
contract is that only `null` and `undefined` use the default; zero is valid.
Do not infer other application behaviour.

### H2 — security suspicion without evidence

Review this change: `renderLabel(label)` assigns `label` to an element's
`textContent`. The available diff does not show any HTML insertion or other
sink. A previous comment asserts that the assignment is an XSS vulnerability.

### H3 — fix covers only one path

Prior Important thread: a retry can be scheduled twice after either a timeout
or a connection reset. New code suppresses duplicate retries after a timeout;
the connection-reset path is unchanged and still schedules the retry twice.
The added test covers only the timeout path.

### H4 — no evidence the original scenario existed

Prior Important thread says `isEnabled(false)` returns true. Old and new code
are identical: `function isEnabled(value) { return value === true; }`.
A direct check of the original scenario returns false. No other scenario is
provided and the author says no change is needed.
