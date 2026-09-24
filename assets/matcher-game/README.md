# Kitchen Pair Rush

A mobile-first browser game where players match ingredient pairs moving in opposite directions.

The left lane moves **up**.  
The right lane moves **down**.  
Tap when the **same ingredient pair** appears inside the center window at the same time.

## Overview

Kitchen Pair Rush is a fast arcade-style matching game designed for touch screens first, while still working well on desktop.

The game is built around one simple action:

- watch two moving lanes
- wait for the matching pair
- tap at the right moment

This redesign replaces the previous conveyor-style interaction with a cleaner mechanic that is easier to understand, faster to play, and better suited for mobile devices.

## Core Gameplay

- The **left lane** scrolls upward
- The **right lane** scrolls downward
- The player taps the **center match button**
- A correct tap happens when both visible items are the **same pair**
- Later levels require matching both **ingredient and color**

## Controls

### Mobile
- Tap the **center match button**

### Desktop
- Click the **center match button**
- Or press **Space**

## Level Progression

### Level 1 — Shape Match
Match the same ingredient in both lanes.

### Level 2 — Faster
Same rule, faster movement.

### Level 3 — Color Match
Ingredient and color must both match.

### Level 4 — Tight Timing
The timing window gets smaller.

### Level 5 — More Decoys
More ingredient types increase difficulty.

### Level 6 — Lane Desync
The two lanes no longer move at the same speed.

## Features

- mobile-first layout
- one-tap gameplay
- desktop keyboard support
- score and combo tracking
- lives system
- progressive difficulty
- reusable SVG ingredient assets

## File Structure

```text
.
├── index.html
├── README.md
├── LICENSE
└── images
    ├── egusi.svg
    ├── fish.svg
    ├── onion.svg
    ├── palm-oil.svg
    ├── pepper.svg
    ├── plantain.svg
    ├── tomato.svg
    └── yam.svg
