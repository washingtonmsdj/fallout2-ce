extends GdUnitTestSuite
## Property test for effect stacking calculation
## **Feature: fallout2-complete-migration, Property 27: Effect Stacking Calculation**
## **Validates: Requirements 10.6**

class_name TestEffectStacking
extends GdUnitTestSuite

var effect_queue: EffectQueue
var critter: Critter

func before_test() -> void:
	effect_queue = EffectQueue.new()
	add_child(effect_queue)
	
	critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.stats = StatData.new()
	critter.stats.strength = 5
	critter.stats.agility = 5
	critter.skills = SkillData.new()
	critter.skills.skill_values[SkillData.Skill.SMALL_GUNS] = 50

func after_test() -> void:
	if effect_queue:
		effect_queue.queue_free()

## Property: For any stat with multiple active effects, 
## get_total_stat_modifier() SHALL return the sum of all effect values
func test_effect_stacking_calculation_property() -> void:
	# Criar múltiplos efeitos que modificam o mesmo stat
	var effect1 = TimedEffect.new()
	effect1.id = "effect1"
	effect1.name = "Effect 1"
	effect1.duration = 10.0
	effect1.stat_modifiers["strength"] = 2
	
	var effect2 = TimedEffect.new()
	effect2.id = "effect2"
	effect2.name = "Effect 2"
	effect2.duration = 10.0
	effect2.stat_modifiers["strength"] = 3
	
	var effect3 = TimedEffect.new()
	effect3.id = "effect3"
	effect3.name = "Effect 3"
	effect3.duration = 10.0
	effect3.stat_modifiers["strength"] = -1
	
	# Adicionar todos os efeitos
	effect_queue.add_effect(critter, effect1)
	effect_queue.add_effect(critter, effect2)
	effect_queue.add_effect(critter, effect3)
	
	# Verificar modificador total
	var total_modifier = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	
	# Total deve ser 2 + 3 - 1 = 4
	assert_that(total_modifier).is_equal(4, 
		"Total modifier should be sum of all effects: 2 + 3 - 1 = 4")

## Test that skill modifiers stack correctly
func test_skill_modifier_stacking() -> void:
	var effect1 = TimedEffect.new()
	effect1.id = "skill_effect1"
	effect1.name = "Skill Effect 1"
	effect1.duration = 10.0
	effect1.skill_modifiers["small_guns"] = 10
	
	var effect2 = TimedEffect.new()
	effect2.id = "skill_effect2"
	effect2.name = "Skill Effect 2"
	effect2.duration = 10.0
	effect2.skill_modifiers["small_guns"] = 15
	
	effect_queue.add_effect(critter, effect1)
	effect_queue.add_effect(critter, effect2)
	
	var total_modifier = effect_queue.get_total_skill_modifier(critter, SkillData.Skill.SMALL_GUNS)
	
	# Total deve ser 10 + 15 = 25
	assert_that(total_modifier).is_equal(25, 
		"Total skill modifier should be sum: 10 + 15 = 25")

## Test that effects on different stats don't interfere
func test_different_stats_independent() -> void:
	var strength_effect = TimedEffect.new()
	strength_effect.id = "strength_effect"
	strength_effect.name = "Strength Effect"
	strength_effect.duration = 10.0
	strength_effect.stat_modifiers["strength"] = 5
	
	var agility_effect = TimedEffect.new()
	agility_effect.id = "agility_effect"
	agility_effect.name = "Agility Effect"
	agility_effect.duration = 10.0
	agility_effect.stat_modifiers["agility"] = 3
	
	effect_queue.add_effect(critter, strength_effect)
	effect_queue.add_effect(critter, agility_effect)
	
	# Verificar que modificadores são independentes
	var strength_mod = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	var agility_mod = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.AGILITY)
	
	assert_that(strength_mod).is_equal(5, "Strength modifier should be 5")
	assert_that(agility_mod).is_equal(3, "Agility modifier should be 3")

## Test that removing effect updates total modifier
func test_removing_effect_updates_total() -> void:
	var effect1 = TimedEffect.new()
	effect1.id = "effect1"
	effect1.name = "Effect 1"
	effect1.duration = 10.0
	effect1.stat_modifiers["strength"] = 5
	
	var effect2 = TimedEffect.new()
	effect2.id = "effect2"
	effect2.name = "Effect 2"
	effect2.duration = 10.0
	effect2.stat_modifiers["strength"] = 3
	
	effect_queue.add_effect(critter, effect1)
	effect_queue.add_effect(critter, effect2)
	
	# Total deve ser 8
	var total_before = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	assert_that(total_before).is_equal(8, "Total should be 8 before removal")
	
	# Remover effect1
	effect_queue.remove_effect(critter, effect1)
	
	# Total deve ser 3
	var total_after = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	assert_that(total_after).is_equal(3, "Total should be 3 after removing effect1")

## Test that expired effects don't contribute to modifiers
func test_expired_effects_not_counted() -> void:
	var effect1 = TimedEffect.new()
	effect1.id = "effect1"
	effect1.name = "Effect 1"
	effect1.duration = 1.0
	effect1.remaining_duration = 1.0
	effect1.stat_modifiers["strength"] = 5
	
	var effect2 = TimedEffect.new()
	effect2.id = "effect2"
	effect2.name = "Effect 2"
	effect2.duration = 10.0
	effect2.remaining_duration = 10.0
	effect2.stat_modifiers["strength"] = 3
	
	effect_queue.add_effect(critter, effect1)
	effect_queue.add_effect(critter, effect2)
	
	# Expirar effect1
	effect_queue._tick_all_effects(2.0)
	
	# Total deve ser apenas 3 (effect2)
	var total = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	assert_that(total).is_equal(3, "Total should only include non-expired effects")

## Test multiple effects with positive and negative modifiers
func test_positive_negative_modifiers() -> void:
	# Criar efeitos com modificadores positivos e negativos
	var effects_data = [
		{"id": "buff1", "modifier": 10},
		{"id": "buff2", "modifier": 5},
		{"id": "debuff1", "modifier": -3},
		{"id": "debuff2", "modifier": -2}
	]
	
	for data in effects_data:
		var effect = TimedEffect.new()
		effect.id = data.id
		effect.name = data.id
		effect.duration = 10.0
		effect.stat_modifiers["strength"] = data.modifier
		effect_queue.add_effect(critter, effect)
	
	# Total deve ser 10 + 5 - 3 - 2 = 10
	var total = effect_queue.get_total_stat_modifier(critter, GameConstants.PrimaryStat.STRENGTH)
	assert_that(total).is_equal(10, "Total should be sum of all modifiers: 10 + 5 - 3 - 2 = 10")
