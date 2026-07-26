@tool
extends "res://scenes/ui/utils/nine_patch_button.gd"
## The button under Play: cycles the difficulty and hands it to EnemyStatScaler,
## which is where the setting actually means something -- how fast enemy stats
## climb per wave. Nothing is stored here; the caption is read back off the
## scaler, so the button can never show a difficulty the run won't be played at.
##
## Extends the nine-patch button rather than sitting beside it as a child node,
## because the caption is the thing that changes and that is the parent's to set.

## What each difficulty is called on the face of the button.
const LABELS := {
	EnemyStatScaler.Difficulty.EASY: "Difficulty: Easy",
	EnemyStatScaler.Difficulty.HARD: "Difficulty: Hard",
}

# The order the button steps through. Listed rather than derived so a difficulty
# added to the enum for tuning doesn't silently appear in the menu.
const ORDER: Array = [
	EnemyStatScaler.Difficulty.EASY,
	EnemyStatScaler.Difficulty.HARD,
]


# @tool, purely so the base class keeps drawing its nine-patch in the editor the
# way it does on every other button -- a non-tool script here would stop the
# whole chain from running there. Nothing below it should run in the editor:
# autoloads don't exist there, so the scaler can't be read.
func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	# The setting survives a return to the menu, so the caption starts from
	# whatever was last chosen rather than from the scene's authored text.
	_refresh()


# The base class already connects `pressed` to this, and that connection resolves
# to the override -- connecting again here would run it, and the click sound,
# twice.
func _on_pressed() -> void:
	super()
	var next: int = (ORDER.find(EnemyStatScalerInstance.difficulty) + 1) % ORDER.size()
	EnemyStatScalerInstance.difficulty = ORDER[next]
	_refresh()


func _refresh() -> void:
	label_text = LABELS[EnemyStatScalerInstance.difficulty]
