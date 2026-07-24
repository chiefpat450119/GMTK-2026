class_name AtkComponent
extends Node
## Deals an entity's damage, and — when given a hurtbox — owns the hit detection
## that triggers it.
##
## The hurtbox's collision mask already decides who can be hit, so nothing here
## checks concrete types: anything it overlaps that has a damageable pool takes
## the hit. Entities react to contacts through the signals below instead of
## wiring up the Area2D themselves.
##
## Leave hurtbox unset for attacks that land somewhere else — a projectile, say —
## and use damage_for() at the point the hit is rolled.

## Every valid contact, whether or not it dealt damage. Bounce/recoil off this
## one so an entity never sits inside its target on a blocked hit.
signal contacted(body: Node2D)
## A contact that got through the attack_interval gate and actually dealt damage.
signal hit_landed(body: Node2D, damage: float)

@export var atk_stat: Stat

@export var hurtbox: Area2D
@export var contact_damage: float
@export var attack_interval: float
@export var active_on_ready: bool = true

@onready var _attack_cd := Cooldown.new(attack_interval)


func _ready() -> void:
	if not hurtbox:
		set_physics_process(false)
		return

	hurtbox.monitoring = active_on_ready
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	_attack_cd.tick(delta)


## Turns contact damage on and off, for attacks that only connect during part of
## their animation — a bash that hurts while travelling but not while winding up.
func set_active(active: bool) -> void:
	if hurtbox:
		hurtbox.monitoring = active


## Applies this entity's damage to whatever damageable pool the target has.
## Returns false if the target had none. Enemies spend health; the player spends
## time. base is the pre-mod number; global atk mods are applied here.
func attack(base: float, target: Node) -> bool:
	var damage := damage_for(base)

	var health := HealthComponent.find_in(target)
	if health:
		health.remove_hp(damage)
		return true

	var time := TimeComponent.find_in(target)
	if time:
		time.remove_time(damage)
		return true

	return false


func damage_for(base: float) -> float:
	return atk_stat.current_val(base)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	contacted.emit(body)

	# is_started() is false until the first hit, so the opening contact always lands.
	if _attack_cd.is_started() and not _attack_cd.is_done():
		return

	if not attack(contact_damage, body):
		return

	_attack_cd.start()
	hit_landed.emit(body, damage_for(contact_damage))
