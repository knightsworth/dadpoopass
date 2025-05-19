extends Node

@export var npc_count: int = 3
@export var npc_scene: PackedScene
@export var auto_generate_npcs: bool = true

@export var world_width: float = 1000.0
@export var world_height: float = 1000.0

var location_dialogue_seeds: Dictionary = {
	"village": """
	The harvest festival starts tomorrow. Have you seen the miller's new windmill? 
	The mayor needs help with the goblin problem. The tavern keeper has a quest for you. 
	Watch out for the old bridge—it’s unstable! The blacksmith is looking for rare ores.
	""",
	"forest": """
	The ancient oaks whisper secrets at night. Have you seen the glowing mushrooms? 
	The druid needs help with a corrupted grove. Beware of the wolf pack near the river! 
	The hidden glade holds a magical spring. Some say a hermit lives deep in the woods.
	""",
	"castle": """
	The king is hosting a tournament soon. Have you explored the castle dungeons? 
	The royal alchemist needs rare ingredients. The guards are searching for a thief! 
	The throne room has a hidden passage. The court mage is researching a dark prophecy.
	"""
}

var name_markov = MarkovMachine.new()
var dialogue_markovs: Dictionary = {}

func _ready():
	print_debug("GameManager initialized")
	
	var names_seed = """
	Aiden-Sophia Elijah-Olivia Liam-Emma Noah-Ava
	Grayson-Isabella Lucas-Mia Mason-Harper
	Thorne-Elysia Garrick-Seraphina Aldric-Lyra
	Kael-Isabelle Rowan-Freya Alaric-Elara
	Dorian-Aria Cassius-Liliana Magnus-Selene
	Riven-Nyra Zephyr-Thalia Caspian-Elowen
	"""
	name_markov.init(names_seed, true)
	
	for location in location_dialogue_seeds.keys():
		var markov = MarkovMachine.new()
		markov.init(location_dialogue_seeds[location], false)
		dialogue_markovs[location] = markov
	
	await get_tree().create_timer(0.1).timeout
	
	if auto_generate_npcs:
		if not npc_scene:
			print_debug("NPC Scene not set in GameManager - creating placeholder NPCs")
			spawn_placeholder_npcs()
		else:
			spawn_npcs()
	
	print_debug("Game started! Use arrow keys to move. Press Enter/Space to interact with NPCs.")

func spawn_npcs():
	for i in range(npc_count):
		var npc_instance = npc_scene.instantiate()
		var random_x = randf_range(150, 250)  # Adjusted for testing
		var random_y = randf_range(150, 250)
		npc_instance.position = Vector2(random_x, random_y)
		var location = determine_location(random_x, random_y)
		npc_instance.npc_name = name_markov.generate_name()
		npc_instance.dialogue_markov = dialogue_markovs[location]
		add_child(npc_instance)
		print_debug("NPC created: " + npc_instance.npc_name + " at position " + str(npc_instance.position) + " in " + location)

func spawn_placeholder_npcs():
	for i in range(npc_count):
		# Create an NPC instance instead of a plain CharacterBody2D
		var npc = NPC.new()  # Use the NPC class directly
		npc.name = "PlaceholderNPC_" + str(i)
		
		# Position randomly (closer for testing)
		var random_x = randf_range(150, 250)
		var random_y = randf_range(150, 250)
		npc.position = Vector2(random_x, random_y)
		
		# Determine location
		var location = determine_location(random_x, random_y)
		
		# Set up name and dialogue using the same logic as spawn_npcs
		npc.npc_name = name_markov.generate_name()
		npc.dialogue_markov = dialogue_markovs[location]
		
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
		label.text = npc.npc_name
		label.position = Vector2(-40, -40)
		label.size = Vector2(80, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		npc.add_child(label)
		
		# Add to scene
		add_child(npc)
		
		print_debug("Placeholder NPC created: " + npc.npc_name + " at position " + str(npc.position) + " in " + location)

func determine_location(x: float, y: float) -> String:
	if x < world_width / 3:
		return "forest"
	elif x < 2 * world_width / 3:
		return "village"
	else:
		return "castle"

func manual_spawn_npc(x: float, y: float):
	if npc_scene:
		var npc_instance = npc_scene.instantiate()
		npc_instance.position = Vector2(x, y)
		var location = determine_location(x, y)
		npc_instance.npc_name = name_markov.generate_name()
		npc_instance.dialogue_markov = dialogue_markovs[location]
		add_child(npc_instance)
		print_debug("Manual NPC spawned at " + str(Vector2(x, y)) + " in " + location)
	else:
		print_debug("Cannot spawn - NPC scene not set")
