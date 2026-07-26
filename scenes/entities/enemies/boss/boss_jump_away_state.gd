class_name BossJumpAwayState
extends State

const JUMP_SQUAT_TIME: float = 0.5
const jump_cooldown: float = 0.5 # delay before starting next state

@export var enemy: Enemy
@export var selector_state: SelectorState

@export var jump_land_atk: AtkComponent

@export var sprite: Sprite2D
@export var collider: CollisionShape2D


@export var jump_duration: float = 1.0 # duration from jump to land
@export var jump_height: float = 100.0 # sprite/collider y offset 

@onready var jump_timer := Cooldown.new(jump_duration)

var land_target := Vector2.ZERO
var jump_speed : float

func enter():
	# play animation
	super()
	
	await get_tree().create_timer(JUMP_SQUAT_TIME).timeout
	
	land_target = enemy.get_player_pos()
	var jump_distance := enemy.get_to_player_vec().length()
	jump_speed = jump_distance / jump_duration
	
	jump_timer.start()

func physics_tick(_delta: float):
	if jump_timer.is_started():
		jump(land_target, _delta)
		jump_timer.tick(_delta)


func jump(land_pos: Vector2, delta: float):
	enemy.global_position = enemy.global_position.move_toward(land_pos, jump_speed * delta)
	
	var t := clampf(jump_timer.percent_complete(), 0.0, 1.0)
	var jump_offset := -4.0 * jump_height * t * (1.0 - t)
	offset_sprite(jump_offset)
	
	if jump_timer.is_done():
		land()

func land():
	jump_timer.stop()
	offset_sprite(0)
	
	jump_land_atk.set_active(true)
	#play land anim or fx
	await get_tree().create_timer(jump_cooldown).timeout
	jump_land_atk.set_active(false)

	
	switch_state(selector_state)
	#spawn atk


func offset_sprite(offset: float):
	var offset_vec := offset * Vector2.DOWN 
	sprite.offset = offset_vec
	collider.position = offset_vec

func exit():

	super()
