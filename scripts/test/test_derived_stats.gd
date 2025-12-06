extends GdUnitTestSuite
## Property test for derived stat calculation
## **Feature: fallout2-complete-migration, Property 23: Derived Stat Calculation**
## **Validates: Requirements 8.6**

class_name TestDerivedStats
extends GdUnitTestSuite

var character_editor: CharacterEditor

func before_test() -> void:
	character_editor = CharacterEditor.new()
	add_child(character_editor)
	character_editor._initialize_temp_data()

func after_test() -> void:
	if character_editor:
		character_editor.queue_free()

## Property: For any finalized character, derived stats SHALL be calculated 
## from SPECIAL using the standard formulas
func test_derived_stat_calculation_property() -> void:
	# Configurar stats conhecidos
	# Total: 8+6+7+5+5+6+3 = 40 pontos (perfeito!)
	character_editor.temp_stats.strength = 8
	character_editor.temp_stats.perception = 6
	character_editor.temp_stats.endurance = 7
	character_editor.temp_stats.charisma = 5
	character_editor.temp_stats.intelligence = 5
	character_editor.temp_stats.agility = 6
	character_editor.temp_stats.luck = 3
	
	# Atualizar pontos
	character_editor._update_points_used()
	assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points remaining")
	
	character_editor.set_name("Test Character")
	
	# Finalizar
	var critter = character_editor.finalize_character()
	assert_that(critter).is_not_null("Should be able to create character")
	
	# Verificar fórmulas de derived stats
	# HP = 15 + (Strength/2) + (2 * Endurance)
	var expected_hp = 15 + int(8 / 2.0) + (2 * 7)
	assert_that(critter.stats.max_hp).is_equal(expected_hp, 
		"HP should be calculated correctly: 15 + (8/2) + (2*7) = %d" % expected_hp)
	
	# AP = 5 + (Agility/2)
	var expected_ap = 5 + int(6 / 2.0)
	assert_that(critter.stats.max_ap).is_equal(expected_ap, 
		"AP should be calculated correctly: 5 + (6/2) = %d" % expected_ap)
	
	# Armor Class = Agility
	assert_that(critter.stats.armor_class).is_equal(6, 
		"Armor Class should equal Agility")
	
	# Melee Damage = Strength - 5 (mínimo 1)
	var expected_melee = max(1, 8 - 5)
	assert_that(critter.stats.melee_damage).is_equal(expected_melee, 
		"Melee Damage should be Strength - 5 = %d" % expected_melee)
	
	# Carry Weight = 25 + (Strength * 25)
	var expected_carry = 25 + (8 * 25)
	assert_that(critter.stats.carry_weight).is_equal(expected_carry, 
		"Carry Weight should be 25 + (8*25) = %d" % expected_carry)
	
	# Sequence = 2 * Perception
	var expected_sequence = 2 * 6
	assert_that(critter.stats.sequence).is_equal(expected_sequence, 
		"Sequence should be 2 * 6 = %d" % expected_sequence)
	
	# Healing Rate = Endurance / 3 (mínimo 1)
	var expected_healing = max(1, int(7 / 3.0))
	assert_that(critter.stats.healing_rate).is_equal(expected_healing, 
		"Healing Rate should be Endurance/3 = %d" % expected_healing)
	
	# Critical Chance = Luck
	assert_that(critter.stats.critical_chance).is_equal(3.0, 
		"Critical Chance should equal Luck")

## Test derived stats with minimum values
func test_derived_stats_minimum_values() -> void:
	# Configurar stats: 1+1+1+1+1+1+1 = 7 pontos usados
	# Precisamos usar 40 pontos, então vamos distribuir o resto
	# Vamos fazer: 1+1+1+1+1+1+34 = 40
	character_editor.temp_stats.strength = 1
	character_editor.temp_stats.perception = 1
	character_editor.temp_stats.endurance = 1
	character_editor.temp_stats.charisma = 1
	character_editor.temp_stats.intelligence = 1
	character_editor.temp_stats.agility = 1
	character_editor.temp_stats.luck = 34  # Usar pontos restantes
	
	character_editor._update_points_used()
	assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points")
	character_editor.set_name("Test Character")
	
	var critter = character_editor.finalize_character()
	
	# Verificar valores mínimos
	# Melee Damage deve ser pelo menos 1
	assert_that(critter.stats.melee_damage).is_greater_equal(1, 
		"Melee Damage should be at least 1")
	
	# Healing Rate deve ser pelo menos 1
	assert_that(critter.stats.healing_rate).is_greater_equal(1, 
		"Healing Rate should be at least 1")

## Test derived stats with maximum values
func test_derived_stats_maximum_values() -> void:
	# Configurar todos os stats em 10 (máximo)
	# Total: 10*7 = 70 pontos, mas só temos 40
	# Vamos usar uma combinação que totaliza 40: 10+10+10+5+2+2+1 = 40
	character_editor.temp_stats.strength = 10
	character_editor.temp_stats.perception = 10
	character_editor.temp_stats.endurance = 10
	character_editor.temp_stats.charisma = 5
	character_editor.temp_stats.intelligence = 2
	character_editor.temp_stats.agility = 2
	character_editor.temp_stats.luck = 1
	
	character_editor._update_points_used()
	assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points")
	character_editor.set_name("Test Character")
	
	var critter = character_editor.finalize_character()
	
	# Verificar valores com stats configurados
	# HP = 15 + (10/2) + (2*10) = 15 + 5 + 20 = 40
	assert_that(critter.stats.max_hp).is_equal(40, "HP should be 40 with str=10, end=10")
	
	# AP = 5 + (2/2) = 6 (agility é 2, não 10)
	assert_that(critter.stats.max_ap).is_equal(6, "AP should be 6 with agi=2")
	
	# Melee Damage = 10 - 5 = 5
	assert_that(critter.stats.melee_damage).is_equal(5, "Melee Damage should be 5")
	
	# Carry Weight = 25 + (10*25) = 275
	assert_that(critter.stats.carry_weight).is_equal(275, "Carry Weight should be 275")
	
	# Sequence = 2 * 10 = 20
	assert_that(critter.stats.sequence).is_equal(20, "Sequence should be 20")
	
	# Healing Rate = 10/3 = 3
	assert_that(critter.stats.healing_rate).is_equal(3, "Healing Rate should be 3")
	
	# Critical Chance = 1 (luck é 1, não 10)
	assert_that(critter.stats.critical_chance).is_equal(1.0, "Critical Chance should be 1")

## Test that derived stats are recalculated after trait application
func test_derived_stats_after_traits() -> void:
	# Configurar stats: 5*7 = 35, precisamos de 5 pontos a mais
	# Vamos fazer: 5+5+5+5+5+5+10 = 40
	character_editor.temp_stats.strength = 5
	character_editor.temp_stats.perception = 5
	character_editor.temp_stats.endurance = 5
	character_editor.temp_stats.charisma = 5
	character_editor.temp_stats.intelligence = 5
	character_editor.temp_stats.agility = 5
	character_editor.temp_stats.luck = 10
	
	# Selecionar trait que modifica stats
	character_editor.select_trait(TraitData.Trait.BRUISER)  # +2 Strength, -2 AP
	
	character_editor._update_points_used()
	assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points")
	character_editor.set_name("Test Character")
	
	var critter = character_editor.finalize_character()
	
	# Verificar que trait foi aplicado
	# Strength deve ser 5 + 2 = 7 (clamped)
	assert_that(critter.stats.strength).is_equal(7, "Strength should be increased by trait")
	
	# AP deve ser reduzido
	# Base AP = 5 + (5/2) = 7, então 7 - 2 = 5
	var expected_ap = 5 + int(5 / 2.0) - 2
	assert_that(critter.stats.max_ap).is_equal(expected_ap, "AP should be reduced by trait")

## Test that current HP and AP are set to max on creation
func test_current_stats_initialized() -> void:
	# Configurar stats para totalizar 40
	character_editor.temp_stats.strength = 5
	character_editor.temp_stats.perception = 5
	character_editor.temp_stats.endurance = 5
	character_editor.temp_stats.charisma = 5
	character_editor.temp_stats.intelligence = 5
	character_editor.temp_stats.agility = 5
	character_editor.temp_stats.luck = 10  # 5*6 + 10 = 40
	
	character_editor._update_points_used()
	assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points")
	character_editor.set_name("Test Character")
	
	var critter = character_editor.finalize_character()
	
	# Current HP deve ser igual a max HP
	assert_that(critter.stats.current_hp).is_equal(critter.stats.max_hp, 
		"Current HP should equal max HP on creation")
	
	# Current AP deve ser igual a max AP
	assert_that(critter.stats.current_ap).is_equal(critter.stats.max_ap, 
		"Current AP should equal max AP on creation")

## Test derived stats calculation with various stat combinations
func test_derived_stats_various_combinations() -> void:
	var test_cases = [
		{"str": 3, "end": 4, "agi": 5, "per": 6, "luck": 7},
		{"str": 9, "end": 8, "agi": 7, "per": 6, "luck": 5},
		{"str": 6, "end": 6, "agi": 6, "per": 6, "luck": 6},
	]
	
	for test_case in test_cases:
		character_editor._initialize_temp_data()
		
		character_editor.temp_stats.strength = test_case.str
		character_editor.temp_stats.endurance = test_case.end
		character_editor.temp_stats.agility = test_case.agi
		character_editor.temp_stats.perception = test_case.per
		character_editor.temp_stats.luck = test_case.luck
		
		# Calcular valores restantes para totalizar 40
		var used = test_case.str + test_case.end + test_case.agi + test_case.per + test_case.luck
		var remaining = 40 - used
		# Distribuir entre charisma e intelligence
		character_editor.temp_stats.charisma = int(remaining / 2)
		character_editor.temp_stats.intelligence = remaining - character_editor.temp_stats.charisma
		
		character_editor._update_points_used()
		assert_that(character_editor.special_points_remaining).is_equal(0, "Should have 0 points")
		character_editor.set_name("Test Character")
		
		var critter = character_editor.finalize_character()
		
		# Verificar fórmulas
		var expected_hp = 15 + int(test_case.str / 2.0) + (2 * test_case.end)
		assert_that(critter.stats.max_hp).is_equal(expected_hp, 
			"HP calculation should be correct for str=%d, end=%d" % [test_case.str, test_case.end])
		
		var expected_ap = 5 + int(test_case.agi / 2.0)
		assert_that(critter.stats.max_ap).is_equal(expected_ap, 
			"AP calculation should be correct for agi=%d" % test_case.agi)
		
		var expected_sequence = 2 * test_case.per
		assert_that(critter.stats.sequence).is_equal(expected_sequence, 
			"Sequence calculation should be correct for per=%d" % test_case.per)
