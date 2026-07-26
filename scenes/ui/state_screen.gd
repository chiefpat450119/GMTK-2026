class_name StateScreen
extends Control
## Base for a full-screen menu that belongs to exactly one game state.
##
## Visibility is derived, never set by hand: the screen is up if and only if
## GameStateManager is in `state`. That is what stops Escape, Retry and the
## upgrade screen from disagreeing about what is on screen — a menu can never be
## left visible over a running game, because nothing but the state drives it.
##
## Screens live under main.tscn's UI layer, which is PROCESS_MODE_ALWAYS, so
## their buttons still respond while the tree is paused.

@export var state: GameStateManager.GameState = GameStateManager.GameState.MAIN_MENU


func _ready() -> void:
	GameStateManager.instance.state_changed.connect(_on_state_changed)
	var active := GameStateManager.instance.state == state
	visible = active
	if active:
		_on_shown()


func _on_state_changed(_from: int, to: int) -> void:
	_apply(to)


func _apply(current: int) -> void:
	var active := current == state
	if active == visible:
		return
	visible = active
	if active:
		_on_shown()
	else:
		_on_hidden()


## Called the frame the screen goes up. Override to refresh contents.
func _on_shown() -> void:
	pass


## Called the frame the screen comes down.
func _on_hidden() -> void:
	pass
