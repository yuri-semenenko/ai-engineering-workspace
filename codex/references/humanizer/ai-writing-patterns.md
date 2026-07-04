# AI Writing Patterns Reference

Deep reference for the `humanizer` skill (see `skills/humanizer/SKILL.md` for the quick pass and output rules). Read this when the text is long, high-stakes, or the first pass still sounds synthetic.

The pattern families track the community-maintained catalog at Wikipedia: Signs of AI writing (WikiProject AI Cleanup), adapted to this repository's persona rules. The taxonomy, rules, and examples are original to this repository.

## Voice matching

When the user supplies a sample of their own writing, imitate it: typical sentence length, how paragraphs open, punctuation habits, how formal the vocabulary runs, whether they use first person. Replace AI patterns with that author's patterns, not with a generic "good writing" default. Without a sample, default to plain, direct, lightly opinionated prose.

Two principles govern every rewrite:

- **Specificity beats polish.** A concrete fact ("deploys dropped from 40 to 12 minutes") always outperforms an abstract claim ("significantly improved deployment efficiency"). If the input has no concrete facts, keep the claim modest instead of inventing details.
- **Clean is not enough.** Text with zero AI patterns can still read as lifeless. Vary sentence length, allow an opinion where the register permits one, and let the author's judgment show. Uniform, neutral, perfectly balanced prose is itself a tell.

## Family 1 — Inflation

**1.1 Manufactured significance.** Claims that something "marks a pivotal moment", "underscores the importance of", "is a testament to", or "reflects broader trends". Strip the ceremony; state what the thing is or does.

> Before: "The migration to the new build system represents a pivotal step in the team's journey toward engineering excellence."
> After: "We migrated to the new build system in March. CI time dropped by half."

**1.2 Promotional register.** "Seamless", "robust", "cutting-edge", "powerful", "best-in-class" — adjectives that sell instead of describe. In technical writing, every one of them should be replaced by the property it is hiding.

> Before: "A seamless, developer-friendly CLI with powerful configuration options."
> After: "A CLI that reads its config from one file and works without flags in the common case."

**1.3 Fake depth via participles.** Trailing "-ing" clauses bolted onto a sentence to simulate analysis: "…, highlighting the need for", "…, ensuring scalability", "…, fostering collaboration". Either the clause says something checkable — then make it its own sentence — or it says nothing — then delete it.

> Before: "The service caches responses at the edge, ensuring optimal performance and enhancing the user experience."
> After: "The service caches responses at the edge. Cached pages return in under 50 ms."

**1.4 Vague authority.** "Experts agree", "studies show", "industry reports indicate" with no named source. Name the source or drop the appeal.

> Before: "Industry reports indicate that most outages are caused by configuration changes."
> After: "Google's SRE book attributes roughly 70% of outages to config changes."

**1.5 Generic upbeat endings.** "Exciting times lie ahead", "this is a major step in the right direction", "the future looks bright". End on the last concrete point instead; a good text does not need a farewell.

## Family 2 — Diction

**2.1 AI-frequent vocabulary.** Words that spiked in post-2023 text: delve, crucial, pivotal, landscape (abstract), tapestry, testament, underscore, showcase, foster, garner, intricate, vibrant, robust, leverage (verb), journey (figurative). One of them is fine. Three in a paragraph is a signature. Swap for the plain word: important, area, show, use, complex.

**2.2 Copula avoidance.** "Serves as", "stands as", "functions as", "acts as" where "is" belongs; "boasts" or "features" where "has" belongs.

> Before: "The gateway serves as the single entry point and boasts built-in rate limiting."
> After: "The gateway is the single entry point and has built-in rate limiting."

**2.3 Synonym cycling.** Renaming the same referent every sentence (the service → the platform → the system → the solution) to dodge repetition. Humans repeat nouns; repeat the noun.

**2.4 Stacked hedging.** "Could potentially", "might possibly", "it could be argued that". Hedge once, precisely, or not at all.

**2.5 Filler frames.** "It is important to note that", "in order to", "due to the fact that", "at this point in time", "has the ability to". Each has a one-word replacement or none.

## Family 3 — Structure

**3.1 Rule-of-three compulsion.** Ideas forced into triplets ("faster, safer, and more reliable") regardless of how many points actually exist. If there are two points, write two.

**3.2 Negative parallelism.** "It's not just X, it's Y"; "this isn't about A, it's about B"; clipped tail negations ("no config, no surprises"). Say the positive claim directly.

> Before: "This isn't just a linter, it's a whole new way of thinking about code quality. No noise, no false positives."
> After: "The linter ships with a curated ruleset, so the default output is quiet enough to leave on in CI."

**3.3 False ranges.** "From X to Y" where X and Y sit on no meaningful axis: "from onboarding flows to database migrations". Replace with a plain list or a real dimension.

**3.4 Formulaic sections.** "Challenges and future prospects", "Despite these challenges…", a "Conclusion" that restates the intro. Write what actually happened or is planned, with dates and owners, or cut the section.

**3.5 Signposting.** "Let's dive in", "here's what you need to know", "without further ado", and headings followed by a one-line restatement of the heading. Start with the content.

## Family 4 — Formatting

**4.1 Em dash overuse.** Most em dashes convert cleanly to a comma, a period, or parentheses. In this user's PR comments and GitHub output, avoid em dashes, arrows, and tildes entirely (persona rule).

**4.2 Mechanical bold.** Bolded openers on every list item ("**Performance:** …", "**Security:** …") and bold sprinkled on noun phrases mid-sentence. Reserve bold for the one thing the reader must not miss; often the fix is folding the list back into a sentence.

**4.3 Emoji decoration.** Emoji on headings and bullets. Remove unless the venue genuinely uses them (a casual Slack post may; a design doc does not).

**4.4 Title Case Headings.** Sentence case for headings in prose documents.

**4.5 Curly quotes and unicode artifacts.** Straight quotes in technical text; watch for “smart” quotes surviving a paste.

## Family 5 — Chat residue

**5.1 Assistant pleasantries.** "I hope this helps", "Certainly!", "Great question!", "Let me know if you'd like me to expand" — chat turns pasted as content. Delete.

**5.2 Knowledge disclaimers.** "As of my last update", "while specific details are limited", "based on available information". Either the fact is known — state it — or it is not — say what is missing and where to look.

**5.3 Sycophancy.** "You're absolutely right", "That's an excellent point". In reviews and replies, respond to the substance without grading the other person's question.

## Self-audit

After the draft, interrogate it once more:

1. Ask: "If I saw this text cold, what would make me suspect a model wrote it?" List the remaining tells honestly — rhythm, vocabulary, structure, anything.
2. Fix each tell.
3. Read the result aloud (mentally). Any sentence you would not say to a colleague gets rewritten or cut.
