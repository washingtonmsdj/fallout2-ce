extends GdUnitTestSuite
## Property test for dialog reputation changes
## **Feature: fallout2-complete-migration, Property 17: Reputation Change Application**
## **Validates: Requirements 5.6**

class_name TestDialogReputationChanges
extends GdUnitTestSuite

var dialog_system: DialogSystem
var player: Critter
var npc: Critter

func before_test() -> void:
	dialog_system = DialogSystem.new()
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.karma = 0
	player.reputation = 0
	
	npc = Critter.new()
	npc.critter_name = "NPC"
	npc.stats = StatData.new()
	npc.skills = SkillData.new()

## Property: For any dialog effect that modifies reputation, 
## the karma and faction values SHALL change by exactly the specified amounts
func test_reputation_change_property() -> void:
	# Test karma changes with various amounts
	var test_cases = [
		{"amount": 10, "expected": 10},
		{"amount": -5, "expected": -5},
		{"amount": 0, "expected": 0},
		{"amount": 100, "expected": 100},
		{"amount": -50, "expected": -50},
	]
	
	for test_case in test_cases:
		# Reset karma
		player.karma = 0
		var initial_karma = player.karma
		var change_amount = test_case.amount
		var expected_karma = initial_karma + test_case.expected
		
		# Create karma change effect
		var effect = DialogEffect.new()
		effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
		effect.karma_amount = change_amount
		
		# Apply effect
		effect.apply(player)
		
		# Verify karma changed by exact amount
		assert_that(player.karma).is_equal(expected_karma, 
			"Karma should change by exactly %d, expected %d, got %d" % [change_amount, expected_karma, player.karma])

## Test that karma changes accumulate correctly
func test_karma_accumulation() -> void:
	player.karma = 0
	
	# Apply multiple karma changes
	var effect1 = DialogEffect.new()
	effect1.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect1.karma_amount = 10
	effect1.apply(player)
	
	var effect2 = DialogEffect.new()
	effect2.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect2.karma_amount = 5
	effect2.apply(player)
	
	var effect3 = DialogEffect.new()
	effect3.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect3.karma_amount = -3
	effect3.apply(player)
	
	# Total should be 10 + 5 - 3 = 12
	assert_that(player.karma).is_equal(12, "Karma should accumulate correctly")

## Test reputation change effect (currently uses karma as proxy)
func test_reputation_change_effect() -> void:
	player.karma = 0
	
	# Create reputation change effect
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.REPUTATION_CHANGE
	effect.faction = "test_faction"
	effect.reputation_amount = 15
	
	# Apply effect
	effect.apply(player)
	
	# Currently, reputation changes are applied as karma
	# This will be updated when faction reputation system is implemented
	assert_that(player.karma).is_equal(15, "Reputation change should affect karma (proxy implementation)")

## Test that dialog option effects are applied
func test_dialog_option_effects() -> void:
	player.karma = 0
	
	# Create dialog option with karma effect
	var option = DialogOption.new()
	option.id = "test_option"
	option.text = "Test option"
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect.karma_amount = 20
	option.effects = [effect]
	
	# Apply option effects
	option.apply_effects(player)
	
	# Verify karma changed
	assert_that(player.karma).is_equal(20, "Dialog option effects should be applied")

## Test that dialog node effects are applied
func test_dialog_node_effects() -> void:
	player.karma = 0
	
	# Create dialog node with karma effect
	var node = DialogNode.new()
	node.id = "test_node"
	node.text = "Test node"
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect.karma_amount = 25
	node.effects = [effect]
	
	# Apply node effects
	node.apply_effects(player)
	
	# Verify karma changed
	assert_that(player.karma).is_equal(25, "Dialog node effects should be applied")

## Test multiple effects in sequence
func test_multiple_effects_sequence() -> void:
	player.karma = 0
	
	# Create multiple effects
	var effect1 = DialogEffect.new()
	effect1.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect1.karma_amount = 10
	
	var effect2 = DialogEffect.new()
	effect2.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect2.karma_amount = -5
	
	var effect3 = DialogEffect.new()
	effect3.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect3.karma_amount = 15
	
	# Apply all effects
	effect1.apply(player)
	effect2.apply(player)
	effect3.apply(player)
	
	# Total should be 10 - 5 + 15 = 20
	assert_that(player.karma).is_equal(20, "Multiple effects should apply in sequence correctly")

## Test that effects are applied through dialog system
func test_dialog_system_effect_application() -> void:
	player.karma = 0
	
	# Create dialog tree with effect
	var tree = DialogTree.new()
	tree.id = "test_tree"
	tree.root_node_id = "root"
	
	var root_node = DialogNode.new()
	root_node.id = "root"
	root_node.text = "Root"
	
	var option = DialogOption.new()
	option.id = "opt1"
	option.text = "Option 1"
	option.next_node_id = ""
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect.karma_amount = 30
	option.effects = [effect]
	
	root_node.options = [option]
	tree.add_node(root_node)
	
	# Start dialog
	dialog_system.start_dialog(npc, tree, player)
	
	# Select option (this should apply effects)
	dialog_system.select_option(option)
	
	# Verify karma changed
	assert_that(player.karma).is_equal(30, "Dialog system should apply option effects when selecting option")

## Test negative karma changes
func test_negative_karma_changes() -> void:
	player.karma = 100
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect.karma_amount = -30
	effect.apply(player)
	
	assert_that(player.karma).is_equal(70, "Negative karma changes should work correctly")

## Test zero karma change
func test_zero_karma_change() -> void:
	player.karma = 50
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.KARMA_CHANGE
	effect.karma_amount = 0
	effect.apply(player)
	
	assert_that(player.karma).is_equal(50, "Zero karma change should not modify karma")

## Test skill increase effect
func test_skill_increase_effect() -> void:
	player.skills.skill_values[SkillData.Skill.SPEECH] = 50
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.SKILL_INCREASE
	effect.skill = SkillData.Skill.SPEECH
	effect.skill_amount = 10
	effect.apply(player)
	
	var new_skill_value = player.skills.get_skill_value(SkillData.Skill.SPEECH)
	assert_that(new_skill_value).is_equal(60, "Skill increase effect should modify skill value")

## Test that NONE effect type does nothing
func test_none_effect_type() -> void:
	player.karma = 50
	
	var effect = DialogEffect.new()
	effect.effect_type = DialogEffect.EffectType.NONE
	effect.apply(player)
	
	assert_that(player.karma).is_equal(50, "NONE effect type should not modify anything")
