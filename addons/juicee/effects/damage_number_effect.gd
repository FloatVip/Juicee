## Floating damage numbers — the classic action-game hit feedback.
##
## Spawns a `Label` at the target's world position, floats it upward with
## fade-out, and supports crit styling (bigger font + alt color + scale punch).
##
## Caller passes the damage value (and optional crit flag) via runtime params:
## [codeblock]
## # Plain hit
## juice.play({"damage": 42})
## # Critical hit
## juice.play({"damage": 999, "is_crit": true})
## [/codeblock]
## If no `damage` key is passed, `default_damage` is used.
@tool
class_name JuiceeDamageNumberEffect
extends JuiceeEffect

## Default damage value when the caller doesn't pass `damage` via runtime params.
@export var default_damage: int = 10
## Color for normal damage hits.
@export var color: Color = Color.WHITE
## Color override for critical hits (when `is_crit` is true in params).
@export var crit_color: Color = Color(1.0, 0.85, 0.20, 1.0)
## How far up the number floats (pixels) before fading away.
@export_range(0.0, 300.0, 1.0) var rise_distance: float = 80.0
## Random horizontal offset spread so overlapping hits don't stack perfectly.
@export_range(0.0, 100.0, 1.0) var spread: float = 40.0
## Font size in pixels for normal hits.
@export_range(8, 128, 1) var font_size: int = 28
## Multiplier for crit font_size (so crits feel bigger).
@export_range(1.0, 3.0, 0.1) var crit_size_multiplier: float = 1.5
## Optional custom font. Leave null to use the project's default UI font.
@export var font: Font
## Total animation duration (rise + fade).
@export_range(0.1, 5.0, 0.05) var duration: float = 0.8
## Optional prefix text (e.g. "-" for damage, "+" for healing, "✦" for special).
@export var prefix: String = ""
## Black outline around the digits — keeps numbers readable on any background.
@export var outline_width: int = 2

func get_category_color() -> Color:
	return Color(0.95, 0.42, 0.21)

func get_category_name() -> String:
	return "Text"

func _apply(context: Node, intensity_mult: float) -> void:
	var target: Node2D = context as Node2D
	if not target or not target.is_inside_tree():
		push_warning("JuiceeDamageNumberEffect: context is not a Node2D")
		return

	# Pull damage + crit flag from runtime params, fall back to defaults.
	var damage_value: int = int(_runtime_params.get("damage", default_damage))
	var is_crit: bool = bool(_runtime_params.get("is_crit", false))

	var label := Label.new()
	label.name = StringName("_juicee_damage_%d" % randi())
	label.text = prefix + str(damage_value)
	label.add_theme_color_override("font_color", crit_color if is_crit else color)
	if outline_width > 0:
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", outline_width)
	var effective_size: int = int(font_size * (crit_size_multiplier if is_crit else 1.0))
	label.add_theme_font_size_override("font_size", effective_size)
	if font:
		label.add_theme_font_override("font", font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Parent into the active scene so the label exists in world space.
	# Spawning under the target itself would inherit any local transforms we
	# don't want (e.g., the target's flash/squash animation).
	var spawn_parent: Node = target.get_tree().current_scene
	if not spawn_parent:
		spawn_parent = target
	spawn_parent.add_child(label)

	# One frame to let the Label compute its content size before we center it.
	await target.get_tree().process_frame
	if not is_instance_valid(label):
		return

	var spread_offset := randf_range(-spread, spread) * 0.5
	var start_pos := target.global_position + Vector2(spread_offset, 0) - label.size * 0.5
	label.global_position = start_pos

	# Parallel tween: rise + fade.
	var end_pos := start_pos + Vector2(0, -rise_distance * intensity_mult)
	var tween := _track(label.create_tween()).set_parallel(true)
	tween.tween_property(label, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration * 0.7).set_delay(duration * 0.3)

	# Crit scale-punch at the start so big hits feel weighty.
	if is_crit:
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2(0.5, 0.5)
		var punch := _track(label.create_tween())
		punch.tween_property(label, "scale", Vector2.ONE * 1.2, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		punch.tween_property(label, "scale", Vector2.ONE, 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	if is_instance_valid(label):
		label.queue_free()
