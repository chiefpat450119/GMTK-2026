class_name DebugMenu
extends Control
## Debug menu — only active in debug builds. Toggle with F1 while playing or paused.
##
## Features:
##   • God Mode: freezes the player's time bar so it never drains.
##   • Spawn Boss: immediately triggers the boss sequence on the current world's spawner,
##     skipping the wave requirement.

# Keep it compile-time safe: the whole script becomes a no-op in release exports.
# (OS.is_debug_build() is checked at runtime so testers on debug exports still get it.)

const TOGGLE_ACTION := &"ui_debug_menu" # We'll fall back to scancode if unbound

@export var god_mode_button: Button
@export var spawn_boss_button: Button
@export var panel: PanelContainer

static var god_mode: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	god_mode_button.pressed.connect(_on_god_mode_button_pressed)
	spawn_boss_button.pressed.connect(_on_spawn_boss_button_pressed)
	_refresh_god_mode_label()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	# Toggle on F1 (fallback scancode check so it works even if the action isn't in project settings)
	var toggled := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			toggled = true

	if not toggled:
		return

	var gsm := GameStateManager.instance
	if gsm == null:
		return

	# Only open while actually in-run (playing or paused — not in menus/victory/etc.)
	var in_run := gsm.state == GameStateManager.GameState.PLAYING \
			   or gsm.state == GameStateManager.GameState.PAUSED
	if not in_run and not visible:
		return

	visible = not visible
	get_viewport().set_input_as_handled()


func _on_god_mode_button_pressed() -> void:
	god_mode = not god_mode
	_refresh_god_mode_label()


func _refresh_god_mode_label() -> void:
	if god_mode_button == null:
		return
	god_mode_button.text = "God Mode: ON" if god_mode else "God Mode: OFF"
	god_mode_button.modulate = Color(0.4, 1.0, 0.5) if god_mode else Color(1, 1, 1)


func _on_spawn_boss_button_pressed() -> void:
	var world := GameStateManager.instance.get_world()
	if world == null:
		push_warning("DebugMenu: no active GameWorld (is a run in progress?)")
		return

	if world.spawner == null:
		push_warning("DebugMenu: GameWorld has no spawner assigned")
		return

	world.spawner.spawn_boss()
	visible = false
