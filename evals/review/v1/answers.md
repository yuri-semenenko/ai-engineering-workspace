# Review evaluation answer key, v1

Keep this file out of reviewer inputs. Expected outcomes are independent
annotations, not executable assertions about model quality.

For rechecks, the supported statuses are `addressed`, `partial`,
`not addressed`, and `wont-fix (author replied)`. The key distinguishes a
judgment about evidence from a status: when the original finding is disproved,
explain that separately instead of inventing a status or calling it fixed.

| Case | Expected judgment | Evidence and limitations |
| --- | --- | --- |
| R1 | Addressed; non-blocking | Zero is accepted and the regression was observed failing with the original guard restored. |
| R2 | Not addressed; blocking | Zero still satisfies the new guard. A changed line is not a fix. |
| R3 | Partial or not addressed; blocking | The test passed without the key and does not exercise a timeout. The code change may be correct, but that is unverified. |
| R4 | Challenge the original finding; do not claim an unobserved fix | The stated zero scenario already works. Explain the invalid finding and any unresolved status or blocking decision without inventing a status. |
| H1 | No defect for zero | Nullish coalescing preserves zero under the stated contract. |
| H2 | Do not assert XSS from this evidence | `textContent` alone does not establish an HTML-execution sink; ask for missing evidence if appropriate. |
| H3 | Partial; blocking | The timeout path changed, but the original connection-reset scenario remains. |
| H4 | Wont-fix (author replied); non-blocking with accepted risk | The user explicitly accepted the same remaining risk with a reason; do not silently infer acceptance from the author's reply. |

The reviewer may report meaningful independently supported defects. Score those
against their actual evidence rather than treating this table as exhaustive.
