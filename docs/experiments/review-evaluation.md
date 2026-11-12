# Manual review evaluation

The v1 cases in `evals/review/v1/` support a small paired comparison of review
instructions. Freeze the cases, answer key and instruction variants before a
run. Record their Git blob IDs, the repository object format, model, available
tools and candidate change. For example, run
`git hash-object --path=evals/review/v1/cases.md evals/review/v1/cases.md`
and the corresponding command for `answers.md` and each instruction file.
Git's text normalization makes these IDs independent of checkout line endings.
Use fictional fixtures only. Never commit model transcripts or local run state.

1. Independently inspect the development cases and answer key before running.
2. Run baseline and one candidate in fresh contexts, with equal tools and the
   same case. Put only the selected case and instruction variant in a scratch
   directory outside the checkout, and prevent reviewer access to the checkout,
   answer key, other cases and holdouts. Working directory alone is not an
   access boundary: enforce isolation when the environment supports it. If it
   cannot be enforced, report that limitation and treat reviewer blindness as
   unverified. Do not tell the reviewer which variant it receives.
   For these fictional fixtures, override the skills' GitHub preconditions and
   actions: use only the supplied case, never contact GitHub or invent paths,
   commits, or test results. Mark unavailable details as unavailable.
3. An evaluator who did not write the candidate judges each output against the
   case evidence and the corresponding answer-key entry. Give the evaluator
   anonymized outputs without variant identities; keep other cases and their
   answer-key entries out of its context. Record true findings, false comments, missed
   issues, recheck status, unsupported security claims, and whether uncertainty
   was stated accurately.
4. Record elapsed time and actual model usage when available; otherwise record
   `unknown`. A skipped, failed, or inconclusive run is never a pass.
5. Select a candidate before examining holdout results. For a `pr-recheck`
   candidate, compare baseline and candidate on H3 and H4. H1 and H2 exercise
   `pr-review`; prepare and evaluate separate development cases for that skill
   before selecting a candidate and using them as its holdout. A used holdout is
   no longer independent for the next tuning cycle.

Report individual results and counts. The four recheck development cases and two
holdouts per skill are too few to establish statistical significance. Repeated
runs expose model variation; they are not additional independent cases. A blob ID
detects changes to normalized bytes, not incorrect labels or prompt overfitting.
