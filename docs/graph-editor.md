# Juicee — Graph Editor Reference

The **JuiceeGraph** bottom panel is a visual node graph for building sequences with branching, looping, and parallel execution. Open it from the bottom dock in the Godot editor.

---

## Overview

The graph editor outputs a `JuiceeGraphResource` (`.tres`) that the runtime `JuiceeGraphPlayer` walks at play-time. You can also **⤓ Export Sequence** to produce a `JuiceeSequence.tres` compatible with `JuiceePlayer`.

The graph and `JuiceeSequence` share the same effect instances — all three workflows (singleton, Inspector, graph) are interoperable.

---

## Toolbar

| Button | Shortcut | Action |
|---|---|---|
| **New** | — | Clear the canvas and start a new graph. Prompts to save if dirty. |
| **Open** | — | Load an existing `.tres` graph file. |
| **Save** | `Ctrl+S` | Save the current graph to its `.tres` file. |
| **Save As…** | — | Save to a new path. |
| **▶ Test** | `F5` | Run the graph against the currently selected node in the scene tree (or the root if nothing is selected). Blocks pulse as they fire. |
| **⤓ Export Sequence** | — | Export a `JuiceeSequence.tres` from the graph (without graph metadata). |
| **✋ Pan** | `Space`+drag | Toggle hand/pan tool. |
| **↑ Update** | — | Check GitHub releases for a newer version of Juicee. |
| **Fit** | `F` | Fit all blocks into view. |

---

## Canvas interactions

| Action | How |
|---|---|
| **Add node** | Right-click on empty canvas → searchable popup |
| **Add node from wire** | Drag a wire to empty space → popup opens, auto-connects on selection |
| **Connect nodes** | Drag from an output port to an input port |
| **Disconnect** | Click a connection line and press `Delete`, or drag the wire off its endpoint |
| **Select** | Click a block or drag-select |
| **Multi-select** | `Shift`+click or `Ctrl`+click |
| **Move** | Drag selected blocks |
| **Delete** | `Delete` or `Backspace` on selected blocks (removes connections too) |
| **Undo/Redo** | `Ctrl+Z` / `Ctrl+Y` — registered with Godot's `EditorUndoRedoManager` |
| **Zoom** | Mouse wheel |
| **Pan** | Middle-click drag or `Space`+drag |
| **Block preview** | Click **▶** on any effect block to preview that single effect |

---

## Node types

### Trigger

Entry point. Every graph needs exactly one. Execution begins here when `JuiceeGraphPlayer.play()` is called.

- No input port.
- One output port → connects to the first effect or flow node.

---

### Effect nodes

One block per effect. The block title shows the effect's display name; the subtitle shows its category ("Camera", "Screen", etc.).

**Selecting a block** opens its property panel on the right side of the graph editor. Properties match the effect's `@export` fields — same sliders and pickers as the Inspector.

**▶ (preview button)** in the titlebar fires just this effect against the currently selected scene node. Screen shader effects render in the editor preview viewport with an amber outline hint.

**Dimension tags** (small `2D` / `3D` icons) in the titlebar indicate which scene types the effect targets.

---

### Split

Parallel fan-out. All connected outputs fire at the same time without `await`. Use for simultaneous effects (shake + flash + chromatic all at once).

- Adjustable port count via **+** / **−** buttons (2–8 outputs).
- All ports fire concurrently — execution continues down each path independently.

---

### Loop

Repeat a chain N times sequentially. Each iteration waits for the previous to finish.

- Single output port → the chain to repeat.
- `count` property controls repetitions.
- Subtitle shows "Repeat × N" live as you type.

---

### Random

Pick exactly one output at random (weighted) and run that branch only.

- Adjustable port count (2–8).
- `weights` property: array of relative weights. `[1, 2, 1]` gives the middle option 2× probability.
- If `weights` is empty or shorter than the port count, equal probability is used.

---

### Condition

Evaluate a GDScript expression against `context`. Branch on the result.

- **Port 0** → True branch.
- **Port 1** → False branch.
- `expression` property: a GDScript expression string evaluated via `Expression`. Has access to the `context` variable.
- Fixed 2-output ports — no +/− controls.

**Expression examples:**

```
context.health < 20
context.is_in_group("player")
context.visible
context.get_meta("invincible", false) == false
context.velocity.length() > 200.0
```

The expression is evaluated by both the runtime player (`JuiceeGraphPlayer`) and the editor's **▶ Test** runner — both paths are consistent.

If expression parsing or execution fails, it defaults to `true` (True branch) and emits a `push_warning`.

---

## Properties panel

Selecting a block opens a scrollable panel on the right side of the graph editor. It shows all `@export` properties of the effect, rendered using Godot's native Inspector widgets:

- **Float** → horizontal slider with value field
- **int** → integer slider
- **Color** → color picker button
- **bool** → checkbox
- **NodePath** → path input
- **Curve** → inline Curve editor
- **Array** → expandable array
- **Enum** → option button

Changes are committed via `EditorUndoRedoManager` — `Ctrl+Z` reverts them.

For **Loop** nodes: the `count` field updates the block's subtitle live.  
For **Random** nodes: the `weights` array and `port_count` drive the port layout.  
For **Condition** nodes: a `LineEdit` with expression examples shown as a hint label.

---

## Debug Test (▶ Test)

Pressing **▶ Test** in the toolbar runs the full graph against the context node in real time:

1. **JuiceeGraphPlayer** walks the graph from the Trigger node.
2. As each block's effect starts, its graph block **pulses** (brightness flash).
3. If an effect has a `delay > 0`, a **progress bar** fills at the bottom of its block while waiting.
4. The graph honors actual flow control — `Loop` repeats N times, `Random` picks a branch, `Condition` evaluates live, `Split` fans out.
5. When all paths finish, the test resets.

**Canceling** the test mid-run: click **▶ Test** again or press `Escape`.

> Screen shader effects preview at editor viewport size. The amber outline hint marks the preview rect. F5/F6 to see true full-screen coverage.

---

## Saving and loading

Graphs save as `JuiceeGraphResource` (`.tres`). The resource contains:
- An array of `JuiceeGraphNodeData` entries (each holds the effect instance + flow properties + position)
- A `PackedStringArray graph_connections` in `"from_id:from_port:to_id:to_port"` format

Effect instances are embedded in the `.tres` as inline sub-resources. Their `@export` properties are diff-able in version control.

**⤓ Export Sequence** produces a `JuiceeSequence.tres` that strips graph metadata (positions, connections) and retains only the ordered effects array. Use this when you want a linear sequence that can be dropped on a `JuiceePlayer.sequence`.

---

## Popup search

Right-clicking the canvas opens a categorized popup. Effects are grouped by category:

- Screen, Camera, Object, Text, Time, Audio, Physics, Flow, Misc
- Flow control nodes (Trigger, Split, Loop, Random, Condition) appear at the top in a dedicated section

The popup has a **search field** — type any substring to filter effects. The matched section headers are hidden if all their effects are filtered out.

Effects that override `get_category_name()` in their script appear under their own custom category. Unknown effects fall through to the "Misc" section.

---

## Auto-connect from wire drag

Dragging a wire to empty space opens the popup. When you select an effect, the new block is:

1. Placed at the cursor position.
2. Automatically connected to the wire you dragged.

This is the fastest way to build a chain — just keep dragging from the last block's output port.

---

## Built-in updater

The **↑ Update** toolbar button:

1. Fetches the GitHub releases API for the latest version.
2. Shows a dialog with the release tag, publish date, and release notes.
3. On confirmation, downloads the archive, extracts `addons/juicee/` over the current installation.
4. Prompts to reload the editor.

No manual file management needed. Requires an internet connection and write access to `addons/juicee/`.
