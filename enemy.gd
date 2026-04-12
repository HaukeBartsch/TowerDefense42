extends Node3D
class_name Enemy

# Enemy properties
var health := 100.0
var max_health: float = 100.0
var speed := 200.0
var reward := 25
var damage := 10


# Movement properties
var velocity := Vector3.ZERO

# Game references
var game_manager: GameManager = null

# Visual components
var mesh_instance: MeshInstance3D
var health_bar: Control

func _ready():
	# Create mesh for enemy (simple sphere)
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 10.0
	sphere_mesh.height = 20.0
	mesh_instance.mesh = sphere_mesh
	mesh_instance.name = "enemy"
	
	var mat = preload("res://materials/enemy.tres")
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# Create health bar UI
	health_bar = _create_health_bar()
	health_bar.name = "Health Bar"
	add_sibling(health_bar)

func _process(delta):
	if not game_manager or game_manager.game_state != "playing":
		return

	# Straight-line billiard motion + reflection
	global_position += velocity * speed * delta

	var min_bound = game_manager.ARENA_MIN
	var max_bound = game_manager.ARENA_MAX

	if global_position.x < min_bound.x:
		global_position.x = min_bound.x
		velocity.x = -velocity.x
	elif global_position.x > max_bound.x:
		global_position.x = max_bound.x
		velocity.x = -velocity.x

	if global_position.z < min_bound.z:
		global_position.z = min_bound.z
		velocity.z = -velocity.z
	elif global_position.z > max_bound.z:
		global_position.z = max_bound.z
		velocity.z = -velocity.z

func _create_health_bar() -> Control:
	var panel = Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return panel

func take_damage(amount: float) -> void:
	health -= amount
	if health_bar:
		health_bar.scale.x = health / max_health
	if health <= 0:
		killed()

func killed():
	if game_manager:
		game_manager.add_money(reward)
		game_manager.remove_enemy(self)

	queue_free()
