extends CharacterBody2D

@export var speed = 300.0  # Movement speed in pixels per second
@export var acceleration = 1500.0  # Acceleration in pixels per second squared
@export var friction = 1500.0  # Friction/deceleration in pixels per second squared
@export var sprint_multiplier = 1.5  # How much faster the character moves when sprinting

# Animation parameters
var animation_player: AnimationPlayer
var sprite: Sprite2D
var dialogue_label: Label

# Interaction parameters
@export var interaction_distance = 100.0
var interacting = false
var current_npc = null

# Access to the MarkovMachine - create instances in _ready()
var dialogue_markov = MarkovMachine.new()
var name_markov = MarkovMachine.new()

func _ready():
	# Get node references with error checking
	animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
	sprite = $Sprite2D if has_node("Sprite2D") else null
	dialogue_label = $DialogueLabel if has_node("DialogueLabel") else null
	
	# Add to player group for easy reference
	add_to_group("player")
	
	# If nodes are missing, create debugging visuals
	if not sprite:
		# Create a placeholder sprite
		sprite = Sprite2D.new()
		add_child(sprite)
		# Create a colored rectangle as placeholder
		var rect = ColorRect.new()
		rect.size = Vector2(32, 32)
		rect.position = Vector2(-16, -16)
		rect.color = Color(0, 0.7, 1)
		add_child(rect)
		print_debug("Player sprite not found, using placeholder")
	
	if not dialogue_label:
		# Create a placeholder label
		dialogue_label = Label.new()
		dialogue_label.position = Vector2(-100, -50)
		dialogue_label.size = Vector2(200, 40)
		dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dialogue_label.visible = false
		add_child(dialogue_label)
		print_debug("DialogueLabel not found, using placeholder")
	
	# Initialize Markov machine for dialogue
	var dialogue_seed = """
	Hello there how are you today
	I have been waiting for someone like you
	The forest is dangerous this time of year
	Have you seen the strange lights in the sky
	My grandmother used to tell stories about this place
	Travelers rarely come through our village
	Be careful of the abandoned mines
	Would you like to trade some goods
	I heard rumors of treasure in the old castle
	The innkeeper might have some work for you
	Some say the ancient ruins are haunted
	Do you believe in magic and spirits
	The harvest festival begins tomorrow
	"""
	dialogue_markov.init(dialogue_seed)
	
	# Initialize Markov machine for names
	var names_seed = """
	Aiden Sophia Elijah Olivia Liam Emma Noah Ava
	Grayson Isabella Lucas Mia Mason Harper
	Thorne Elysia Garrick Seraphina Aldric Lyra
	Kael Isabelle Rowan Freya Alaric Elara
	Dorian Aria Cassius Liliana Magnus Selene
	Riven Nyra Zephyr Thalia Caspian Elowen
	"""
	name_markov.init(names_seed)
	
	print_debug("Player controller initialized successfully")

func _physics_process(delta):
	if interacting:
		# Skip movement while interacting
		return
		
	# Get movement input
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Check for sprint input
	var current_speed = speed
	if Input.is_action_pressed("ui_select"):  # "ui_select" is the default Spacebar/Enter button
		current_speed *= sprint_multiplier
	
	# Handle acceleration and friction
	if input_direction != Vector2.ZERO:
		# Accelerate towards target velocity when there's input
		velocity = velocity.move_toward(input_direction * current_speed, acceleration * delta)
		
		# Handle animations
		handle_animations(input_direction)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		# Idle animation
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")
	
	# Apply movement
	move_and_slide()
	
	# Check for interaction input
	if Input.is_action_just_pressed("ui_accept"):  # "ui_accept" is usually Enter/Space
		try_interact()

func handle_animations(direction):
	# Skip animation handling if no animation player
	if not animation_player:
		return
		
	# This is a simple implementation - you might want to improve this based on your animations
	if abs(direction.x) > abs(direction.y):
		# Moving horizontally
		if direction.x > 0:
			# Right
			if animation_player.has_animation("walk_right"):
				animation_player.play("walk_right")
			# Flip sprite if needed
			if sprite:
				sprite.flip_h = false
		else:
			# Left
			if animation_player.has_animation("walk_left"):
				animation_player.play("walk_left")
			else:
				# If you don't have separate left animation, flip the right animation
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

func try_interact():
	# Find the closest NPC within interaction distance
	var closest_npc = find_closest_npc()
	
	if closest_npc:
		interacting = true
		current_npc = closest_npc
		display_dialogue()
	else:
		# No NPC in range
		hide_dialogue()
		print_debug("No NPC in range to interact with")

func find_closest_npc():
	# Get all NPCs in the scene
	var npcs = get_tree().get_nodes_in_group("npc")
	
	var closest_distance = interaction_distance
	var closest = null
	
	for npc in npcs:
		var distance = global_position.distance_to(npc.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = npc
	
	return closest

func display_dialogue():
	if current_npc and dialogue_label:
		# Generate dialogue using Markov chain
		var dialogue = dialogue_markov.generate_new()
		dialogue_label.text = dialogue
		dialogue_label.visible = true
		
		print_debug("Displaying dialogue: " + dialogue)
		
		# Set a timer to hide dialogue after a few seconds
		await get_tree().create_timer(4.0).timeout
		hide_dialogue()

func hide_dialogue():
	if dialogue_label:
		dialogue_label.visible = false
		interacting = false
		current_npc = null
		
func generate_npc_name():
	# Generate a random NPC name using the name Markov chain
	return name_markov.generate_new()
