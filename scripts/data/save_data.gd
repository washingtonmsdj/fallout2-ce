extends Resource
class_name SaveData
## Save data structure for Fallout 2 CE

# Save metadata
@export var save_name: String = ""
@export var timestamp: int = 0
@export var game_version: String = "0.1.0"
@export var checksum: String = ""

# Player data
@export var player_data: Dictionary = {}

# World data
@export var world_data: Dictionary = {}

# Quest data
@export var quest_data: Dictionary = {}

# Party data
@export var party_data: Array = []

# Economy data
@export var economy_data: Dictionary = {}

# Reputation data
@export var reputation_data: Dictionary = {}

# Effect queue data
@export var effect_queue_data: Dictionary = {}

# Combat data
@export var combat_data: Dictionary = {}

func _init() -> void:
	timestamp = Time.get_unix_time_from_system()

## Generate checksum for save validation
func generate_checksum() -> String:
	var data_string = JSON.stringify({
		"player_data": player_data,
		"world_data": world_data,
		"quest_data": quest_data,
		"party_data": party_data,
		"economy_data": economy_data,
		"reputation_data": reputation_data,
		"effect_queue_data": effect_queue_data,
		"combat_data": combat_data
	})
	
	checksum = data_string.md5_text()
	return checksum

## Validate save data integrity
func validate_checksum() -> bool:
	var current_checksum = generate_checksum()
	return checksum == current_checksum

## Serialize critter data
func serialize_critter(critter: Critter) -> Dictionary:
	if not critter:
		return {}
	
	var data = {
		"critter_name": critter.critter_name,
		"critter_id": critter.critter_id,
		"position": {"x": critter.position.x, "y": critter.position.y},
		"stats": critter.stats.serialize() if critter.stats else {},
		"skills": critter.skills.serialize() if critter.skills else {},
		"traits": critter.traits.serialize() if critter.traits else {},
		"perks": critter.perks.serialize() if critter.perks else {},
		"inventory": [],
		"equipped_items": {},
		"health": critter.health,
		"max_health": critter.max_health,
		"action_points": critter.action_points,
		"karma": critter.karma,
		"caps": critter.caps,
		"faction": critter.faction,
		"sequence": critter.sequence
	}
	
	# Serialize inventory
	if critter.inventory:
		for item in critter.inventory.items:
			data.inventory.append(item.serialize())
	
	# Serialize equipped items
	if critter.equipped_items:
		for slot in critter.equipped_items:
			var item = critter.equipped_items[slot]
			if item:
				data.equipped_items[slot] = item.serialize()
	
	return data

## Deserialize critter data
func deserialize_critter(data: Dictionary) -> Critter:
	var critter = Critter.new()
	
	critter.critter_name = data.get("critter_name", "")
	critter.critter_id = data.get("critter_id", "")
	
	var pos_data = data.get("position", {})
	critter.position = Vector2(pos_data.get("x", 0.0), pos_data.get("y", 0.0))
	
	# Deserialize stats, skills, traits, perks
	if data.has("stats"):
		critter.stats = StatData.new()
		critter.stats.deserialize(data.stats)
	
	if data.has("skills"):
		critter.skills = SkillData.new()
		critter.skills.deserialize(data.skills)
	
	if data.has("traits"):
		critter.traits = TraitData.new()
		critter.traits.deserialize(data.traits)
	
	if data.has("perks"):
		critter.perks = PerkData.new()
		critter.perks.deserialize(data.perks)
	
	# Deserialize inventory
	if data.has("inventory"):
		critter.inventory = Inventory.new()
		for item_data in data.inventory:
			var item = Item.new()
			item.deserialize(item_data)
			critter.inventory.add_item(item)
	
	# Deserialize equipped items
	if data.has("equipped_items"):
		critter.equipped_items = {}
		for slot in data.equipped_items:
			var item = Item.new()
			item.deserialize(data.equipped_items[slot])
			critter.equipped_items[slot] = item
	
	critter.health = data.get("health", 100)
	critter.max_health = data.get("max_health", 100)
	critter.action_points = data.get("action_points", 10)
	critter.karma = data.get("karma", 0)
	critter.caps = data.get("caps", 0)
	critter.faction = data.get("faction", "")
	critter.sequence = data.get("sequence", 0)
	
	return critter

## Serialize quest data
func serialize_quest(quest: Quest) -> Dictionary:
	if not quest:
		return {}
	
	return {
		"quest_id": quest.quest_id,
		"title": quest.title,
		"description": quest.description,
		"state": quest.state,
		"objectives": quest.objectives.duplicate(),
		"rewards": quest.rewards.duplicate(),
		"quest_giver": quest.quest_giver,
		"completion_date": quest.completion_date
	}

## Deserialize quest data
func deserialize_quest(data: Dictionary) -> Quest:
	var quest = Quest.new()
	
	quest.quest_id = data.get("quest_id", "")
	quest.title = data.get("title", "")
	quest.description = data.get("description", "")
	quest.state = data.get("state", Quest.QuestState.INACTIVE)
	quest.objectives = data.get("objectives", []).duplicate()
	quest.rewards = data.get("rewards", []).duplicate()
	quest.quest_giver = data.get("quest_giver", "")
	quest.completion_date = data.get("completion_date", "")
	
	return quest

## Serialize effect data
func serialize_timed_effect(effect: TimedEffect) -> Dictionary:
	if not effect:
		return {}
	
	return {
		"id": effect.id,
		"name": effect.name,
		"type": effect.effect_type,
		"duration": effect.duration,
		"remaining_duration": effect.remaining_duration,
		"is_addiction": effect.is_addiction,
		"stat_modifiers": effect.stat_modifiers.duplicate(),
		"skill_modifiers": effect.skill_modifiers.duplicate(),
		"damage_per_hour": effect.damage_per_hour,
		"crippled_limbs": effect.crippled_limbs.duplicate()
	}

## Deserialize effect data
func deserialize_timed_effect(data: Dictionary) -> TimedEffect:
	var effect = TimedEffect.new()
	
	effect.id = data.get("id", "")
	effect.name = data.get("name", "")
	effect.effect_type = data.get("type", TimedEffect.EffectType.STAT_MODIFIER)
	effect.duration = data.get("duration", 0.0)
	effect.remaining_duration = data.get("remaining_duration", 0.0)
	effect.is_addiction = data.get("is_addiction", false)
	effect.stat_modifiers = data.get("stat_modifiers", {}).duplicate()
	effect.skill_modifiers = data.get("skill_modifiers", {}).duplicate()
	effect.damage_per_hour = data.get("damage_per_hour", 0.0)
	effect.crippled_limbs = data.get("crippled_limbs", {}).duplicate()
	
	return effect

## Serialize this SaveData to dictionary for JSON
func serialize_to_dict() -> Dictionary:
	return {
		"save_name": save_name,
		"timestamp": timestamp,
		"game_version": game_version,
		"checksum": checksum,
		"player_data": player_data,
		"world_data": world_data,
		"quest_data": quest_data,
		"party_data": party_data,
		"economy_data": economy_data,
		"reputation_data": reputation_data,
		"effect_queue_data": effect_queue_data,
		"combat_data": combat_data
	}

## Deserialize from dictionary (after JSON parse)
func deserialize_from_dict(data: Dictionary) -> Error:
	save_name = data.get("save_name", "")
	timestamp = data.get("timestamp", 0)
	game_version = data.get("game_version", "0.1.0")
	checksum = data.get("checksum", "")
	player_data = data.get("player_data", {})
	world_data = data.get("world_data", {})
	quest_data = data.get("quest_data", {})
	party_data = data.get("party_data", [])
	economy_data = data.get("economy_data", {})
	reputation_data = data.get("reputation_data", {})
	effect_queue_data = data.get("effect_queue_data", {})
	combat_data = data.get("combat_data", {})
	return OK