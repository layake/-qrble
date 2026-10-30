class_name Marble
extends RigidBody3D

signal contacted

const STILL_SPEED := 0.05


func setup(radius: float, marble_mass: float, tint: Color) -> void:
	mass = marble_mass
	linear_damp = 0.3
	angular_damp = 0.5
	contact_monitor = true
	max_contacts_reported = 4
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.5
	physics_material_override.friction = 0.4
	body_entered.connect(_on_body_entered)
	_add_visuals(radius, tint)


func is_still() -> bool:
	return linear_velocity.length() < STILL_SPEED and angular_velocity.length() < STILL_SPEED


func _add_visuals(radius: float, tint: Color) -> void:
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collision.shape = sphere_shape
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	sphere_mesh.material = material
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)


func _on_body_entered(body: Node) -> void:
	if body is Marble:
		contacted.emit()
