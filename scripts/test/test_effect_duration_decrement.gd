extends GdUnitTestSuite
## Property test for effect duration decrement
## **Feature: fallout2-complete-migration, Property 26: Effect Duration Decrement**
## **Validates: Requirements 10.2**

class_name TestEffectDurationDecrement
extends GdUnitTestSuite

var effect_queue: EffectQueue
var critter: Critter

func before_test() -> void:
	effect_queue = EffectQueue.new()
	add_child(effect_queue)
	
	critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.stats = StatData.new()
	critter.skills = SkillData.new()

func after_test() -> void:
	if effect_queue:
		effect_queue.queue_free()

## Property: For any timed effect, after tick_effects(T) is called, 
## the effect's remaining duration SHALL decrease by T
func test_effect_duration_decrement_property() -> void:
	# Criar efeito com duração conhecida
	var effect = TimedEffect.new()
	effect.id = "test_effect"
	effect.name = "Test Effect"
	effect.duration = 10.0
	effect.remaining_duration = 10.0
	
	# Adicionar ao critter
	effect_queue.add_effect(critter, effect)
	
	# Tick com diferentes valores de tempo
	var test_cases = [1.0, 2.5, 0.5, 3.0]
	var expected_remaining = 10.0
	
	for time_passed in test_cases:
		var old_remaining = effect.remaining_duration
		effect.tick(time_passed)
		expected_remaining -= time_passed
		
		assert_that(effect.remaining_duration).is_equal(expected_remaining, 
			"Duration should decrease by %f, expected %f, got %f" % [time_passed, expected_remaining, effect.remaining_duration])
		
		# Verificar que não ficou negativo
		assert_that(effect.remaining_duration).is_greater_equal(0.0, 
			"Duration should not be negative")

## Test that effect expires when duration reaches zero
func test_effect_expiration() -> void:
	var effect = TimedEffect.new()
	effect.id = "expiring_effect"
	effect.name = "Expiring Effect"
	effect.duration = 5.0
	effect.remaining_duration = 5.0
	
	effect_queue.add_effect(critter, effect)
	
	# Tick até expirar
	effect.tick(5.0)
	
	assert_that(effect.is_expired()).is_true("Effect should be expired")
	assert_that(effect.remaining_duration).is_equal(0.0, "Remaining duration should be 0")

## Test that effect duration doesn't go negative
func test_duration_not_negative() -> void:
	var effect = TimedEffect.new()
	effect.id = "test_effect"
	effect.name = "Test Effect"
	effect.duration = 3.0
	effect.remaining_duration = 3.0
	
	# Tick mais do que a duração
	effect.tick(10.0)
	
	assert_that(effect.remaining_duration).is_equal(0.0, "Duration should not go negative")
	assert_that(effect.is_expired()).is_true("Effect should be expired")

## Test that effect queue removes expired effects
func test_expired_effects_removed() -> void:
	var effect1 = TimedEffect.new()
	effect1.id = "effect1"
	effect1.name = "Effect 1"
	effect1.duration = 1.0
	effect1.remaining_duration = 1.0
	
	var effect2 = TimedEffect.new()
	effect2.id = "effect2"
	effect2.name = "Effect 2"
	effect2.duration = 5.0
	effect2.remaining_duration = 5.0
	
	effect_queue.add_effect(critter, effect1)
	effect_queue.add_effect(critter, effect2)
	
	# Simular passagem de tempo (2 horas)
	effect_queue._tick_all_effects(2.0)
	
	# effect1 deve ter expirado, effect2 ainda deve estar ativo
	var active_effects = effect_queue.get_active_effects(critter)
	
	# Verificar que effect1 foi removido
	var effect1_found = false
	var effect2_found = false
	
	for effect in active_effects:
		if effect.id == "effect1":
			effect1_found = true
		if effect.id == "effect2":
			effect2_found = true
	
	assert_that(effect1_found).is_false("Expired effect should be removed")
	assert_that(effect2_found).is_true("Non-expired effect should still be active")

## Test multiple effects with different durations
func test_multiple_effects_duration() -> void:
	var effects = []
	for i in range(5):
		var effect = TimedEffect.new()
		effect.id = "effect_%d" % i
		effect.name = "Effect %d" % i
		effect.duration = float(i + 1)  # Durações: 1, 2, 3, 4, 5
		effect.remaining_duration = float(i + 1)
		effects.append(effect)
		effect_queue.add_effect(critter, effect)
	
	# Tick 2.5 horas
	effect_queue._tick_all_effects(2.5)
	
	# Verificar durações restantes
	var active_effects = effect_queue.get_active_effects(critter)
	
	# Efeitos com duração <= 2.5 devem ter expirado
	var expired_count = 0
	var active_count = 0
	
	for effect in active_effects:
		if effect.is_expired():
			expired_count += 1
		else:
			active_count += 1
			# Verificar que duração foi reduzida corretamente
			var original_duration = float(effect.id.split("_")[1].to_int() + 1)
			var expected_remaining = max(0.0, original_duration - 2.5)
			assert_that(effect.remaining_duration).is_equal(expected_remaining, 
				"Effect %s should have remaining duration %f" % [effect.id, expected_remaining])
	
	# Efeitos 0, 1, 2 devem ter expirado (duração <= 2.5)
	# Efeitos 3, 4 devem estar ativos
	assert_that(active_count).is_equal(2, "Should have 2 active effects")
	assert_that(expired_count).is_equal(0, "Expired effects should be removed from active list")
