class_name BossJumpState
extends State

enum LandTargetType {
	TOWARD_PLAYER,
	AWAY_FROM_PLAYER
}

const JUMP_SQUAT_TIME: float = 0.5
const JUMP_SQUAT_TIME_FAST: float = 0.2
const JUMP_COOLDOWN: float = 0.5 # delay before starting next state
const JUMP_AWAY_DISTANCE: int = 100

@export var land_target_type: LandTargetType

@export var enemy: Enemy
@export var selector_state: SelectorState

@export var jump_land_atk: AtkComponent

#@export var sprite: Sprite2D
@export var collider: CollisionShape2D


@export var jump_duration: float = 1.0 # duration from jump to land
@export var jump_height: float = 100.0 # sprite/collider y offset 

@onready var jump_timer := Cooldown.new(jump_duration)

var land_target := Vector2.ZERO
var jump_speed : float

var _landed = false

func enter():
	# play animation
	super()
	_landed = false
	
	await jump_squat_delay(land_target_type)
	jump_anim()
	await get_tree().create_timer(0.2).timeout
	
	land_target = get_land_pos(land_target_type)
	var jump_distance := enemy.position.distance_to(land_target)
	jump_speed = jump_distance / jump_duration
	
	jump_timer.start()


func jump_anim():
	SFX.play(&"boss_jump")
	SFX.play(&"boss_jump2")
	SFX.play(&"boss_jump3")
	await get_tree().create_timer(play_anim(&"Jump_Airborne")).timeout
	if not _landed:
		play_anim(&"Jump_Airborne_Freeze")


func physics_tick(_delta: float):
	if jump_timer.is_started():
		jump(land_target, _delta)
		jump_timer.tick(_delta)

func jump_squat_delay(target_type: LandTargetType):
	var yield_time: float
	match target_type:
		LandTargetType.TOWARD_PLAYER:
			SFX.play(&"boss_squat_short")
			yield_time = play_anim(&"Jump")
		LandTargetType.AWAY_FROM_PLAYER:
			SFX.play(&"boss_squat_long")
			yield_time = play_anim(&"Jump", 2.0)
		_:
			return play_anim(&"Jump")

	await get_tree().create_timer(yield_time).timeout

func get_land_pos(target_type: LandTargetType) -> Vector2:
	match target_type:
		LandTargetType.TOWARD_PLAYER:
			return enemy.get_player_pos()
		LandTargetType.AWAY_FROM_PLAYER:
			return _find_away_target()
		_:
			return Vector2.ZERO
		

func _find_away_target() -> Vector2:
	var rot := randf() * 2 * PI
	var pos := Vector2.from_angle(rot) * JUMP_AWAY_DISTANCE
	return pos

func jump(land_pos: Vector2, delta: float):
	enemy.global_position = enemy.global_position.move_toward(land_pos, jump_speed * delta)
	
	var t := clampf(jump_timer.percent_complete(), 0.0, 1.0)
	var jump_offset := -4.0 * jump_height * t * (1.0 - t)
	offset_sprite(jump_offset)
	
	if jump_timer.is_done():
		land()

func land():
	SFX.play(&"boss_land")
	jump_timer.stop()
	offset_sprite(0)
	
	_landed = true
	
	CameraShake.shake(1)
	
	jump_land_atk.set_active(true)
	#play land anim or fx
	await get_tree().create_timer(play_anim(&"Jump_End")).timeout
	jump_land_atk.set_active(false)

	
	switch_state(selector_state)


func offset_sprite(offset: float):
	var offset_vec := offset * Vector2.DOWN 
	anim.position = offset_vec
	collider.position = offset_vec
	jump_land_atk.position = offset_vec

func exit():

	super()
