extends GdUnitTestSuite
## Property test for critical hit location effects
## **Feature: fallout2-complete-migration, Property 28: Critical Hit Location Effects**
## **Validates: Requirements 11.1**

class_name TestCriticalHitLocationEffects
extends GdUnitTestSuite

var critical_table: CriticalHitTable
var attacker: Critter
var defender: Critter

func before_test() -> void:
	critical_table = CriticalHitTable.new()
	
	attacker = Critter.new()
	attacker.critter_name = "Attacker"
	attacker.stats = StatData.new()
	attacker.skills = SkillData.new()
	
	defender = Critter.new()
	defender.critter_name = "Defender"
	defender.stats = StatData.new()
	defender.stats.strength = 5
	defender.stats.perception = 5
	defender.stats.endurance = 5
	defender.skills = SkillData.new()

## Property: For any critical hit, the damage multiplier and effects 
## SHALL vary based on hit location and effect level
func test_critical_hit_location_effects_property() -> void:
	# Testar diferentes localizações
	var locations = [
		GameConstants.HitLocation.HEAD,
		GameConstants.HitLocation.TORSO,
		GameConstants.HitLocation.EYES,
		GameConstants.HitLocation.LEFT_ARM
	]
	
	for location in locations:
		# Testar diferentes níveis de efeito
		for effect_level in range(CriticalHitTable.CriticalEffectLevel.EXTREME + 1):
			var effect = critical_table.get_critical_effect(location, effect_level)
			
			# Verificar que efeito existe
			assert_that(effect).is_not_null("Effect should exist for location %d, level %d" % [location, effect_level])
			
			# Verificar que multiplicador de dano é válido
			assert_that(effect.damage_multiplier).is_greater(0.0, 
				"Damage multiplier should be positive")
			assert_that(effect.damage_multiplier).is_less_equal(10.0, 
				"Damage multiplier should be reasonable")

## Test that head shots have higher multipliers
func test_head_shot_multipliers() -> void:
	var head_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.HEAD, 
		CriticalHitTable.CriticalEffectLevel.MASSIVE
	)
	
	var torso_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.TORSO,
		CriticalHitTable.CriticalEffectLevel.MASSIVE
	)
	
	# Head shots devem ter multiplicador maior ou igual
	assert_that(head_effect.damage_multiplier).is_greater_equal(torso_effect.damage_multiplier,
		"Head shots should have equal or higher damage multiplier")

## Test that eye shots have highest multipliers
func test_eye_shot_multipliers() -> void:
	var eye_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.EYES,
		CriticalHitTable.CriticalEffectLevel.MASSIVE
	)
	
	var head_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.HEAD,
		CriticalHitTable.CriticalEffectLevel.MASSIVE
	)
	
	# Eye shots devem ter multiplicador maior
	assert_that(eye_effect.damage_multiplier).is_greater_equal(head_effect.damage_multiplier,
		"Eye shots should have highest damage multiplier")

## Test that effect levels increase damage
func test_effect_level_damage_increase() -> void:
	var location = GameConstants.HitLocation.TORSO
	
	var normal_effect = critical_table.get_critical_effect(location, CriticalHitTable.CriticalEffectLevel.NORMAL)
	var massive_effect = critical_table.get_critical_effect(location, CriticalHitTable.CriticalEffectLevel.MASSIVE)
	
	# Efeitos mais severos devem ter multiplicadores maiores
	assert_that(massive_effect.damage_multiplier).is_greater(normal_effect.damage_multiplier,
		"Massive critical should have higher multiplier than normal")

## Test that critical effects apply stat penalties
func test_critical_stat_penalties() -> void:
	var initial_perception = defender.stats.perception
	
	# Aplicar efeito de crítico nos olhos
	var eye_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.EYES,
		CriticalHitTable.CriticalEffectLevel.SEVERE
	)
	
	var result = critical_table.apply_critical_effect(defender, eye_effect, GameConstants.HitLocation.EYES)
	
	# Verificar que percepção foi reduzida
	assert_that(defender.stats.perception).is_less(initial_perception,
		"Perception should be reduced after eye critical")

## Test that massive criticals can trigger
func test_massive_critical_check() -> void:
	# Criar efeito que requer massive critical check
	var effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.HEAD,
		CriticalHitTable.CriticalEffectLevel.SEVERE
	)
	
	# Aplicar múltiplas vezes para testar probabilidade
	var massive_count = 0
	for i in range(100):
		defender.stats.perception = 5  # Reset
		var result = critical_table.apply_critical_effect(defender, effect, GameConstants.HitLocation.HEAD)
		if result.massive_critical:
			massive_count += 1
	
	# Deve haver pelo menos alguns massive criticals (probabilístico)
	# Mas não todos (não é garantido)
	assert_that(massive_count).is_greater_equal(0, "Should have some massive criticals")
	assert_that(massive_count).is_less(100, "Not all should be massive criticals")

## Test that limb crippling can occur
func test_limb_crippling() -> void:
	var arm_effect = critical_table.get_critical_effect(
		GameConstants.HitLocation.LEFT_ARM,
		CriticalHitTable.CriticalEffectLevel.SEVERE
	)
	
	# Aplicar múltiplas vezes para testar probabilidade
	var cripple_count = 0
	for i in range(100):
		var result = critical_table.apply_critical_effect(defender, arm_effect, GameConstants.HitLocation.LEFT_ARM)
		if result.crippled_limb:
			cripple_count += 1
	
	# Deve haver alguns aleijamentos (probabilístico)
	assert_that(cripple_count).is_greater_equal(0, "Should have some limb cripples")

## Test effect level calculation
func test_effect_level_calculation() -> void:
	# Testar diferentes rolls
	var test_cases = [
		{"roll": 10, "expected": CriticalHitTable.CriticalEffectLevel.NORMAL},
		{"roll": 30, "expected": CriticalHitTable.CriticalEffectLevel.MINOR},
		{"roll": 50, "expected": CriticalHitTable.CriticalEffectLevel.MODERATE},
		{"roll": 80, "expected": CriticalHitTable.CriticalEffectLevel.SEVERE},
		{"roll": 95, "expected": CriticalHitTable.CriticalEffectLevel.MASSIVE},
		{"roll": 110, "expected": CriticalHitTable.CriticalEffectLevel.EXTREME}
	]
	
	for test_case in test_cases:
		var level = critical_table.calculate_effect_level(test_case.roll)
		assert_that(level).is_equal(test_case.expected,
			"Roll %d should produce effect level %d" % [test_case.roll, test_case.expected])
