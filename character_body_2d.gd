extends CharacterBody2D

@export var speed = 300.0  # Movement speed in pixels per second
@export var acceleration = 1500.0  # Acceleration in pixels per second squared
@export var friction = 1500.0  # Friction/deceleration in pixels per second squared
@export var sprint_multiplier = 1.5  # How much faster the character moves when sprinting

# Animation parameters
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(delta):
	# Get movement input
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Check for sprint input (using Shift key)
	var current_speed = speed
	if Input.is_action_pressed("ui_select"):  # "ui_select" is the default Spacebar/Enter button
		current_speed *= sprint_multiplier
	
	# Handle acceleration and friction
	if input_direction != Vector2.ZERO:
		# Accelerate towards target velocity when there's input
		velocity = velocity.move_toward(input_direction * current_speed, acceleration * delta)
		
		# Handle animations

	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		# Idle animation

	
	# Apply movement
	move_and_slide()
