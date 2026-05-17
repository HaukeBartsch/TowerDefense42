extends CharacterBody3D
class_name Enemy

# Enemy properties
var health := 100.0
var max_health: float = 100.0
var speed := 200.0
var reward := 25
var damage := 10
var mass := 1.0


# Movement properties
# set by the game_manager when a new enemy is spawned
# var velocity := Vector3.ZERO

# Game references
var game_manager: GameManager = null

# Visual components
var mesh_instance: MeshInstance3D
var health_bar: Control
var rigid_body: CollisionShape3D

func _ready():
	# Create mesh for enemy (simple sphere)
	#self.gravity_scale = 0.0
	#self.constant_force = Vector3(0.0,0.0,0.0)
	#self.can_sleep = false
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
	rigid_body = CollisionShape3D.new() # RigidBody3D.new()
	rigid_body.shape = sphere_mesh.create_convex_shape(true, true)
	#rigid_body.gravity_scale = 0.0
	add_child(rigid_body)
	# rigid_body.scale *= 20 # Vector3(20,20,20)
	# rigid_body.scale = Vector3(20,20,20)
	
	# Create health bar UI
	health_bar = _create_health_bar()
	health_bar.name = "Health Bar"
	add_child(health_bar)

func _physics_process(delta):
	if not game_manager or game_manager.game_state != "playing":
		return

	var borderWidth = 15
	var min_bound = game_manager.ARENA_MIN + Vector3(borderWidth, borderWidth, borderWidth)
	var max_bound = game_manager.ARENA_MAX - Vector3(borderWidth, borderWidth, borderWidth)

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
	
	# don't allow enemies to stop
	if delta * velocity.length() < speed:
		velocity *= 1.0001
	
	var motion = velocity * delta
	# handle multiple collisions in one frame
	for i in 5:
		var collision = move_and_collide(motion)
		if collision:
			# Reflect velocity and update motion
			motion = collision.get_remainder().bounce(collision.get_normal())
			velocity = velocity.bounce(collision.get_normal())
			# reduce health if one of the colliding bodies is a tower
			# var object_one = collision.get_collider_owner() # Or collision.collider
			var object_two = collision.get_collider()       # The object you hit
			if object_two is Tower:
				object_two.take_damage(25.0)


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
		
func apply_force(force: Vector3) -> void:
	self.velocity += force

func killed():
	if game_manager:
		game_manager.add_money(reward)
		game_manager.remove_enemy(self)

	queue_free()
