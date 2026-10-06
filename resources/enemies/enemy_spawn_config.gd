## EnemySpawnConfig
## Custom Resource that defines configuration settings for spawning enemies.
extends Resource
class_name EnemySpawnConfig

## The type identifier of the enemy to spawn.
@export var enemy_type: Enemy.EnemiesNames
## The PackedScene of the enemy to instantiate.
@export var scene: PackedScene
## The number of enemy instances to spawn for this configuration.
@export var quantity: int = 1
## Toggle to enable or skip spawning for this configuration.
@export var enabled: bool = true
