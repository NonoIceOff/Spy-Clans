extends CharacterBody3D

# -------------------------
# PARAMÈTRES PERSONNAGE
# -------------------------
const SPEED := 5.0
const JUMP_VELOCITY := 4.5

# -------------------------
# PARAMÈTRES CAMÉRA
# -------------------------
var mouse_sensitivity := 0.002
var camera_rotation := Vector2.ZERO # x = pitch, y = yaw

var camera_distance := 0.0
var target_camera_distance := 0.0
var camera_min := -2.0
var camera_max := 10.0
var zoom_speed := 1.0
var zoom_smoothness := 10.0

@onready var pivot := $Pivot
@onready var camera := $Pivot/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pivot.position.y = 1
	camera.position.z = camera_distance


func _input(event: InputEvent) -> void:
	# ROTATION CAMÉRA
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x - event.relative.y * mouse_sensitivity, -PI / 2, PI / 2)

		rotation.y = camera_rotation.y
		pivot.rotation.x = camera_rotation.x

	# ZOOM
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_distance = clamp(target_camera_distance - zoom_speed, camera_min, camera_max)

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_distance = clamp(target_camera_distance + zoom_speed, camera_min, camera_max)

	# ÉCHAPPER POUR LIBÉRER LA SOURIS
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Zoom smooth
	camera_distance = lerp(camera_distance, target_camera_distance, zoom_smoothness * delta)
	camera.position.z = camera_distance
	
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Déplacements WASD
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
