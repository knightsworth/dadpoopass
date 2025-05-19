extends CharacterBody2D
class_name NPC

@export var npc_name: String = ""
@export var movement_speed: float = 50.0
@export var wander_radius: float = 100.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

var animation_player: AnimationPlayer
var sprite: Sprite2D
var name_label: Label

var dialogue_markov: MarkovMachine = null

enum State {IDLE, WALKING}
var current_state = State.IDLE
var home_position: Vector2
var target_position: Vector2
var idle_timer: float = 0.0

func _ready():
	home_position = global_position
	
	animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
	sprite = $Sprite2D if has_node("Sprite2D") else null
	name_label = $NameLabel if has_node("NameLabel") else null
	
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		var rect = ColorRect.new()
		rect.size = Vector2(32, 32)
		rect.position = Vector2(-16, -16) 
		rect.color = Color(0.2, 0.8, 0.3)
		add_child(rect)
		print_debug("NPC sprite not found, using placeholder")
	
	if not name_label:
		name_label = Label.new()
		name_label.position = Vector2(-50, -40)
		name_label.size = Vector2(100, 40)  # Increased height to accommodate multiple lines
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Enable word wrapping
		add_child(name_label)
		print_debug("NameLabel not found, using placeholder")
	
	if npc_name.is_empty():
		npc_name = "Unknown"
	
	if name_label:
		name_label.text = npc_name
	
	enter_idle_state()
	
	add_to_group("npc")
	
	print_debug("NPC initialized: " + npc_name)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.WALKING:
			process_walking_state(delta)

func process_idle_state(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		enter_walking_state()

func process_walking_state(_delta):
	var direction = target_position - global_position
	var distance = direction.length()
	
	if distance < 5.0:
		enter_idle_state()
		return
	
	direction = direction.normalized()
	velocity = direction * movement_speed
	handle_animations(direction)
	move_and_slide()

func enter_idle_state():
	current_state = State.IDLE
	velocity = Vector2.ZERO
	idle_timer = randf_range(idle_time_min, idle_time_max)
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func enter_walking_state():
	current_state = State.WALKING
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	target_position = home_position + random_offset

func handle_animations(direction):
	if not animation_player:
		return
		
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			if animation_player.has_animation("walk_right"):
				animation_player.play("walk_right")
			if sprite:
				sprite.flip_h = false
		else:
			if animation_player.has_animation("walk_left"):
				animation_player.play("walk_left")
			else:
				if animation_player.has_animation("walk_right"):
					animation_player.play("walk_right")
					if sprite:
						sprite.flip_h = true
	else:
		if direction.y > 0:
			if animation_player.has_animation("walk_down"):
				animation_player.play("walk_down")
		else:
			if animation_player.has_animation("walk_up"):
				animation_player.play("walk_up")

func interact(player):
	var previous_state = current_state
	current_state = State.IDLE
	velocity = Vector2.ZERO
	
	var direction = player.global_position - global_position
	handle_animations(direction)
	
	var dialogue = "Hello traveler."
	if dialogue_markov:
		dialogue = dialogue_markov.generate_sentences(randi_range(1, 3))
		print_debug("NPC " + npc_name + " generated dialogue: " + dialogue)
	else:
		print_debug("NPC " + npc_name + " has no dialogue_markov set")
	
	# Reduced timer to minimize delay, but this won't block player movement anymore
	await get_tree().create_timer(0.1).timeout
	current_state = previous_state
	
	return dialogue
