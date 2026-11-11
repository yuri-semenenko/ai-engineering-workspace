# Manual review evaluation

The v1 cases in `evals/review/v1/` support a small paired comparison of review
instructions. Freeze the case and answer-key bytes before a run; record their
SHA-256 hashes, skill version, model, available tools, and candidate change.
Use fictional fixtures only. Never commit model transcripts or local run state.

1. Independently inspect the development cases and answer key before running.
2. Run baseline and one candidate in fresh contexts, with equal tools and the
   same case. Give each reviewer only its case and instruction variant. Do not
   pass the answer key, other cases, or the variant identity to the evaluator.
   For these fictional fixtures, override the skills' GitHub preconditions and
   actions: use only the supplied case, never contact GitHub or invent paths,
   commits, or test results. Mark unavailable details as unavailable.
3. An evaluator who did not write the candidate judges each output against the
   evidence. Record true findings, false comments, missed issues, recheck status,
   unsupported security claims, and whether uncertainty was stated accurately.
4. Record elapsed time and actual model usage when available; otherwise record
   `unknown`. A skipped, failed, or inconclusive run is never a pass.
5. Select a candidate before examining holdout results. For a `pr-recheck`
   candidate, compare baseline and candidate on H3 and H4. H1 and H2 exercise
   `pr-review`; prepare and evaluate separate development cases for that skill
   before selecting a candidate and using them as its holdout. A used holdout is
   no longer independent for the next tuning cycle.

Report individual results and counts. The four recheck development cases and two
holdouts per skill are too few to establish statistical significance. Repeated runs expose model
variation; they are not additional independent cases. The hash detects changes
to case bytes, not incorrect labels or prompt overfitting.
