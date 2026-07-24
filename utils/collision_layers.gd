class_name CollisionLayers
extends RefCounted
## Physics layer bits, mirrored from the layer assignments in the entity scenes
## and from project.godot's layer names.
##
## Kept in one place because masks are also built at runtime (see Projectile),
## and those would otherwise drift from what the scenes are set to.

const PLAYER := 1 << 0  ## Layer 1 — the player body
const ENEMY := 1 << 1  ## Layer 2 — enemy bodies
