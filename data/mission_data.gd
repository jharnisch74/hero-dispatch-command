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
		},
		# --- NEW MISSIONS ---
		{
			"name": "Toxic Spill",
			"emoji": "☣️",
			"description": "Contain a hazardous chemical leak and treat victims",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.TECH],
			"zone": "industrial"
		},
		{
			"name": "Kidnapping",
			"emoji": "⛓️",
			"description": "Track and rescue a high-profile kidnap victim",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.COMBAT],
			"zone": "residential"
		},
		{
			"name": "Looting Spree",
			"emoji": "🛒",
			"description": "Stop mass looting during a city blackout",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED],
			"zone": "downtown"
		},
		{
			"name": "Power Grid Failure",
			"emoji": "⚡",
			"description": "Repair critical infrastructure after a system-wide failure",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.SPEED],
			"zone": "industrial"
		},
		{
			"name": "Giant Monster",
			"emoji": "🦖",
			"description": "Defeat a colossal creature attacking the city",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.COMBAT],
			"zone": "waterfront"
		},
		{
			"name": "Subway Derailment",
			"emoji": "🚇",
			"description": "Extract passengers from a crashed subway train",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.INVESTIGATION],
			"zone": "downtown"
		},
		{
			"name": "Skydiving Mishap",
			"emoji": "💨",
			"description": "Catch a skydiver whose parachute failed",
			"difficulty": Mission.Difficulty.EASY,
			"specialties": [Hero.Specialty.SPEED, Hero.Specialty.RESCUE],
			"zone": "park"
		},
		{
			"name": "Data Recovery",
			"emoji": "💾",
			"description": "Recover a crucial hard drive from a volatile location",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION],
			"zone": "waterfront"
		},
		{
			"name": "Animal Stampede",
			"emoji": "🦌",
			"description": "Herd panicked zoo animals back to their enclosures",
			"difficulty": Mission.Difficulty.EASY,
			"specialties": [Hero.Specialty.SPEED, Hero.Specialty.INVESTIGATION],
			"zone": "park"
		},
		{
			"name": "Art Forgery Ring",
			"emoji": "🖼️",
			"description": "Infiltrate and expose a massive art forgery operation",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.INVESTIGATION],
			"zone": "residential"
		},
		{
			"name": "Asteroid Fragment",
			"emoji": "☄️",
			"description": "Safely retrieve a dangerous meteorite fragment",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.COMBAT],
			"zone": "industrial"
		},
		{
			"name": "Escaped Inmate",
			"emoji": "🚨",
			"description": "Track down and re-apprehend a dangerous fugitive",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.COMBAT],
			"zone": "downtown"
		},
		{
			"name": "Mad Scientist",
			"emoji": "🧪",
			"description": "Stop a rogue scientist's dangerous experiment",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.COMBAT],
			"zone": "industrial"
		},
		{
			"name": "Water Main Burst",
			"emoji": "💧",
			"description": "Divert floodwaters and rescue citizens from rising water",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.RESCUE],
			"zone": "waterfront"
		},
		{
			"name": "Teleportation Mishap",
			"emoji": "🌌",
			"description": "Locate and stabilize objects/people displaced by a teleporter malfunction",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.RESCUE],
			"zone": "downtown"
		},
		{
			"name": "Drone Swarm",
			"emoji": "🚁",
			"description": "Neutralize an aggressive swarm of automated drones",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.SPEED],
			"zone": "park"
		},
		{
			"name": "Sinkhole Rescue",
			"emoji": "🕳️",
			"description": "Save people and vehicles from a sudden city sinkhole",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.RESCUE],
			"zone": "residential"
		},
		{
			"name": "Train Hijack",
			"emoji": "🚂",
			"description": "Stop a runaway train and subdue the hijackers",
			"difficulty": Mission.Difficulty.HARD,
			"specialties": [Hero.Specialty.SPEED, Hero.Specialty.COMBAT],
			"zone": "industrial"
		},
		{
			"name": "Paranormal Event",
			"emoji": "👻",
			"description": "Investigate and neutralize a hostile spectral entity",
			"difficulty": Mission.Difficulty.EXTREME,
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.TECH],
			"zone": "residential"
		},
		{
			"name": "Drug Cartel Bust",
			"emoji": "💵",
			"description": "Dismantle a major criminal drug operation",
			"difficulty": Mission.Difficulty.MEDIUM,
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.INVESTIGATION],
			"zone": "waterfront"
		}
	]

static func get_success_story(mission_name: String, hero_names: String, success: bool, money: int, fame: int) -> String:
	"""Generate mission completion story based on mission type"""
	var stories = {
		# Existing Missions
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
		},
		"Traffic Accident": {
			"success": "✅ %s cleared the pileup and treated the injured. Traffic is moving again! (+$%d 💰 +%d ⭐)",
			"failure": "❌ The clearing took too long, causing city-wide delays. %s stabilized the injured. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Museum Heist": {
			"success": "✅ %s recovered all priceless artifacts and captured the thieves! (+$%d 💰 +%d ⭐)",
			"failure": "❌ The thieves escaped with one minor artifact, but %s secured the most valuable pieces. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Earthquake": {
			"success": "✅ %s navigated the rubble and rescued countless trapped citizens. (+$%d 💰 +%d ⭐)",
			"failure": "❌ Rescue efforts were hampered by aftershocks. %s saved many lives but the damage is severe. (Partial: +$%d 💰 +%d ⭐)"
		},
# Replace the "# --- NEW MISSIONS STORIES ---" section (around line 280-350) with this:

		# --- NEW MISSIONS STORIES ---
		"Toxic Spill": {
			"success": "✅ %s successfully contained the toxic spill and decontaminated the entire area. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The spill was contained, but some long-term environmental damage was done. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Kidnapping": {
			"success": "✅ %s located and safely rescued the victim, apprehending the kidnappers without incident. (+$%d 💰 +%d ⭐)",
			"failure": "❌ %s found the victim, but the kidnappers escaped into the city. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Looting Spree": {
			"success": "✅ %s stopped the mass looting! Most stolen goods were recovered and order was restored. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The blackout made pursuit difficult. %s stopped the worst of it, but many looters escaped. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Power Grid Failure": {
			"success": "✅ %s repaired critical infrastructure and restored power to the entire city. (+$%d 💰 +%d ⭐)",
			"failure": "❌ Power was only restored partially. %s prevented a total system collapse but repairs are ongoing. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Giant Monster": {
			"success": "✅ %s defeated the colossal creature, saving the city from catastrophic destruction! (+$%d 💰 +%d ⭐)",
			"failure": "❌ The monster was driven back, but it caused heavy collateral damage before retreating. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Subway Derailment": {
			"success": "✅ %s quickly extracted all passengers from the wreck without major injury. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The rescue was slow due to the confined space. %s got most out safely, but with some delays. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Skydiving Mishap": {
			"success": "✅ %s successfully intercepted the skydiver and brought them safely to the ground. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The skydiver was saved, but suffered a minor injury during the emergency landing. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Data Recovery": {
			"success": "✅ %s recovered the crucial hard drive from the volatile location just in time. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The data was recovered, but the drive was partially corrupted during extraction. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Animal Stampede": {
			"success": "✅ %s successfully herded all panicked zoo animals back to safety. (+$%d 💰 +%d ⭐)",
			"failure": "❌ A few animals escaped the park perimeter. %s will continue to assist with the search. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Art Forgery Ring": {
			"success": "✅ %s exposed and dismantled the massive art forgery operation. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The ringleaders escaped capture, but %s secured most of the evidence. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Asteroid Fragment": {
			"success": "✅ %s safely retrieved and secured the dangerous meteorite fragment. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The fragment was secured, but its energy caused a temporary city blackout. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Escaped Inmate": {
			"success": "✅ %s successfully tracked down and re-apprehended the dangerous fugitive. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The inmate was sighted but eluded capture. The search continues. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Mad Scientist": {
			"success": "✅ %s stopped the rogue scientist and neutralized the dangerous experiment! (+$%d 💰 +%d ⭐)",
			"failure": "❌ The experiment was stopped, but not before causing a minor instability in the zone. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Water Main Burst": {
			"success": "✅ %s diverted the floodwaters and rescued all citizens from the rising water. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The flooding caused property damage before %s could fully contain the break. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Teleportation Mishap": {
			"success": "✅ %s successfully located and stabilized all misplaced objects and people. (+$%d 💰 +%d ⭐)",
			"failure": "❌ One crucial object was permanently lost in the interdimensional rift. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Drone Swarm": {
			"success": "✅ %s neutralized the aggressive drone swarm and secured the area. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The drones caused minor infrastructure damage before being fully taken down. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Sinkhole Rescue": {
			"success": "✅ %s rescued all people and stabilized the vehicles before the sinkhole grew larger. (+$%d 💰 +%d ⭐)",
			"failure": "❌ One vehicle was lost into the sinkhole, but all lives were saved. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Train Hijack": {
			"success": "✅ %s stopped the runaway train, subdued the hijackers, and saved the passengers. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The train was stopped, but the hijackers escaped during the chaos. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Paranormal Event": {
			"success": "✅ %s investigated and successfully neutralized the hostile spectral entity. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The entity was only temporarily repelled, and remains a future threat. (Partial: +$%d 💰 +%d ⭐)"
		},
		"Drug Cartel Bust": {
			"success": "✅ %s dismantled the major drug operation and arrested all cartel leaders. (+$%d 💰 +%d ⭐)",
			"failure": "❌ The drug lab was shut down, but the main cartel leader escaped the city. (Partial: +$%d 💰 +%d ⭐)"
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
