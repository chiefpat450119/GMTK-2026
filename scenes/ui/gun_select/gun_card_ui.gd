class_name GunCardUI
extends Button

signal selected(gun: GunData)

@export var icon_rect: TextureRect
@export var title_label: Label
@export var description_label: Label

var _gun : GunData

func _ready() -> void:
	
	pressed.connect(_on_pressed)
	# The root handles the click, so nothing layered on top may swallow it.
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(gun: GunData) -> void:
	_gun = gun
	
	title_label.text = gun.title
	description_label.text = gun.description
	icon_rect.texture = gun.icon


func _on_pressed():
	if _gun == null:
		return
	selected.emit(_gun)
