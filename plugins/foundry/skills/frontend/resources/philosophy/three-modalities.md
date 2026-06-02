# Three Modalities — all first-class

Every element must be usable, and pleasant, in three input realities. Build for all three; let the device/customer answer decide emphasis.

## 1. Touch / device
Tapping is the easiest input but **too much tapping is annoying**. Adopt the **three-tap strategy**: any task reachable within ~three taps. Large targets (≥44×44px), generous spacing, avoid hover-only affordances, avoid reflows that move targets under a moving thumb.

## 2. Mouse + keyboard
Usually a larger screen — **tolerates more density** and rewards hover affordances, tooltips, and fine pointer control. Frequent actions inline; secondary actions in menus.

## 3. Keyboard-only
Full operability without a mouse: logical tab order, type-to-filter, arrow roving in grids/listboxes, Enter to commit, Esc to cancel/close, optional shortcut chords for power users. This is both an accessibility requirement and a power-user delight.

## Design implication
The *same* element shifts emphasis by modality — e.g. the action menu is two taps on touch, hover-open on mouse, and a focus+arrow+Enter sequence on keyboard. Record per-modality behaviour in the marker's `modality` field.
