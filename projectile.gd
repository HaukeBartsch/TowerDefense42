extends Node3D
class_name Projectile

# Projectile properties
var damage := 25.0
var speed := 100.0
var target: Enemy = null

func _ready():
	# Create mesh for projectile (small sphere)
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 2.5
	sphere_mesh.height = 5
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)


func _process(delta: float):
	if not target or not is_instance_valid(target):
		queue_free()
		return

	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

	# Check if reached target
	if (global_position - target.global_position).length() < 1.0:
		hit_target()


func hit_target():
	if not target or not is_instance_valid(target):
		queue_free()
		return

	# Apply damage to target
	target.take_damage(damage)

	# Remove projectile
	queue_free()
