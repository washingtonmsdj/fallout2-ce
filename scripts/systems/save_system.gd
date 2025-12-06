extends Node
class_name SaveSystem
## Complete save system for Fallout 2 CE

signal save_completed(save_name: String)
signal load_completed(save_name: String)
signal save_failed(save_name: String, error: String)
signal load_failed(save_name: String, error: String)
signal auto_save_triggered
signal quick_save_triggered

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SAVE_SLOTS = 10
const QUICKSAVE_SLOT = "quicksave"
const AUTOSAVE_SLOT = "autosave"
const AUTOSAVE_INTERVAL = 300.0  # 5 minutes in seconds

# References to game systems
var player: Critter = null
var party_system: PartySystem = null
var economy_system: EconomySystem = null
var reputation_system: ReputationSystem = null
var effect_queue: EffectQueue = null
var quest_system: Node = null  # To be implemented later
var world_system: Node = null  # To be implemented later

# Save slots info
var save_slots: Dictionary = {}

# Auto-save timer
var auto_save_timer: Timer = null
var auto_save_enabled: bool = true

func _ready() -> void:
	_create_save_directory()
	_load_save_slots_info()
	_setup_auto_save_timer()
	_setup_input_handling()

## Initialize with game systems
func initialize_systems(
	player_critter: Critter,
	party_sys: PartySystem,
	economy_sys: EconomySystem,
	reputation_sys: ReputationSystem,
	effect_q: EffectQueue
) -> void:
	player = player_critter
	party_system = party_sys
	economy_system = economy_sys
	reputation_system = reputation_sys
	effect_queue = effect_q

## Setup auto-save timer
func _setup_auto_save_timer() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTOSAVE_INTERVAL
	auto_save_timer.one_shot = false
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)

	if auto_save_enabled:
		auto_save_timer.start()

## Enable/disable auto-save
func set_auto_save_enabled(enabled: bool) -> void:
	auto_save_enabled = enabled
	if auto_save_timer:
		if enabled:
			auto_save_timer.start()
		else:
			auto_save_timer.stop()

## Auto-save timer callback
func _on_auto_save_timer_timeout() -> void:
	if auto_save_enabled and player:
		auto_save()

## Force trigger auto-save (for specific events)
func trigger_auto_save() -> void:
	if player:
		auto_save()

## Setup input handling for quicksave/quickload
func _setup_input_handling() -> void:
	# Note: Input handling would typically be set up in a UI or input manager
	# This is a placeholder for the functionality
	pass

## Handle quicksave input (F5 by default)
func handle_quicksave_input() -> void:
	if player:
		quick_save()

## Handle quickload input (F9 by default)
func handle_quickload_input() -> void:
	if save_slot_exists(QUICKSAVE_SLOT):
		quick_load()
	else:
		print("No quicksave available")

## Create save directory if it doesn't exist
func _create_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

## Load save slots information
func _load_save_slots_info() -> void:
	var save_info_path = SAVE_DIR + "save_slots.json"
	if FileAccess.file_exists(save_info_path):
		var file = FileAccess.open(save_info_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		
		if error == OK:
			save_slots = json.data
		else:
			print("Error loading save slots info: ", json.get_error_message())

## Save save slots information
func _save_save_slots_info() -> void:
	var save_info_path = SAVE_DIR + "save_slots.json"
	var file = FileAccess.open(save_info_path, FileAccess.WRITE)
	
	var json = JSON.new()
	file.store_string(json.stringify(save_slots))
	file.close()

## Get full save path for slot
func _get_save_path(slot_name: String) -> String:
	return SAVE_DIR + slot_name + SAVE_EXTENSION

## Save game to specific slot
func save_game(slot_name: String, save_name: String = "") -> bool:
	if not player:
		save_failed.emit(slot_name, "No player reference")
		return false
	
	var save_data = SaveData.new()
	save_data.save_name = save_name if save_name != "" else slot_name
	
	# Serialize player data
	save_data.player_data = save_data.serialize_critter(player)
	
	# Serialize party data
	if party_system:
		save_data.party_data = []
		for companion in party_system.party_members:
			if companion != player:  # Don't save player twice
				save_data.party_data.append(save_data.serialize_critter(companion))
		
		save_data.player_data["party_behaviors"] = party_system.companion_behaviors
	
	# Serialize economy data
	if economy_system:
		save_data.economy_data = {
			"base_price_multiplier": economy_system.base_price_multiplier,
			"barter_skill_modifier": economy_system.barter_skill_modifier,
			"trade_history": economy_system.trade_history.duplicate()
		}
	
	# Serialize reputation data
	if reputation_system:
		save_data.reputation_data = {
			"karma_values": reputation_system.karma_values.duplicate(),
			"faction_reputations": reputation_system.faction_reputations.duplicate()
		}
	
	# Serialize effect queue data
	if effect_queue:
		save_data.effect_queue_data = {
			"active_effects": {},
			"addictions": effect_queue.addictions.duplicate()
		}
		
		# Serialize active effects
		for critter_id in effect_queue.active_effects:
			save_data.effect_queue_data.active_effects[critter_id] = []
			for effect in effect_queue.active_effects[critter_id]:
				save_data.effect_queue_data.active_effects[critter_id].append(
					save_data.serialize_timed_effect(effect)
				)
		
		# Add critter registry info
		save_data.effect_queue_data["critter_registry"] = effect_queue.critter_registry.duplicate()
	
	# Generate checksum
	save_data.generate_checksum()
	
	# Save to file
	var save_path = _get_save_path(slot_name)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		save_failed.emit(slot_name, "Cannot open save file for writing")
		return false
	
	var json = JSON.new()
	var save_json = json.stringify(save_data.serialize_to_dict())
	file.store_string(save_json)
	file.close()
	
	# Update save slots info
	save_slots[slot_name] = {
		"name": save_data.save_name,
		"timestamp": save_data.timestamp,
		"player_name": player.critter_name,
		"player_level": player.stats.get_stat(GameConstants.PrimaryStat.LEVEL) if player.stats else 1,
		"location": "Unknown"  # TODO: Add location system
	}
	
	_save_save_slots_info()
	
	save_completed.emit(slot_name)
	return true

## Load game from specific slot
func load_game(slot_name: String) -> bool:
	var save_path = _get_save_path(slot_name)
	if not FileAccess.file_exists(save_path):
		load_failed.emit(slot_name, "Save file does not exist")
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		load_failed.emit(slot_name, "Invalid save file format")
		return false
	
	var save_data = SaveData.new()
	save_data.deserialize_from_dict(json.data)
	
	# Validate checksum
	if not save_data.validate_checksum():
		load_failed.emit(slot_name, "Save file corrupted")
		return false
	
	# Deserialize player data
	if player:
		player.queue_free()
	player = save_data.deserialize_critter(save_data.player_data)
	
	# Restore party behaviors
	if party_system and save_data.player_data.has("party_behaviors"):
		party_system.companion_behaviors = save_data.player_data.party_behaviors
	
	# Deserialize party data
	if party_system:
		# Clear existing party
		for companion in party_system.party_members.duplicate():
			if companion != player:
				party_system.remove_companion(companion)
		
		# Load companions
		for companion_data in save_data.party_data:
			var companion = save_data.deserialize_critter(companion_data)
			party_system.add_companion(companion)
	
	# Deserialize economy data
	if economy_system and save_data.economy_data:
		economy_system.base_price_multiplier = save_data.economy_data.get("base_price_multiplier", 1.0)
		economy_system.barter_skill_modifier = save_data.economy_data.get("barter_skill_modifier", 0.01)
		economy_system.trade_history = save_data.economy_data.get("trade_history", []).duplicate()
	
	# Deserialize reputation data
	if reputation_system and save_data.reputation_data:
		reputation_system.karma_values = save_data.reputation_data.get("karma_values", {}).duplicate()
		reputation_system.faction_reputations = save_data.reputation_data.get("faction_reputations", {}).duplicate()
	
	# Deserialize effect queue data
	if effect_queue and save_data.effect_queue_data:
		effect_queue.active_effects = {}
		effect_queue.addictions = save_data.effect_queue_data.get("addictions", {}).duplicate()
		
		# Restore critter registry
		if save_data.effect_queue_data.has("critter_registry"):
			effect_queue.critter_registry = save_data.effect_queue_data.critter_registry.duplicate()
		
		# Restore active effects
		var active_effects_data = save_data.effect_queue_data.get("active_effects", {})
		for critter_id in active_effects_data:
			effect_queue.active_effects[critter_id] = []
			for effect_data in active_effects_data[critter_id]:
				var effect = save_data.deserialize_timed_effect(effect_data)
				effect_queue.active_effects[critter_id].append(effect)
	
	load_completed.emit(slot_name)
	return true

## Quick save
func quick_save() -> bool:
	var success = save_game(QUICKSAVE_SLOT, "Quick Save")
	if success:
		quick_save_triggered.emit()
	return success

## Quick load
func quick_load() -> bool:
	return load_game(QUICKSAVE_SLOT)

## Auto save
func auto_save() -> bool:
	var success = save_game(AUTOSAVE_SLOT, "Auto Save")
	if success:
		auto_save_triggered.emit()
	return success

## Get list of available save slots
func get_save_slots() -> Dictionary:
	return save_slots.duplicate()

## Delete save slot
func delete_save_slot(slot_name: String) -> bool:
	var save_path = _get_save_path(slot_name)
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open(SAVE_DIR)
		dir.remove(save_path)
		
		if save_slots.has(slot_name):
			save_slots.erase(slot_name)
			_save_save_slots_info()
		
		return true
	
	return false

## Check if save slot exists
func save_slot_exists(slot_name: String) -> bool:
	return FileAccess.file_exists(_get_save_path(slot_name))

## Validate save file integrity
func validate_save_file(slot_name: String) -> Dictionary:
	var result = {"valid": false, "error": ""}
	
	var save_path = _get_save_path(slot_name)
	if not FileAccess.file_exists(save_path):
		result.error = "Save file does not exist"
		return result
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		result.error = "Invalid JSON format"
		return result
	
	var save_data = SaveData.new()
	var deserialize_result = save_data.deserialize_from_dict(json.data)
	if deserialize_result != OK:
		result.error = "Failed to deserialize save data"
		return result
	
	if not save_data.validate_checksum():
		result.error = "Checksum validation failed - file may be corrupted"
		return result
	
	result.valid = true
	return result

## Get save slot info
func get_save_slot_info(slot_name: String) -> Dictionary:
	if save_slots.has(slot_name):
		return save_slots[slot_name].duplicate()
	return {}

## Create new game save
func new_game() -> void:
	# Reset all systems to initial state
	if player:
		player.queue_free()
	
	player = Critter.new()
	player.critter_name = "Player"
	player.critter_id = "player"
	
	# Initialize basic stats
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.traits = TraitData.new()
	player.perks = PerkData.new()
	player.inventory = Inventory.new()
	player.equipped_items = {}
	
	# Reset other systems
	if party_system:
		party_system.party_members.clear()
		party_system.companion_behaviors.clear()
	
	if economy_system:
		economy_system.trade_history.clear()
	
	if reputation_system:
		reputation_system.karma_values.clear()
		reputation_system.faction_reputations.clear()
	
	if effect_queue:
		effect_queue.active_effects.clear()
		effect_queue.addictions.clear()
		effect_queue.critter_registry.clear()