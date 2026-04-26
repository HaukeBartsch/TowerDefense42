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
var rigid_body: RigidBody3D

func _ready():
	# Create mesh for enemy (simple sphere)
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 10.0
	sphere_mesh.height = 20.0
	mesh_instance.mesh = sphere_mesh
	mesh_instance.name = "enemy"
	self.name = "Enemy"
	
	var mat = preload("res://materials/enemy.tres")
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# add a sphere 
	rigid_body = RigidBody3D.new()
	rigid_body.gravity_scale = 0.0
	add_child(rigid_body)
	rigid_body.scale *= 20 # Vector3(20,20,20)
	
	# Create health bar UI
	health_bar = _create_health_bar()
	health_bar.name = "Health Bar"
	add_child(health_bar)

func _process(delta):
	if not game_manager or game_manager.game_state != "playing":
		return

	# Straight-line billiard motion + reflection
	# global_position += velocity * speed * delta
	rigid_body.scale = Vector3(20,20,20)

	var min_bound = game_manager.ARENA_MIN
	var max_bound = game_manager.ARENA_MAX

	if global_position.x < min_bound.x:
		global_position.x = min_bound.x
		velocity.x = -velocity.x
		self.rigid_body.linear_velocity.x = -self.rigid_body.linear_velocity.x
	elif global_position.x > max_bound.x:
		global_position.x = max_bound.x
		velocity.x = -velocity.x
		self.rigid_body.linear_velocity.x = -self.rigid_body.linear_velocity.x

	if global_position.z < min_bound.z:
		global_position.z = min_bound.z
		velocity.z = -velocity.z
		self.rigid_body.linear_velocity.z = -self.rigid_body.linear_velocity.z
	elif global_position.z > max_bound.z:
		global_position.z = max_bound.z
		velocity.z = -velocity.z
		self.rigid_body.linear_velocity.z = -self.rigid_body.linear_velocity.z
	
	if self.rigid_body:
		if self.rigid_body.linear_velocity.length() < velocity.length():
			self.rigid_body.add_constant_force(velocity * delta * rigid_body.mass)
		var keep_y = global_position.y
		global_position += self.rigid_body.linear_velocity * speed * delta
		global_position.y = keep_y


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
