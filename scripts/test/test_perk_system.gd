extends Node
## Testes de propriedade para PerkSystem
## **Feature: fallout2-complete-migration, Property 2: Perk Availability Filtering**
## **Feature: fallout2-complete-migration, Property 4: Perk Rank Bounds**
## **Validates: Requirements 1.2, 1.4**

class_name TestPerkSystem

## Testa que apenas perks com requisitos atendidos são retornados como disponíveis
func test_perk_availability_filtering() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Obter perks disponíveis
	var available_perks = perk_system.get_available_perks(critter)
	
	# Verificar que todos os perks disponíveis têm requisitos atendidos
	for perk in available_perks:
		assert(perk.can_acquire(critter),
			"Available perk '%s' should have requirements met" % perk.get_name())
	
	# Aumentar stats do personagem
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	# Aumentar skills
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter perks disponíveis novamente
	var available_perks_high = perk_system.get_available_perks(critter)
	
	# Com stats altos, deve haver mais perks disponíveis
	assert(available_perks_high.size() >= available_perks.size(),
		"More perks should be available with higher stats")

## Testa que o rank de um perk nunca excede max_ranks
func test_perk_rank_bounds() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Aumentar stats para poder adquirir perks
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter um perk
	var available_perks = perk_system.get_available_perks(critter)
	if available_perks.size() == 0:
		return  # Sem perks disponíveis, pular teste
	
	var perk = available_perks[0]
	var max_ranks = perk.max_ranks
	
	# Tentar adquirir o perk mais vezes que max_ranks
	for i in range(max_ranks + 5):
		var success = perk_system.acquire_perk(perk, critter)
		
		# Após max_ranks, não deve ser possível adquirir mais
		if i >= max_ranks:
			assert(not success,
				"Should not be able to acquire perk beyond max_ranks")
	
	# Verificar que o rank nunca excede max_ranks
	var rank = perk_system.get_perk_rank(perk.perk_id, critter)
	assert(rank <= max_ranks,
		"Perk rank should never exceed max_ranks, got %d > %d" % [rank, max_ranks])

## Testa que adquirir um perk começa com rank 1
func test_perk_rank_starts_at_one() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Aumentar stats
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter um perk
	var available_perks = perk_system.get_available_perks(critter)
	if available_perks.size() == 0:
		return
	
	var perk = available_perks[0]
	
	# Verificar que o rank é 0 antes de adquirir
	assert(perk_system.get_perk_rank(perk.perk_id, critter) == 0,
		"Perk rank should be 0 before acquisition")
	
	# Adquirir o perk
	perk_system.acquire_perk(perk, critter)
	
	# Verificar que o rank é 1 após adquirir
	assert(perk_system.get_perk_rank(perk.perk_id, critter) == 1,
		"Perk rank should be 1 after first acquisition")

## Testa que o rank aumenta corretamente com múltiplas aquisições
func test_perk_rank_increments() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Aumentar stats
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter um perk com múltiplos ranks
	var available_perks = perk_system.get_available_perks(critter)
	var multi_rank_perk = null
	
	for perk in available_perks:
		if perk.max_ranks > 1:
			multi_rank_perk = perk
			break
	
	if multi_rank_perk == null:
		return  # Sem perks com múltiplos ranks
	
	# Adquirir o perk múltiplas vezes
	for i in range(multi_rank_perk.max_ranks):
		perk_system.acquire_perk(multi_rank_perk, critter)
		var rank = perk_system.get_perk_rank(multi_rank_perk.perk_id, critter)
		assert(rank == i + 1,
			"Perk rank should be %d after %d acquisitions" % [i + 1, i + 1])

## Testa que remover um perk reseta o rank para 0
func test_perk_removal_resets_rank() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Aumentar stats
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter um perk
	var available_perks = perk_system.get_available_perks(critter)
	if available_perks.size() == 0:
		return
	
	var perk = available_perks[0]
	
	# Adquirir o perk
	perk_system.acquire_perk(perk, critter)
	assert(perk_system.get_perk_rank(perk.perk_id, critter) > 0,
		"Perk should be acquired")
	
	# Remover o perk
	perk_system.remove_perk(perk, critter)
	
	# Verificar que o rank é 0 após remover
	assert(perk_system.get_perk_rank(perk.perk_id, critter) == 0,
		"Perk rank should be 0 after removal")

## Testa que has_perk retorna true apenas para perks adquiridos
func test_has_perk_accuracy() -> void:
	var perk_system = PerkSystem.new()
	var critter = _create_test_critter()
	
	perk_system.set_current_critter(critter)
	
	# Aumentar stats
	critter.stats.strength = 10
	critter.stats.perception = 10
	critter.stats.agility = 10
	critter.stats.intelligence = 10
	critter.stats.endurance = 10
	critter.stats.charisma = 10
	critter.stats.luck = 10
	critter.level = 99
	
	for skill in SkillData.Skill.values():
		critter.skills.skill_values[skill] = 200
	
	# Obter um perk
	var available_perks = perk_system.get_available_perks(critter)
	if available_perks.size() == 0:
		return
	
	var perk = available_perks[0]
	
	# Verificar que has_perk retorna false antes de adquirir
	assert(not perk_system.has_perk(perk.perk_id, critter),
		"has_perk should return false before acquisition")
	
	# Adquirir o perk
	perk_system.acquire_perk(perk, critter)
	
	# Verificar que has_perk retorna true após adquirir
	assert(perk_system.has_perk(perk.perk_id, critter),
		"has_perk should return true after acquisition")

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
	print("=== Running PerkSystem Property Tests ===")
	
	test_perk_availability_filtering()
	print("✓ test_perk_availability_filtering passed")
	
	test_perk_rank_bounds()
	print("✓ test_perk_rank_bounds passed")
	
	test_perk_rank_starts_at_one()
	print("✓ test_perk_rank_starts_at_one passed")
	
	test_perk_rank_increments()
	print("✓ test_perk_rank_increments passed")
	
	test_perk_removal_resets_rank()
	print("✓ test_perk_removal_resets_rank passed")
	
	test_has_perk_accuracy()
	print("✓ test_has_perk_accuracy passed")
	
	print("=== All PerkSystem tests passed! ===")
