extends Node
## Teste de propriedade para comportamento de fuga de IA
## **Feature: fallout2-complete-migration, Property 6: AI Flee Behavior**
## **Validates: Requirements 2.2**

class_name TestAIFleeBehavior

## Testa que IA foge quando HP está abaixo do limiar
func test_ai_flees_when_low_hp() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.DEFENSIVE
	
	# Reduzir HP para abaixo do limiar
	critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
	
	# Verificar que deve fugir
	var should_flee = ai_controller.should_flee()
	assert(should_flee,
		"Defensive AI should flee when HP is below threshold")

## Testa que IA não fuge quando HP está acima do limiar
func test_ai_does_not_flee_when_high_hp() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.DEFENSIVE
	
	# Manter HP alto
	critter.stats.current_hp = critter.stats.max_hp
	
	# Verificar que não deve fugir
	var should_flee = ai_controller.should_flee()
	assert(not should_flee,
		"Defensive AI should not flee when HP is high")

## Testa que personalidade AGGRESSIVE nunca foge
func test_aggressive_never_flees() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.AGGRESSIVE
	
	# Reduzir HP drasticamente
	critter.stats.current_hp = 1
	
	# Verificar que não foge
	var should_flee = ai_controller.should_flee()
	assert(not should_flee,
		"Aggressive AI should never flee")

## Testa que personalidade BERSERK nunca foge
func test_berserk_never_flees() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.BERSERK
	
	# Reduzir HP drasticamente
	critter.stats.current_hp = 1
	
	# Verificar que não foge
	var should_flee = ai_controller.should_flee()
	assert(not should_flee,
		"Berserk AI should never flee")

## Testa que personalidade COWARD sempre foge quando baixo
func test_coward_flees_when_low() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.COWARD
	
	# Reduzir HP para abaixo do limiar
	critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
	
	# Verificar que foge
	var should_flee = ai_controller.should_flee()
	assert(should_flee,
		"Coward AI should flee when HP is low")

## Testa que limiar de fuga é respeitado
func test_flee_threshold_respected() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.DEFENSIVE
	ai_controller.flee_threshold = 0.5  # 50%
	
	# Testar em vários níveis de HP
	for hp_percentage in [0.1, 0.3, 0.5, 0.7, 0.9]:
		critter.stats.current_hp = int(critter.stats.max_hp * hp_percentage)
		var should_flee = ai_controller.should_flee()
		
		if hp_percentage < ai_controller.flee_threshold:
			assert(should_flee,
				"Should flee when HP is %.1f%% (below %.1f%% threshold)" % [hp_percentage * 100, ai_controller.flee_threshold * 100])
		else:
			assert(not should_flee,
				"Should not flee when HP is %.1f%% (above %.1f%% threshold)" % [hp_percentage * 100, ai_controller.flee_threshold * 100])

## Testa que mudança de estado para FLEE é acionada
func test_flee_state_change() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	ai_controller.personality = AIController.AIPersonality.DEFENSIVE
	
	# Inicialmente em COMBAT
	assert(ai_controller.current_state == AIController.AIState.COMBAT,
		"Should be in COMBAT state after target acquisition")
	
	# Reduzir HP para ativar fuga
	critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
	
	# Avaliar turno deve considerar fuga
	var should_flee = ai_controller.should_flee()
	assert(should_flee,
		"Should flee when HP is low")

## Testa que posição de fuga é válida
func test_flee_position_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	target.global_position = Vector2(100, 100)
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	critter.global_position = Vector2(0, 0)
	
	# Encontrar posição de fuga
	var flee_position = ai_controller.find_cover()
	
	# Verificar que está longe do alvo
	var distance = flee_position.distance_to(target.global_position)
	assert(distance > 50.0,
		"Flee position should be away from target")

## Testa que múltiplas personalidades têm comportamentos diferentes
func test_personality_flee_differences() -> void:
	var personalities = [
		AIController.AIPersonality.AGGRESSIVE,
		AIController.AIPersonality.DEFENSIVE,
		AIController.AIPersonality.COWARD,
		AIController.AIPersonality.BERSERK
	]
	
	var flee_counts = {}
	
	for personality in personalities:
		flee_counts[personality] = 0
		
		for i in range(10):
			var ai_controller = AIController.new()
			var critter = _create_test_critter()
			var target = _create_test_critter()
			target.critter_name = "Target"
			
			ai_controller.set_controlled_critter(critter)
			ai_controller.set_target(target)
			ai_controller.personality = personality
			
			# Reduzir HP
			critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
			
			if ai_controller.should_flee():
				flee_counts[personality] += 1
	
	# Verificar que AGGRESSIVE e BERSERK nunca fogem
	assert(flee_counts[AIController.AIPersonality.AGGRESSIVE] == 0,
		"Aggressive should never flee")
	assert(flee_counts[AIController.AIPersonality.BERSERK] == 0,
		"Berserk should never flee")
	
	# Verificar que DEFENSIVE e COWARD fogem
	assert(flee_counts[AIController.AIPersonality.DEFENSIVE] > 0,
		"Defensive should flee sometimes")
	assert(flee_counts[AIController.AIPersonality.COWARD] > 0,
		"Coward should flee sometimes")

## Cria um personagem de teste
func _create_test_critter() -> Critter:
	var critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.is_player = false
	critter.faction = "enemy"
	critter.level = 5
	
	critter.stats = StatData.new()
	critter.stats.strength = 6
	critter.stats.perception = 6
	critter.stats.endurance = 6
	critter.stats.charisma = 5
	critter.stats.intelligence = 5
	critter.stats.agility = 6
	critter.stats.luck = 5
	critter.stats.calculate_derived_stats()
	
	critter.skills = SkillData.new()
	
	return critter

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running AI Flee Behavior Property Tests ===")
	
	test_ai_flees_when_low_hp()
	print("✓ test_ai_flees_when_low_hp passed")
	
	test_ai_does_not_flee_when_high_hp()
	print("✓ test_ai_does_not_flee_when_high_hp passed")
	
	test_aggressive_never_flees()
	print("✓ test_aggressive_never_flees passed")
	
	test_berserk_never_flees()
	print("✓ test_berserk_never_flees passed")
	
	test_coward_flees_when_low()
	print("✓ test_coward_flees_when_low passed")
	
	test_flee_threshold_respected()
	print("✓ test_flee_threshold_respected passed")
	
	test_flee_state_change()
	print("✓ test_flee_state_change passed")
	
	test_flee_position_validity()
	print("✓ test_flee_position_validity passed")
	
	test_personality_flee_differences()
	print("✓ test_personality_flee_differences passed")
	
	print("=== All AI Flee Behavior tests passed! ===")
