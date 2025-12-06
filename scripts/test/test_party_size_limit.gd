extends GdUnitTestSuite
## Property test for party size limit
## **Feature: fallout2-complete-migration, Property 24: Party Size Limit**
## **Validates: Requirements 9.6**

class_name TestPartySizeLimit
extends GdUnitTestSuite

var party_system: PartySystem
var player: Critter

func before_test() -> void:
	party_system = PartySystem.new()
	add_child(party_system)
	
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.stats = StatData.new()
	player.skills = SkillData.new()
	
	party_system.set_player(player)

func after_test() -> void:
	if party_system:
		party_system.queue_free()

## Property: For any party, party_members.size() SHALL never exceed MAX_PARTY_SIZE (5)
func test_party_size_limit_property() -> void:
	# Tentar adicionar mais de MAX_PARTY_SIZE companheiros
	for i in range(PartySystem.MAX_PARTY_SIZE + 5):
		var companion = Critter.new()
		companion.critter_name = "Companion %d" % i
		companion.stats = StatData.new()
		companion.skills = SkillData.new()
		
		var result = party_system.add_companion(companion)
		
		if i < PartySystem.MAX_PARTY_SIZE:
			# Primeiros MAX_PARTY_SIZE devem ser adicionados
			assert_that(result).is_true("Should be able to add companion %d" % i)
			assert_that(party_system.party_members.size()).is_equal(i + 1, 
				"Should have %d companions" % (i + 1))
		else:
			# Depois de MAX_PARTY_SIZE, deve falhar
			assert_that(result).is_false("Should not be able to add companion %d (exceeds limit)" % i)
			assert_that(party_system.party_members.size()).is_equal(PartySystem.MAX_PARTY_SIZE, 
				"Should still have exactly %d companions" % PartySystem.MAX_PARTY_SIZE)

## Test that is_party_full() works correctly
func test_is_party_full() -> void:
	# Inicialmente não deve estar cheio
	assert_that(party_system.is_party_full()).is_false("Party should not be full initially")
	
	# Adicionar companheiros até o limite
	for i in range(PartySystem.MAX_PARTY_SIZE):
		var companion = Critter.new()
		companion.critter_name = "Companion %d" % i
		companion.stats = StatData.new()
		companion.skills = SkillData.new()
		
		party_system.add_companion(companion)
		
		if i < PartySystem.MAX_PARTY_SIZE - 1:
			assert_that(party_system.is_party_full()).is_false("Party should not be full with %d companions" % (i + 1))
		else:
			assert_that(party_system.is_party_full()).is_true("Party should be full with %d companions" % PartySystem.MAX_PARTY_SIZE)

## Test that removing companion allows adding new one
func test_remove_and_add_companion() -> void:
	# Adicionar até o limite
	for i in range(PartySystem.MAX_PARTY_SIZE):
		var companion = Critter.new()
		companion.critter_name = "Companion %d" % i
		companion.stats = StatData.new()
		companion.skills = SkillData.new()
		party_system.add_companion(companion)
	
	assert_that(party_system.is_party_full()).is_true("Party should be full")
	
	# Remover um companheiro
	var first_companion = party_system.party_members[0]
	party_system.remove_companion(first_companion)
	
	assert_that(party_system.is_party_full()).is_false("Party should not be full after removal")
	assert_that(party_system.party_members.size()).is_equal(PartySystem.MAX_PARTY_SIZE - 1, 
		"Should have %d companions" % (PartySystem.MAX_PARTY_SIZE - 1))
	
	# Agora deve ser possível adicionar outro
	var new_companion = Critter.new()
	new_companion.critter_name = "New Companion"
	new_companion.stats = StatData.new()
	new_companion.skills = SkillData.new()
	
	var result = party_system.add_companion(new_companion)
	assert_that(result).is_true("Should be able to add new companion after removal")
	assert_that(party_system.party_members.size()).is_equal(PartySystem.MAX_PARTY_SIZE, 
		"Should have %d companions again" % PartySystem.MAX_PARTY_SIZE)

## Test that player is not counted in party_members
func test_player_not_in_party_members() -> void:
	# Player não deve estar em party_members
	assert_that(party_system.player in party_system.party_members).is_false("Player should not be in party_members array")
	
	# Tamanho do party deve incluir player
	assert_that(party_system.get_party_size()).is_equal(1, "Party size should be 1 (just player)")
	
	# Adicionar um companheiro
	var companion = Critter.new()
	companion.critter_name = "Companion"
	companion.stats = StatData.new()
	companion.skills = SkillData.new()
	party_system.add_companion(companion)
	
	assert_that(party_system.party_members.size()).is_equal(1, "Should have 1 companion")
	assert_that(party_system.get_party_size()).is_equal(2, "Party size should be 2 (player + 1 companion)")

## Test that cannot add same companion twice
func test_duplicate_companion_prevention() -> void:
	var companion = Critter.new()
	companion.critter_name = "Companion"
	companion.stats = StatData.new()
	companion.skills = SkillData.new()
	
	# Adicionar primeira vez
	var result1 = party_system.add_companion(companion)
	assert_that(result1).is_true("Should be able to add companion first time")
	assert_that(party_system.party_members.size()).is_equal(1, "Should have 1 companion")
	
	# Tentar adicionar novamente
	var result2 = party_system.add_companion(companion)
	assert_that(result2).is_false("Should not be able to add same companion twice")
	assert_that(party_system.party_members.size()).is_equal(1, "Should still have 1 companion")

## Test that cannot add player as companion
func test_cannot_add_player_as_companion() -> void:
	var result = party_system.add_companion(player)
	assert_that(result).is_false("Should not be able to add player as companion")
	assert_that(party_system.party_members.size()).is_equal(0, "Should have 0 companions")
