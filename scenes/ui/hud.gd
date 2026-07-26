extends Control
## Run HUD: the time machine readout and the XP meter.
##
## Lives in the shell rather than the world so it survives the rebuild between
## runs — which is why nothing here holds a reference to the player. Both halves
## resolve what they need from Player.instance when their event fires.

## TimeHud is its own CanvasLayer, so it renders independently of this Control
## and has to be shown and hidden alongside it by hand.
@export var time_hud: CanvasLayer
@export var xp_bar: ProgressBar
@export var level_label: Label
@export var xp_listener: GameEventListener


func _ready() -> void:
	xp_listener.response.connect(_on_xp_changed)
	GameStateManager.instance.state_changed.connect(_on_state_changed)
	_apply_visibility(GameStateManager.instance.state)


func _on_state_changed(_from: int, to: int) -> void:
	_apply_visibility(to)


func _apply_visibility(current: int) -> void:
	# Up for the whole run, including behind the pause and upgrade screens: how
	# much time and XP you have is part of what you're deciding on when a card is
	# in front of you.
	var showing := current == GameStateManager.GameState.PLAYING \
		or current == GameStateManager.GameState.PAUSED \
		or current == GameStateManager.GameState.UPGRADING
	visible = showing
	time_hud.visible = showing
	if showing:
		# The meter is still drawing the last run's level at this point — this HUD
		# outlives the world that owns the LevelComponent, and nothing raises the
		# XP event until the first pickup. GameStateManager enters PLAYING after
		# the new player is in the tree, so there is a fresh component to read.
		# Also fires on unpause and on closing a card, which just redraws the same
		# numbers.
		_on_xp_changed()


func _on_xp_changed() -> void:
	if Player.instance == null:
		return
	var level := LevelComponent.find_in(Player.instance)
	if level == null:
		return
	xp_bar.max_value = level.requirement()
	xp_bar.value = level.xp
	level_label.text = "Lv %d" % level.level
