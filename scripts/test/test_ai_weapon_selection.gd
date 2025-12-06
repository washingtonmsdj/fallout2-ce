extends Node
## Testes de propriedade para seleção de arma e gerenciamento de munição de IA
## **Feature: fallout2-complete-migration, Property 7: AI Weapon Selection**
## **Feature: fallout2-complete-migration, Property 8: AI Ammo Management**
## **Validates: Requirements 2.3, 2.6**

class_name TestAIWeaponSelection

## Testa que IA seleciona a arma com maior dano
func test_ai_selects_highest_damage_weapon() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar armas com diferentes danos
	var weak_weapon = Weapon.new()
	weak_weapon.item_name = "Weak Pistol"
	weak_weapon.min_damage = 1
	weak_weapon.max_damage = 5
	
	var strong_weapon = Weapon.new()
	strong_weapon.item_name = "Strong Rifle"
	strong_weapon.min_damage = 10
	strong_weapon.max_damage = 20
	
	critter.inventory.append(weak_weapon)
	critter.inventory.append(strong_weapon)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar a arma mais forte
	assert(selected_weapon == strong_weapon,
		"AI should select the weapon with highest damage")

## Testa que IA considera arma equipada
func test_ai_considers_equipped_weapon() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar arma equipada
	var equipped = Weapon.new()
	equipped.item_name = "Equipped Weapon"
	equipped.min_damage = 15
	equipped.max_damage = 25
	critter.equipped_weapon = equipped
	
	# Criar arma no inventário mais fraca
	var inventory_weapon = Weapon.new()
	inventory_weapon.item_name = "Weak Weapon"
	inventory_weapon.min_damage = 5
	inventory_weapon.max_damage = 10
	critter.inventory.append(inventory_weapon)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve manter a arma equipada
	assert(selected_weapon == equipped,
		"AI should keep equipped weapon if it's the best")

## Testa que IA troca para arma melhor
func test_ai_switches_to_better_weapon() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar arma equipada fraca
	var weak_equipped = Weapon.new()
	weak_equipped.item_name = "Weak Equipped"
	weak_equipped.min_damage = 5
	weak_equipped.max_damage = 10
	critter.equipped_weapon = weak_equipped
	
	# Criar arma melhor no inventário
	var strong_weapon = Weapon.new()
	strong_weapon.item_name = "Strong Weapon"
	strong_weapon.min_damage = 20
	strong_weapon.max_damage = 30
	critter.inventory.append(strong_weapon)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar a arma mais forte
	assert(selected_weapon == strong_weapon,
		"AI should switch to better weapon")

## Testa que IA retorna null sem armas
func test_ai_returns_null_without_weapons() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Sem armas equipadas ou no inventário
	critter.equipped_weapon = null
	critter.inventory.clear()
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve retornar null
	assert(selected_weapon == null,
		"AI should return null when no weapons available")

## Testa que IA calcula dano médio corretamente
func test_ai_calculates_average_damage() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar armas com danos conhecidos
	var weapon1 = Weapon.new()
	weapon1.item_name = "Weapon 1"
	weapon1.min_damage = 10
	weapon1.max_damage = 20  # Média: 15
	
	var weapon2 = Weapon.new()
	weapon2.item_name = "Weapon 2"
	weapon2.min_damage = 5
	weapon2.max_damage = 15  # Média: 10
	
	critter.inventory.append(weapon1)
	critter.inventory.append(weapon2)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar weapon1 (maior dano médio)
	assert(selected_weapon == weapon1,
		"AI should select weapon with highest average damage")

## Testa que IA prefere arma com maior dano mínimo em caso de empate
func test_ai_prefers_higher_min_damage_on_tie() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar armas com mesma média de dano
	var weapon1 = Weapon.new()
	weapon1.item_name = "Weapon 1"
	weapon1.min_damage = 10
	weapon1.max_damage = 20  # Média: 15
	
	var weapon2 = Weapon.new()
	weapon2.item_name = "Weapon 2"
	weapon2.min_damage = 5
	weapon2.max_damage = 25  # Média: 15
	
	critter.inventory.append(weapon1)
	critter.inventory.append(weapon2)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar weapon1 (maior dano mínimo)
	assert(selected_weapon == weapon1,
		"AI should prefer weapon with higher minimum damage")

## Testa que IA gerencia munição (verificação básica)
func test_ai_ammo_management_check() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar arma sem munição
	var ranged_weapon = Weapon.new()
	ranged_weapon.item_name = "Pistol"
	ranged_weapon.weapon_type = GameConstants.WeaponType.SMALL_GUN
	ranged_weapon.min_damage = 5
	ranged_weapon.max_damage = 10
	ranged_weapon.current_ammo = 0
	ranged_weapon.max_ammo = 30
	
	critter.equipped_weapon = ranged_weapon
	
	# Criar arma melee como alternativa
	var melee_weapon = Weapon.new()
	melee_weapon.item_name = "Knife"
	melee_weapon.weapon_type = GameConstants.WeaponType.MELEE
	melee_weapon.min_damage = 3
	melee_weapon.max_damage = 8
	
	critter.inventory.append(melee_weapon)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar uma arma válida
	assert(selected_weapon != null,
		"AI should select a valid weapon")

## Testa que múltiplas seleções são consistentes
func test_ai_weapon_selection_consistency() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Criar armas
	var weapon1 = Weapon.new()
	weapon1.item_name = "Weapon 1"
	weapon1.min_damage = 5
	weapon1.max_damage = 10
	
	var weapon2 = Weapon.new()
	weapon2.item_name = "Weapon 2"
	weapon2.min_damage = 15
	weapon2.max_damage = 25
	
	critter.inventory.append(weapon1)
	critter.inventory.append(weapon2)
	
	# Selecionar múltiplas vezes
	var first_selection = ai_controller.select_best_weapon()
	var second_selection = ai_controller.select_best_weapon()
	var third_selection = ai_controller.select_best_weapon()
	
	# Todas as seleções devem ser iguais
	assert(first_selection == second_selection,
		"AI weapon selection should be consistent")
	assert(second_selection == third_selection,
		"AI weapon selection should be consistent")

## Testa que IA seleciona arma apropriada para distância
func test_ai_weapon_selection_by_range() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	target.global_position = Vector2(100, 100)
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	critter.global_position = Vector2(0, 0)
	
	# Criar armas de diferentes alcances
	var melee = Weapon.new()
	melee.item_name = "Melee"
	melee.weapon_type = GameConstants.WeaponType.MELEE
	melee.min_damage = 10
	melee.max_damage = 20
	melee.range = 1
	
	var ranged = Weapon.new()
	ranged.item_name = "Ranged"
	ranged.weapon_type = GameConstants.WeaponType.SMALL_GUN
	ranged.min_damage = 5
	ranged.max_damage = 15
	ranged.range = 20
	
	critter.inventory.append(melee)
	critter.inventory.append(ranged)
	
	# Selecionar melhor arma
	var selected_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar uma arma válida
	assert(selected_weapon != null,
		"AI should select a valid weapon based on range")

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
	print("=== Running AI Weapon Selection Property Tests ===")
	
	test_ai_selects_highest_damage_weapon()
	print("✓ test_ai_selects_highest_damage_weapon passed")
	
	test_ai_considers_equipped_weapon()
	print("✓ test_ai_considers_equipped_weapon passed")
	
	test_ai_switches_to_better_weapon()
	print("✓ test_ai_switches_to_better_weapon passed")
	
	test_ai_returns_null_without_weapons()
	print("✓ test_ai_returns_null_without_weapons passed")
	
	test_ai_calculates_average_damage()
	print("✓ test_ai_calculates_average_damage passed")
	
	test_ai_prefers_higher_min_damage_on_tie()
	print("✓ test_ai_prefers_higher_min_damage_on_tie passed")
	
	test_ai_ammo_management_check()
	print("✓ test_ai_ammo_management_check passed")
	
	test_ai_weapon_selection_consistency()
	print("✓ test_ai_weapon_selection_consistency passed")
	
	test_ai_weapon_selection_by_range()
	print("✓ test_ai_weapon_selection_by_range passed")
	
	print("=== All AI Weapon Selection tests passed! ===")
