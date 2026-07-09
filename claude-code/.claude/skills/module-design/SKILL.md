---
name: module-design
description: Shape a module so a small, stable interface hides substantial implementation — deep modules, information hiding, and the test for whether an abstraction earns its keep. Use when designing or reviewing a module or interface boundary, extracting a helper or wrapper, or deciding whether an abstraction is worth it: "design this module", "what should this interface expose", "is this abstraction worth it", "спроектируй модуль", "какой интерфейс здесь нужен", "стоит ли эта абстракция". Different from /lazy (whether the code should exist at all — the rung before this), /complexity-audit (whole-tree over-engineering scan after the fact), and /rfc (system-level decisions). Pairs with both.
---

# Module Design

Shape modules so a small, stable interface hides substantial implementation. The unit of design is the interface a caller sees, not the code behind it. Favor composition and explicit data flow; add an abstraction only when it earns the indirection it introduces.

## Rationalizations

| Rationalization | Rebuttal |
|---|---|
| "I'll wrap it now so it's easy to swap later." | One implementation is a hypothetical seam. Wrap it when the second arrives, not before. |
| "More layers means cleaner separation." | Layers are cost. A layer that only forwards calls adds surface without hiding anything. |
| "The interface should expose everything, just in case." | A wide interface leaks the implementation and freezes it. Expose what the caller needs; hide how. |
| "It's more flexible with a config object or a strategy." | Configurable indirection is complexity you pay for on every read. Flexibility no caller uses is dead weight. |

## What a deep module looks like

- **Small interface, substantial body.** The value is the ratio: much hidden behind little exposed. Depth is a property of the interface, not the line count.
- **Information hiding.** Callers depend on what it does, never on how. A change to the implementation must not ripple outward.
- **The interface is the test surface.** A small, honest interface is the natural seam to test through. If it is hard to test without reaching inside, the boundary is wrong.

## Design moves

- **Deletion test.** If you removed the module, would its knowledge scatter back into callers? If nothing leaks, it was not encapsulating anything — inline it.
- **Adapter rule.** One implementation behind an abstraction is a hypothetical seam; two is a real one. Introduce the interface when the second appears, not in anticipation of it.
- **Inject dependencies, return results.** Prefer functions that take what they need and return a value over ones that reach for globals or fire hidden side effects. Testability follows for free.
- **Push complexity down, not out.** A module earns its keep by absorbing hard cases so callers do not repeat them. A module that hands its edge cases back to every caller is shallow.

## Glossary (use these words precisely)

- **Module** — a unit with an interface and a hidden implementation. Not "a file", and not the TypeScript `interface` keyword.
- **Interface** — everything a caller must know to use it: signatures, types, thrown errors, observable side effects.
- **Depth** — how much implementation the interface hides. Deep is good; shallow (interface ≈ implementation) is the smell.
- **Seam** — a place you can substitute behavior for a test or a new implementation (Feathers). A real seam has a reason to exist.

## Anti-patterns to refuse

- **Shallow module / pass-through wrapper** — an interface as wide as the thing it wraps; delete it and lose nothing.
- **Premature adapter** — an abstraction over a single implementation, "for flexibility".
- **Configuration-driven indirection** — flags and strategies no caller actually varies.
- **Leaky interface** — exposing internal types or state so callers couple to the implementation.

## Rules

- Present the simplest shape first; justify every layer and abstraction against its indirection cost.
- Prefer composition of small functions over inheritance and framework hooks.
- A boundary you cannot test through cheaply is the wrong boundary — fix the boundary, do not mock around it.
- When you accept a shallow module or a speculative seam on purpose, mark it with the `TRADEOFF(...)` convention so /debt-ledger can find it.

## Output

This is a design aid, not a document. Recommend a concrete module shape: the interface (signatures and types), what stays hidden, and where the test seam is. When reviewing, point at the specific interface that is too wide, the layer that only forwards, or the adapter with a single implementation, and give the smaller shape. English prose, no em dashes, per persona.
