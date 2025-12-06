extends Node
## Teste de propriedade para PerkEffect
## **Feature: fallout2-complete-migration, Property 3: Perk Effect Application**
## **Validates: Requirements 1.3, 1.5, 1.6**

class_name TestPerkEffect

## Testa que aplicar um efeito de bônus de stat aumenta o stat exatamente pelo valor especificado
func test_stat_bonus_application() -> void:
	# Criar um personagem de teste
	var critter = _create_test_critter()
	var initial_strength = critter.stats.strength
	
	# Criar um efeito de bônus de stat
	var effect = PerkEffect.new()
	effect.effect_type = PerkEffect.EffectType.STAT_BONUS
	effect.target = "STRENGTH"
	effect.value = 2.0
	
	# Aplicar o efeito
	effect.apply_effect(critter)
	
	# Verificar que o stat foi aumentado exatamente pelo valor
	assert(critter.stats.strength == initial_strength + 2, 
		"Stat bonus should increase strength by exactly 2")
	
	# Remover o efeito
	effect.remove_effect(critter)
	
	# Verificar que o stat foi restaurado
	assert(critter.stats.strength == initial_strength,
		"Removing effect should restore original stat value")

## Testa que aplicar múltiplos efeitos de bônus acumula corretamente
func test_multiple_stat_bonuses() -> void:
	var critter = _create_test_critter()
	var initial_strength = critter.stats.strength
	
	# Criar e aplicar múltiplos efeitos
	var effect1 = PerkEffect.new()
	effect1.effect_type = PerkEffect.EffectType.STAT_BONUS
	effect1.target = "STRENGTH"
	effect1.value = 1.0
	
	var effect2 = PerkEffect.new()
	effect2.effect_type = PerkEffect.EffectType.STAT_BONUS
	effect2.target = "STRENGTH"
	effect2.value = 2.0
	
	effect1.apply_effect(critter)
	effect2.apply_effect(critter)
	
	# Verificar que ambos os efeitos foram aplicados
	assert(critter.stats.strength == initial_strength + 3,
		"Multiple stat bonuses should accumulate correctly")
	
	# Remover um efeito
	effect1.remove_effect(critter)
	assert(critter.stats.strength == initial_strength + 2,
		"Removing one effect should leave the other in place")
	
	# Remover o segundo efeito
	effect2.remove_effect(critter)
	assert(critter.stats.strength == initial_strength,
		"Removing all effects should restore original value")

## Testa que efeitos de bônus de skill funcionam corretamente
func test_skill_bonus_application() -> void:
	var critter = _create_test_critter()
	var initial_small_guns = critter.skills.get_skill_value(SkillData.Skill.SMALL_GUNS)
	
	# Criar efeito de bônus de skill
	var effect = PerkEffect.new()
	effect.effect_type = PerkEffect.EffectType.SKILL_BONUS
	effect.target = "SMALL_GUNS"
	effect.value = 5.0
	
	# Aplicar o efeito
	effect.apply_effect(critter)
	
	# Verificar que o skill foi aumentado
	assert(critter.skills.get_skill_value(SkillData.Skill.SMALL_GUNS) == initial_small_guns + 5,
		"Skill bonus should increase skill by exactly 5")
	
	# Remover o efeito
	effect.remove_effect(critter)
	
	# Verificar que o skill foi restaurado
	assert(critter.skills.get_skill_value(SkillData.Skill.SMALL_GUNS) == initial_small_guns,
		"Removing skill bonus should restore original value")

## Testa que efeitos de bônus de dano funcionam corretamente
func test_damage_bonus_application() -> void:
	var critter = _create_test_critter()
	
	# Criar efeito de bônus de dano
	var effect = PerkEffect.new()
	effect.effect_type = PerkEffect.EffectType.DAMAGE_BONUS
	effect.target = "DAMAGE"
	effect.value = 3.0
	
	# Aplicar o efeito
	effect.apply_effect(critter)
	
	# Verificar que o bônus de dano foi aplicado
	var damage_bonus = critter.get_meta("perk_damage_bonus") if critter.has_meta("perk_damage_bonus") else 0
	assert(damage_bonus == 3,
		"Damage bonus should be applied correctly")
	
	# Remover o efeito
	effect.remove_effect(critter)
	
	# Verificar que o bônus foi removido
	damage_bonus = critter.get_meta("perk_damage_bonus") if critter.has_meta("perk_damage_bonus") else 0
	assert(damage_bonus == 0,
		"Removing damage bonus should restore to zero")

## Testa que efeitos especiais são adicionados corretamente
func test_special_ability_application() -> void:
	var critter = _create_test_critter()
	
	# Criar efeito de habilidade especial
	var effect = PerkEffect.new()
	effect.effect_type = PerkEffect.EffectType.SPECIAL_ABILITY
	effect.target = "NIGHT_VISION"
	
	# Aplicar o efeito
	effect.apply_effect(critter)
	
	# Verificar que a habilidade foi adicionada
	var abilities = critter.get_meta("special_abilities") if critter.has_meta("special_abilities") else []
	assert("NIGHT_VISION" in abilities,
		"Special ability should be added to critter")
	
	# Remover o efeito
	effect.remove_effect(critter)
	
	# Verificar que a habilidade foi removida
	abilities = critter.get_meta("special_abilities") if critter.has_meta("special_abilities") else []
	assert("NIGHT_VISION" not in abilities,
		"Removing special ability should remove it from critter")

## Testa que efeitos com condições são verificados corretamente
func test_effect_condition_check() -> void:
	var critter = _create_test_critter()
	
	# Criar efeito sem condição
	var effect_no_condition = PerkEffect.new()
	effect_no_condition.condition = ""
	assert(effect_no_condition.can_apply(critter),
		"Effect without condition should always be applicable")
	
	# Criar efeito com condição (por enquanto sempre retorna true)
	var effect_with_condition = PerkEffect.new()
	effect_with_condition.condition = "STRENGTH >= 5"
	assert(effect_with_condition.can_apply(critter),
		"Effect with condition should be checked")

## Testa que aplicar efeito a null não causa erro
func test_null_critter_handling() -> void:
	var effect = PerkEffect.new()
	effect.effect_type = PerkEffect.EffectType.STAT_BONUS
	effect.target = "STRENGTH"
	effect.value = 1
	
	# Não deve lançar exceção
	effect.apply_effect(null)
	effect.remove_effect(null)

## Testa que todos os stats podem receber bônus
func test_all_stats_bonus() -> void:
	var critter = _create_test_critter()
	var stats_to_test = [
		"STRENGTH",
		"PERCEPTION",
		"ENDURANCE",
		"CHARISMA",
		"INTELLIGENCE",
		"AGILITY",
		"LUCK"
	]
	
	for stat_name in stats_to_test:
		var effect = PerkEffect.new()
		effect.effect_type = PerkEffect.EffectType.STAT_BONUS
		effect.target = stat_name
		effect.value = 1.0
		
		# Não deve falhar para nenhum stat
		effect.apply_effect(critter)
		effect.remove_effect(critter)

## Cria um personagem de teste com stats e skills inicializados
func _create_test_critter() -> Critter:
	var critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.is_player = true
	critter.faction = "player"
	
	# Inicializar stats
	critter.stats = StatData.new()
	critter.stats.strength = 5
	critter.stats.perception = 5
	critter.stats.endurance = 5
	critter.stats.charisma = 5
	critter.stats.intelligence = 5
	critter.stats.agility = 5
	critter.stats.luck = 5
	critter.stats.calculate_derived_stats()
	
	# Inicializar skills
	critter.skills = SkillData.new()
	
	return critter

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running PerkEffect Property Tests ===")
	
	test_stat_bonus_application()
	print("✓ test_stat_bonus_application passed")
	
	test_multiple_stat_bonuses()
	print("✓ test_multiple_stat_bonuses passed")
	
	test_skill_bonus_application()
	print("✓ test_skill_bonus_application passed")
	
	test_damage_bonus_application()
	print("✓ test_damage_bonus_application passed")
	
	test_special_ability_application()
	print("✓ test_special_ability_application passed")
	
	test_effect_condition_check()
	print("✓ test_effect_condition_check passed")
	
	test_null_critter_handling()
	print("✓ test_null_critter_handling passed")
	
	test_all_stats_bonus()
	print("✓ test_all_stats_bonus passed")
	
	print("=== All PerkEffect tests passed! ===")
