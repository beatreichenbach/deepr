extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

@export var flare_scene: PackedScene
@export var MOUSE_SENSITIVITY := 0.2
@export var CAMERA : Camera3D
@onready var CAMERA_CONTROLLER  = $camera_controller
@onready var RAYCAST = $camera_controller/RayCast3D

var color = Color()
var initialized = false

signal fire_hit(position)


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	var id = name.to_int()
	print("enter tree: ", id)
	print("position: ", position)
	set_multiplayer_authority(id)
	seed(id)
	color = Color.from_hsv((randi() % 12) / 12.0, 1, 1)

func _input(event):
	if event.is_action_released("exit"):
		get_tree().quit()
		$"../".exit_game()
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		CAMERA_CONTROLLER.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	if Input.is_action_just_pressed("flare"):
		var flare = flare_scene.instantiate()
		flare.get_node("light").set_color(color)
		get_tree().get_root().get_child(0).add_child(flare)
		get_tree().get_root().get_child(0).add_child(flare)
		
		var camera_transform = CAMERA_CONTROLLER.get_global_transform().translated_local(Vector3(0, 0, -1))
		flare.set_global_transform(camera_transform)
		flare.apply_central_force(-camera_transform.basis.z * 1000)
		
	if Input.is_action_just_pressed("fire") and RAYCAST.is_colliding():
		emit_signal("fire_hit", RAYCAST.get_collision_point())
		
	if not initialized and Input.is_action_just_pressed("jump"):
		initialized = true
		
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	CAMERA.set_current(is_multiplayer_authority())
	CAMERA.get_node("VoxelViewer").set_network_peer_id(name.to_int())
	
	var spawn_position = get_tree().get_root().get_child(0).get_node("spawn_point").get_position()
	self.set_position(spawn_position)
	

func _physics_process(delta):
	if initialized and is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var movement_speed = SPEED
		# Handle Sprint.
		if Input.is_action_pressed("sprint") and is_on_floor():
			movement_speed = SPRINT_SPEED

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
		else:
			velocity.x = move_toward(velocity.x, 0, movement_speed)
			velocity.z = move_toward(velocity.z, 0, movement_speed)

		move_and_slide()

