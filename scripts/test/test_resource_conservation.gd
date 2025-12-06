## Test for Resource Conservation Property
## **Feature: city-map-system, Property 5: Resource Conservation**
## **Validates: Requirements 6.2, 6.3**

extends GutTest

var economy_system: EconomySystem
var config: CityConfig

func before_each() -> void:
	config = CityConfig.new()
	economy_system = EconomySystem.new()
	economy_system.config = config
	economy_system._ready()

func test_resource_conservation_no_production() -> void:
	"""Property: For any resource with no production or consumption, amount should remain constant"""
	var initial_amount = economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD)
	
	# Simular múltiplas atualizações
	for i in range(100):
		economy_system.update_economy(1.0)
	
	var final_amount = economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD)
	
	assert_equal(final_amount, initial_amount, 
		"Resource amount should remain constant with no production/consumption")

func test_resource_production_increases_amount() -> void:
	"""Property: For any resource with production, amount should increase"""
	var resource = economy_system._resources[EconomySystem.ResourceType.FOOD]
	var initial_amount = resource.amount
	
	# Definir taxa de produção
	resource.production_rate = 10.0  # 10 por segundo
	
	# Simular 5 segundos
	economy_system.update_economy(5.0)
	
	var final_amount = resource.amount
	
	assert_true(final_amount > initial_amount,
		"Resource amount should increase with production")
	assert_true(abs(final_amount - (initial_amount + 50.0)) < 0.1,
		"Resource increase should match production rate")

func test_resource_consumption_decreases_amount() -> void:
	"""Property: For any resource with consumption, amount should decrease"""
	var resource = economy_system._resources[EconomySystem.ResourceType.WATER]
	var initial_amount = resource.amount
	
	# Definir taxa de consumo
	resource.consumption_rate = 5.0  # 5 por segundo
	
	# Simular 5 segundos
	economy_system.update_economy(5.0)
	
	var final_amount = resource.amount
	
	assert_true(final_amount < initial_amount,
		"Resource amount should decrease with consumption")
	assert_true(abs(final_amount - (initial_amount - 25.0)) < 0.1,
		"Resource decrease should match consumption rate")

func test_resource_never_negative() -> void:
	"""Property: For any resource, amount should never go below 0"""
	var resource = economy_system._resources[EconomySystem.ResourceType.CAPS]
	resource.amount = 10.0
	resource.consumption_rate = 100.0  # Consumo muito alto
	
	# Simular 10 segundos
	economy_system.update_economy(10.0)
	
	var final_amount = resource.amount
	
	assert_true(final_amount >= 0.0,
		"Resource amount should never be negative")

func test_production_consumption_balance() -> void:
	"""Property: For balanced production and consumption, amount should remain stable"""
	var resource = economy_system._resources[EconomySystem.ResourceType.MATERIALS]
	var initial_amount = resource.amount
	
	# Definir produção e consumo iguais
	resource.production_rate = 20.0
	resource.consumption_rate = 20.0
	
	# Simular 10 segundos
	economy_system.update_economy(10.0)
	
	var final_amount = resource.amount
	
	assert_true(abs(final_amount - initial_amount) < 0.1,
		"Resource amount should remain stable with balanced production/consumption")

func test_price_increases_with_scarcity() -> void:
	"""Property: For scarce resources (low amount, high demand), price should increase"""
	var resource = economy_system._resources[EconomySystem.ResourceType.MEDICINE]
	resource.amount = 10.0
	resource.production_rate = 1.0
	resource.consumption_rate = 10.0
	var initial_price = resource.price
	
	# Simular 10 segundos
	economy_system.update_economy(10.0)
	
	var final_price = resource.price
	
	assert_true(final_price > initial_price,
		"Price should increase when resource is scarce")

func test_price_decreases_with_surplus() -> void:
	"""Property: For surplus resources (high amount, low demand), price should decrease"""
	var resource = economy_system._resources[EconomySystem.ResourceType.FUEL]
	resource.amount = 500.0
	resource.production_rate = 50.0
	resource.consumption_rate = 5.0
	var initial_price = resource.price
	
	# Simular 10 segundos
	economy_system.update_economy(10.0)
	
	var final_price = resource.price
	
	assert_true(final_price < initial_price,
		"Price should decrease when resource is in surplus")

func test_add_resource_increases_amount() -> void:
	"""Property: For any resource, adding amount should increase it"""
	var initial_amount = economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD)
	
	var success = economy_system.add_resource(EconomySystem.ResourceType.FOOD, 50.0)
	
	assert_true(success, "Adding resource should succeed")
	assert_equal(economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD), 
		initial_amount + 50.0, "Resource amount should increase by added amount")

func test_remove_resource_decreases_amount() -> void:
	"""Property: For any resource, removing amount should decrease it"""
	var initial_amount = economy_system.get_resource_amount(EconomySystem.ResourceType.WATER)
	
	var success = economy_system.remove_resource(EconomySystem.ResourceType.WATER, 30.0)
	
	assert_true(success, "Removing resource should succeed")
	assert_equal(economy_system.get_resource_amount(EconomySystem.ResourceType.WATER), 
		initial_amount - 30.0, "Resource amount should decrease by removed amount")

func test_remove_resource_fails_if_insufficient() -> void:
	"""Property: For insufficient resources, removal should fail"""
	var initial_amount = economy_system.get_resource_amount(EconomySystem.ResourceType.COMPONENTS)
	
	var success = economy_system.remove_resource(EconomySystem.ResourceType.COMPONENTS, 
		initial_amount + 100.0)
	
	assert_false(success, "Removing more than available should fail")
	assert_equal(economy_system.get_resource_amount(EconomySystem.ResourceType.COMPONENTS), 
		initial_amount, "Resource amount should not change on failed removal")

func test_price_history_tracking() -> void:
	"""Property: For any resource, price history should be tracked"""
	var resource = economy_system._resources[EconomySystem.ResourceType.WEAPONS]
	
	# Definir vários preços
	for i in range(10):
		economy_system.set_resource_price(EconomySystem.ResourceType.WEAPONS, float(i + 1))
	
	assert_equal(resource.price_history.size(), 10,
		"Price history should track all price changes")

func test_price_history_limited_to_100() -> void:
	"""Property: For any resource, price history should be limited to 100 entries"""
	var resource = economy_system._resources[EconomySystem.ResourceType.CAPS]
	
	# Definir 150 preços
	for i in range(150):
		economy_system.set_resource_price(EconomySystem.ResourceType.CAPS, float(i + 1))
	
	assert_equal(resource.price_history.size(), 100,
		"Price history should be limited to 100 entries")

func test_trade_resources_exchanges_correctly() -> void:
	"""Property: For resource trading, value should be conserved"""
	var food_initial = economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD)
	var water_initial = economy_system.get_resource_amount(EconomySystem.ResourceType.WATER)
	
	var food_price = economy_system.get_resource_price(EconomySystem.ResourceType.FOOD)
	var water_price = economy_system.get_resource_price(EconomySystem.ResourceType.WATER)
	
	# Trocar 10 unidades de comida por água
	var water_received = economy_system.trade_resources(
		EconomySystem.ResourceType.FOOD, 10.0, EconomySystem.ResourceType.WATER)
	
	var food_final = economy_system.get_resource_amount(EconomySystem.ResourceType.FOOD)
	var water_final = economy_system.get_resource_amount(EconomySystem.ResourceType.WATER)
	
	assert_equal(food_final, food_initial - 10.0, "Food should decrease by traded amount")
	assert_true(water_final > water_initial, "Water should increase")
	
	# Verificar que o valor foi conservado
	var food_value_lost = 10.0 * food_price
	var water_value_gained = water_received * water_price
	assert_true(abs(food_value_lost - water_value_gained) < 0.1,
		"Value should be conserved in trade")

func test_resource_statistics() -> void:
	"""Property: For any economy state, statistics should accurately reflect it"""
	var stats = economy_system.get_resource_statistics()
	
	assert_equal(stats["total_resources"], 9, "Should have 9 resource types")
	assert_true(stats.has("resources"), "Statistics should include resources")
	assert_equal(stats["resources"].size(), 9, "Should have stats for all 9 resources")
	
	# Verificar que cada recurso tem as informações corretas
	for resource_name in stats["resources"].keys():
		var resource_stats = stats["resources"][resource_name]
		assert_true(resource_stats.has("amount"))
		assert_true(resource_stats.has("production_rate"))
		assert_true(resource_stats.has("consumption_rate"))
		assert_true(resource_stats.has("price"))
		assert_true(resource_stats.has("balance"))
