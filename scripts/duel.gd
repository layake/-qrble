extends Node3D

const FIELD_SIZE := 12.0
const MARBLE_RADIUS := 0.25
const MARBLE_MASS := 0.05
const MIN_DRAG_PIXELS := 10.0
const MAX_DRAG_PIXELS := 200.0
const FORCE_PER_PIXEL := 0.001
const SETTLE_DELAY := 0.3
const WALL_THICKNESS := 0.5
const WALL_HEIGHT := 1.0
const START_STOCK := 1

var marbles: Array[Marble] = []
var stock: Array[int] = [START_STOCK, START_STOCK]
var current_player := 0
var shooting := false
var over := false
var last_winner := -1
var settle_time := 0.0
var drag_start := Vector2.ZERO
var dragging := false
var status_label: Label


func _ready() -> void:
	_build_field()
	_build_hud()
	_start_round()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if over:
		if mouse.pressed:
			_next_round()
		return
	if mouse.pressed and not shooting and _shooter().is_still():
		drag_start = mouse.position
		dragging = true
	elif not mouse.pressed and dragging:
		dragging = false
		_shoot(mouse.position - drag_start)


func _physics_process(delta: float) -> void:
	if not shooting:
		return
	settle_time -= delta
	if settle_time > 0.0 or not _all_still():
		return
	shooting = false
	current_player = 1 - current_player
	_update_status()


func _shoot(drag: Vector2) -> void:
	if drag.length() < MIN_DRAG_PIXELS:
		return
	# Glisser vers l'arrière, la bille part vers l'avant (comme un élastique).
	var pull := drag.limit_length(MAX_DRAG_PIXELS)
	_shooter().apply_central_impulse(Vector3(-pull.x, 0.0, -pull.y) * FORCE_PER_PIXEL)
	shooting = true
	settle_time = SETTLE_DELAY
	_update_status()


func _on_contact() -> void:
	if shooting:
		_end_round(current_player)


func _end_round(winner: int) -> void:
	shooting = false
	over = true
	last_winner = winner
	stock[winner] += 1
	stock[1 - winner] -= 1
	_update_status()


func _next_round() -> void:
	if stock[0] <= 0 or stock[1] <= 0:
		stock[0] = START_STOCK
		stock[1] = START_STOCK
	_start_round()


func _start_round() -> void:
	for marble in marbles:
		marble.queue_free()
	marbles.clear()
	marbles.append(_spawn_marble(Vector3(-3.0, MARBLE_RADIUS, 0.0), Color.RED))
	marbles.append(_spawn_marble(Vector3(3.0, MARBLE_RADIUS, 0.0), Color.BLUE))
	current_player = 0
	shooting = false
	over = false
	_update_status()


func _spawn_marble(spawn_position: Vector3, tint: Color) -> Marble:
	var marble := Marble.new()
	marble.setup(MARBLE_RADIUS, MARBLE_MASS, tint)
	marble.position = spawn_position
	marble.contacted.connect(_on_contact)
	add_child(marble)
	return marble


func _shooter() -> Marble:
	return marbles[current_player]


func _all_still() -> bool:
	for marble in marbles:
		if not marble.is_still():
			return false
	return true


func _update_status() -> void:
	var counts := "Billes  J1 : %d   J2 : %d" % [stock[0], stock[1]]
	if over:
		status_label.text = "Joueur %d gagne la bille !\n%s\nTape pour continuer" % [last_winner + 1, counts]
	elif shooting:
		status_label.text = "Tir en cours...\n%s" % counts
	else:
		status_label.text = "Tour du joueur %d\n%s" % [current_player + 1, counts]


func _build_field() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0.0, 14.0, 4.0)
	camera.look_at(Vector3.ZERO)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60.0, -30.0, 0.0)
	add_child(sun)

	var ground_physics := PhysicsMaterial.new()
	ground_physics.friction = 0.6
	_add_box(Vector3(0.0, -0.1, 0.0), Vector3(FIELD_SIZE, 0.2, FIELD_SIZE), ground_physics, Color(0.45, 0.45, 0.48))

	var wall_physics := PhysicsMaterial.new()
	wall_physics.bounce = 0.8
	wall_physics.friction = 0.2
	var wall_color := Color(0.55, 0.35, 0.2)
	var edge := FIELD_SIZE / 2.0 + WALL_THICKNESS / 2.0
	var long_side := Vector3(FIELD_SIZE + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS)
	var short_side := Vector3(WALL_THICKNESS, WALL_HEIGHT, FIELD_SIZE)
	_add_box(Vector3(0.0, WALL_HEIGHT / 2.0, -edge), long_side, wall_physics, wall_color)
	_add_box(Vector3(0.0, WALL_HEIGHT / 2.0, edge), long_side, wall_physics, wall_color)
	_add_box(Vector3(-edge, WALL_HEIGHT / 2.0, 0.0), short_side, wall_physics, wall_color)
	_add_box(Vector3(edge, WALL_HEIGHT / 2.0, 0.0), short_side, wall_physics, wall_color)


func _add_box(box_position: Vector3, box_size: Vector3, physics: PhysicsMaterial, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = box_position
	body.physics_material_override = physics

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_size
	collision.shape = box_shape

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh_instance.mesh = box_mesh

	body.add_child(collision)
	body.add_child(mesh_instance)
	add_child(body)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(24.0, 24.0)
	status_label.add_theme_font_size_override("font_size", 32)
	layer.add_child(status_label)
