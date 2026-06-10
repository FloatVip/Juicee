## Show/hide a node for the duration of the effect, then restore its
## original visibility. FEEL's MMF_SetActive parity.
##
## Use for: muzzle flashes, hit sparks, "explosion mark" sprites, item
## highlights, debug overlays — anything you want flickering on briefly as
## part of a juice sequence without manual show()/hide() bookkeeping.
@tool
class_name JuiceeSetActiveEffect
extends JuiceeEffect

enum Action { SHOW, HIDE, TOGGLE }

## Node path to toggle (relative to context, or absolute).
@export var target_path: NodePath
## What to do for the duration: show it, hide it, or flip its current state.
@export var action: Action = Action.SHOW
## How long to keep the new state before restoring the original visibility.
@export_range(0.05, 30.0, 0.05) var duration: float = 0.5
## If true, the original visibility is restored at the end. If false, the
## change is permanent (useful for one-shot reveals).
@export var restore_on_end: bool = true

func get_category_color() -> Color:
	return Color(0.40, 0.85, 0.45)

func get_category_name() -> String:
	return "Flow"

func _apply(context: Node, _intensity_mult: float) -> void:
	if not context or not context.is_inside_tree():
		return
	var target: CanvasItem = context.get_node_or_null(target_path) as CanvasItem
	# CanvasItem covers Node2D + Control; fall back to plain Node for Node3D etc.
	if not target:
		var generic: Node = context.get_node_or_null(target_path)
		if generic and "visible" in generic:
			target = generic
		else:
			push_warning("JuiceeSetActiveEffect: target '%s' not found / not visibility-toggleable" % str(target_path))
			return

	var original_visible: bool = target.visible
	var new_visible: bool
	match action:
		Action.SHOW:   new_visible = true
		Action.HIDE:   new_visible = false
		Action.TOGGLE: new_visible = not original_visible

	target.visible = new_visible

	var tree := context.get_tree()
	if not tree:
		return
	await tree.create_timer(duration, true, false, false).timeout

	if _cancelled or not is_instance_valid(target):
		return
	if restore_on_end:
		target.visible = original_visible
