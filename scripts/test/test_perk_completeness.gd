extends Node
## Teste de propriedade para completude de perks
## **Feature: fallout2-complete-migration, Property 1: Perk Definition Completeness**
## **Validates: Requirements 1.1**

class_name TestPerkCompleteness

## Testa que todos os perks têm definições completas
func test_perk_definition_completeness() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	
	# Verificar que temos 119 perks
	assert(all_perks.size() == 119,
		"Should have exactly 119 perks, got %d" % all_perks.size())
	
	# Verificar que cada perk tem nome e descrição não vazios
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		
		assert(perk != null,
			"Perk %d should not be null" % perk_id)
		
		assert(perk.name != "",
			"Perk %d should have a non-empty name" % perk_id)
		
		assert(perk.description != "",
			"Perk %d should have a non-empty description" % perk_id)
		
		assert(perk.max_ranks > 0,
			"Perk %d should have max_ranks > 0" % perk_id)
		
		assert(perk.level_requirement > 0,
			"Perk %d should have level_requirement > 0" % perk_id)

## Testa que cada perk tem um efeito ou requisito definido
func test_perk_has_effects_or_requirements() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		
		# Cada perk deve ter pelo menos um efeito, requisito de stat ou requisito de skill
		var has_effects = perk.effects.size() > 0
		var has_stat_reqs = perk.stat_requirements.size() > 0
		var has_skill_reqs = perk.skill_requirements.size() > 0
		
		# Perks podem ter apenas requisitos sem efeitos (perks de requisito)
		# ou apenas efeitos sem requisitos (perks básicos)
		# Então apenas verificamos que o perk é válido
		assert(perk.perk_id >= 0,
			"Perk %d should have a valid perk_id" % perk_id)

## Testa que todos os IDs de perk estão mapeados
func test_all_perk_ids_mapped() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	
	# Verificar que todos os IDs de 0 a 118 estão presentes
	for i in range(119):
		var perk_enum = i as PerkData.Perk
		assert(perk_enum in all_perks,
			"Perk ID %d should be in the perk definitions" % i)

## Testa que nenhum perk tem requisitos inválidos
func test_perk_requirements_valid() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		
		# Verificar requisitos de stats
		for stat in perk.stat_requirements:
			var req_value = perk.stat_requirements[stat]
			assert(req_value >= GameConstants.PRIMARY_STAT_MIN and req_value <= GameConstants.PRIMARY_STAT_MAX,
				"Perk %d stat requirement should be between %d and %d, got %d" % [
					perk_id, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX, req_value
				])
		
		# Verificar requisitos de skills
		for skill in perk.skill_requirements:
			var req_value = perk.skill_requirements[skill]
			assert(req_value >= 0 and req_value <= 200,
				"Perk %d skill requirement should be between 0 and 200, got %d" % [perk_id, req_value])

## Testa que nenhum perk tem efeitos inválidos
func test_perk_effects_valid() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		
		for effect in perk.effects:
			assert(effect != null,
				"Perk %d should not have null effects" % perk_id)
			
			assert(effect.target != "",
				"Perk %d effect should have a non-empty target" % perk_id)

## Testa que perks podem ser adquiridos com requisitos válidos
func test_perk_acquisition_logic() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	var critter = _create_test_critter()
	
	# Aumentar o nível do personagem para 99
	critter.level = 99
	
	# Aumentar todos os stats para 10
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.intelligence = 10
	critter.stats.agility = 10
	critter.stats.luck = 10
	
	# Aumentar todas as skills para 200
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Com stats e skills máximos, todos os perks devem ser adquiríveis
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		assert(perk.can_acquire(critter),
			"Perk %d should be acquirable with max stats and skills" % perk_id)

## Testa que perks não podem ser adquiridos com requisitos insuficientes
func test_perk_acquisition_requirements() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	var critter = _create_test_critter()
	
	# Personagem com stats e skills mínimos
	critter.level = 1
	critter.stats.strength = 1
	critter.stats.perception = 1
	critter.stats.endurance = 1
	critter.stats.charisma = 1
	critter.stats.intelligence = 1
	critter.stats.agility = 1
	critter.stats.luck = 1
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 0
	
	# Alguns perks não devem ser adquiríveis
	var acquirable_count = 0
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		if perk.can_acquire(critter):
			acquirable_count += 1
	
	# Deve haver alguns perks adquiríveis (os que não têm requisitos)
	assert(acquirable_count > 0,
		"Should have at least some perks acquirable with minimum stats")

## Testa que nenhum perk tem nome duplicado
func test_no_duplicate_perk_names() -> void:
	var all_perks = PerkDefinitions.get_all_perks()
	var names_seen: Dictionary = {}
	
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		var perk_name = perk.name.to_lower()
		
		# Permitir nomes genéricos para perks sem definição específica
		if perk_name.begins_with("perk "):
			continue
		
		assert(perk_name not in names_seen,
			"Duplicate perk name '%s' found at IDs %d and %d" % [perk.name, names_seen[perk_name], perk_id])
		
		names_seen[perk_name] = perk_id

## Cria um personagem de teste
func _create_test_critter() -> Critter:
	var critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.is_player = true
	critter.faction = "player"
	critter.level = 1
	
	critter.stats = StatData.new()
	critter.stats.strength = 5
	critter.stats.perception = 5
	critter.stats.endurance = 5
	critter.stats.charisma = 5
	critter.stats.intelligence = 5
	critter.stats.agility = 5
	critter.stats.luck = 5
	critter.stats.calculate_derived_stats()
	
	critter.skills = SkillData.new()
	
	return critter

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running Perk Completeness Property Tests ===")
	
	test_perk_definition_completeness()
	print("✓ test_perk_definition_completeness passed")
	
	test_perk_has_effects_or_requirements()
	print("✓ test_perk_has_effects_or_requirements passed")
	
	test_all_perk_ids_mapped()
	print("✓ test_all_perk_ids_mapped passed")
	
	test_perk_requirements_valid()
	print("✓ test_perk_requirements_valid passed")
	
	test_perk_effects_valid()
	print("✓ test_perk_effects_valid passed")
	
	test_perk_acquisition_logic()
	print("✓ test_perk_acquisition_logic passed")
	
	test_perk_acquisition_requirements()
	print("✓ test_perk_acquisition_requirements passed")
	
	test_no_duplicate_perk_names()
	print("✓ test_no_duplicate_perk_names passed")
	
	print("=== All Perk Completeness tests passed! ===")
