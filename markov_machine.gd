extends Object
class_name MarkovMachine

var occurrences : Dictionary = {}
var name_occurrences : Dictionary = {}
var lengths : Dictionary = {}
var name_lengths : Dictionary = {}
var sentence_starters : Array = []

func add_occurrence(previous : String, occ : String, is_name : bool = false):
	var target_dict = name_occurrences if is_name else occurrences
	if not previous in target_dict:
		target_dict[previous] = {}
	if not occ in target_dict[previous]:
		target_dict[previous][occ] = 1
	else:
		target_dict[previous][occ] += 1

func add_length(key : int, is_name : bool = false):
	var target_dict = name_lengths if is_name else lengths
	if not key in target_dict:
		target_dict[key] = 1
	else:
		target_dict[key] += 1

func pick_weighted(dictionary : Dictionary):
	var sum_weights = 0
	for i in dictionary:
		sum_weights += dictionary[i]
	
	var rnd = randi_range(0, sum_weights - 1)
	
	for i in dictionary:
		if rnd < dictionary[i]:
			return i
		rnd -= dictionary[i]
	
	return dictionary.keys()[0]

func init(seed_text: String, is_name : bool = false):
	if is_name:
		var names = seed_text.split("\n", false)
		for name in names:
			name = name.strip_edges()
			if name == "":
				continue
			var parts = name.to_lower().split("-")
			if parts.size() == 0:
				continue
			add_length(parts.size(), true)
			for j in range(parts.size()):
				var prev = "" if j == 0 else parts[j-1]
				var curr = parts[j]
				add_occurrence(prev, curr, true)
	else:
		var lines = seed_text.split("\n", false)
		for line in lines:
			var words = line.strip_edges().split(" ", false)
			if words.size() == 0:
				continue
			add_length(words.size())
			
			var start_token = "<START>"
			sentence_starters.append(words[0].to_lower())
			add_occurrence("", start_token)
			add_occurrence(start_token, words[0].to_lower())
			
			for j in range(words.size()):
				var current = words[j].to_lower()
				var next_word = ""
				if j < words.size() - 1:
					next_word = words[j + 1].to_lower()
				else:
					next_word = "<END>"
				
				add_occurrence(current, next_word)
				
				if current.ends_with(".") or current.ends_with("!") or current.ends_with("?"):
					if j < words.size() - 1:
						sentence_starters.append(words[j + 1].to_lower())
						add_occurrence("", start_token)
						add_occurrence(start_token, words[j + 1].to_lower())

func generate_name():
	var parts = []
	var current_part = ""
	var target_length = randi_range(1, 3)
	
	if "" in name_occurrences:
		current_part = pick_weighted(name_occurrences[""])
		parts.append(current_part)
	else:
		return "Traveler"
	
	while len(parts) < target_length:
		if current_part in name_occurrences:
			var next_part = pick_weighted(name_occurrences[current_part])
			parts.append(next_part)
			current_part = next_part
		else:
			break
	
	var result = ""
	if parts.size() > 0:
		for i in range(parts.size()):
			parts[i] = parts[i].capitalize()
		result = " ".join(parts)
	
	return result

func generate_sentences(num_sentences : int = 1):
	var sentences = []
	for _i in range(num_sentences):
		var words = []
		var current_word = "<START>"
		var target_length = pick_weighted(lengths) if lengths.size() > 0 else 5
		var used_phrases = {}  # Track phrases to avoid repetition
		
		# Start with a sentence starter
		if sentence_starters.size() > 0:
			current_word = sentence_starters[randi() % sentence_starters.size()]
			words.append(current_word)
		else:
			words.append("hello")
		
		# Generate words for the sentence
		var attempts = 0  # Prevent infinite loops
		while len(words) < target_length and attempts < target_length * 2:
			if current_word in occurrences:
				var next_word = pick_weighted(occurrences[current_word])
				if next_word == "<END>":
					break
				
				# Check for repetitive phrases (last 3 words)
				var recent_words = words.slice(max(0, len(words) - 3), len(words))
				recent_words.append(next_word)
				var recent_phrase = " ".join(recent_words)
				if recent_phrase in used_phrases:
					attempts += 1
					continue
				
				used_phrases[recent_phrase] = true
				words.append(next_word)
				current_word = next_word
				attempts = 0
			else:
				break
		
		# Format the sentence
		var sentence = ""
		if words.size() > 0:
			words[0] = words[0].capitalize()
			sentence = " ".join(words)
			if not sentence.ends_with(".") and not sentence.ends_with("?") and not sentence.ends_with("!"):
				var endings = [".", "!", "?"]
				sentence += endings[randi() % endings.size()]
		else:
			sentence = "Hello traveler."
		sentences.append(sentence)
	
	return " ".join(sentences)

func generate_npc():
	var name = generate_name()
	var dialogue = generate_sentences(randi_range(1, 3))
	return {"name": name, "dialogue": dialogue}
