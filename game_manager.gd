extends Node

# This script handles the world/game setup
# Place it on your main scene node

# Number of NPCs to generate
@export var npc_count: int = 5
@export var npc_scene: PackedScene
@export var auto_generate_npcs: bool = true

# World boundaries
@export var world_width: float = 1000.0
@export var world_height: float = 1000.0

# Called when the node enters the scene tree for the first time
func _ready():
	print_debug("GameManager initialized")
	
	# Wait a moment to ensure everything else is initialized
	await get_tree().create_timer(0.1).timeout
	
	# Check if we should auto-generate NPCs
	if auto_generate_npcs:
		# If NPC scene isn't explicitly set, try to create a placeholder NPC
		if not npc_scene:
			print_debug("NPC Scene not set in GameManager - creating placeholder NPCs")
			spawn_placeholder_npcs()
		else:
			# Normal NPC spawning
			spawn_npcs()
	
	# Print instructions
	print_debug("Game started! Use arrow keys to move. Press Enter/Space to interact with NPCs.")

func spawn_npcs():
	for i in range(npc_count):
		var npc_instance = npc_scene.instantiate()
		
		# Position the NPC randomly within world bounds
		var random_x = randf_range(100, world_width - 100)
		var random_y = randf_range(100, world_height - 100)
		npc_instance.position = Vector2(random_x, random_y)
		
		# Add the NPC to the scene
		add_child(npc_instance)
		
		# Log NPC creation
		print_debug("NPC created: " + npc_instance.npc_name + " at position " + str(npc_instance.position))

func spawn_placeholder_npcs():
	for i in range(npc_count):
		# Create basic CharacterBody2D as placeholder
		var npc = CharacterBody2D.new()
		npc.name = "PlaceholderNPC_" + str(i)
		
		# Position randomly
		var random_x = randf_range(100, world_width - 100)
		var random_y = randf_range(100, world_height - 100)
		npc.position = Vector2(random_x, random_y)
		
		# Add to NPC group
		npc.add_to_group("npc")
		
		# Add visual indicator
		var rect = ColorRect.new()
		rect.size = Vector2(32, 32)
		rect.position = Vector2(-16, -16)
		rect.color = Color(1, 0.5, 0)
		npc.add_child(rect)
		
		# Add name label
		var label = Label.new()
		label.text = "NPC " + str(i)
		label.position = Vector2(-40, -40)
		label.size = Vector2(80, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		npc.add_child(label)
		
		# Add property needed for interaction
		npc.set_meta("npc_name", "NPC " + str(i))
		
		# Add to scene
		add_child(npc)
		
		print_debug("Placeholder NPC created at " + str(npc.position))

# Call this from your debug menu or console to manually spawn NPCs
func manual_spawn_npc(x: float, y: float):
	# Check if we have a scene to instantiate
	if npc_scene:
		var npc_instance = npc_scene.instantiate()
		npc_instance.position = Vector2(x, y)
		add_child(npc_instance)
		print_debug("Manual NPC spawned at " + str(Vector2(x, y)))
	else:
		print_debug("Cannot spawn - NPC scene not set")
