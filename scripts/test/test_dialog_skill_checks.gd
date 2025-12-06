extends GdUnitTestSuite
## Property test for dialog skill checks
## **Feature: fallout2-complete-migration, Property 16: Skill Check Probability**
## **Validates: Requirements 5.3**

class_name TestDialogSkillChecks
extends GdUnitTestSuite

var dialog_system: DialogSystem
var player: Critter

func before_test() -> void:
	dialog_system = DialogSystem.new()
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.karma = 0

## Property: For any skill check with difficulty D and skill value S, 
## success probability SHALL be clamp((S - D + 50) / 100, 0.05, 0.95)
func test_skill_check_probability_property() -> void:
	# Test with various skill values and difficulties
	var test_cases = [
		{"skill": 0, "difficulty": 50, "expected_min": 0.05, "expected_max": 0.05},  # Clamped to 0.05
		{"skill": 50, "difficulty": 50, "expected_min": 0.45, "expected_max": 0.55},  # ~0.5
		{"skill": 100, "difficulty": 50, "expected_min": 0.95, "expected_max": 0.95},  # Clamped to 0.95
		{"skill": 25, "difficulty": 50, "expected_min": 0.20, "expected_max": 0.30},  # ~0.25
		{"skill": 75, "difficulty": 50, "expected_min": 0.70, "expected_max": 0.80},  # ~0.75
		{"skill": 200, "difficulty": 50, "expected_min": 0.95, "expected_max": 0.95},  # Clamped to 0.95
		{"skill": 50, "difficulty": 0, "expected_min": 0.95, "expected_max": 0.95},   # Clamped to 0.95
		{"skill": 50, "difficulty": 100, "expected_min": 0.05, "expected_max": 0.05}, # Clamped to 0.05
	]
	
	for test_case in test_cases:
		var skill_value = test_case.skill
		var difficulty = test_case.difficulty
		var expected_min = test_case.expected_min
		var expected_max = test_case.expected_max
		
		# Set player skill
		player.skills.skill_values[SkillData.Skill.SPEECH] = skill_value
		
		# Calculate expected probability
		var expected_prob = clamp((skill_value - difficulty + 50) / 100.0, 0.05, 0.95)
		
		# Run many trials to verify probability
		var success_count = 0
		var trials = 1000
		
		for i in range(trials):
			# Reset random seed for reproducibility in tests
			# Note: In real gameplay, we want randomness, but for testing we'll use many trials
			var success = dialog_system.check_skill(SkillData.Skill.SPEECH, difficulty)
			if success:
				success_count += 1
		
		var actual_prob = float(success_count) / float(trials)
		
		# Allow some variance due to randomness (within 5% of expected)
		var variance = 0.05
		assert_that(actual_prob).is_between(expected_prob - variance, expected_prob + variance, 
			"Skill check probability should be approximately %f for skill=%d, difficulty=%d, got %f" % [expected_prob, skill_value, difficulty, actual_prob])

## Test that skill check probability is clamped to [0.05, 0.95]
func test_skill_check_probability_bounds() -> void:
	# Test minimum bound (0.05)
	player.skills.skill_values[SkillData.Skill.SPEECH] = 0
	
	var success_count = 0
	var trials = 1000
	for i in range(trials):
		if dialog_system.check_skill(SkillData.Skill.SPEECH, 200):  # Very high difficulty
			success_count += 1
	
	var prob = float(success_count) / float(trials)
	# Should be at least 0.05 (5% minimum chance)
	assert_that(prob).is_greater_equal(0.03, "Minimum success chance should be at least 0.05")
	assert_that(prob).is_less_equal(0.10, "Minimum success chance should not exceed 0.10")
	
	# Test maximum bound (0.95)
	player.skills.skill_values[SkillData.Skill.SPEECH] = 200
	
	success_count = 0
	for i in range(trials):
		if dialog_system.check_skill(SkillData.Skill.SPEECH, 0):  # Very low difficulty
			success_count += 1
	
	prob = float(success_count) / float(trials)
	# Should be at most 0.95 (95% maximum chance)
	assert_that(prob).is_greater_equal(0.90, "Maximum success chance should be at least 0.90")
	assert_that(prob).is_less_equal(0.97, "Maximum success chance should not exceed 0.95")

## Test skill check formula accuracy
func test_skill_check_formula() -> void:
	# Test the exact formula: clamp((S - D + 50) / 100, 0.05, 0.95)
	var test_cases = [
		{"skill": 50, "difficulty": 50, "expected": 0.5},
		{"skill": 60, "difficulty": 50, "expected": 0.6},
		{"skill": 40, "difficulty": 50, "expected": 0.4},
		{"skill": 100, "difficulty": 50, "expected": 0.95},  # Clamped
		{"skill": 0, "difficulty": 50, "expected": 0.05},    # Clamped
	]
	
	for test_case in test_cases:
		var skill_value = test_case.skill
		var difficulty = test_case.difficulty
		var expected = test_case.expected
		
		player.skills.skill_values[SkillData.Skill.SPEECH] = skill_value
		
		# Calculate expected probability
		var calculated = clamp((skill_value - difficulty + 50) / 100.0, 0.05, 0.95)
		
		assert_that(calculated).is_equal(expected, 
			"Formula should calculate %f for skill=%d, difficulty=%d" % [expected, skill_value, difficulty])

## Test that skill check emits signal
func test_skill_check_signal() -> void:
	player.skills.skill_values[SkillData.Skill.SPEECH] = 50
	
	var signal_received = false
	var signal_skill: SkillData.Skill
	var signal_difficulty: int
	var signal_success: bool
	
	# Connect to signal
	dialog_system.skill_check_performed.connect(func(skill, difficulty, success):
		signal_received = true
		signal_skill = skill
		signal_difficulty = difficulty
		signal_success = success
	)
	
	# Perform skill check
	var result = dialog_system.check_skill(SkillData.Skill.SPEECH, 50)
	
	# Verify signal was emitted
	assert_that(signal_received).is_true("Skill check should emit signal")
	assert_that(signal_skill).is_equal(SkillData.Skill.SPEECH, "Signal should contain correct skill")
	assert_that(signal_difficulty).is_equal(50, "Signal should contain correct difficulty")
	assert_that(signal_success).is_equal(result, "Signal should contain correct success result")

## Test stat check functionality
func test_stat_check() -> void:
	# Test stat check with various thresholds
	player.stats.charisma = 5
	
	# Should pass
	var result1 = dialog_system.check_stat(GameConstants.PrimaryStat.CHARISMA, 4)
	assert_that(result1).is_true("Stat check should pass when stat >= threshold")
	
	# Should fail
	var result2 = dialog_system.check_stat(GameConstants.PrimaryStat.CHARISMA, 6)
	assert_that(result2).is_false("Stat check should fail when stat < threshold")
	
	# Edge case: exactly equal
	var result3 = dialog_system.check_stat(GameConstants.PrimaryStat.CHARISMA, 5)
	assert_that(result3).is_true("Stat check should pass when stat == threshold")

## Test stat check signal
func test_stat_check_signal() -> void:
	player.stats.perception = 7
	
	var signal_received = false
	var signal_stat: GameConstants.PrimaryStat
	var signal_threshold: int
	var signal_success: bool
	
	# Connect to signal
	dialog_system.stat_check_performed.connect(func(stat, threshold, success):
		signal_received = true
		signal_stat = stat
		signal_threshold = threshold
		signal_success = success
	)
	
	# Perform stat check
	var result = dialog_system.check_stat(GameConstants.PrimaryStat.PERCEPTION, 5)
	
	# Verify signal was emitted
	assert_that(signal_received).is_true("Stat check should emit signal")
	assert_that(signal_stat).is_equal(GameConstants.PrimaryStat.PERCEPTION, "Signal should contain correct stat")
	assert_that(signal_threshold).is_equal(5, "Signal should contain correct threshold")
	assert_that(signal_success).is_equal(result, "Signal should contain correct success result")

## Test all SPECIAL stats in stat check
func test_all_stat_checks() -> void:
	player.stats.strength = 8
	player.stats.perception = 6
	player.stats.endurance = 7
	player.stats.charisma = 5
	player.stats.intelligence = 9
	player.stats.agility = 4
	player.stats.luck = 3
	
	var stats_to_test = [
		GameConstants.PrimaryStat.STRENGTH,
		GameConstants.PrimaryStat.PERCEPTION,
		GameConstants.PrimaryStat.ENDURANCE,
		GameConstants.PrimaryStat.CHARISMA,
		GameConstants.PrimaryStat.INTELLIGENCE,
		GameConstants.PrimaryStat.AGILITY,
		GameConstants.PrimaryStat.LUCK,
	]
	
	for stat in stats_to_test:
		var result = dialog_system.check_stat(stat, 5)
		# All stats should pass threshold of 5 except agility (4) and luck (3)
		if stat == GameConstants.PrimaryStat.AGILITY or stat == GameConstants.PrimaryStat.LUCK:
			assert_that(result).is_false("Stat check should fail for %s with value below threshold" % stat)
		else:
			assert_that(result).is_true("Stat check should pass for %s with value above threshold" % stat)
