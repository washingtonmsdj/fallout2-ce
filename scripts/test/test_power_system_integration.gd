## Test: PowerSystem Integration
## Testes de integração para o sistema de energia

class_name TestPowerSystemIntegration
extends GdUnitTestSuite

var power_system: PowerSystem
var grid_system: GridSystem
var building_system: BuildingSystem
var event_bus: CityEventBus

func before_each() -> void:
	# Criar sistemas
	power_system = PowerSystem.new()
	grid_system = GridSystem.new()
	building_system = BuildingSystem.new()
	event_bus = CityEventBus.new()
	
	# Configurar sistemas
	var config = CityConfig.new()
	power_system.set_config(config)
	grid_system.set_config(config)
	building_system.set_config(config)
	
	# Inicializar grid
	grid_system.set_grid_size(50, 50)
	
	# Conectar sistemas
	power_system.set_systems(grid_system, building_system, event_bus)
	building_system.set_systems(grid_system, null, event_bus)

func after_each() -> void:
	power_system.clear()
	grid_system.clear()

func test_add_power_source() -> void:
	"""Test: Adicionar fonte de energia"""
	var pos = Vector2i(10, 10)
	var output = 100.0
	
	var source_id = power_system.add_power_source(-1, pos, output)
	
	assert_that(source_id).is_greater_than_or_equal_to(0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_generation"]).is_equal(output)
	assert_that(stats["source_count"]).is_equal(1)

func test_add_power_consumer() -> void:
	"""Test: Adicionar consumidor de energia"""
	var pos = Vector2i(10, 10)
	var demand = 50.0
	
	var consumer_id = power_system.add_power_consumer(-1, pos, demand)
	
	assert_that(consumer_id).is_greater_than_or_equal_to(0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_demand"]).is_equal(demand)
	assert_that(stats["consumer_count"]).is_equal(1)

func test_power_balance_sufficient() -> void:
	"""Test: Geração suficiente para demanda"""
	# Criar fonte
	power_system.add_power_source(-1, Vector2i(10, 10), 100.0)
	
	# Criar consumidor com demanda menor
	power_system.add_power_consumer(-1, Vector2i(12, 12), 50.0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["power_deficit"]).is_equal(0.0)
	assert_that(stats["total_supplied"]).is_equal(50.0)

func test_power_shortage() -> void:
	"""Test: Falta de energia quando demanda excede geração"""
	# Criar fonte pequena
	power_system.add_power_source(-1, Vector2i(10, 10), 50.0)
	
	# Criar consumidor com demanda maior
	power_system.add_power_consumer(-1, Vector2i(12, 12), 100.0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["power_deficit"]).is_equal(50.0)
	assert_that(stats["total_supplied"]).is_equal(50.0)

func test_conduit_placement() -> void:
	"""Test: Colocar conduto de energia"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	var success = power_system.place_conduit(from, to)
	
	assert_that(success).is_true()
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["conduit_count"]).is_equal(1)

func test_conduit_too_far() -> void:
	"""Test: Conduto muito distante deve falhar"""
	var from = Vector2i(10, 10)
	var to = Vector2i(50, 50)  # Muito longe
	
	var success = power_system.place_conduit(from, to)
	
	assert_that(success).is_false()

func test_remove_conduit() -> void:
	"""Test: Remover conduto"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	power_system.place_conduit(from, to)
	var success = power_system.remove_conduit(from, to)
	
	assert_that(success).is_true()
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["conduit_count"]).is_equal(0)

func test_building_power_status() -> void:
	"""Test: Status de energia de edifício"""
	# Criar edifício
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY,
		Vector2i(10, 10),
		Vector2i(3, 3)
	)
	building_system.complete_construction(building_id)
	
	# Adicionar fonte e consumidor
	power_system.add_power_source(-1, Vector2i(10, 10), 100.0)
	power_system.add_power_consumer(building_id, Vector2i(10, 10), 50.0)
	
	var status = power_system.get_building_power_status(building_id)
	
	assert_that(status["is_connected"]).is_true()
	assert_that(status["is_powered"]).is_true()
	assert_that(status["demand"]).is_equal(50.0)
	assert_that(status["supplied"]).is_equal(50.0)

func test_power_shortage_effects() -> void:
	"""Test: Efeitos de falta de energia"""
	# Criar edifício
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY,
		Vector2i(10, 10),
		Vector2i(3, 3)
	)
	building_system.complete_construction(building_id)
	
	# Criar fonte insuficiente
	power_system.add_power_source(-1, Vector2i(10, 10), 30.0)
	power_system.add_power_consumer(building_id, Vector2i(10, 10), 100.0)
	
	# Aplicar efeitos
	power_system.apply_power_shortage_effects()
	
	# Verificar que o edifício foi afetado
	var building = building_system.get_building(building_id)
	assert_that(building.is_operational).is_false()

func test_multiple_sources() -> void:
	"""Test: Múltiplas fontes de energia"""
	power_system.add_power_source(-1, Vector2i(10, 10), 50.0)
	power_system.add_power_source(-1, Vector2i(20, 20), 50.0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_generation"]).is_equal(100.0)
	assert_that(stats["source_count"]).is_equal(2)

func test_multiple_consumers() -> void:
	"""Test: Múltiplos consumidores"""
	power_system.add_power_consumer(-1, Vector2i(10, 10), 30.0)
	power_system.add_power_consumer(-1, Vector2i(20, 20), 40.0)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_demand"]).is_equal(70.0)
	assert_that(stats["consumer_count"]).is_equal(2)

func test_source_efficiency() -> void:
	"""Test: Eficiência de fonte de energia"""
	var source_id = power_system.add_power_source(-1, Vector2i(10, 10), 100.0)
	
	# Reduzir eficiência para 50%
	power_system.set_source_efficiency(source_id, 0.5)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_generation"]).is_equal(50.0)

func test_source_active_state() -> void:
	"""Test: Estado ativo/inativo de fonte"""
	var source_id = power_system.add_power_source(-1, Vector2i(10, 10), 100.0)
	
	# Desativar fonte
	power_system.set_source_active(source_id, false)
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["total_generation"]).is_equal(0.0)
	
	# Reativar fonte
	power_system.set_source_active(source_id, true)
	
	stats = power_system.get_power_statistics()
	assert_that(stats["total_generation"]).is_equal(100.0)

func test_shortage_report() -> void:
	"""Test: Relatório de falta de energia"""
	# Criar situação de falta
	power_system.add_power_source(-1, Vector2i(10, 10), 50.0)
	power_system.add_power_consumer(-1, Vector2i(12, 12), 100.0)
	
	var report = power_system.get_shortage_report()
	
	assert_that(report["has_shortage"]).is_true()
	assert_that(report["deficit"]).is_equal(50.0)
	assert_that(report["deficit_percentage"]).is_equal(50.0)
	assert_that(report["total_affected"]).is_greater_than(0)

func test_clear_system() -> void:
	"""Test: Limpar sistema"""
	power_system.add_power_source(-1, Vector2i(10, 10), 100.0)
	power_system.add_power_consumer(-1, Vector2i(12, 12), 50.0)
	
	power_system.clear()
	
	var stats = power_system.get_power_statistics()
	assert_that(stats["source_count"]).is_equal(0)
	assert_that(stats["consumer_count"]).is_equal(0)
	assert_that(stats["total_generation"]).is_equal(0.0)
	assert_that(stats["total_demand"]).is_equal(0.0)
