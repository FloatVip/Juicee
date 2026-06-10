## Juicee — Effects Showcase
##
## A clean keyboard-driven demo of every core effect in the addon.
## NO gameplay logic, NO mechanics — just press a key, see the effect.
##
## Number keys 1-9, 0  → individual effects (one per key)
## H / B               → Hit Stop / Slow-Mo
## X                   → STOP everything (kills running effects + visual overlays)
## Space               → toggle JUICE on/off (sanity check)
extends Node2D

@onready var target: Node2D = $Target
@onready var status_label: Label = $UI/StatusLabel
@onready var juicee_label: Label = $UI/JuiceeLabel

var juicee_on: bool = true

func _ready() -> void:
	_refresh_juicee_label()
	status_label.text = "Press a key — see hint panel on the right"

func _refresh_juicee_label() -> void:
	juicee_label.text = "JUICE: %s   (Space to toggle)" % ("ON" if juicee_on else "OFF")
	juicee_label.modulate = Color(0.4, 1.0, 0.5) if juicee_on else Color(0.9, 0.5, 0.5)

func _show_status(name: String) -> void:
	status_label.text = "▶  %s" % name

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode

	if key == KEY_SPACE:
		juicee_on = not juicee_on
		_refresh_juicee_label()
		return

	if key == KEY_X:
		_stop_everything()
		return

	if not juicee_on:
		_show_status("(JUICE is off — toggle Space)")
		return

	match key:
		KEY_1:
			_show_status("Camera Shake")
			Juicee.shake_camera(self, 12.0, 0.3)
		KEY_2:
			_show_status("Camera Zoom (punch)")
			Juicee.zoom_camera(self, 1.2, 0.4)
		KEY_3:
			_show_status("Chromatic Aberration")
			Juicee.chromatic(self, 8.0, 0.25)
		KEY_4:
			_show_status("Vignette (red)")
			Juicee.vignette(self, 0.7, 0.6, Color(0.6, 0, 0))
		KEY_5:
			_show_status("Blur (full screen)")
			Juicee.blur(self, 4.0, 0.6)
		KEY_6:
			_show_status("Glitch")
			Juicee.glitch(self, 0.6, 0.3)
		KEY_7:
			_show_status("Flash (target)")
			Juicee.flash(target, Color.WHITE, 0.15, 1)
		KEY_8:
			_show_status("Bounce (target scale punch)")
			Juicee.bounce(target, 1.4, 0.35)
		KEY_9:
			_show_status("Burst (particles)")
			Juicee.burst(target, 20, Color(1.0, 0.6, 0.2), 360.0)
		KEY_0:
			_show_status("Confetti")
			Juicee.confetti(target, 40)
		KEY_H:
			_show_status("Hit Stop (80 ms freeze)")
			Juicee.hit_stop(self, 0.08)
		KEY_B:
			_show_status("Slow-Mo (TimeScaleRamp)")
			Juicee.slow_mo(self, 0.2, 0.5)

func _stop_everything() -> void:
	Engine.time_scale = 1.0
	# Sweep any node whose name starts with "_juicee_" — catches all screen
	# overlays plus auto-renamed siblings left behind by interrupted plays.
	_sweep_juicee_overlays(self)
	_show_status("■  STOPPED")

func _sweep_juicee_overlays(node: Node) -> void:
	for child in node.get_children():
		if String(child.name).begins_with("_juicee_"):
			child.queue_free()
		else:
			_sweep_juicee_overlays(child)
