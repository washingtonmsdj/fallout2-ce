## Test for Defense Rating Calculation Property
## **Feature: city-map-system, Property 10: Defense Rating Calculation**
## **Validates: Requirements 15.2**

class_name TestDefenseRating
extends GdUnitTestSuite

var defense_system: DefenseSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	defense_system = DefenseSystem.new()
	defense_system.set_config(config)
	defense_system.set_systems(null, null)

func test_defense_rating_empty() -> void:
	"""Property: For empty defense system, defense rating should be 0"""
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(0.0)

func test_defense_rating_single_wall() -> void:
	"""Property: For single wall at full health, rating should be 10"""
	defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(10.0)

func test_defense_rating_damaged_wall() -> void:
	"""Property: For damaged wall, rating should be proportional to health"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	# Danificar a parede para 50% de saúde
	var defense = defense_system.get_defense(defense_id)
	defense.health = 50.0  # max_health é 100
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(5.0)

func test_defense_rating_destroyed_wall() -> void:
	"""Property: For destroyed wall, rating should be 0"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	# Destruir a parede
	var defense = defense_system.get_defense(defense_id)
	defense.health = 0.0
	defense.is_active = false
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(0.0)

func test_defense_rating_multiple_structures() -> void:
	"""Property: For multiple structures, rating should be sum of individual ratings"""
	# Construir múltiplas estruturas
	defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	defense_system.build_defense(DefenseSystem.DefenseType.GATE, Vector2i(11, 10))
	defense_system.build_defense(DefenseSystem.DefenseType.GUARD_TOWER, Vector2i(12, 10))
	
	var rating = defense_system.get_defense_rating()
	# Wall: 10, Gate: 8, Guard Tower: 25 = 43
	assert_that(rating).is_equal(43.0)

func test_defense_rating_turret_with_ammo() -> void:
	"""Property: For turret with full ammo, rating should include ammo factor"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.TURRET_BALLISTIC, Vector2i(10, 10))
	
	var defense = defense_system.get_defense(defense_id)
	# Full ammo: 300/300 = 1.0
	# Rating: 35 * 1.0 * 1.0 = 35
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(35.0)

func test_defense_rating_turret_without_ammo() -> void:
	"""Property: For turret without ammo, rating should be 0"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.TURRET_BALLISTIC, Vector2i(10, 10))
	
	var defense = defense_system.get_defense(defense_id)
	defense.ammo = 0  # No ammo
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(0.0)

func test_defense_rating_turret_half_ammo() -> void:
	"""Property: For turret with half ammo, rating should be half"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.TURRET_BALLISTIC, Vector2i(10, 10))
	
	var defense = defense_system.get_defense(defense_id)
	defense.ammo = 150  # Half of 300
	
	var rating = defense_system.get_defense_rating()
	# 35 * 1.0 * 0.5 = 17.5
	assert_that(rating).is_between(17.4, 17.6)

func test_defense_rating_laser_turret() -> void:
	"""Property: For laser turret at full health and ammo, rating should be 40"""
	defense_system.build_defense(DefenseSystem.DefenseType.TURRET_LASER, Vector2i(10, 10))
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(40.0)

func test_defense_rating_trap_mine() -> void:
	"""Property: For trap mine at full health, rating should be 15"""
	defense_system.build_defense(DefenseSystem.DefenseType.TRAP_MINE, Vector2i(10, 10))
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(15.0)

func test_defense_rating_trap_spike() -> void:
	"""Property: For trap spike at full health, rating should be 5"""
	defense_system.build_defense(DefenseSystem.DefenseType.TRAP_SPIKE, Vector2i(10, 10))
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(5.0)

func test_defense_rating_inactive_structure() -> void:
	"""Property: For inactive structure, rating should not include it"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	var defense = defense_system.get_defense(defense_id)
	defense.is_active = false
	
	var rating = defense_system.get_defense_rating()
	assert_that(rating).is_equal(0.0)

func test_defense_rating_mixed_structures() -> void:
	"""Property: For mixed structures with various health/ammo, rating should be accurate"""
	# Wall at full health
	defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	# Gate at 50% health
	var gate_id = defense_system.build_defense(DefenseSystem.DefenseType.GATE, Vector2i(11, 10))
	var gate = defense_system.get_defense(gate_id)
	gate.health = 40.0  # 50% of 80
	
	# Guard tower at full health and ammo
	defense_system.build_defense(DefenseSystem.DefenseType.GUARD_TOWER, Vector2i(12, 10))
	
	var rating = defense_system.get_defense_rating()
	# Wall: 10 * 1.0 * 1.0 = 10
	# Gate: 8 * 0.5 * 1.0 = 4
	# Guard Tower: 25 * 1.0 * 1.0 = 25
	# Total: 39
	assert_that(rating).is_equal(39.0)

func test_defense_rating_by_faction() -> void:
	"""Property: For faction-specific rating, only faction structures should be counted"""
	var faction_a = 1
	var faction_b = 2
	
	# Construir estruturas para facção A
	defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10), faction_a)
	defense_system.build_defense(DefenseSystem.DefenseType.GATE, Vector2i(11, 10), faction_a)
	
	# Construir estruturas para facção B
	defense_system.build_defense(DefenseSystem.DefenseType.GUARD_TOWER, Vector2i(20, 20), faction_b)
	
	var rating_a = defense_system.get_defense_rating_by_faction(faction_a)
	var rating_b = defense_system.get_defense_rating_by_faction(faction_b)
	
	# Faction A: 10 + 8 = 18
	# Faction B: 25
	assert_that(rating_a).is_equal(18.0)
	assert_that(rating_b).is_equal(25.0)

func test_defense_rating_consistency() -> void:
	"""Property: For same defense configuration, rating should be consistent"""
	# Build same configuration twice
	defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	defense_system.build_defense(DefenseSystem.DefenseType.GATE, Vector2i(11, 10))
	
	var rating1 = defense_system.get_defense_rating()
	var rating2 = defense_system.get_defense_rating()
	
	assert_that(rating1).is_equal(rating2)

func test_defense_rating_after_damage() -> void:
	"""Property: For damaged structure, rating should decrease proportionally"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.GUARD_TOWER, Vector2i(10, 10))
	
	var rating_before = defense_system.get_defense_rating()
	
	# Danificar a torre
	defense_system.damage_defense(defense_id, 30.0)  # 30 damage out of 60 max health
	
	var rating_after = defense_system.get_defense_rating()
	
	# Before: 25 * 1.0 * 1.0 = 25
	# After: 25 * 0.5 * 1.0 = 12.5
	assert_that(rating_before).is_equal(25.0)
	assert_that(rating_after).is_between(12.4, 12.6)

func test_defense_rating_after_repair() -> void:
	"""Property: For repaired structure, rating should increase proportionally"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.WALL, Vector2i(10, 10))
	
	# Danificar
	defense_system.damage_defense(defense_id, 50.0)
	var rating_damaged = defense_system.get_defense_rating()
	
	# Reparar
	defense_system.repair_defense(defense_id, 50.0)
	var rating_repaired = defense_system.get_defense_rating()
	
	assert_that(rating_damaged).is_equal(5.0)
	assert_that(rating_repaired).is_equal(10.0)

func test_defense_rating_after_ammo_refill() -> void:
	"""Property: For refilled turret, rating should increase"""
	var defense_id = defense_system.build_defense(DefenseSystem.DefenseType.TURRET_BALLISTIC, Vector2i(10, 10))
	
	var defense = defense_system.get_defense(defense_id)
	defense.ammo = 0  # Empty ammo
	
	var rating_empty = defense_system.get_defense_rating()
	
	# Reabastecer
	defense_system.refill_ammo(defense_id, 300)
	var rating_full = defense_system.get_defense_rating()
	
	assert_that(rating_empty).is_equal(0.0)
	assert_that(rating_full).is_equal(35.0)

func test_defense_rating_all_types() -> void:
	"""Property: For all defense types, rating should be calculated correctly"""
	var types = [
		DefenseSystem.DefenseType.WALL,
		DefenseSystem.DefenseType.GATE,
		DefenseSystem.DefenseType.GUARD_TOWER,
		DefenseSystem.DefenseType.TURRET_BALLISTIC,
		DefenseSystem.DefenseType.TURRET_LASER,
		DefenseSystem.DefenseType.TRAP_MINE,
		DefenseSystem.DefenseType.TRAP_SPIKE
	]
	
	var expected_ratings = [10.0, 8.0, 25.0, 35.0, 40.0, 15.0, 5.0]
	
	for i in range(types.size()):
		defense_system = DefenseSystem.new()
		defense_system.set_config(config)
		defense_system.set_systems(null, null)
		
		defense_system.build_defense(types[i], Vector2i(10 + i, 10))
		
		var rating = defense_system.get_defense_rating()
		assert_that(rating).is_equal(expected_ratings[i])
