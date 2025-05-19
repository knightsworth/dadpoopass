extends CharacterBody2D

@export var speed = 300.0
@export var acceleration = 1500.0
@export var friction = 1500.0
@export var sprint_multiplier = 1.5

var animation_player: AnimationPlayer
var sprite: Sprite2D
var dialogue_ui: CanvasLayer
var dialogue_background: ColorRect
var dialogue_label: Label
var npc_name_label: Label
var options_container: HBoxContainer

@export var interaction_distance = 300.0
var interacting = false
var current_npc: NPC = null

func _ready():
	animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
	sprite = $Sprite2D if has_node("Sprite2D") else null
	
	add_to_group("player")
	
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		var rect = ColorRect.new()
		rect.size = Vector2(32, 32)
		rect.position = Vector2(-16, -16)
		rect.color = Color(0, 0.7, 1)
		add_child(rect)
		print_debug("Player sprite not found, using placeholder")
	
	# Set up the dialogue UI on a CanvasLayer
	dialogue_ui = CanvasLayer.new()
	add_child(dialogue_ui)
	
	# Background for dialogue
	dialogue_background = ColorRect.new()
	dialogue_background.color = Color(0, 0, 0, 0.8)
	dialogue_ui.add_child(dialogue_background)
	
	# NPC name label
	npc_name_label = Label.new()
	npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_name_label.add_theme_color_override("font_color", Color(1, 1, 0))
	npc_name_label.visible = false
	dialogue_ui.add_child(npc_name_label)
	
	# Dialogue label
	dialogue_label = Label.new()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_label.add_theme_color_override("font_color", Color(1, 1, 1))
	dialogue_label.visible = false
	dialogue_ui.add_child(dialogue_label)
	
	# Options container
	options_container = HBoxContainer.new()
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.visible = false
	dialogue_ui.add_child(options_container)
	
	# Add interaction option buttons
	var options = ["Trade", "Steal", "Kill", "Quest", "Leave"]
	for option in options:
		var button = Button.new()
		button.text = option
		button.connect("pressed", Callable(self, "_on_option_pressed").bind(option.to_lower()))
		options_container.add_child(button)
	
	# Position UI elements
	update_dialogue_position()
	
	# Ensure the dialogue is initially hidden
	hide_dialogue()
	print_debug("Player controller initialized successfully")

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_dialogue_position()

func update_dialogue_position():
	var viewport_size = get_viewport_rect().size
	var dialogue_width = viewport_size.x * 0.8
	var dialogue_height = viewport_size.y * 0.25
	var dialogue_x = (viewport_size.x - dialogue_width) / 2
	var dialogue_y = viewport_size.y * 0.65
	
	# Background
	dialogue_background.size = Vector2(dialogue_width, dialogue_height)
	dialogue_background.position = Vector2(dialogue_x, dialogue_y)
	
	# NPC name label
	npc_name_label.size = Vector2(dialogue_width - 20, 20)
	npc_name_label.position = Vector2(dialogue_x + 10, dialogue_y + 10)
	
	# Dialogue label
	dialogue_label.size = Vector2(dialogue_width - 20, dialogue_height - 70)
	dialogue_label.position = Vector2(dialogue_x + 10, dialogue_y + 35)
	
	# Options container
	options_container.size = Vector2(dialogue_width - 20, 30)
	options_container.position = Vector2(dialogue_x + 10, dialogue_y + dialogue_height - 40)

func _physics_process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var current_speed = speed
	if Input.is_action_pressed("ui_select"):
		current_speed *= sprint_multiplier
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * current_speed, acceleration * delta)
		handle_animations(input_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")
	
	move_and_slide()
	
	# Check if the player is still within range of the current NPC
	if current_npc:
		var distance = global_position.distance_to(current_npc.global_position)
		if distance > interaction_distance:
			hide_dialogue()
	
	# Check for new interaction
	if Input.is_action_just_pressed("ui_accept"):
		try_interact()

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

func try_interact():
	if interacting:
		return
	
	var closest_npc = find_closest_npc()
	
	if closest_npc:
		current_npc = closest_npc
		interacting = true
		display_dialogue_non_blocking()
	else:
		hide_dialogue()
		print_debug("No NPC in range to interact with")

func find_closest_npc() -> NPC:
	var npcs = get_tree().get_nodes_in_group("npc")
	print_debug("Found " + str(npcs.size()) + " NPCs in group 'npc'")
	
	var closest_distance = interaction_distance
	var closest: NPC = null
	
	for npc in npcs:
		var npc_casted: NPC = npc as NPC
		if not npc_casted:
			print_debug("Node in 'npc' group is not an NPC: " + str(npc))
			continue
		var distance = global_position.distance_to(npc_casted.global_position)
		print_debug("Distance to NPC " + npc_casted.npc_name + ": " + str(distance))
		if distance < closest_distance:
			closest_distance = distance
			closest = npc_casted
	
	return closest

func display_dialogue_non_blocking():
	if current_npc and dialogue_label:
		_show_dialogue_coroutine()

func _show_dialogue_coroutine() -> void:
	var dialogue = await current_npc.interact(self)
	if dialogue == "":
		dialogue = "I have nothing to say."
	
	# Show NPC name and dialogue
	npc_name_label.text = current_npc.npc_name
	npc_name_label.visible = true
	print_debug("Setting NPC name label to: " + npc_name_label.text)
	
	dialogue_label.text = dialogue
	dialogue_label.visible = true
	options_container.visible = true
	print_debug("Dialogue label set to visible, text: " + dialogue_label.text)

func _on_option_pressed(option: String):
	if not current_npc:
		return
	
	var response = ""
	match option:
		"trade":
			response = "Let’s trade! I have some goods to offer."
		"steal":
			response = "Hey, don’t steal from me! I’ll call the guards!"
		"kill":
			response = "You dare to attack me? I’ll defend myself!"
			current_npc.queue_free()
			hide_dialogue()
			return
		"quest":
			response = "I have a quest for you. Will you help me?"
		"leave":
			hide_dialogue()
			return
	
	# Update dialogue with the response
	dialogue_label.text = response
	print_debug("Option " + option + " selected, response: " + response)

func hide_dialogue():
	if dialogue_label:
		npc_name_label.visible = false
		dialogue_label.visible = false
		options_container.visible = false
		print_debug("Dialogue label hidden")
		interacting = false
		current_npc = null
	else:
		print_debug("Dialogue label is null, cannot hide")
