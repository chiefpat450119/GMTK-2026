extends Node
## Master game state machine. Autoloaded as `GameStateManager`.
##
## Owns three things nothing else may touch:
##   1. `get_tree().paused`. Everything else reacts to state_changed instead of
##      setting the flag, or the pause menu and the upgrade screen end up
##      fighting over it — close a card while paused and you'd resume the game
##      behind the pause menu.
##   2. The run lifecycle: rebuilding the world, and clearing the run state that
##      lives in shared Stat resources.
##   3. The handoff to the upgrade screen, so the game is reliably paused behind
##      it and reliably running again once a card is picked.
##
## main.tscn hands over its world mount with bind_shell() on ready. Until that
## lands this sits in MAIN_MENU and start_run() is a no-op.

enum State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	UPGRADING,
	GAME_OVER,
}

## Emitted after `state` is already updated, so handlers can read it directly.
signal state_changed(from: State, to: State)

const PAUSE_ACTION := &"Pause"

## Rebuilt from scratch on every start_run(). Its root must be a GameWorld.
@export var world_scene: PackedScene
## Every Stat that carries run-scoped Modifiers. Cleared between runs.
@export var stat_registry: StatRegistry
## Raised to put the upgrade screen up.
@export var upgrade_offer_event: GameEvent

var state: State = State.MAIN_MENU

var _world_mount: Node = null
var _world: GameWorld = null
var _resettables: Array[Node] = []


func _ready() -> void:
	# In code rather than the .tscn: if this is ever ALWAYS by accident, pausing
	# stops the manager that owns unpausing and the game locks up for good.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(PAUSE_ACTION):
		return
	# Ignored during UPGRADING and GAME_OVER — those are modal by design.
	if state == State.PLAYING or state == State.PAUSED:
		get_viewport().set_input_as_handled()
		toggle_pause()


## Handed the node that runs are instanced under, by main.tscn on ready.
func bind_shell(world_mount: Node) -> void:
	_world_mount = world_mount


## Registers a node whose reset() drops run-scoped state — EnemyStatScaler's
## wave scaling, UpgradeManager's stack counts. Keeps this manager from needing
## to know either type, or the order they happen to load in.
func register_resettable(node: Node) -> void:
	if not _resettables.has(node):
		_resettables.append(node)


func unregister_resettable(node: Node) -> void:
	_resettables.erase(node)


# --- transitions ---

## Starts a fresh run: tears the old world down, wipes run state, rebuilds.
## Retry goes through here too, so nothing can leak between attempts.
func start_run() -> void:
	if _world_mount == null:
		push_error("start_run() called before bind_shell() — no world mount")
		return
	# Teardown first: the old world's nodes shouldn't be alive to react to
	# stats being cleared out from under them.
	_teardown_world()
	_reset_run()
	if not _build_world():
		return
	_set_state(State.PLAYING)
	_world.begin()


func pause() -> void:
	if state != State.PLAYING:
		return
	_set_state(State.PAUSED)


func resume() -> void:
	if state != State.PAUSED:
		return
	_set_state(State.PLAYING)


func toggle_pause() -> void:
	if state == State.PLAYING:
		pause()
	elif state == State.PAUSED:
		resume()


## Puts the upgrade screen up.
func request_upgrade() -> void:
	if state != State.PLAYING:
		return
	# UPGRADING pauses the tree through _apply_pause(), so the world is frozen
	# behind the cards without UpgradeUI touching get_tree().paused itself.
	_set_state(State.UPGRADING)
	upgrade_offer_event.raise()


## Called by UpgradeUI once a card has been applied.
func close_upgrades() -> void:
	if state != State.UPGRADING:
		return
	_set_state(State.PLAYING)


## Time ran out. Only reachable from PLAYING — the clock doesn't tick anywhere else.
func game_over() -> void:
	if state != State.PLAYING:
		return
	_set_state(State.GAME_OVER)


func to_main_menu() -> void:
	if state == State.MAIN_MENU:
		return
	_teardown_world()
	_set_state(State.MAIN_MENU)


# --- internals ---

func _reset_run() -> void:
	# Stats are shared Resources, cached by the engine for the whole process, so
	# a run's Modifiers outlive the scene they were picked in. Reloading the
	# scene does not undo them — this does.
	if stat_registry:
		stat_registry.clear_all()
	for node in _resettables:
		if is_instance_valid(node):
			node.call(&"reset")


func _build_world() -> bool:
	if world_scene == null:
		push_error("GameStateManager has no world_scene assigned")
		return false
	_world = world_scene.instantiate() as GameWorld
	if _world == null:
		push_error("world_scene's root node must be a GameWorld")
		return false
	_world_mount.add_child(_world)
	return true


func _teardown_world() -> void:
	if _world == null:
		return
	# free(), not queue_free(): a deferred free leaves the outgoing Player alive
	# beside the incoming one for a frame, and Player._enter_tree() frees
	# whichever it decides is the duplicate — sometimes the new one.
	_world_mount.remove_child(_world)
	_world.free()
	_world = null


func _set_state(next: State) -> void:
	if next == state:
		return
	var previous := state
	state = next
	_apply_pause()
	state_changed.emit(previous, next)


func _apply_pause() -> void:
	get_tree().paused = state != State.PLAYING
