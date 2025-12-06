## Test for Faction Territory Exclusivity Property
## **Feature: city-map-system, Property 6: Faction Territory Exclusivity**
## **Validates: Requirements 12.2**

extends GutTest

var faction_system: FactionSystem
var grid_system: GridSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	grid_system = GridSystem.new()
	grid_system.initialize(100, 100)
	
	faction_system = FactionSystem.new()
	faction_system.set_systems(grid_system, null)

func test_territory_exclusivity() -> void:
	"""Property: For any tile, it should belong to at most one faction"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	var tiles_a = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(11, 10)]
	var tiles_b = [Vector2i(20, 20), Vector2i(20, 21), Vector2i(21, 20)]
	
	# Reivindicar territórios
	faction_system.claim_territory(faction_a, tiles_a)
	faction_system.claim_territory(faction_b, tiles_b)
	
	# Verificar exclusividade
	for tile in tiles_a:
		assert_equal(faction_system.get_faction_at(tile), faction_a,
			"Tile %s should belong to faction A" % tile)
	
	for tile in tiles_b:
		assert_equal(faction_system.get_faction_at(tile), faction_b,
			"Tile %s should belong to faction B" % tile)

func test_overlapping_territory_rejected() -> void:
	"""Property: For overlapping territory claims, the second claim should be rejected"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	var tiles = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(11, 10)]
	
	# Primeira reivindicação deve suceder
	var result_a = faction_system.claim_territory(faction_a, tiles)
	assert_true(result_a, "First territory claim should succeed")
	
	# Segunda reivindicação deve falhar
	var result_b = faction_system.claim_territory(faction_b, tiles)
	assert_false(result_b, "Overlapping territory claim should fail")
	
	# Verificar que a primeira facção mantém o território
	for tile in tiles:
		assert_equal(faction_system.get_faction_at(tile), faction_a,
			"Tile should still belong to faction A")

func test_territory_release() -> void:
	"""Property: For released territory, tiles should no longer belong to any faction"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	
	var tiles = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(11, 10)]
	
	# Reivindicar e depois liberar
	faction_system.claim_territory(faction_a, tiles)
	faction_system.release_territory(faction_a, tiles)
	
	# Verificar que os tiles foram liberados
	for tile in tiles:
		assert_equal(faction_system.get_faction_at(tile), -1,
			"Tile should not belong to any faction after release")

func test_partial_territory_claim() -> void:
	"""Property: For partial territory claims, only unclaimed tiles should be added"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	var tiles_a = [Vector2i(10, 10), Vector2i(10, 11)]
	var tiles_b = [Vector2i(10, 11), Vector2i(11, 11)]  # Sobrepõe em (10, 11)
	
	# Primeira reivindicação
	faction_system.claim_territory(faction_a, tiles_a)
	
	# Segunda reivindicação com sobreposição
	var result = faction_system.claim_territory(faction_b, tiles_b)
	assert_false(result, "Claim with overlap should fail")

func test_territory_size() -> void:
	"""Property: For any faction, territory size should match claimed tiles"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	
	var tiles = []
	for x in range(10, 20):
		for y in range(10, 20):
			tiles.append(Vector2i(x, y))
	
	faction_system.claim_territory(faction_a, tiles)
	
	var territory_size = faction_system.get_territory_size(faction_a)
	assert_equal(territory_size, 100, "Territory size should match claimed tiles")

func test_get_faction_territory() -> void:
	"""Property: For any faction, get_faction_territory should return all claimed tiles"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	
	var tiles = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(11, 10), Vector2i(11, 11)]
	
	faction_system.claim_territory(faction_a, tiles)
	
	var territory = faction_system.get_faction_territory(faction_a)
	
	assert_equal(territory.size(), 4, "Territory should contain all claimed tiles")
	for tile in tiles:
		assert_true(tile in territory, "Tile %s should be in territory" % tile)

func test_multiple_claims_same_faction() -> void:
	"""Property: For multiple claims by same faction, all tiles should be added"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	
	var tiles_1 = [Vector2i(10, 10), Vector2i(10, 11)]
	var tiles_2 = [Vector2i(20, 20), Vector2i(20, 21)]
	
	faction_system.claim_territory(faction_a, tiles_1)
	faction_system.claim_territory(faction_a, tiles_2)
	
	var territory = faction_system.get_faction_territory(faction_a)
	
	assert_equal(territory.size(), 4, "Territory should contain all claimed tiles")

func test_territory_adjacency_detection() -> void:
	"""Property: For adjacent territories, check_territorial_dispute should detect them"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	# Criar territórios adjacentes
	var tiles_a = [Vector2i(10, 10), Vector2i(10, 11)]
	var tiles_b = [Vector2i(11, 10), Vector2i(11, 11)]  # Adjacente a A
	
	faction_system.claim_territory(faction_a, tiles_a)
	faction_system.claim_territory(faction_b, tiles_b)
	
	var has_dispute = faction_system.check_territorial_dispute(faction_a, faction_b)
	assert_true(has_dispute, "Adjacent territories should be detected as dispute")

func test_no_dispute_for_distant_territories() -> void:
	"""Property: For distant territories, check_territorial_dispute should return false"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	# Criar territórios distantes
	var tiles_a = [Vector2i(10, 10), Vector2i(10, 11)]
	var tiles_b = [Vector2i(50, 50), Vector2i(50, 51)]  # Longe de A
	
	faction_system.claim_territory(faction_a, tiles_a)
	faction_system.claim_territory(faction_b, tiles_b)
	
	var has_dispute = faction_system.check_territorial_dispute(faction_a, faction_b)
	assert_false(has_dispute, "Distant territories should not be detected as dispute")

func test_faction_statistics() -> void:
	"""Property: For any faction state, statistics should accurately reflect it"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	var faction_b = faction_system.create_faction("Faction B", Color.BLUE)
	
	var tiles_a = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(11, 10)]
	faction_system.claim_territory(faction_a, tiles_a)
	
	var stats = faction_system.get_faction_statistics()
	
	assert_equal(stats["total_factions"], 2, "Should have 2 factions")
	assert_true(stats["factions"].has("Faction A"))
	assert_true(stats["factions"].has("Faction B"))
	
	var faction_a_stats = stats["factions"]["Faction A"]
	assert_equal(faction_a_stats["territory_size"], 3, "Faction A should have 3 tiles")
	assert_equal(faction_a_stats["members"], 0, "Faction A should have 0 members initially")

func test_faction_members() -> void:
	"""Property: For any faction, members should be tracked correctly"""
	var faction_a = faction_system.create_faction("Faction A", Color.RED)
	
	# Adicionar membros
	faction_system.add_faction_member(faction_a, 1)
	faction_system.add_faction_member(faction_a, 2)
	faction_system.add_faction_member(faction_a, 3)
	
	var members = faction_system.get_faction_members(faction_a)
	assert_equal(members.size(), 3, "Faction should have 3 members")
	
	# Remover um membro
	faction_system.remove_faction_member(faction_a, 2)
	
	members = faction_system.get_faction_members(faction_a)
	assert_equal(members.size(), 2, "Faction should have 2 members after removal")
	assert_false(2 in members, "Removed member should not be in faction")
