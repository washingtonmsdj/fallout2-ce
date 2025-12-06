extends GdUnitTestSuite
## Property test for party combat inclusion
## **Feature: fallout2-complete-migration, Property 25: Party Combat Inclusion**
## **Validates: Requirements 9.2**

class_name TestPartyCombatInclusion
extends GdUnitTestSuite

var party_system: PartySystem
var player: Critter
var combat_system: CombatSystem

func before_test() -> void:
	party_system = PartySystem.new()
	add_child(party_system)
	
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.stats = StatData.new()
	player.stats.sequence = 10
	player.skills = SkillData.new()
	
	party_system.set_player(player)
	
	combat_system = CombatSystem.new()
	add_child(combat_system)

func after_test() -> void:
	if party_system:
		party_system.queue_free()
	if combat_system:
		combat_system.queue_free()

## Property: For any combat with party members, all living party members 
## SHALL appear in turn_order sorted by Sequence
func test_party_combat_inclusion_property() -> void:
	# Criar companheiros com diferentes Sequence
	var companion1 = Critter.new()
	companion1.critter_name = "Companion 1"
	companion1.stats = StatData.new()
	companion1.stats.sequence = 15  # Maior sequence
	companion1.skills = SkillData.new()
	
	var companion2 = Critter.new()
	companion2.critter_name = "Companion 2"
	companion2.stats = StatData.new()
	companion2.stats.sequence = 8   # Menor sequence
	companion2.skills = SkillData.new()
	
	# Adicionar ao party
	party_system.add_companion(companion1)
	party_system.add_companion(companion2)
	
	# Criar inimigo
	var enemy = Critter.new()
	enemy.critter_name = "Enemy"
	enemy.stats = StatData.new()
	enemy.stats.sequence = 12
	enemy.skills = SkillData.new()
	enemy.faction = "enemy"
	
	# Obter party para combate
	var party_members = party_system.get_party_for_combat()
	
	# Verificar que todos os membros vivos estão incluídos
	assert_that(player in party_members).is_true("Player should be in combat party")
	assert_that(companion1 in party_members).is_true("Companion 1 should be in combat party")
	assert_that(companion2 in party_members).is_true("Companion 2 should be in combat party")
	
	# Verificar ordenação por Sequence (maior primeiro)
	assert_that(party_members[0]).is_equal(companion1, "Companion 1 should be first (highest sequence)")
	assert_that(party_members[1]).is_equal(player, "Player should be second")
	assert_that(party_members[2]).is_equal(companion2, "Companion 2 should be third (lowest sequence)")

## Test that dead companions are not included
func test_dead_companions_excluded() -> void:
	var companion = Critter.new()
	companion.critter_name = "Dead Companion"
	companion.stats = StatData.new()
	companion.stats.sequence = 10
	companion.stats.current_hp = 0  # Morto
	companion.skills = SkillData.new()
	
	party_system.add_companion(companion)
	
	var party_members = party_system.get_party_for_combat()
	
	# Companheiro morto não deve estar incluído
	assert_that(companion in party_members).is_false("Dead companion should not be in combat party")
	assert_that(player in party_members).is_true("Player should still be in combat party")

## Test that unconscious companions are not included
func test_unconscious_companions_excluded() -> void:
	var companion = Critter.new()
	companion.critter_name = "Unconscious Companion"
	companion.stats = StatData.new()
	companion.stats.sequence = 10
	companion.stats.current_hp = -1  # Inconsciente (HP negativo mas não morto)
	companion.skills = SkillData.new()
	
	party_system.add_companion(companion)
	
	var party_members = party_system.get_party_for_combat()
	
	# Companheiro inconsciente não deve estar incluído
	assert_that(companion in party_members).is_false("Unconscious companion should not be in combat party")

## Test that all party members are sorted correctly
func test_party_members_sorted_by_sequence() -> void:
	# Criar múltiplos companheiros com diferentes sequences
	var companions = []
	for i in range(5):
		var companion = Critter.new()
		companion.critter_name = "Companion %d" % i
		companion.stats = StatData.new()
		companion.stats.sequence = 5 + i * 2  # Sequences: 5, 7, 9, 11, 13
		companion.skills = SkillData.new()
		companions.append(companion)
		party_system.add_companion(companion)
	
	player.stats.sequence = 10  # Sequence do player
	
	var party_members = party_system.get_party_for_combat()
	
	# Verificar que estão ordenados por Sequence (maior primeiro)
	for i in range(party_members.size() - 1):
		var current = party_members[i]
		var next = party_members[i + 1]
		
		assert_that(current.stats.sequence).is_greater_equal(next.stats.sequence, 
			"Party members should be sorted by Sequence (descending)")

## Test that player is always included if alive
func test_player_always_included() -> void:
	# Adicionar companheiros
	for i in range(3):
		var companion = Critter.new()
		companion.critter_name = "Companion %d" % i
		companion.stats = StatData.new()
		companion.stats.sequence = 10
		companion.skills = SkillData.new()
		party_system.add_companion(companion)
	
	var party_members = party_system.get_party_for_combat()
	
	# Player deve estar sempre incluído se vivo
	assert_that(player in party_members).is_true("Player should always be in combat party if alive")
	
	# Matar player
	player.stats.current_hp = 0
	
	party_members = party_system.get_party_for_combat()
	
	# Player morto não deve estar incluído
	assert_that(player in party_members).is_false("Dead player should not be in combat party")

## Test combat system integration
func test_combat_system_integration() -> void:
	# Adicionar companheiros
	var companion = Critter.new()
	companion.critter_name = "Companion"
	companion.stats = StatData.new()
	companion.stats.sequence = 12
	companion.skills = SkillData.new()
	party_system.add_companion(companion)
	
	# Criar inimigo
	var enemy = Critter.new()
	enemy.critter_name = "Enemy"
	enemy.stats = StatData.new()
	enemy.stats.sequence = 10
	enemy.skills = SkillData.new()
	enemy.faction = "enemy"
	
	# Obter party para combate
	var party_members = party_system.get_party_for_combat()
	
	# Criar array de combatantes (party + inimigos)
	var combatants: Array[Critter] = []
	combatants.append_array(party_members)
	combatants.append(enemy)
	
	# Iniciar combate
	combat_system.start_combat(combatants)
	
	# Verificar que todos os membros do party estão no turn_order
	var turn_order = combat_system.turn_order
	
	assert_that(player in turn_order).is_true("Player should be in turn order")
	assert_that(companion in turn_order).is_true("Companion should be in turn order")
	assert_that(enemy in turn_order).is_true("Enemy should be in turn order")

## Test that party members maintain correct order in combat
func test_party_order_in_combat() -> void:
	# Criar companheiros com sequences conhecidas
	var companion1 = Critter.new()
	companion1.critter_name = "Fast Companion"
	companion1.stats = StatData.new()
	companion1.stats.sequence = 20  # Mais rápido
	companion1.skills = SkillData.new()
	
	var companion2 = Critter.new()
	companion2.critter_name = "Slow Companion"
	companion2.stats = StatData.new()
	companion2.stats.sequence = 5   # Mais lento
	companion2.skills = SkillData.new()
	
	player.stats.sequence = 10  # Médio
	
	party_system.add_companion(companion1)
	party_system.add_companion(companion2)
	
	var party_members = party_system.get_party_for_combat()
	
	# Verificar ordem: companion1 (20) > player (10) > companion2 (5)
	assert_that(party_members[0]).is_equal(companion1, "Fastest companion should be first")
	assert_that(party_members[1]).is_equal(player, "Player should be second")
	assert_that(party_members[2]).is_equal(companion2, "Slowest companion should be last")
