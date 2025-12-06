## Test: WaterSystem Integration
## Testes de integração para o sistema de água

class_name TestWaterSystemIntegration
extends GdUnitTestSuite

var water_system: WaterSystem
var grid_system: GridSystem
var building_system: BuildingSystem
var citizen_system: CitizenSystem
var event_bus: CityEventBus

func before_each() -> void:
	# Criar sistemas
	water_system = WaterSystem.new()
	grid_system = GridSystem.new()
	building_system = BuildingSystem.new()
	citizen_system = CitizenSystem.new()
	event_bus = CityEventBus.new()
	
	# Configurar sistemas
	var config = CityConfig.new()
	water_system.set_config(config)
	grid_system.set_config(config)
	building_system.set_config(config)
	citizen_system.set_config(config)
	
	# Inicializar grid
	grid_system.set_grid_size(50, 50)
	
	# Conectar sistemas
	water_system.set_systems(grid_system, building_system, citizen_system, event_bus)
	building_system.set_systems(grid_system, null, event_bus)
	citizen_system.set_systems(grid_system, building_system, event_bus)

func after_each() -> void:
	water_system.clear()
	grid_system.clear()

func test_add_water_source() -> void:
	"""Test: Adicionar fonte de água"""
	var pos = Vector2i(10, 10)
	var output = 100.0
	var quality = WaterSystem.WaterQuality.CLEAN
	
	var source_id = water_system.add_water_source(-1, pos, WaterSystem.SourceType.WELL, output, quality)
	
	assert_that(source_id).is_greater_than_or_equal_to(0)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["total_production"]).is_equal(output)
	assert_that(stats["source_count"]).is_equal(1)

func test_add_water_consumer() -> void:
	"""Test: Adicionar consumidor de água"""
	var pos = Vector2i(10, 10)
	var demand = 50.0
	
	var consumer_id = water_system.add_water_consumer(-1, pos, demand)
	
	assert_that(consumer_id).is_greater_than_or_equal_to(0)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["total_demand"]).is_equal(demand)
	assert_that(stats["consumer_count"]).is_equal(1)

func test_water_balance_sufficient() -> void:
	"""Test: Produção suficiente para demanda"""
	# Criar fonte
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	
	# Criar consumidor com demanda menor
	water_system.add_water_consumer(-1, Vector2i(12, 12), 50.0)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["water_deficit"]).is_equal(0.0)
	assert_that(stats["total_supplied"]).is_equal(50.0)

func test_water_shortage() -> void:
	"""Test: Falta de água quando demanda excede produção"""
	# Criar fonte pequena
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 50.0, WaterSystem.WaterQuality.CLEAN)
	
	# Criar consumidor com demanda maior
	water_system.add_water_consumer(-1, Vector2i(12, 12), 100.0)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["water_deficit"]).is_equal(50.0)
	assert_that(stats["total_supplied"]).is_equal(50.0)

func test_pipe_placement() -> void:
	"""Test: Colocar tubulação"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	var success = water_system.place_pipe(from, to)
	
	assert_that(success).is_true()
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["pipe_count"]).is_equal(1)

func test_pipe_too_far() -> void:
	"""Test: Tubulação muito distante deve falhar"""
	var from = Vector2i(10, 10)
	var to = Vector2i(50, 50)  # Muito longe
	
	var success = water_system.place_pipe(from, to)
	
	assert_that(success).is_false()

func test_remove_pipe() -> void:
	"""Test: Remover tubulação"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	water_system.place_pipe(from, to)
	var success = water_system.remove_pipe(from, to)
	
	assert_that(success).is_true()
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["pipe_count"]).is_equal(0)

func test_water_quality_levels() -> void:
	"""Test: Níveis de qualidade da água"""
	# Criar fontes com diferentes qualidades
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 50.0, WaterSystem.WaterQuality.DIRTY)
	water_system.add_water_source(-1, Vector2i(20, 20), WaterSystem.SourceType.PURIFIER, 50.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_source(-1, Vector2i(30, 30), WaterSystem.SourceType.TREATMENT_PLANT, 50.0, WaterSystem.WaterQuality.PURIFIED)
	
	var distribution = water_system.get_quality_distribution()
	
	assert_that(distribution[WaterSystem.WaterQuality.DIRTY]).is_equal(1)
	assert_that(distribution[WaterSystem.WaterQuality.CLEAN]).is_equal(1)
	assert_that(distribution[WaterSystem.WaterQuality.PURIFIED]).is_equal(1)

func test_contamination() -> void:
	"""Test: Contaminação de fonte"""
	var source_id = water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	
	# Contaminar fonte
	water_system.contaminate_source(source_id, 50.0)
	
	var level = water_system.get_contamination_level(source_id)
	assert_that(level).is_equal(50.0)

func test_purification() -> void:
	"""Test: Purificação de fonte"""
	var source_id = water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	
	# Contaminar e depois purificar
	water_system.contaminate_source(source_id, 80.0)
	water_system.purify_source(source_id, 50.0)
	
	var level = water_system.get_contamination_level(source_id)
	assert_that(level).is_equal(30.0)

func test_contamination_affects_quality() -> void:
	"""Test: Contaminação afeta qualidade"""
	var source_id = water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.PURIFIER, 100.0, WaterSystem.WaterQuality.PURIFIED)
	
	var sources = water_system.get_water_sources()
	var source = sources[0]
	
	# Qualidade inicial
	assert_that(source.get_effective_quality()).is_equal(WaterSystem.WaterQuality.PURIFIED)
	
	# Contaminar moderadamente
	water_system.contaminate_source(source_id, 50.0)
	assert_that(source.get_effective_quality()).is_equal(WaterSystem.WaterQuality.CLEAN)
	
	# Contaminar severamente
	water_system.contaminate_source(source_id, 30.0)
	assert_that(source.get_effective_quality()).is_equal(WaterSystem.WaterQuality.DIRTY)

func test_building_water_status() -> void:
	"""Test: Status de água de edifício"""
	# Criar edifício
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY,
		Vector2i(10, 10),
		Vector2i(3, 3)
	)
	building_system.complete_construction(building_id)
	
	# Adicionar fonte e consumidor
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_consumer(building_id, Vector2i(10, 10), 50.0)
	
	var status = water_system.get_building_water_status(building_id)
	
	assert_that(status["is_connected"]).is_true()
	assert_that(status["is_supplied"]).is_true()
	assert_that(status["demand"]).is_equal(50.0)
	assert_that(status["supplied"]).is_equal(50.0)
	assert_that(status["quality"]).is_equal(WaterSystem.WaterQuality.CLEAN)

func test_water_shortage_effects() -> void:
	"""Test: Efeitos de falta de água"""
	# Criar edifício
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY,
		Vector2i(10, 10),
		Vector2i(3, 3)
	)
	building_system.complete_construction(building_id)
	
	# Criar fonte insuficiente
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 20.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_consumer(building_id, Vector2i(10, 10), 100.0)
	
	# Aplicar efeitos
	water_system.apply_water_shortage_effects()
	
	# Verificar que o edifício foi afetado
	var building = building_system.get_building(building_id)
	assert_that(building.is_operational).is_false()

func test_multiple_sources() -> void:
	"""Test: Múltiplas fontes de água"""
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 50.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_source(-1, Vector2i(20, 20), WaterSystem.SourceType.PURIFIER, 50.0, WaterSystem.WaterQuality.PURIFIED)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["total_production"]).is_equal(100.0)
	assert_that(stats["source_count"]).is_equal(2)

func test_multiple_consumers() -> void:
	"""Test: Múltiplos consumidores"""
	water_system.add_water_consumer(-1, Vector2i(10, 10), 30.0)
	water_system.add_water_consumer(-1, Vector2i(20, 20), 40.0)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["total_demand"]).is_equal(70.0)
	assert_that(stats["consumer_count"]).is_equal(2)

func test_source_active_state() -> void:
	"""Test: Estado ativo/inativo de fonte"""
	var source_id = water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	
	# Desativar fonte
	water_system.set_source_active(source_id, false)
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["total_production"]).is_equal(0.0)
	
	# Reativar fonte
	water_system.set_source_active(source_id, true)
	
	stats = water_system.get_water_statistics()
	assert_that(stats["total_production"]).is_equal(100.0)

func test_pipe_leak() -> void:
	"""Test: Vazamento em tubulação"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	water_system.place_pipe(from, to)
	
	# Definir vazamento de 50%
	water_system.set_pipe_leak_rate(from, to, 0.5)
	
	var pipe = water_system.get_pipe_at(from, to)
	assert_that(pipe).is_not_null()
	assert_that(pipe.leak_rate).is_equal(0.5)
	assert_that(pipe.get_effective_capacity()).is_equal(500.0)  # 1000 * 0.5

func test_pipe_repair() -> void:
	"""Test: Reparo de tubulação"""
	var from = Vector2i(10, 10)
	var to = Vector2i(15, 15)
	
	water_system.place_pipe(from, to)
	water_system.set_pipe_leak_rate(from, to, 0.8)
	
	# Reparar
	water_system.repair_pipe(from, to)
	
	var pipe = water_system.get_pipe_at(from, to)
	assert_that(pipe.leak_rate).is_equal(0.0)

func test_shortage_report() -> void:
	"""Test: Relatório de falta de água"""
	# Criar situação de falta
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 50.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_consumer(-1, Vector2i(12, 12), 100.0)
	
	var report = water_system.get_shortage_report()
	
	assert_that(report["has_shortage"]).is_true()
	assert_that(report["deficit"]).is_equal(50.0)
	assert_that(report["deficit_percentage"]).is_equal(50.0)
	assert_that(report["total_affected"]).is_greater_than(0)

func test_quality_upgrade() -> void:
	"""Test: Melhoria de qualidade"""
	var source_id = water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.DIRTY)
	
	# Melhorar qualidade
	var success = water_system.upgrade_source_quality(source_id, WaterSystem.WaterQuality.CLEAN)
	
	assert_that(success).is_true()
	
	var sources = water_system.get_water_sources()
	assert_that(sources[0].quality).is_equal(WaterSystem.WaterQuality.CLEAN)

func test_clear_system() -> void:
	"""Test: Limpar sistema"""
	water_system.add_water_source(-1, Vector2i(10, 10), WaterSystem.SourceType.WELL, 100.0, WaterSystem.WaterQuality.CLEAN)
	water_system.add_water_consumer(-1, Vector2i(12, 12), 50.0)
	
	water_system.clear()
	
	var stats = water_system.get_water_statistics()
	assert_that(stats["source_count"]).is_equal(0)
	assert_that(stats["consumer_count"]).is_equal(0)
	assert_that(stats["total_production"]).is_equal(0.0)
	assert_that(stats["total_demand"]).is_equal(0.0)
