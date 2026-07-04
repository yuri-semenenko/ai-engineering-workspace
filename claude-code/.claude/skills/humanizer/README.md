# Humanizer

A skill for Claude Code that rewrites text to remove the telltale patterns of AI-generated writing while preserving meaning, facts, and register.

## Usage

### Claude Code

```
/humanizer
```

Then paste or point to the text. Optionally provide a sample of your own writing for voice matching:

```
/humanizer — rewrite the text in draft.md, match the voice of docs/style-sample.md
```

The skill triggers only on an explicit humanize request; it does not run on every text edit.

## What it covers

Five pattern families: inflation (manufactured significance, promotional register, vague authority), diction (AI-frequent vocabulary, copula avoidance, hedging), structure (rule of three, negative parallelism, signposting), formatting (em dashes, mechanical bold, emoji), and chat residue (assistant pleasantries, disclaimers, sycophancy). Every pass ends with an adversarial self-audit.

A full worked example (before / draft / audit / final) lives in `example.md`.

## Methodology

The pattern families track the community-maintained catalog at [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) (WikiProject AI Cleanup), adapted to this repository's persona rules for technical and GitHub-facing writing. The taxonomy, rewrite rules, and examples are original to this repository.

## Related surfaces

- Codex: `codex/skills/humanizer/` (quick pass) + `codex/references/humanizer/ai-writing-patterns.md` (deep reference)
- Copilot: `copilot/workspace-template/.github/prompts/humanize.prompt.md`
