class_name GameStateManager
extends Node
## Master game state machine. A node in main.tscn, reached from anywhere as
## `GameStateManager.instance`.
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

static var instance: GameStateManager

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	UPGRADING,
	GAME_OVER,
}

## Emitted after `state` is already updated, so handlers can read it directly.
signal state_changed(from: GameState, to: GameState)

const PAUSE_ACTION := &"Pause"

## Rebuilt from scratch on every start_run(). Its root must be a GameWorld.
@export var world_scene: PackedScene
## Every Stat that carries run-scoped Modifiers. Cleared between runs.
@export var stat_registry: StatRegistry
## Raised to put the upgrade screen up.
@export var upgrade_offer_event: GameEvent

var state: GameState = GameState.MAIN_MENU

# Static so the autoloads can register before this node exists.
static var _resettables: Array[Node] = []

var _world_mount: Node = null
var _world: GameWorld = null
var _pending_upgrades: int = 0


func _enter_tree() -> void:
	if instance != null and instance != self:
		push_error("Duplicate GameStateManager")
		queue_free()
		return
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _ready() -> void:
	# In code rather than the .tscn: if this is ever not ALWAYS by accident, pausing
	# stops the manager that owns unpausing and the game locks up for good.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(PAUSE_ACTION):
		return
	# Ignored during UPGRADING and GAME_OVER — those are modal by design.
	if state == GameState.PLAYING or state == GameState.PAUSED:
		get_viewport().set_input_as_handled()
		toggle_pause()


## Handed the node that runs are instanced under, by main.tscn on ready.
func bind_shell(world_mount: Node) -> void:
	_world_mount = world_mount


## Registers a node whose reset() drops run-scoped state — EnemyStatScaler's
## wave scaling, UpgradeManager's stack counts. Keeps this manager from needing
## to know either type, or the order they happen to load in.
static func register_resettable(node: Node) -> void:
	if not _resettables.has(node):
		_resettables.append(node)


static func unregister_resettable(node: Node) -> void:
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
	_set_state(GameState.PLAYING)
	_world.begin()


func pause() -> void:
	if state != GameState.PLAYING:
		return
	_set_state(GameState.PAUSED)


func resume() -> void:
	if state != GameState.PAUSED:
		return
	_set_state(GameState.PLAYING)


func toggle_pause() -> void:
	if state == GameState.PLAYING:
		pause()
	elif state == GameState.PAUSED:
		resume()


## Puts the upgrade screen up, or queues another one behind the one already up.
## Safe to call several times in the same frame — a big XP pickup does exactly
## that, once per level it granted.
func request_upgrade() -> void:
	if state != GameState.PLAYING and state != GameState.UPGRADING:
		return
	_pending_upgrades += 1
	# Already showing cards: the offer waits until that one is picked.
	if state == GameState.UPGRADING:
		return
	# UPGRADING pauses the tree through _apply_pause(), so the world is frozen
	# behind the cards without UpgradeUI touching get_tree().paused itself.
	_set_state(GameState.UPGRADING)
	upgrade_offer_event.raise()


## Called by UpgradeUI once a card has been applied. Stays in UPGRADING and
## offers again if more level-ups are still owed.
func close_upgrades() -> void:
	if state != GameState.UPGRADING:
		return
	_pending_upgrades = maxi(_pending_upgrades - 1, 0)
	if _pending_upgrades > 0:
		upgrade_offer_event.raise()
		return
	_set_state(GameState.PLAYING)


## Drops every queued offer and hands the game back. For when the screen has
## nothing to show — an empty pool would otherwise leave the player staring at
## a queue that can never be worked through.
func cancel_upgrades() -> void:
	if state != GameState.UPGRADING:
		return
	_pending_upgrades = 0
	_set_state(GameState.PLAYING)


## Time ran out. Only reachable from PLAYING — the clock doesn't tick anywhere else.
func game_over() -> void:
	if state != GameState.PLAYING:
		return
	_set_state(GameState.GAME_OVER)


func to_main_menu() -> void:
	if state == GameState.MAIN_MENU:
		return
	_pending_upgrades = 0
	_teardown_world()
	_set_state(GameState.MAIN_MENU)


# --- internals ---

func _reset_run() -> void:
	# Offers owed to the previous run die with it — a retry out of a queued
	# upgrade screen would otherwise open cards over the fresh world.
	_pending_upgrades = 0
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


func _set_state(next: GameState) -> void:
	if next == state:
		return
	var previous := state
	state = next
	_apply_pause()
	state_changed.emit(previous, next)


func _apply_pause() -> void:
	get_tree().paused = state != GameState.PLAYING
