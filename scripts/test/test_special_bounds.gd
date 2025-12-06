extends GdUnitTestSuite
## Property test for SPECIAL bounds enforcement
## **Feature: fallout2-complete-migration, Property 20: SPECIAL Bounds Enforcement**
## **Validates: Requirements 8.2**

class_name TestSpecialBounds
extends GdUnitTestSuite

var character_editor: CharacterEditor

func before_test() -> void:
	character_editor = CharacterEditor.new()
	add_child(character_editor)

func after_test() -> void:
	if character_editor:
		character_editor.queue_free()

## Property: For any stat allocation, the value SHALL be clamped between MIN_STAT (1) and MAX_STAT (10)
func test_special_bounds_property() -> void:
	# Test with various invalid values
	var test_cases = [
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": -100, "expected": 1},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 0, "expected": 1},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 1, "expected": 1},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 5, "expected": 5},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 10, "expected": 10},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 11, "expected": 10},
		{"stat": GameConstants.PrimaryStat.STRENGTH, "attempt": 100, "expected": 10},
	]
	
	for test_case in test_cases:
		# Reset editor
		character_editor._initialize_temp_data()
		
		var stat = test_case.stat
		var attempt = test_case.attempt
		var expected = test_case.expected
		
		# Tentar definir valor diretamente
		character_editor._set_stat_value(stat, attempt)
		var actual = character_editor._get_stat_value(stat)
		
		assert_that(actual).is_equal(expected, 
			"Stat value should be clamped to %d when attempting to set %d" % [expected, attempt])

## Test that allocation enforces bounds
func test_allocation_enforces_bounds() -> void:
	character_editor._initialize_temp_data()
	
	# Tentar aumentar além do máximo
	var stat = GameConstants.PrimaryStat.STRENGTH
	character_editor._set_stat_value(stat, 10)
	
	# Tentar aumentar mais (deve falhar)
	var result = character_editor.allocate_stat(stat, 1)
	assert_that(result).is_false("Should not be able to increase stat beyond MAX_STAT")
	assert_that(character_editor._get_stat_value(stat)).is_equal(10, "Stat should remain at 10")
	
	# Tentar diminuir abaixo do mínimo
	character_editor._set_stat_value(stat, 1)
	var result2 = character_editor.allocate_stat(stat, -1)
	assert_that(result2).is_false("Should not be able to decrease stat below MIN_STAT")
	assert_that(character_editor._get_stat_value(stat)).is_equal(1, "Stat should remain at 1")

## Test all SPECIAL stats enforce bounds
func test_all_stats_enforce_bounds() -> void:
	var stats = [
		GameConstants.PrimaryStat.STRENGTH,
		GameConstants.PrimaryStat.PERCEPTION,
		GameConstants.PrimaryStat.ENDURANCE,
		GameConstants.PrimaryStat.CHARISMA,
		GameConstants.PrimaryStat.INTELLIGENCE,
		GameConstants.PrimaryStat.AGILITY,
		GameConstants.PrimaryStat.LUCK
	]
	
	for stat in stats:
		character_editor._initialize_temp_data()
		
		# Test minimum
		character_editor._set_stat_value(stat, -100)
		assert_that(character_editor._get_stat_value(stat)).is_equal(1, 
			"%s should be clamped to 1" % GameConstants.PrimaryStat.keys()[stat])
		
		# Test maximum
		character_editor._set_stat_value(stat, 100)
		assert_that(character_editor._get_stat_value(stat)).is_equal(10, 
			"%s should be clamped to 10" % GameConstants.PrimaryStat.keys()[stat])

## Test that points are tracked correctly
func test_points_tracking() -> void:
	character_editor._initialize_temp_data()
	
	# Todos começam em 5, então 7 * 5 = 35 pontos usados
	# 40 - 35 = 5 pontos restantes
	assert_that(character_editor.special_points_remaining).is_equal(5, 
		"Should start with 5 points remaining")
	
	# Aumentar um stat
	character_editor.allocate_stat(GameConstants.PrimaryStat.STRENGTH, 1)
	assert_that(character_editor.special_points_remaining).is_equal(4, 
		"Should have 4 points remaining after increasing one stat")
	
	# Diminuir um stat
	character_editor.allocate_stat(GameConstants.PrimaryStat.STRENGTH, -1)
	assert_that(character_editor.special_points_remaining).is_equal(5, 
		"Should have 5 points remaining after decreasing stat back")

## Test that allocation fails when no points available
func test_allocation_fails_without_points() -> void:
	character_editor._initialize_temp_data()
	
	# Usar todos os pontos
	for i in range(5):
		character_editor.allocate_stat(GameConstants.PrimaryStat.STRENGTH, 1)
	
	assert_that(character_editor.special_points_remaining).is_equal(0, 
		"Should have 0 points remaining")
	
	# Tentar aumentar outro stat (deve falhar)
	var result = character_editor.allocate_stat(GameConstants.PrimaryStat.PERCEPTION, 1)
	assert_that(result).is_false("Should not be able to allocate without points")

## Test that finalization requires all points used
func test_finalization_requires_all_points_used() -> void:
	character_editor._initialize_temp_data()
	character_editor.set_name("Test Character")
	
	# Tentar finalizar com pontos restantes (deve falhar)
	var critter = character_editor.finalize_character()
	assert_that(critter).is_null("Should not be able to finalize with points remaining")
	
	# Usar todos os pontos
	while character_editor.special_points_remaining > 0:
		character_editor.allocate_stat(GameConstants.PrimaryStat.STRENGTH, 1)
	
	# Agora deve funcionar
	critter = character_editor.finalize_character()
	assert_that(critter).is_not_null("Should be able to finalize with all points used")
