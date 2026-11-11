# Review evaluation answer key, v1

Keep this file out of reviewer inputs. Expected outcomes are independent
annotations, not executable assertions about model quality.

| Case | Expected judgment | Evidence and limitations |
| --- | --- | --- |
| R1 | Addressed; non-blocking | Zero is accepted and the regression was observed failing with the original guard restored. |
| R2 | Not addressed; blocking | Zero still satisfies the new guard. A changed line is not a fix. |
| R3 | Insufficient evidence for addressed; blocking | The test passed without the key and does not exercise a timeout. The code change may be correct, but that is unverified. |
| R4 | Challenge the original finding; do not claim an unobserved fix | The stated zero scenario already works. Distinguish invalid finding from author risk acceptance; explain any unresolved blocking decision. |
| H1 | No defect for zero | Nullish coalescing preserves zero under the stated contract. |
| H2 | Do not assert XSS from this evidence | `textContent` alone does not establish an HTML-execution sink; ask for missing evidence if appropriate. |
| H3 | Partial; blocking | The timeout path changed, but the original connection-reset scenario remains. |
| H4 | Challenge the original finding; do not claim an unobserved fix | The stated false-input scenario already works; the available evidence does not establish another defect. |

The reviewer may report meaningful independently supported defects. Score those
against their actual evidence rather than treating this table as exhaustive.
