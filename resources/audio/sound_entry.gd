class_name SoundEntry
extends Resource
## One playable sound in a SoundBank. See sound_bank.gd.

## Bank key — what callers pass to SFX.play().
@export var id: StringName

## The clip. Wrap it in an AudioStreamRandomizer to get variation: the
## randomizer bakes its pitch and volume roll into each playback instance as it
## starts, which is the only way voices sharing one player can differ from each
## other. A randomizer holding a single stream is still worth it for that alone.
@export var stream: AudioStream

@export var bus: StringName = &"SFX"
@export_range(-40.0, 12.0, 0.1) var volume_db: float = 0.0

## Concurrent voices. Overflow cuts the oldest. Keep this low — four copies of
## one clip sum to roughly +12 dB and comb-filter into a single flanged smear
## rather than reading as four separate events.
@export_range(1, 16) var max_polyphony: int = 1

## Minimum seconds between two starts of this sound. max_polyphony caps how many
## voices overlap, but won't stop a held trigger from starting one every frame
## and continuously evicting the oldest — this is what does.
@export_range(0.0, 1.0, 0.01) var retrigger_cooldown: float = 0.0
