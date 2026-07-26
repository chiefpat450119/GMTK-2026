class_name Player
extends CharacterBody2D
## Singleton containing data of relevant componentns for ease of access

static var instance: Player

@export var time_component : TimeComponent
@export var movement_component : MovementComponent
@export var dash_component : DashComponent
@export var sprite : AnimatedSprite2D

@export var gun_holder: GunHolder

@export var after_image: AfterImageSpawner
var _after_image_timer: float

## Last non-zero movement input, so a dash tapped from a standstill still travels
## the way the player was last headed instead of being spent on nothing.
var _last_dir: Vector2 = Vector2.RIGHT


func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free() # Prevents duplicate instances from existing

func _exit_tree() -> void:
	# The world is freed and rebuilt between runs, so a stale instance here would
	# leave enemies chasing a dead Player. Guarded because duplicates that were
	# freed above also pass through here without ever having claimed the slot.
	if instance == self:
		instance = null

func _ready() -> void:
	dash_component.dash_started.connect(_on_dash_started)


func _on_dash_started(_origin: Vector2, iframe_duration: float) -> void:
	time_component.grant_invulnerability(iframe_duration)


func _physics_process(_delta: float) -> void:
	dash_component.tick(_delta)

	var dir: Vector2 = Input.get_vector("Left", "Right", "Up", "Down")
	if dir != Vector2.ZERO:
		_last_dir = dir
	dash_component.request_dash(Input.is_action_just_pressed("Dash"), _last_dir)

	if dash_component.is_dashing():
		dash_component.move_dash()
		spawn_after_image(_delta)
	else:
		movement_component.move(dir)
		_after_image_timer = 0.0

	_update_sprite(dir)


func spawn_after_image(delta):
	#copy sprite current frame sprite. spawn afterimage every 0.1s
	_after_image_timer -= delta
	if _after_image_timer > 0.0:
		return
		
	_after_image_timer = 0.1
	
	var frame_texture := sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)
	

	var image = after_image.spawn_image(self, frame_texture)
	sprite.visible = false
	image.flip_h = sprite.flip_h
	image.global_transform = sprite.global_transform
	image.scale = sprite.scale
	await get_tree().create_timer(.001).timeout
	sprite.visible = true


## A dash holds its launch pose for its whole duration, matching the locked
## movement direction, so releasing or reversing the keys mid-dash can't flip the
## character out from under the motion.
func _update_sprite(dir: Vector2) -> void:
	if dash_component.is_dashing():
		var dash_dir: Vector2 = dash_component.dash_direction()
		if absf(dash_dir.x) >= absf(dash_dir.y):
			sprite.animation = &"Dash_Left_Right"
			sprite.flip_h = dash_dir.x < 0.0
		elif dash_dir.y < 0.0:
			sprite.animation = &"Dash_Up"
		else:
			sprite.animation = &"Dash_Down"
		return
	elif dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			sprite.animation = &"Move_Side"
			sprite.flip_h = dir.x < 0.0
		elif dir.y < 0.0:
			sprite.animation = &"Move_Up"
		else:
			sprite.animation = &"Move_Down"
		return

		

	sprite.animation = &"Idle"
	if dir.x < 0.0:
		sprite.flip_h = true
	elif dir.x > 0.0:
		sprite.flip_h = false
