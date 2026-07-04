---
name: Frontend Standards
description: React and frontend implementation guidance.
applyTo: "**/*.tsx,**/*.jsx,**/*.css,**/*.scss,**/*.module.css,**/*.module.scss"
---

# Frontend Standards

Follow existing design system and component conventions.

Prefer:

- semantic HTML
- accessible controls
- predictable state flow
- stable layout dimensions for fixed-format UI
- clear loading, error, and empty states
- small focused components

Avoid:

- decorative complexity without product value
- component abstractions before repetition is real
- layout shifts from dynamic content
- text overflow or overlap
- hidden keyboard traps

For React, use hooks correctly and keep side effects explicit. Avoid duplicating derived state unless it is needed for interaction.

