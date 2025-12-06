class_name TestEncounterProbability extends GdUnitTestSuite

# Property 13: Encounter Probability Bounds
# For any travel segment, random encounter probability SHALL be between 0 and danger_level / 10
# Validates: Requirements 4.3

var worldmap_system: WorldmapSystem

func before_test() -> void:
	worldmap_system = WorldmapSystem.new()

func test_encounter_probability_zero_danger() -> void:
	# Danger level 0 should have 0% encounter chance
	var encounter = worldmap_system.check_random_encounter(5, 0)
	
	# With danger_level 0, probability = 0/10 = 0.0
	# Should never trigger (or very rarely due to randomness)
	# Run multiple times to verify
	var triggered = 0
	for i in 100:
		if worldmap_system.check_random_encounter(5, 0):
			triggered += 1
	
	assert_int(triggered).is_equal(0)

func test_encounter_probability_max_danger() -> void:
	# Danger level 10 should have 100% encounter chance
	var triggered = 0
	for i in 100:
		if worldmap_system.check_random_encounter(5, 10):
			triggered += 1
	
	# Should trigger most of the time (100% probability)
	assert_int(triggered).is_greater_equal(95)

func test_encounter_probability_bounds() -> void:
	# Property test: probability is always between 0 and danger_level/10
	for danger in range(0, 11):
		var max_probability = float(danger) / 10.0
		
		# Run multiple checks
		var triggered = 0
		for i in 100:
			if worldmap_system.check_random_encounter(5, danger):
				triggered += 1
		
		var actual_probability = float(triggered) / 100.0
		
		# Actual probability should be <= max_probability (with some tolerance for randomness)
		assert_float(actual_probability).is_less_equal(max_probability + 0.1)

func test_encounter_requires_valid_level() -> void:
	# Create encounter with specific level requirements
	var encounter = RandomEncounter.new()
	encounter.id = "test_encounter"
	encounter.name = "Test Encounter"
	encounter.min_player_level = 10
	encounter.max_player_level = 20
	encounter.probability = 1.0
	
	worldmap_system.register_encounter(encounter)
	
	# Player level 5 (below minimum) should not get this encounter
	var result = worldmap_system.check_random_encounter(5, 10)
	
	# May be null or different encounter
	if result:
		assert_string(result.id).is_not_equal("test_encounter")

func test_encounter_probability_mid_range() -> void:
	# Danger level 5 should have ~50% encounter chance
	var triggered = 0
	for i in 1000:
		if worldmap_system.check_random_encounter(5, 5):
			triggered += 1
	
	var probability = float(triggered) / 1000.0
	
	# Should be around 0.5 (50%)
	assert_float(probability).is_between(0.4, 0.6)
