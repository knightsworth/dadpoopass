extends Object
class_name MarkovMachine

var occurences : Dictionary = {}
var lengths : Dictionary = {}

func add_occurence(previous : String, occ : String):
	if not previous in occurences.keys():
		occurences[previous] = {}
	if not occ in occurences[previous].keys():
		occurences[previous][occ] = 1
	else:
		occurences[previous][occ] += 1
		
func add_length(key : int):
	if not key in lengths.keys():
		lengths[key] = 1
	else:
		lengths[key] += 1
		
func pick_weighted(dictionary : Dictionary):
	var sum_weights = 0
	for i in dictionary.keys():
		sum_weights += dictionary[i]
	
	var rnd = randi_range(0, sum_weights - 1)
	
	for i in dictionary.keys():
		if rnd < dictionary[i]:
			return i
		rnd -= dictionary[i]
	
	# Fallback in case something goes wrong
	return dictionary.keys()[0]

func init(seed_text: String):
	var lines = seed_text.split("\n", false)
	for i in lines:
		var chars = i.split()
		add_length(len(chars))
		for j in len(chars):
			if j == 0:
				add_occurence("", chars[j].to_lower())
			else:
				add_occurence(chars[j-1].to_lower(), chars[j].to_lower())

func generate_new():
	# Start with an empty word
	var words = []
	var current_word = ""
	
	if "" in occurences:
		current_word = pick_weighted(occurences[""])
		words.append(current_word)
	else:
		# Fallback if empty string not in occurences
		return "Hello traveler"
	
	# Determine a reasonable length for our generated text
	var target_length = pick_weighted(lengths) if not lengths.size() > 0 else 5
	
	# Generate the rest of the words
	while len(words) < target_length:
		if current_word in occurences:
			var next_word = pick_weighted(occurences[current_word])
			words.append(next_word)
			current_word = next_word
		else:
			# If we reach a dead end, stop generation
			break
	
	# Format the result properly - capitalize first word
	var result = ""
	if words.size() > 0:
		words[0] = words[0].capitalize()
		result = " ".join(words)
		
		# Add some punctuation at the end
		if not result.ends_with(".") and not result.ends_with("?") and not result.ends_with("!"):
			# Randomly choose ending punctuation
			var endings = [".", "!", "?"]
			result += endings[randi() % endings.size()]
	
	return result
