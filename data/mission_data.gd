# res://scripts/data/mission_data.gd
# Define all mission templates here
extends RefCounted
class_name MissionData

static func get_mission_templates() -> Array:
	return [
		{
			"name": "Cat Rescue",
			"emoji": "🐱",
			"description": "Save a cat stuck in a tree",
			"difficulty": Mission.Difficulty.EASY,
			"specialties": [Hero.Specialty.RESCUE],
			"zone": "park"
		},
		{
			"name": "Bank Robbery",
			"emoji": "🏦",
			"description": "Stop criminals robbing the city bank",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED],
			"zone": "downtown"
		},
		{
			"name": "Hostage Crisis",
			"emoji": "🏢",
			"description": "Rescue hostages from a building",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.INVESTIGATION],
			"zone": "waterfront"
		},
		{
			"name": "Cyber Attack",
			"emoji": "💻",
			"description": "Stop hackers from stealing city data",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.TECH],
			"zone": "industrial"
		},
		{
			"name": "Super Villain",
			"emoji": "🦹",
			"description": "Defeat the infamous Dr. Chaos",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.COMBAT],
			"zone": "downtown"
		},
		{
			"name": "Bomb Threat",
			"emoji": "💣",
			"description": "Defuse bombs across the city",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.SPEED],
			"zone": "industrial"
		},
		{
			"name": "Investigation",
			"emoji": "🔍",
			"description": "Solve a mysterious disappearance",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.INVESTIGATION],
			"zone": "residential"
		},
		{
			"name": "Fire Rescue",
			"emoji": "🔥",
			"description": "Save people from a burning building",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.SPEED],
			"zone": "residential"
		},
		{
			"name": "Gang War",
			"emoji": "⚔️",
			"description": "Stop warring criminal factions",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.COMBAT],
			"zone": "downtown"
		},
		{
			"name": "Lost Pet",
			"emoji": "🐕",
			"description": "Find a lost puppy in the park",
			"difficulty": Mission.Difficulty.EASY,
			"specialties": [Hero.Specialty.INVESTIGATION],
			"zone": "park"
		},
		{
			"name": "Alien Invasion",
			"emoji": "👽",
			"description": "Repel extraterrestrial attackers",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.TECH],
			"zone": "downtown"
		},
		{
			"name": "Bridge Collapse",
			"emoji": "🌉",
			"description": "Save civilians from a collapsing bridge",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.RESCUE],
			"zone": "waterfront"
		},
		{
			"name": "Traffic Accident",
			"emoji": "🚗",
			"description": "Clear a massive highway pileup",
			"difficulty": Mission.Difficulty.EASY,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.SPEED],
			"zone": "industrial"
		},
		{
			"name": "Museum Heist",
			"emoji": "🏛️",
			"description": "Stop thieves from stealing priceless artifacts",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.COMBAT],
			"zone": "downtown"
		},
		{
			"name": "Earthquake",
			"emoji": "🌊",
			"description": "Rescue people trapped in collapsed buildings",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.SPEED],
			"zone": "residential"
		}
	]

static func get_success_story(mission_name: String, hero_names: String, success: bool, money: int, fame: int) -> String:
	"""Generate mission completion story based on mission type"""
	var stories = {
		"Cat Rescue": {
			"success": "✅ %s successfully rescued the cat from the tree! The grateful owner rewarded them. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The cat escaped to another tree... %s tried their best. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Bank Robbery": {
			"success": "✅ %s stopped the bank robbery! The criminals have been apprehended and the money secured. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The robbers escaped with some cash, but %s prevented greater losses. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Hostage Crisis": {
			"success": "✅ %s rescued all hostages safely! The building was secured without casualties. (+$%d 💰 +%d ⭐)",
			"failure": "❌ Some hostages were injured during the rescue. %s did what they could. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Cyber Attack": {
			"success": "✅ %s thwarted the cyber attack! City data has been secured and hackers traced. (+$%d 💰 +%d ⭐)",
			"failure": "❌ Some data was stolen before %s could stop the hackers. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Super Villain": {
			"success": "✅ %s defeated the villain! Dr. Chaos has been captured and imprisoned. The city is safe! (+$%d 💰 +%d ⭐)",
			"failure": "❌ Dr. Chaos escaped! %s fought valiantly but the villain got away. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Bomb Threat": {
			"success": "✅ %s defused all bombs with seconds to spare! Countless lives were saved. (+$%d 💰 +%d ⭐)",
			"failure": "❌ One bomb detonated causing minor damage. %s defused the rest in time. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Investigation": {
			"success": "✅ %s solved the mystery! The missing person has been found safe and sound. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The trail went cold... %s needs more clues to solve this case. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Fire Rescue": {
			"success": "✅ %s evacuated the building and extinguished the flames! Everyone made it out safely. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The fire spread faster than expected. %s saved most people but some were injured. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Gang War": {
			"success": "✅ %s stopped the gang war! Peace has been restored to the streets. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The gangs scattered before %s could apprehend them all. The conflict continues. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Lost Pet": {
			"success": "✅ %s found the lost puppy! The family is overjoyed to be reunited. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The puppy ran off again! %s will keep searching. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Alien Invasion": {
			"success": "✅ %s repelled the alien invaders! Earth is safe once more. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The aliens retreated but will return... %s bought us time. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Bridge Collapse": {
			"success": "✅ %s rescued everyone from the collapsing bridge! All civilians evacuated safely. (+$%d 💰 +%d ⭐)",
			"failure": "❌ Not everyone made it off in time. %s saved as many as they could. (Partial: +$%d 💰 +%d ⭐)"
		}
	}
	
	var story_key = "success" if success else "failure"
	if stories.has(mission_name) and stories[mission_name].has(story_key):
		return stories[mission_name][story_key] % [hero_names, money, fame]
	else:
		# Default story
		if success:
			return "✅ SUCCESS! %s completed %s! (+$%d 💰 +%d ⭐)" % [hero_names, mission_name, money, fame]
		else:
			return "❌ FAILED! %s couldn't complete %s. (Partial: +$%d 💰 +%d ⭐)" % [hero_names, mission_name, money, fame]
