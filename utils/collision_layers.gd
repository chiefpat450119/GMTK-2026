class_name CollisionLayers
extends RefCounted
## Physics layer bits, mirrored from the layer assignments in the entity scenes
## and from project.godot's layer names.
##
## Kept in one place because masks are also built at runtime (see Projectile),
## and those would otherwise drift from what the scenes are set to.

const PLAYER := 1 << 0  ## Layer 1 — the player body
const WALL := 1 << 1    ## Layer 2 — the walls of the arena

const ENEMY := 1 << 3   ## Layer 4 — enemy bodies
