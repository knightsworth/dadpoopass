extends CharacterBody2D
class_name NPC

@export var npc_name: String = ""
@export var movement_speed: float = 50.0
@export var wander_radius: float = 100.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

# Node references
var animation_player: AnimationPlayer
var sprite: Sprite2D
var name_label: Label

# State variables
enum State {IDLE, WALKING}
var current_state = State.IDLE
var home_position: Vector2
var target_position: Vector2
var idle_timer: float = 0.0

# Called when the node enters the scene tree for the first time
func _ready():
	# Store initial position as home
	home_position = global_position
	
	# Set up node references with error checking
	animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
	sprite = $Sprite2D if has_node("Sprite2D") else null
	name_label = $NameLabel if has_node("NameLabel") else null
	
	# Create missing nodes if needed
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		# Create a visual placeholder
		var rect = ColorRect.new()
		rect.size = Vector2(32, 32)
		rect.position = Vector2(-16, -16) 
		rect.color = Color(0.2, 0.8, 0.3)
		add_child(rect)
		print_debug("NPC sprite not found, using placeholder")
	
	if not name_label:
		name_label = Label.new()
		name_label.position = Vector2(-50, -40)
		name_label.size = Vector2(100, 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(name_label)
		print_debug("NameLabel not found, using placeholder")
	
	# Set up the NPC name
	if npc_name.is_empty():
		# If no name is set, try to get one from the player's Markov chain
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("generate_npc_name"):
			npc_name = player.generate_npc_name().capitalize()
		else:
			# Fallback names if Markov is not available
			var fallback_names = ["Villager", "Citizen", "Traveler", "Merchant"]
			npc_name = fallback_names[randi() % fallback_names.size()]
	
	# Set the name label
	if name_label:
		name_label.text = npc_name
	
	# Start in idle state
	enter_idle_state()
	
	# Add to the NPC group for easier interaction
	add_to_group("npc")
	
	print_debug("NPC initialized: " + npc_name)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.WALKING:
			process_walking_state(delta)

func process_idle_state(delta):
	# Count down idle timer
	idle_timer -= delta
	
	if idle_timer <= 0:
		# Transition to walking
		enter_walking_state()

func process_walking_state(_delta):
	# Move towards target position
	var direction = target_position - global_position
	var distance = direction.length()
	
	if distance < 5.0:
		# Reached target, go back to idle
		enter_idle_state()
		return
	
	# Normalize direction and set velocity
	direction = direction.normalized()
	velocity = direction * movement_speed
	
	# Update animation
	handle_animations(direction)
	
	# Apply movement
	move_and_slide()

func enter_idle_state():
	current_state = State.IDLE
	velocity = Vector2.ZERO
	
	# Set a random idle time
	idle_timer = randf_range(idle_time_min, idle_time_max)
	
	# Play idle animation
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func enter_walking_state():
	current_state = State.WALKING
	
	# Choose a random point within our wander radius
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	
	target_position = home_position + random_offset

func handle_animations(direction):
	# Skip if no animation player
	if not animation_player:
		return
		
	# Similar to player animation logic
	if abs(direction.x) > abs(direction.y):
		# Moving horizontally
		if direction.x > 0:
			# Right
			if animation_player.has_animation("walk_right"):
				animation_player.play("walk_right")
			if sprite:
				sprite.flip_h = false
		else:
			# Left
			if animation_player.has_animation("walk_left"):
				animation_player.play("walk_left")
			else:
				# If left animation doesn't exist, flip the right one
				if animation_player.has_animation("walk_right"):
					animation_player.play("walk_right")
					if sprite:
						sprite.flip_h = true
	else:
		# Moving vertically
		if direction.y > 0:
			# Down
			if animation_player.has_animation("walk_down"):
				animation_player.play("walk_down")
		else:
			# Up
			if animation_player.has_animation("walk_up"):
				animation_player.play("walk_up")

# Called when player interacts with this NPC
func interact(player):
	# Stop moving while interacting
	var previous_state = current_state
	current_state = State.IDLE
	velocity = Vector2.ZERO
	
	# Face toward the player
	var direction = player.global_position - global_position
	handle_animations(direction)
	
	# After interaction is done, return to previous state
	await get_tree().create_timer(0.5).timeout
	current_state = previous_state
