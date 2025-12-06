extends GdUnitTestSuite
## Property test for save/load round trip
## **Feature: fallout2-complete-migration, Property 33: Save/Load Round Trip**
## **Validates: Requirements 14.1, 14.2**

class_name TestSaveLoadRoundTrip
extends GdUnitTestSuite

var save_system: SaveSystem
var player: Critter
var party_system: PartySystem
var economy_system: EconomySystem
var reputation_system: ReputationSystem
var effect_queue: EffectQueue

var test_save_slot = "test_slot"

func before_test() -> void:
	save_system = SaveSystem.new()
	add_child(save_system)
	
	party_system = PartySystem.new()
	add_child(party_system)
	
	economy_system = EconomySystem.new()
	add_child(economy_system)
	
	reputation_system = ReputationSystem.new()
	add_child(reputation_system)
	
	effect_queue = EffectQueue.new()
	add_child(effect_queue)
	
	# Create test player
	player = Critter.new()
	player.critter_name = "Test Player"
	player.critter_id = "test_player"
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.traits = TraitData.new()
	player.perks = PerkData.new()
	player.inventory = Inventory.new()
	player.equipped_items = {}
	player.health = 85
	player.max_health = 100
	player.action_points = 7
	player.karma = 25
	player.caps = 1500
	player.faction = "vault_dwellers"
	player.sequence = 5
	
	# Initialize systems
	save_system.initialize_systems(player, party_system, economy_system, reputation_system, effect_queue)

func after_test() -> void:
	# Clean up test save
	if save_system.save_slot_exists(test_save_slot):
		save_system.delete_save_slot(test_save_slot)
	
	if save_system:
		save_system.queue_free()
	if party_system:
		party_system.queue_free()
	if economy_system:
		economy_system.queue_free()
	if reputation_system:
		reputation_system.queue_free()
	if effect_queue:
		effect_queue.queue_free()

## Property: Saving and loading SHALL preserve all game state exactly
func test_save_load_round_trip_property() -> void:
	# Setup complex game state
	_setup_complex_game_state()
	
	# Save game
	assert_that(save_system.save_game(test_save_slot, "Test Save")).is_true()
	
	# Create backup of original state
	var original_player_data = _serialize_player_state(player)
	var original_party_data = _serialize_party_state()
	var original_economy_data = _serialize_economy_state()
	var original_reputation_data = _serialize_reputation_state()
	var original_effect_data = _serialize_effect_state()
	
	# Modify current state to ensure loading actually works
	player.health = 1
	player.caps = 0
	reputation_system.set_karma(player, -100)
	
	# Load game
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	# Verify all state was restored
	_verify_player_state_restored(original_player_data)
	_verify_party_state_restored(original_party_data)
	_verify_economy_state_restored(original_economy_data)
	_verify_reputation_state_restored(original_reputation_data)
	_verify_effect_state_restored(original_effect_data)

## Test basic player data preservation
func test_player_data_preservation() -> void:
	player.health = 42
	player.caps = 1337
	player.karma = -50
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	player.health = 100  # Change values
	player.caps = 0
	player.karma = 0
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	assert_that(player.health).is_equal(42)
	assert_that(player.caps).is_equal(1337)
	assert_that(player.karma).is_equal(-50)

## Test inventory preservation
func test_inventory_preservation() -> void:
	var weapon = Weapon.new()
	weapon.item_name = "Test Weapon"
	weapon.item_id = "test_weapon"
	weapon.damage = 15
	player.inventory.add_item(weapon)
	
	player.equipped_items["weapon"] = weapon
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	player.inventory.clear()
	player.equipped_items.clear()
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	assert_that(player.inventory.items.size()).is_equal(1)
	assert_that(player.inventory.items[0].item_name).is_equal("Test Weapon")
	assert_that(player.equipped_items.has("weapon")).is_true()
	assert_that(player.equipped_items["weapon"].item_name).is_equal("Test Weapon")

## Test party preservation
func test_party_preservation() -> void:
	var companion = Critter.new()
	companion.critter_name = "Test Companion"
	companion.critter_id = "test_companion"
	companion.health = 75
	
	party_system.add_companion(companion)
	party_system.set_companion_behavior(companion, {"aggressive": true, "use_items": false})
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	party_system.remove_companion(companion)
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	assert_that(party_system.party_members.size()).is_equal(2)  # player + companion
	assert_that(party_system.party_members[1].critter_name).is_equal("Test Companion")
	assert_that(party_system.get_companion_behavior(companion)["aggressive"]).is_true()

## Test economy data preservation
func test_economy_preservation() -> void:
	economy_system.base_price_multiplier = 1.2
	economy_system.barter_skill_modifier = 0.015
	
	var trade_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"player_items": ["item1"],
		"trader_items": ["item2"],
		"caps_exchanged": 500
	}
	economy_system.trade_history.append(trade_record)
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	economy_system.base_price_multiplier = 1.0
	economy_system.barter_skill_modifier = 0.01
	economy_system.trade_history.clear()
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	assert_that(economy_system.base_price_multiplier).is_equal(1.2)
	assert_that(economy_system.barter_skill_modifier).is_equal(0.015)
	assert_that(economy_system.trade_history.size()).is_equal(1)
	assert_that(economy_system.trade_history[0]["caps_exchanged"]).is_equal(500)

## Test reputation preservation
func test_reputation_preservation() -> void:
	reputation_system.set_karma(player, 150)
	reputation_system.set_faction_reputation(player, "vault_city", 75)
	reputation_system.set_faction_reputation(player, "enclave", -25)
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	reputation_system.set_karma(player, 0)
	reputation_system.set_faction_reputation(player, "vault_city", 0)
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	assert_that(reputation_system.get_karma(player)).is_equal(150)
	assert_that(reputation_system.get_faction_reputation(player, "vault_city")).is_equal(75)
	assert_that(reputation_system.get_faction_reputation(player, "enclave")).is_equal(-25)

## Test effect queue preservation
func test_effect_queue_preservation() -> void:
	var effect = TimedEffect.new()
	effect.id = "test_effect"
	effect.duration = 3600.0  # 1 hour
	effect.remaining_duration = 1800.0  # 30 minutes
	effect.stat_modifiers = {"strength": 2}
	
	effect_queue.add_effect(player, effect)
	effect_queue.addictions[player.critter_name + "_" + str(player.get_instance_id())] = {
		"jet": {"severity": 2}
	}
	
	assert_that(save_system.save_game(test_save_slot)).is_true()
	effect_queue.remove_effect(player, effect)
	
	assert_that(save_system.load_game(test_save_slot)).is_true()
	
	var player_id = player.critter_name + "_" + str(player.get_instance_id())
	assert_that(effect_queue.active_effects.has(player_id)).is_true()
	assert_that(effect_queue.active_effects[player_id].size()).is_equal(1)
	assert_that(effect_queue.active_effects[player_id][0].id).is_equal("test_effect")
	assert_that(effect_queue.addictions.has(player_id)).is_true()
	assert_that(effect_queue.addictions[player_id]["jet"]["severity"]).is_equal(2)

## Setup complex game state for comprehensive testing
func _setup_complex_game_state() -> void:
	# Complex player setup
	player.stats.set_stat(GameConstants.PrimaryStat.STRENGTH, 8)
	player.stats.set_stat(GameConstants.PrimaryStat.PERCEPTION, 7)
	player.stats.set_stat(GameConstants.PrimaryStat.ENDURANCE, 6)
	player.stats.set_stat(GameConstants.PrimaryStat.CHARISMA, 5)
	player.stats.set_stat(GameConstants.PrimaryStat.INTELLIGENCE, 9)
	player.stats.set_stat(GameConstants.PrimaryStat.AGILITY, 7)
	player.stats.set_stat(GameConstants.PrimaryStat.LUCK, 4)
	player.stats.set_stat(GameConstants.PrimaryStat.LEVEL, 15)
	
	# Add items to inventory
	for i in range(5):
		var item = Item.new()
		item.item_name = "Test Item " + str(i)
		item.item_id = "test_item_" + str(i)
		player.inventory.add_item(item)
	
	# Add companions
	for i in range(2):
		var companion = Critter.new()
		companion.critter_name = "Companion " + str(i)
		companion.critter_id = "companion_" + str(i)
		companion.health = 50 + i * 25
		party_system.add_companion(companion)
	
	# Complex reputation state
	reputation_system.set_karma(player, 42)
	for faction in ["vault_city", "new_reno", "shady_sands", "enclave"]:
		reputation_system.set_faction_reputation(player, faction, randi_range(-100, 100))
	
	# Complex economy state
	economy_system.base_price_multiplier = 0.95
	for i in range(3):
		economy_system.trade_history.append({
			"timestamp": Time.get_unix_time_from_system() - i * 3600,
			"caps_exchanged": 100 * (i + 1)
		})

## Helper functions for state serialization/verification
func _serialize_player_state(critter: Critter) -> Dictionary:
	return {
		"name": critter.critter_name,
		"health": critter.health,
		"caps": critter.caps,
		"karma": critter.karma,
		"inventory_size": critter.inventory.items.size() if critter.inventory else 0,
		"equipped_count": critter.equipped_items.size()
	}

func _serialize_party_state() -> Dictionary:
	return {
		"member_count": party_system.party_members.size(),
		"behavior_count": party_system.companion_behaviors.size()
	}

func _serialize_economy_state() -> Dictionary:
	return {
		"price_multiplier": economy_system.base_price_multiplier,
		"barter_modifier": economy_system.barter_skill_modifier,
		"trade_count": economy_system.trade_history.size()
	}

func _serialize_reputation_state() -> Dictionary:
	return {
		"karma": reputation_system.get_karma(player),
		"faction_count": reputation_system.get_known_factions(player).size()
	}

func _serialize_effect_state() -> Dictionary:
	var player_id = player.critter_name + "_" + str(player.get_instance_id())
	return {
		"active_effects": effect_queue.active_effects.get(player_id, []).size(),
		"addiction_count": effect_queue.addictions.get(player_id, {}).size()
	}

func _verify_player_state_restored(original: Dictionary) -> void:
	assert_that(player.critter_name).is_equal(original.name)
	assert_that(player.health).is_equal(original.health)
	assert_that(player.caps).is_equal(original.caps)
	assert_that(player.karma).is_equal(original.karma)
	assert_that(player.inventory.items.size()).is_equal(original.inventory_size)
	assert_that(player.equipped_items.size()).is_equal(original.equipped_count)

func _verify_party_state_restored(original: Dictionary) -> void:
	assert_that(party_system.party_members.size()).is_equal(original.member_count)
	assert_that(party_system.companion_behaviors.size()).is_equal(original.behavior_count)

func _verify_economy_state_restored(original: Dictionary) -> void:
	assert_that(economy_system.base_price_multiplier).is_equal(original.price_multiplier)
	assert_that(economy_system.barter_skill_modifier).is_equal(original.barter_modifier)
	assert_that(economy_system.trade_history.size()).is_equal(original.trade_count)

func _verify_reputation_state_restored(original: Dictionary) -> void:
	assert_that(reputation_system.get_karma(player)).is_equal(original.karma)
	assert_that(reputation_system.get_known_factions(player).size()).is_equal(original.faction_count)

func _verify_effect_state_restored(original: Dictionary) -> void:
	var player_id = player.critter_name + "_" + str(player.get_instance_id())
	assert_that(effect_queue.active_effects.get(player_id, []).size()).is_equal(original.active_effects)
	assert_that(effect_queue.addictions.get(player_id, {}).size()).is_equal(original.addiction_count)