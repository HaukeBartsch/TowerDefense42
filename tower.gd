extends StaticBody3D
class_name Tower

# Tower properties
var damage := 25.0
var health := 100.0
var range_val := 80.0
var fire_rate := 1.0
var last_fire_time_ms := 0
var target: Enemy = null

# Tower state
var is_active := true
var game_manager: GameManager = null
var rigid_body: CollisionShape3D

func _ready():
	# Create tower visual (cylinder)	
	var tower01_scene = preload("res://Tower01.glb")
	var model_instance = tower01_scene.instantiate()
	var mesh_node1 = model_instance.get_node("Cylinder") as MeshInstance3D	
	var mesh_data = mesh_node1.mesh
	
	# Here a default tower in case we don't have a mesh loaded from Blender
	#var mesh_instance = MeshInstance3D.new()
	#var cylinder_mesh = CylinderMesh.new()
	#cylinder_mesh.top_radius = 3
	#cylinder_mesh.bottom_radius = 10.0
	#cylinder_mesh.height = 20.0
	#cylinder_mesh.radial_segments = 16
	#mesh_instance.mesh = cylinder_mesh

	#var mat = preload("res://materials/tower.tres")
	#mesh_instance.material_override = mat
	#add_child(mesh_instance)
	add_child(model_instance)
	self.name = "Tower"

	# add a collision shape
	rigid_body = CollisionShape3D.new() # RigidBody3D.new()
	#rigid_body.shape = cylinder_mesh.create_convex_shape(true, true)
	rigid_body.shape = mesh_data.create_convex_shape(true, true)
	#rigid_body.gravity_scale = 0.0
	add_child(rigid_body)

	game_manager = get_tree().get_root().get_node_or_null("GameManager")

func _process(_delta: float):
	if not is_active or not game_manager or game_manager.game_state != "playing":
		return

	# Find new target if needed
	if not target or not is_instance_valid(target):
		target = find_target()

	# Fire if we have a target and are ready
	if target != null:
		var time_since_last_fire_ms := Time.get_ticks_msec() - last_fire_time_ms
		if time_since_last_fire_ms >= fire_rate * 1000:
			shoot_target()

func find_target() -> Enemy:
	var nearest_enemy: Enemy = null
	var min_distance_sq := range_val * range_val

	for enemy in game_manager.enemies:
		if not is_instance_valid(enemy):
			continue

		var dist_sq := global_position.distance_squared_to(enemy.global_position)
		if dist_sq <= min_distance_sq and dist_sq <= range_val * range_val:
			min_distance_sq = dist_sq
			nearest_enemy = enemy

	return nearest_enemy

func shoot_target():
	if not target or not is_instance_valid(target):
		return

	# Create projectile
	var projectile_scene := preload("res://projectile.tscn")
	var projectile := projectile_scene.instantiate()

	# Position at top of tower
	projectile.target = target
	projectile.damage = damage

	game_manager.add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 1.5, 0)

	last_fire_time_ms = Time.get_ticks_msec()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		killed()
		

func killed():
	if game_manager:
		game_manager.remove_tower(self)

	queue_free()
