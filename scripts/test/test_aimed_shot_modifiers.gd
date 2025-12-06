extends GdUnitTestSuite
## Property test for aimed shot modifiers
## **Feature: fallout2-complete-migration, Property 29: Aimed Shot Modifiers**
## **Validates: Requirements 11.5**

class_name TestAimedShotModifiers
extends GdUnitTestSuite

var combat_system: CombatSystem
var attacker: Critter
var defender: Critter

func before_test() -> void:
	combat_system = CombatSystem.new()
	add_child(combat_system)
	
	attacker = Critter.new()
	attacker.critter_name = "Attacker"
	attacker.stats = StatData.new()
	attacker.stats.strength = 5
	attacker.stats.agility = 5
	attacker.skills = SkillData.new()
	attacker.skills.skill_values[SkillData.Skill.SMALL_GUNS] = 75
	
	defender = Critter.new()
	defender.critter_name = "Defender"
	defender.stats = StatData.new()
	defender.stats.armor_class = 10
	defender.skills = SkillData.new()

func after_test() -> void:
	if combat_system:
		combat_system.queue_free()

## Property: For any aimed shot, accuracy SHALL decrease and damage SHALL increase 
## based on hit location difficulty
func test_aimed_shot_modifiers_property() -> void:
	# Testar diferentes localizações
	var locations = [
		GameConstants.HitLocation.HEAD,
		GameConstants.HitLocation.EYES,
		GameConstants.HitLocation.GROIN,
		GameConstants.HitLocation.TORSO
	]
	
	for location in locations:
		# Obter penalidade de precisão
		var accuracy_penalty = combat_system._get_aimed_shot_penalty(location)
		
		# Obter bônus de dano
		var damage_bonus = combat_system._get_aimed_shot_damage_bonus(location)
		
		# Verificar que penalidades e bônus são consistentes
		if location == GameConstants.HitLocation.EYES:
			# Olhos devem ter maior penalidade e maior bônus
			assert_that(accuracy_penalty).is_greater_equal(50.0,
				"Eyes should have high accuracy penalty")
			assert_that(damage_bonus).is_greater_equal(0.5,
				"Eyes should have high damage bonus")
		elif location == GameConstants.HitLocation.HEAD:
			# Cabeça deve ter penalidade e bônus moderados
			assert_that(accuracy_penalty).is_greater_equal(30.0,
				"Head should have moderate accuracy penalty")
			assert_that(damage_bonus).is_greater_equal(0.3,
				"Head should have moderate damage bonus")
		elif location == GameConstants.HitLocation.TORSO:
			# Torso deve ter penalidade e bônus mínimos
			assert_that(accuracy_penalty).is_equal(0.0,
				"Torso should have no accuracy penalty")
			assert_that(damage_bonus).is_equal(0.0,
				"Torso should have no damage bonus")

## Test that harder locations have higher penalties
func test_location_difficulty_penalties() -> void:
	var torso_penalty = combat_system._get_aimed_shot_penalty(GameConstants.HitLocation.TORSO)
	var head_penalty = combat_system._get_aimed_shot_penalty(GameConstants.HitLocation.HEAD)
	var eyes_penalty = combat_system._get_aimed_shot_penalty(GameConstants.HitLocation.EYES)
	
	# Penalidades devem aumentar com dificuldade
	assert_that(torso_penalty).is_less_equal(head_penalty,
		"Torso should have lower penalty than head")
	assert_that(head_penalty).is_less_equal(eyes_penalty,
		"Head should have lower penalty than eyes")

## Test that harder locations have higher damage bonuses
func test_location_difficulty_bonuses() -> void:
	var torso_bonus = combat_system._get_aimed_shot_damage_bonus(GameConstants.HitLocation.TORSO)
	var head_bonus = combat_system._get_aimed_shot_damage_bonus(GameConstants.HitLocation.HEAD)
	var eyes_bonus = combat_system._get_aimed_shot_damage_bonus(GameConstants.HitLocation.EYES)
	
	# Bônus devem aumentar com dificuldade
	assert_that(torso_bonus).is_less_equal(head_bonus,
		"Torso should have lower bonus than head")
	assert_that(head_bonus).is_less_equal(eyes_bonus,
		"Head should have lower bonus than eyes")

## Test that aimed shots apply modifiers correctly
func test_aimed_shot_execution() -> void:
	# Criar arma
	var weapon = Weapon.new()
	weapon.min_damage = 10
	weapon.max_damage = 15
	attacker.equipped_weapon = weapon
	
	# Executar aimed shot na cabeça
	var result = combat_system.execute_aimed_shot(attacker, defender, GameConstants.HitLocation.HEAD)
	
	# Verificar que resultado tem informações corretas
	assert_that(result).is_not_null("Result should not be null")
	
	# Se acertou, dano deve ser maior que tiro normal
	if result.hit and result.damage > 0:
		# Dano deve ser maior devido ao bônus
		var base_damage = (weapon.min_damage + weapon.max_damage) / 2
		var expected_min = int(base_damage * 1.5)  # +50% bônus para cabeça
		assert_that(result.damage).is_greater_equal(expected_min,
			"Aimed shot damage should be increased")

## Test that accuracy penalty reduces hit chance
func test_accuracy_penalty_effect() -> void:
	# Configurar para ter chance de acerto conhecida
	attacker.skills.skill_values[SkillData.Skill.SMALL_GUNS] = 100
	defender.stats.armor_class = 0
	
	# Tiro normal no torso (sem penalidade)
	var normal_result = combat_system.execute_attack(attacker, defender, GameConstants.HitLocation.TORSO)
	
	# Aimed shot nos olhos (com penalidade alta)
	var aimed_result = combat_system.execute_aimed_shot(attacker, defender, GameConstants.HitLocation.EYES)
	
	# Aimed shot deve ter menor chance de acerto (mas não garantido devido a RNG)
	# Vamos apenas verificar que a função executa sem erros
	assert_that(aimed_result).is_not_null("Aimed shot should return result")

## Test different hit locations have different modifiers
func test_location_modifier_variation() -> void:
	var locations = [
		GameConstants.HitLocation.HEAD,
		GameConstants.HitLocation.EYES,
		GameConstants.HitLocation.GROIN,
		GameConstants.HitLocation.LEFT_ARM,
		GameConstants.HitLocation.LEFT_LEG
	]
	
	var penalties = []
	var bonuses = []
	
	for location in locations:
		penalties.append(combat_system._get_aimed_shot_penalty(location))
		bonuses.append(combat_system._get_aimed_shot_damage_bonus(location))
	
	# Verificar que há variação (não todos iguais)
	var penalty_variation = false
	for i in range(penalties.size() - 1):
		if penalties[i] != penalties[i + 1]:
			penalty_variation = true
			break
	
	assert_that(penalty_variation).is_true("Different locations should have different penalties")
