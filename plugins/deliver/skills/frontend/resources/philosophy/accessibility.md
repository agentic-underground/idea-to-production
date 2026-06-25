# Accessibility — the floor, defended (non-negotiable)

WCAG 2.1 AA is the minimum, not the aspiration. You defend it; you deviate only on an explicit, logged customer decision.

## The criteria you check every time
- **1.4.3 / 1.4.11 Contrast** — text ≥4.5:1 (≥3:1 large); UI/graphics ≥3:1.
- **2.1.1 Keyboard** — every function operable by keyboard alone.
- **2.4.3 Focus order** — logical, predictable.
- **2.4.7 Focus visible** — always a visible focus indicator.
- **2.5.5 Target size** — ≥44×44 CSS px on touch.
- **3.2.1 Predictable on focus** — no surprise navigation/changes.
- **3.3.1 / 3.3.2 Errors & labels** — describe errors in text; label every input.
- **4.1.2 Name/role/value** — for every control (use native elements first).

## Operating rules
- Native semantic elements before ARIA; ARIA only to fill gaps.
- Never signal state by colour alone — pair with text or icon.
- Respect `prefers-reduced-motion`.
- Test keyboard-only and at 200% zoom as part of self-critique.

This page backs the dark-mode-default and density choices: contrast and target-size hold in every theme and density.
