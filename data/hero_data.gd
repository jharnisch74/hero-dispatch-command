# res://scripts/data/hero_data.gd
# Define all starting heroes here
extends RefCounted
class_name HeroData

static func get_starting_heroes() -> Array:
	return [
		{
			"name": "Captain Thunder",
			"emoji": "⚡",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED]
		},
		{
			"name": "Shadow Strike",
			"emoji": "🥷",
			"specialties": [Hero.Specialty.SPEED, Hero.Specialty.INVESTIGATION]
		},
		{
			"name": "Tech Wizard",
			"emoji": "🧙",
			"specialties": [Hero.Specialty.TECH, Hero.Specialty.INVESTIGATION]
		},
		{
			"name": "Guardian",
			"emoji": "🛡️",
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.COMBAT]
		},
		{
			"name": "Frost Queen",
			"emoji": "❄️",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.RESCUE]
		},
		{
			"name": "Pyro",
			"emoji": "🔥",
			"specialties": [Hero.Specialty.COMBAT, Hero.Specialty.SPEED]
		},
		{
			"name": "Healer",
			"emoji": "💚",
			"specialties": [Hero.Specialty.RESCUE, Hero.Specialty.INVESTIGATION]
		},
		{
			"name": "Night Owl",
			"emoji": "🦉",
			"specialties": [Hero.Specialty.INVESTIGATION, Hero.Specialty.SPEED]
		}
	]
