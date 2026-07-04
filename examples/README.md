# Examples

The fastest way to tell a methodology kit from a prompt collection is to look at
what it produces. These are worked outputs of the process skills, applied to one
coherent (fictional) engineering problem so you can see how the pieces connect.

## The thread

A fictional product needs to deliver **outbound webhooks** reliably. Today they
are sent synchronously inside the request handler; a slow or failing subscriber
blocks the caller and drops the event. The same problem runs through three
documents, each a different skill and a different moment in the decision:

| File | Skill | Moment |
| --- | --- | --- |
| [`rfc-sample.md`](./rfc-sample.md) | `rfc` | The approach is contested. Explore options, recommend one. |
| [`adr-sample.md`](./adr-sample.md) | `adr` | The decision is made. Record why, for future readers. |
| [`pr-review-sample.md`](./pr-review-sample.md) | `pr-classify` | The implementation exists. Review it, triaged by severity. |

Read them in that order and you see the workflow the kit encodes: explore in an
RFC, commit in an ADR, verify in review. Each one follows the format its skill
enforces, described in [`docs/principles/documents.md`](../docs/principles/documents.md)
and [`docs/principles/review-discipline.md`](../docs/principles/review-discipline.md).

Everything here is invented. The stack, the code, and the scenario are generic on
purpose — the point is the shape of the reasoning, not the domain.
