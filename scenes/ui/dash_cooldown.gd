class_name DashCooldown
extends Control
## One dash icon per charge the player can bank, filling left to right.
##
## Only the first icon is authored. Everything under this node is treated as the
## template for a single charge and cloned for the rest, so the art, size, offsets
## and fill mode stay defined in exactly one place — a designer restyling the
## icon in the scene gets every charge for free, and adding a charge needs no
## scene work at all.
##
## Charges come from an upgrade, so the count changes mid-run and is re-checked
## every frame rather than fixed at _ready().

## Gap between icons, in this node's local space, so the parent's scale applies to
## it like it does to the icons themselves. The authored icon is 200 wide, so this
## is that plus a little air.
@export var spacing: float = 210.0

## The authored progress bar. Must be a direct child: its siblings are what get
## cloned alongside it, and the clone is found by position among them.
@export var fill: TextureProgressBar

# The authored icon's nodes, captured before any cloning. Index of `fill` within
# it tells a fresh clone which of its nodes is the bar.
var _template: Array[Node] = []
var _fill_index: int = -1

# One entry per charge, parallel to the component's charge indices. Index 0 is the
# authored icon; the rest are clones. _icons holds every node of each icon so a
# removed one can be freed as a group.
var _icons: Array[Array] = []
var _fills: Array[TextureProgressBar] = []


func _ready() -> void:
	if fill == null:
		push_warning("DashCooldown has no fill assigned")
		set_process(false)
		return

	_template = get_children()
	_fill_index = _template.find(fill)
	if _fill_index == -1:
		# Cloning walks the direct children only, so a bar nested deeper would be
		# duplicated but never found again. Degrade to the single authored icon
		# rather than silently showing charges that never fill.
		push_warning("DashCooldown expects `fill` to be a direct child; extra charges will not be shown")

	_icons.append(_template)
	_fills.append(_init_bar(fill))


func _process(_delta: float) -> void:
	# The player enters the tree alongside the HUD, hence the guard on the first
	# frames.
	if Player.instance == null:
		return
	var dash := Player.instance.dash_component
	_match_icon_count(dash.max_charges())

	var available := dash.charges_available()
	var refilling := dash.recharge_progress()
	for i in _fills.size():
		# Banked charges read full, the next one in line shows the sweep, and
		# anything past that is still empty.
		if i < available:
			_fills[i].value = 1.0
		elif i == available:
			_fills[i].value = refilling
		else:
			_fills[i].value = 0.0


# Grows by cloning the authored icon and shrinks by freeing those clones. Never
# touches index 0, so the node the scene actually wired up always survives.
func _match_icon_count(count: int) -> void:
	count = maxi(count, 1)
	if _fill_index == -1:
		return
	while _fills.size() < count:
		_add_icon()
	while _fills.size() > count:
		_remove_icon()


func _add_icon() -> void:
	var offset := Vector2(spacing * _icons.size(), 0.0)
	var clones: Array[Node] = []
	for node in _template:
		var clone := node.duplicate()
		# Only the laid-out half of the template needs shifting; anything else the
		# icon happens to carry is copied as-is.
		if clone is Control:
			(clone as Control).position = (node as Control).position + offset
		add_child(clone)
		clones.append(clone)
	_icons.append(clones)
	_fills.append(_init_bar(clones[_fill_index] as TextureProgressBar))


func _remove_icon() -> void:
	_fills.pop_back()
	# Freed as the group that was added together, rather than by counting back
	# from the last child: queue_free() is deferred, so dropping more than one
	# charge in a single frame would otherwise still see the previous icon in
	# place, free it twice and leave this one behind.
	for node in _icons.pop_back():
		node.queue_free()


# The component reports a 0..1 ratio, so the bar reads it straight. step 0 keeps
# the sweep continuous instead of snapping to 1% notches.
func _init_bar(bar: TextureProgressBar) -> TextureProgressBar:
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = 0.0
	return bar
