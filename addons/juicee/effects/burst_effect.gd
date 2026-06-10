@tool
class_name JuiceeBurstEffect
extends JuiceeEffect

## Number of particles to emit.
@export_range(1, 128, 1) var amount: int = 12
## Average particle speed (actual is randomized 0.7×–1.3× this).
@export_range(0.0, 500.0, 1.0) var speed: float = 120.0
## Spread angle in degrees (180 = full circle, 90 = quarter).
@export_range(0.0, 180.0, 1.0) var spread: float = 120.0
## How long particles live before disappearing.
@export_range(0.05, 5.0, 0.05) var lifetime: float = 0.5
## Particle color.
@export var color: Color = Color(1.0, 0.8, 0.3, 1.0)
## Gravity applied per second to particles (e.g., Vector2(0, 980) for falling).
@export var gravity: Vector2 = Vector2.ZERO

func get_category_color() -> Color:
	return Color(0.22, 0.58, 1.00)

func _apply(context: Node, intensity_mult: float) -> void:
	# Particles render in editor preview — no global side effects on the editor.
	var origin: Node2D = context as Node2D
	if not origin:
		push_warning("JuiceeBurstEffect: context is not a Node2D")
		return
	if not origin.is_inside_tree():
		return

	var effective_amount := max(1, int(amount * intensity_mult))
	var effective_speed := speed * intensity_mult
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = effective_amount
	p.lifetime = lifetime
	p.initial_velocity_min = effective_speed * 0.7
	p.initial_velocity_max = effective_speed * 1.3
	p.spread = spread
	p.gravity = gravity
	p.color = color
	p.global_position = origin.global_position
	origin.get_tree().current_scene.add_child(p)
	p.emitting = true
	await origin.get_tree().create_timer(lifetime + 0.15, true, false, false).timeout
	if is_instance_valid(p):
		p.queue_free()
