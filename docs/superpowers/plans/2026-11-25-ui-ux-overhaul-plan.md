# UI/UX & 3D Board Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the visual presentation, 3D board layout, 4-corner player cards, 3D money stacks, oversized pawns, multi-skin 3D physics-style dice, property modals, and animation pacing of *Cờ Tỷ Phú Đa Thế Giới* to match the *Business Tour* reference aesthetic while passing all automated Godot tests.

**Architecture:** Keep `src/game.gd` core rules/save schema untouched (`×1000` / `K` formatting applied cleanly in presentation helpers) while replacing the visual/UI layer across modular GDScript units (`src/board_art.gd`, `src/money_pile.gd`, `src/dice_rig.gd`, `src/character.gd`, `src/player_banner.gd`, `src/hud_modals.gd`, `src/tile_text.gd`, and `src/main.gd`) plus updated GLSL compatibility shaders (`assets/backdrop.gdshader`, `assets/field.gdshader`).

**Tech Stack:** Godot 4.4.1 (`gl_compatibility` renderer), GDScript, Godot Spatial & CanvasItem shaders.

## Global Constraints

- Renderer must remain `gl_compatibility` (desktop + mobile safe, no Forward+-only features).
- Preserve all public properties/methods tested by `tests/smoke.gd`, `tests/economy.gd`, `tests/flow.gd`, and `tests/capture.gd` (`playing`, `menu_ui`, `name_input`, `names`, `selected_map`, `map_title`, `inspected_tile`, `inspect_panel`, `inspect_text`, `selection_marker`, `rolling`, `dice_values[i].get_node("Top").get_child_count()`, `save_game()`, `load_game()`).
- Total duration of `animate_roll()` from `on_action()` to `rolling == false` must remain `< 2.85s` for all rolls `2..12` so `tests/flow.gd`'s `3.0s` timer assertion passes deterministically.

---

### Task 1: Shaders, 3D Money Stacks & Clean Reference-Style 3D Board

**Files:**
- Modify: `assets/backdrop.gdshader`
- Modify: `assets/field.gdshader`
- Create: `src/money_pile.gd`
- Modify: `src/board_art.gd`
- Modify: `src/tile_text.gd`

- [ ] **Step 1:** Update `assets/backdrop.gdshader` to warm sunset plum-to-peach gradient with subtle rotated rounded-square decorative watermarks, and `assets/field.gdshader` to crisp bright stadium lawn stripes with subtle pitch markings.
- [ ] **Step 2:** Create `src/money_pile.gd` building lush multi-layer green banknote bundles with white paper bands, plus dynamic silver bars, gold bars, and colored property card stacks driven by player cash and owned tile count.
- [ ] **Step 3:** Rewrite `src/board_art.gd` with exact non-overlapping `12×12` corners and `7.22×12` edge tiles, camera-facing price strips (`60K`–`340K`), crisp `Label3D` uppercase tile names, rainbow Chance wheels, Tax invoices, 4 iconic corners (`START` arch, `LOST ISLAND`, `STADIUM`, `WORLD TOUR`), 3 clean center-court map themes, and dynamic `update_tile_visual()` spawning owner-colored houses (levels 1–4) and luxury hotels (level 5) only when owned.

### Task 2: Oversized Pawns & Multi-Skin 3D Throw Dice System

**Files:**
- Modify: `src/character.gd`
- Create: `src/dice_rig.gd`

- [ ] **Step 1:** Upgrade `src/character.gd` with prominent player-colored ringed pedestal base, brighter character lighting/rim tint, and smooth idle/hop pose animation scaled ~2× larger on the board.
- [ ] **Step 2:** Create `src/dice_rig.gd` implementing rounded-bevel 3D dice with all 6 faces (`Top`, `Bottom`, `Front`, `Back`, `Left`, `Right`), 4 selectable skins (`Obsidian Gold`, `Royal Ivory`, `Ruby Vegas`, `Jade Cyber`), particle burst rings on bounce impact, and parabolic throw trajectories from the active player's quadrant into the center court.

### Task 3: 4-Corner Player Cards, Speech Bubbles, Modals & Main Orchestration

**Files:**
- Modify: `src/player_banner.gd`
- Create: `src/hud_modals.gd`
- Modify: `src/main.gd`

- [ ] **Step 1:** Rewrite `src/player_banner.gd` to match the 4-corner *Business Tour* banners (Hot Pink, Sky Blue, Leaf Green, Golden Yellow; top vs bottom vertical symmetry; crisp vector green banknote stack icon; formatted `1 500 000` cash; active glow & VIP frame).
- [ ] **Step 2:** Create `src/hud_modals.gd` providing vector icons, comic speech bubble (`SpeechBubble`) anchored to 3D characters, floating `+K / -K` cash toast, Monopoly-style `PropertyDeedCard` popup for buying/inspecting tiles, and `DiceSkinPopup` selector.
- [ ] **Step 3:** Update `src/main.gd` to wire stable panoramic camera, calm bouncy step-by-step pawn hops, `1.2s` bot turn pacing, redesigned centered/card-based Welcome/Setup/Pause/Assets menus, right-side circular glossy buttons with owned-property badge, and full test compatibility.

### Task 4: Verification & Visual Capture Audit

**Files:**
- Test: `tests/smoke.gd`, `tests/economy.gd`, `tests/flow.gd`, `tests/capture.gd`

- [ ] **Step 1:** Run headless unit & flow tests (`smoke.gd`, `economy.gd`, `flow.gd`) with `/private/tmp/godot-4.4.1/Godot.app/Contents/MacOS/Godot`.
- [ ] **Step 2:** Run `tests/capture.gd` to render fresh `evidence/*.png` screenshots and inspect them visually against the reference image, refining spacing, contrast, and proportions until polished.
