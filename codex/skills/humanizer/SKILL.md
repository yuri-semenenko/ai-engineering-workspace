---
name: humanizer
description: Use when editing or reviewing text that should sound natural, human-written, less promotional, less AI-generated, or closer to the user's own voice.
---

# Humanizer

Rewrite text so it sounds like a real person wrote it, while preserving meaning and intent.

## Quick Pass

- Remove inflated significance claims, promotional language, vague authority, generic conclusions, and formulaic transitions.
- Prefer specific nouns and direct verbs over "showcases", "underscores", "serves as", "crucial", "pivotal", and similar filler.
- Vary sentence rhythm. Do not make every paragraph the same size or structure.
- Avoid em dash overuse, arrows, emojis, title-case microheadings, excessive bold labels, and rule-of-three lists unless the user's sample uses them.
- Keep technical writing clear and plain. Do not add warmth by adding fluff.

## Voice Matching

If the user provides a sample, match sentence length, punctuation habits, paragraph openings, vocabulary, and level of directness. If no sample is provided, use a concise, natural, opinionated voice.

## Deep Reference

For a full checklist of AI-writing patterns, read `$CODEX_HOME/references/humanizer/ai-writing-patterns.md` only when the text is long, high-stakes, or the first pass still sounds synthetic.

## Output

Before returning, do a final anti-AI audit: ask yourself what still makes the text obviously AI-generated, and revise until nothing does.

Return the revised text. If useful, add a short note with the main changes, but do not over-explain the edit.
