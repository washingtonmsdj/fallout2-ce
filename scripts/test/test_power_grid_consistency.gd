## Test: Power Grid Consistency
## **Feature: city-map-system, Property 8: Power Grid Consistency**
## **Validates: Requirements 19.3, 19.4**
##
## Property: For any building marked as power_connected, there SHALL exist 
## a valid path through power conduits to a power source

class_name TestPowerGridConsistency
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

func test_property_power_grid_consistency() -> void:
	"""
	Property Test: Power Grid Consistency
	
	For any building marked as power_connected, there must exist a valid path
	to a power source through the power grid.
	"""
	var iterations = 100
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(iterations):
		# Limpar estado anterior
		power_system.clear()
		
		# Gerar configuração aleatória
		var num_sources = rng.randi_range(1, 5)
		var num_consumers = rng.randi_range(1, 10)
		var num_conduits = rng.randi_range(0, 15)
		
		var sources: Array = []
		var consumers: Array = []
		
		# Criar fontes de energia
		for j in range(num_sources):
			var pos = Vector2i(
				rng.randi_range(5, 45),
				rng.randi_range(5, 45)
			)
			var output = rng.randf_range(50.0, 500.0)
			var source_id = power_system.add_power_source(-1, pos, output)
			sources.append({"id": source_id, "pos": pos})
		
		# Criar consumidores
		for j in range(num_consumers):
			var pos = Vector2i(
				rng.randi_range(5, 45),
				rng.randi_range(5, 45)
			)
			var demand = rng.randf_range(10.0, 100.0)
			var consumer_id = power_system.add_power_consumer(-1, pos, demand)
			consumers.append({"id": consumer_id, "pos": pos})
		
		# Criar alguns condutos aleatórios
		for j in range(num_conduits):
			var from_idx = rng.randi_range(0, sources.size() + consumers.size() - 1)
			var to_idx = rng.randi_range(0, sources.size() + consumers.size() - 1)
			
			if from_idx == to_idx:
				continue
			
			var all_nodes = sources + consumers
			var from_pos = all_nodes[from_idx]["pos"]
			var to_pos = all_nodes[to_idx]["pos"]
			
			# Tentar colocar conduto (pode falhar se muito longe)
			power_system.place_conduit(from_pos, to_pos)
		
		# VERIFICAR PROPRIEDADE:
		# Para cada consumidor marcado como conectado, deve haver caminho para fonte
		var all_consumers = power_system.get_power_consumers()
		
		for consumer in all_consumers:
			if consumer.is_connected:
				# Deve haver pelo menos uma fonte alcançável
				var has_path_to_source = false
				
				for source_data in sources:
					var source = power_system._power_sources.get(source_data["id"])
					if source != null:
						if power_system._has_path_to_source(consumer.position, source.position):
							has_path_to_source = true
							break
				
				assert_that(has_path_to_source).is_true()

func test_direct_connection_is_valid() -> void:
	"""
	Test: Conexão direta dentro do alcance deve ser válida
	"""
	# Criar fonte
	var source_pos = Vector2i(10, 10)
	var source_id = power_system.add_power_source(-1, source_pos, 100.0)
	
	# Criar consumidor próximo (dentro do alcance)
	var consumer_pos = Vector2i(12, 12)
	var consumer_id = power_system.add_power_consumer(-1, consumer_pos, 50.0)
	
	# Verificar que o consumidor está conectado
	var consumers = power_system.get_power_consumers()
	var consumer = consumers[0]
	
	assert_that(consumer.is_connected).is_true()

func test_distant_connection_requires_conduit() -> void:
	"""
	Test: Conexão distante requer conduto
	"""
	# Criar fonte
	var source_pos = Vector2i(10, 10)
	var source_id = power_system.add_power_source(-1, source_pos, 100.0)
	
	# Criar consumidor distante (fora do alcance)
	var consumer_pos = Vector2i(30, 30)
	var consumer_id = power_system.add_power_consumer(-1, consumer_pos, 50.0)
	
	# Verificar que o consumidor NÃO está conectado
	var consumers = power_system.get_power_consumers()
	var consumer = consumers[0]
	
	assert_that(consumer.is_connected).is_false()
	
	# Adicionar conduto intermediário
	var mid_pos = Vector2i(20, 20)
	power_system.place_conduit(source_pos, mid_pos)
	power_system.place_conduit(mid_pos, consumer_pos)
	
	# Agora deve estar conectado
	consumers = power_system.get_power_consumers()
	consumer = consumers[0]
	
	assert_that(consumer.is_connected).is_true()

func test_disconnected_consumer_not_marked_connected() -> void:
	"""
	Test: Consumidor sem caminho para fonte não deve ser marcado como conectado
	"""
	# Criar duas redes isoladas
	
	# Rede 1: fonte + consumidor
	var source1_pos = Vector2i(10, 10)
	power_system.add_power_source(-1, source1_pos, 100.0)
	var consumer1_pos = Vector2i(12, 12)
	power_system.add_power_consumer(-1, consumer1_pos, 50.0)
	
	# Rede 2: apenas consumidor (sem fonte)
	var consumer2_pos = Vector2i(40, 40)
	power_system.add_power_consumer(-1, consumer2_pos, 50.0)
	
	# Verificar estados
	var consumers = power_system.get_power_consumers()
	
	var consumer1_connected = false
	var consumer2_connected = false
	
	for consumer in consumers:
		if consumer.position == consumer1_pos:
			consumer1_connected = consumer.is_connected
		elif consumer.position == consumer2_pos:
			consumer2_connected = consumer.is_connected
	
	# Consumidor 1 deve estar conectado
	assert_that(consumer1_connected).is_true()
	
	# Consumidor 2 NÃO deve estar conectado
	assert_that(consumer2_connected).is_false()

func test_conduit_creates_valid_path() -> void:
	"""
	Test: Conduto cria caminho válido entre pontos
	"""
	var pos1 = Vector2i(10, 10)
	var pos2 = Vector2i(15, 15)
	
	# Adicionar fonte em pos1
	power_system.add_power_source(-1, pos1, 100.0)
	
	# Adicionar consumidor em pos2 (pode estar fora do alcance direto)
	power_system.add_power_consumer(-1, pos2, 50.0)
	
	# Adicionar conduto
	var success = power_system.place_conduit(pos1, pos2)
	
	if success:
		# Se o conduto foi criado, deve haver caminho
		var has_path = power_system._has_path_to_source(pos2, pos1)
		assert_that(has_path).is_true()

func test_removed_conduit_breaks_connection() -> void:
	"""
	Test: Remover conduto quebra conexão se era o único caminho
	"""
	# Criar cadeia: fonte -> mid -> consumidor
	var source_pos = Vector2i(10, 10)
	var mid_pos = Vector2i(20, 20)
	var consumer_pos = Vector2i(30, 30)
	
	power_system.add_power_source(-1, source_pos, 100.0)
	power_system.add_power_consumer(-1, consumer_pos, 50.0)
	
	# Criar condutos
	power_system.place_conduit(source_pos, mid_pos)
	power_system.place_conduit(mid_pos, consumer_pos)
	
	# Verificar que está conectado
	var consumers = power_system.get_power_consumers()
	assert_that(consumers[0].is_connected).is_true()
	
	# Remover um conduto
	power_system.remove_conduit(mid_pos, consumer_pos)
	
	# Verificar que não está mais conectado
	consumers = power_system.get_power_consumers()
	assert_that(consumers[0].is_connected).is_false()

func test_multiple_paths_maintain_connection() -> void:
	"""
	Test: Múltiplos caminhos mantêm conexão mesmo se um for removido
	"""
	# Criar rede com redundância
	var source_pos = Vector2i(10, 10)
	var consumer_pos = Vector2i(20, 20)
	var alt_pos = Vector2i(15, 15)
	
	power_system.add_power_source(-1, source_pos, 100.0)
	power_system.add_power_consumer(-1, consumer_pos, 50.0)
	
	# Criar dois caminhos
	power_system.place_conduit(source_pos, consumer_pos)  # Caminho direto
	power_system.place_conduit(source_pos, alt_pos)       # Caminho alternativo
	power_system.place_conduit(alt_pos, consumer_pos)
	
	# Verificar conexão
	var consumers = power_system.get_power_consumers()
	assert_that(consumers[0].is_connected).is_true()
	
	# Remover caminho direto
	power_system.remove_conduit(source_pos, consumer_pos)
	
	# Ainda deve estar conectado via caminho alternativo
	consumers = power_system.get_power_consumers()
	assert_that(consumers[0].is_connected).is_true()
