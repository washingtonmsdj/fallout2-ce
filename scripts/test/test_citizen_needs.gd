## Test for Citizen Need Bounds Property
## **Feature: city-map-system, Property 4: Citizen Need Bounds**
## **Validates: Requirements 5.1**

extends GutTest

var citizen_system: CitizenSystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	citizen_system = CitizenSystem.new()
	citizen_system.config = config

func test_citizen_needs_start_in_bounds() -> void:
	"""Property: For any spawned citizen, all needs should be within [0, 100]"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	assert_true(citizen != null, "Citizen should be created")
	
	for need_type in citizen.needs.keys():
		var need_value = citizen.needs[need_type]
		assert_true(need_value >= 0.0 and need_value <= 100.0,
			"Need %d should be in range [0, 100], got %.1f" % [need_type, need_value])

func test_fulfill_need_respects_bounds() -> void:
	"""Property: For any need fulfillment, the resulting need should remain within [0, 100]"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	
	# Fulfill needs by large amounts
	citizen_system.fulfill_need(citizen_id, CitizenSystem.NeedType.HUNGER, 200.0)
	citizen_system.fulfill_need(citizen_id, CitizenSystem.NeedType.THIRST, 150.0)
	
	var citizen = citizen_system.get_citizen(citizen_id)
	
	for need_type in citizen.needs.keys():
		var need_value = citizen.needs[need_type]
		assert_true(need_value >= 0.0 and need_value <= 100.0,
			"Need %d should be in range [0, 100] after fulfillment, got %.1f" % [need_type, need_value])

func test_need_decay_respects_bounds() -> void:
	"""Property: For any need decay, the resulting need should remain within [0, 100]"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	
	# Simulate many updates to cause decay
	for i in range(1000):
		citizen_system.update_citizen_needs(1.0)
	
	var citizen = citizen_system.get_citizen(citizen_id)
	
	for need_type in citizen.needs.keys():
		var need_value = citizen.needs[need_type]
		assert_true(need_value >= 0.0 and need_value <= 100.0,
			"Need %d should be in range [0, 100] after decay, got %.1f" % [need_type, need_value])

func test_critical_need_detection() -> void:
	"""Property: For any citizen with critical need, get_critical_need should return that need"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	# Set one need to critical
	citizen.needs[CitizenSystem.NeedType.HUNGER] = 10.0
	
	var critical_need = citizen.get_critical_need()
	assert_equal(critical_need, CitizenSystem.NeedType.HUNGER,
		"Should detect hunger as critical need")

func test_no_critical_need_when_all_high() -> void:
	"""Property: For any citizen with all needs above threshold, get_critical_need should return -1"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	# Set all needs to high
	for need_type in citizen.needs.keys():
		citizen.needs[need_type] = 80.0
	
	var critical_need = citizen.get_critical_need()
	assert_equal(critical_need, -1,
		"Should return -1 when no critical needs")

func test_need_critical_threshold() -> void:
	"""Property: For any need below critical threshold, is_need_critical should return true"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	citizen.needs[CitizenSystem.NeedType.HUNGER] = 15.0
	
	assert_true(citizen.is_need_critical(CitizenSystem.NeedType.HUNGER),
		"Need below threshold should be critical")

func test_need_not_critical_above_threshold() -> void:
	"""Property: For any need above critical threshold, is_need_critical should return false"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	citizen.needs[CitizenSystem.NeedType.HUNGER] = 50.0
	
	assert_false(citizen.is_need_critical(CitizenSystem.NeedType.HUNGER),
		"Need above threshold should not be critical")

func test_multiple_citizens_independent_needs() -> void:
	"""Property: For any two citizens, their needs should be independent"""
	var citizen_id1 = citizen_system.spawn_citizen("Citizen 1", Vector2i(10, 10))
	var citizen_id2 = citizen_system.spawn_citizen("Citizen 2", Vector2i(20, 20))
	
	var citizen1 = citizen_system.get_citizen(citizen_id1)
	var citizen2 = citizen_system.get_citizen(citizen_id2)
	
	# Fulfill needs for citizen 1
	citizen_system.fulfill_need(citizen_id1, CitizenSystem.NeedType.HUNGER, 50.0)
	
	# Citizen 2's needs should not change
	var citizen2_hunger_before = citizen2.needs[CitizenSystem.NeedType.HUNGER]
	
	# Update needs
	citizen_system.update_citizen_needs(1.0)
	
	var citizen2_hunger_after = citizen2.needs[CitizenSystem.NeedType.HUNGER]
	
	# Should only have decayed, not been affected by citizen 1's fulfillment
	assert_true(citizen2_hunger_after <= citizen2_hunger_before,
		"Citizen 2's hunger should only decay, not be affected by citizen 1")

func test_all_need_types_tracked() -> void:
	"""Property: For any citizen, all need types should be tracked"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	# Check all need types are present
	assert_true(citizen.needs.has(CitizenSystem.NeedType.HUNGER))
	assert_true(citizen.needs.has(CitizenSystem.NeedType.THIRST))
	assert_true(citizen.needs.has(CitizenSystem.NeedType.REST))
	assert_true(citizen.needs.has(CitizenSystem.NeedType.HAPPINESS))
	assert_true(citizen.needs.has(CitizenSystem.NeedType.HEALTH))
	assert_true(citizen.needs.has(CitizenSystem.NeedType.SAFETY))

func test_decay_rate_consistency() -> void:
	"""Property: For any need type, decay rate should be consistent"""
	var citizen_id = citizen_system.spawn_citizen("Test Citizen", Vector2i(10, 10))
	var citizen = citizen_system.get_citizen(citizen_id)
	
	# Set all needs to 100
	for need_type in citizen.needs.keys():
		citizen.needs[need_type] = 100.0
	
	# Update once
	citizen_system.update_citizen_needs(1.0)
	
	var needs_after_1 = {}
	for need_type in citizen.needs.keys():
		needs_after_1[need_type] = citizen.needs[need_type]
	
	# Update again
	citizen_system.update_citizen_needs(1.0)
	
	var needs_after_2 = {}
	for need_type in citizen.needs.keys():
		needs_after_2[need_type] = citizen.needs[need_type]
	
	# Decay should be consistent
	for need_type in citizen.needs.keys():
		var decay_1 = 100.0 - needs_after_1[need_type]
		var decay_2 = needs_after_1[need_type] - needs_after_2[need_type]
		
		# Allow small floating point differences
		assert_true(abs(decay_1 - decay_2) < 0.1,
			"Decay for need %d should be consistent: %.2f vs %.2f" % [need_type, decay_1, decay_2])
