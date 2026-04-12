extends Node3D
class_name GameManager

# Game state
var money = 500
var lives = 20
var wave_number = 1
var game_state := "menu"  # menu, playing, paused, gameOver

# Game entities
var towers: Array[Node] = []
var enemies: Array[Node3D] = []
var projectiles: Array[Node3D] = []

# Grid system for tower placement
const TOWER_COST = 100
const GRID_SIZE := 64.0
const GRID_WIDTH := 15
const GRID_HEIGHT := 10

const W = GRID_SIZE * GRID_WIDTH
const H = GRID_SIZE * GRID_HEIGHT

# Arena bounds for billiard motion
const ARENA_MIN := Vector3(-W/2, 0, -H/2)
const ARENA_MAX := Vector3(W/2, 0, H/2)

# Wave configuration
var wave_enemies: Array = []
var current_wave_enemy_index := 0
var is_wave_active := false

# Timers
var _spawn_timer := 0.0
var _wave_complete_timer := 0.0

# Signals
signal money_changed(new_money)
signal lives_changed(new_lives)
signal wave_started(wave_number)
signal game_over()

func _ready():
	_create_debug_floor()
	start_game()

func _create_debug_floor() -> void:
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	# this should depend on the arena size
	plane.size = Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
	plane.subdivide_depth = 20
	plane.subdivide_width = 20
	floor_mesh.mesh = plane
	
	var mat2 = preload("res://materials/floor.tres")
	floor_mesh.material_override = mat2
	floor_mesh.transform = Transform3D(Basis(), Vector3(0, -5, 0))
	floor_mesh.name = "floor"
	add_child(floor_mesh)

func start_game():
	self.game_state = "playing"
	var light = get_tree().get_root().get_node_or_null("GameManager/OmniLight3D")
	light.omni_attenuation = -0.2
	start_wave(1)

func start_wave(wave_num: int) -> void:
	wave_number = wave_num
	is_wave_active = true
	current_wave_enemy_index = 0
	_spawn_timer = 0.0

	# Define enemies for this wave
	wave_enemies = []
	var enemy_count = 5 + wave_num * 2
	for i in range(enemy_count):
		wave_enemies.append({
			"health": 80.0 + float(wave_num) * 8.0,
			"speed": 6.0 + float(wave_num) * 0.4,
			"reward": 20 + wave_num * 5
		})

	wave_started.emit(wave_num)
	print("Wave ", wave_num, " started with ", enemy_count, " enemies!")

func spawn_enemy() -> Node3D:
	if is_wave_active and current_wave_enemy_index < wave_enemies.size():
		var enemy_scene = preload("res://enemy.tscn")
		var enemy = enemy_scene.instantiate()

		# Spawn at a random location in the arena
		var spawn_x = randf_range(ARENA_MIN.x, ARENA_MAX.x)
		var spawn_z = randf_range(ARENA_MIN.z, ARENA_MAX.z)

		enemy.health = wave_enemies[current_wave_enemy_index]["health"]
		enemy.max_health = enemy.health
		enemy.speed = wave_enemies[current_wave_enemy_index]["speed"]
		enemy.reward = wave_enemies[current_wave_enemy_index]["reward"]
		enemy.game_manager = self

		# Random direction for billiard motion
		var angle = randf() * TAU
		enemy.velocity = Vector3(cos(angle), 0, sin(angle)).normalized()

		add_child(enemy)
		enemies.append(enemy)
		enemy.global_position = Vector3(spawn_x, 5, spawn_z)
		current_wave_enemy_index += 1

		return enemy
	return null

func _process(delta: float):
	# Spawn enemies at intervals
	_spawn_timer += delta
	if is_wave_active and current_wave_enemy_index < wave_enemies.size() and _spawn_timer >= 1.5:
		_spawn_timer = 0.0
		spawn_enemy()

	# Handle wave completion delay
	if not is_wave_active and _wave_complete_timer > 0:
		_wave_complete_timer -= delta
		if _wave_complete_timer <= 0:
			_wave_complete_timer = 0
			start_wave(wave_number + 1)

func remove_enemy(enemy: Node3D) -> void:
	if enemy in enemies:
		enemies.erase(enemy)
		if is_wave_active and current_wave_enemy_index >= wave_enemies.size() and enemies.size() == 0:
			is_wave_active = false
			_wave_complete_timer = 5.0
			print("Wave complete! Starting next wave in 5 seconds...")

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	print("Money: ", money)

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func lose_lives(amount: int) -> void:
	lives -= amount
	lives_changed.emit(lives)
	print("Lives: ", lives)
	if lives <= 0:
		game_state = "gameOver"
		game_over.emit()
		print("GAME OVER!")
		get_tree().paused = true

func place_tower(pos: Vector3) -> bool:
	if remove_money(TOWER_COST):
		var tower_scene = preload("res://tower.tscn")
		var tower = tower_scene.instantiate()
		tower.game_manager = self
		add_child(tower)
		towers.append(tower)
		tower.global_position = pos
		print("Tower placed at ", pos)
		return true
	return false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("place_tower") and self.game_state == "playing":
		# Get mouse position and convert to 3D world space via raycast
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera_3d()
		if camera:
			var ray_from = camera.project_ray_origin(mouse_pos)
			var ray_normal = camera.project_ray_normal(mouse_pos)
			# Intersect with ground plane (y=0)
			var t = -ray_from.y / ray_normal.y
			var ground_pos = ray_from + ray_normal * t
			# Snap to grid
			#var grid_pos = Vector3(
			#	round(ground_pos.x / (GRID_SIZE*GRID_WIDTH)) * (GRID_SIZE*GRID_WIDTH),
			#	0,
			#	round(ground_pos.z / (GRID_SIZE*GRID_HEIGHT)) * (GRID_SIZE*GRID_HEIGHT)
			#)
			place_tower(ground_pos)
			get_tree().root.set_input_as_handled()
