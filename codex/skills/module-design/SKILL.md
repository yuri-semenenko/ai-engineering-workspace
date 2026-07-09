---
name: module-design
description: Use when designing or reviewing a module or interface boundary, extracting a helper or wrapper, or deciding whether an abstraction is worth it. Favors deep modules, information hiding, and composition over speculative layering.
---

# Module Design

Shape modules so a small, stable interface hides substantial implementation. The unit of design is the interface a caller sees, not the code behind it. Add an abstraction only when it earns the indirection it introduces.

## What a deep module looks like

- Small interface, substantial body: much hidden behind little exposed. Depth is a property of the interface, not the line count.
- Callers depend on what it does, never on how. A change to the implementation must not ripple outward.
- The interface is the test surface. If it is hard to test without reaching inside, the boundary is wrong.

## Design moves

- Deletion test: if removing the module scatters its knowledge back into callers, it encapsulates nothing — inline it.
- Adapter rule: one implementation behind an abstraction is a hypothetical seam; two is a real one. Add the interface when the second appears.
- Inject dependencies and return results rather than reaching for globals or firing hidden side effects.
- Push complexity down (absorb hard cases) instead of out (handing edge cases back to every caller).

## Guardrails

- Prefer composition of small functions over inheritance and framework hooks.
- Refuse the shallow wrapper, the premature adapter, configuration-driven indirection no caller varies, and interfaces that leak internal types or state.
- Present the simplest shape first and justify every layer against its indirection cost.
- Distinct from architect (system-level decisions) and rfc: this is about one module's interface.
