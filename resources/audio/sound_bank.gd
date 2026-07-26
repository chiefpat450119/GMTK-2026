class_name SoundBank
extends Resource
## Every sound effect in the game, as data. The SFX autoload builds one
## AudioStreamPlayer per entry from this on boot.
##
## Adding a sound is an inspector edit plus one SFX.play() call — nothing needs
## a new @export, and no scene has to own an AudioStreamPlayer.

@export var entries: Array[SoundEntry] = []
