extends CanvasLayer

# UI for tower defense game
# Displays money, lives, wave information

var game_manager: GameManager
var money_label: Label
var lives_label: Label
var wave_label: Label
var enemy_count_label: Label
var enemy_position_label: Label

func _ready():
	game_manager = get_parent() as GameManager
	if game_manager:
		# Ensure UI elements exist
		money_label = _create_label(Vector2(12, 12), "Money: 0")
		lives_label = _create_label(Vector2(12, 32), "Lives: 0")
		wave_label = _create_label(Vector2(12, 52), "Wave: 0")
		enemy_count_label = _create_label(Vector2(12, 72), "Enemies: 0")
		enemy_position_label = _create_label(Vector2(12, 92), "Avg Pos: (0,0,0)")

		game_manager.money_changed.connect(_on_money_changed)
		game_manager.lives_changed.connect(_on_lives_changed)
		game_manager.wave_started.connect(_on_wave_started)
	
		# Update initial values
		_on_money_changed(game_manager.money)
		_on_lives_changed(game_manager.lives)
		_on_wave_started(game_manager.wave_number)

func _on_money_changed(new_money: int) -> void:
	if money_label:
		money_label.text = "Money: %d" % new_money

func _on_lives_changed(new_lives: int) -> void:
	if lives_label:
		lives_label.text = "Lives: %d" % new_lives

func _on_wave_started(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "Wave: %d" % wave_num

func _process(delta: float) -> void:
	if not game_manager:
		return

	var count = game_manager.enemies.size()
	if enemy_count_label:
		enemy_count_label.text = "Enemies: %d" % count

	if count > 0:
		#var avg = Vector3.ZERO
		#for enemy in game_manager.enemies:
		#	if enemy and enemy is Node3D:
		#		avg += enemy.global_position
		#avg /= float(count)
		if enemy_position_label:
			enemy_position_label.text = "Speed: %.1f" % game_manager.wave_enemies[0].speed
	else:
		if enemy_position_label:
			enemy_position_label.text = "Speed: "

func _create_label(pos: Vector2, text: String) -> Label:
	var label = Label.new()
	label.position = pos
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(label)
	return label
