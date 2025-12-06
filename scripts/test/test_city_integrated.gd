## Script de Teste Integrado - City Map System
## Integra todos os sistemas: Grid, Road, Building, Citizen, Economy, Faction
extends Node2D

# Sistemas principais
var city_manager
var grid_system
var road_system
var zone_system
var building_system
var citizen_system
var economy_system
var faction_system
var event_bus
var shared_config

# Renderer
var city_renderer

# UI References
@onready var camera: Camera2D = $Camera2D
@onready var population_label: Label = %PopulationLabel
@onready var buildings_label: Label = %BuildingsLabel
@onready var food_label: Label = %FoodLabel
@onready var water_label: Label = %WaterLabel
@onready var caps_label: Label = %CapsLabel
@onready var materials_label: Label = %MaterialsLabel
@onready var happiness_label: Label = %HappinessLabel
@onready var speed_label: Label = %SpeedLabel

# Configurações
var game_speed: float = 1.0
var zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 2.0
var camera_smoothing: float = 5.0

# Estado
var selected_building_type: int = 0  # SMALL_HOUSE
var selected_zone_type: int = 0  # RESIDENTIAL
var is_building_mode: bool = false
var is_zone_mode: bool = false

func _ready() -> void:
	print("🏙️ Initializing City Map System...")
	
	# Carregar scripts
	var CityConfigScript = load("res://scripts/city/core/city_config.gd")
	var EventBusScript = load("res://scripts/city/core/event_bus.gd")
	var GridSystemScript = load("res://scripts/city/systems/grid_system.gd")
	var RoadSystemScript = load("res://scripts/city/systems/road_system.gd")
	var ZoneSystemScript = load("res://scripts/city/systems/zone_system.gd")
	var BuildingSystemScript = load("res://scripts/city/systems/building_system.gd")
	var CitizenSystemScript = load("res://scripts/city/systems/citizen_system.gd")
	var EconomySystemScript = load("res://scripts/city/systems/economy_system.gd")
	var FactionSystemScript = load("res://scripts/city/systems/faction_system.gd")
	
	# Criar config compartilhado
	shared_config = CityConfigScript.new()
	
	# Criar EventBus
	event_bus = EventBusScript.new()
	add_child(event_bus)
	
	# Criar GridSystem
	grid_system = GridSystemScript.new()
	add_child(grid_system)
	if grid_system.has_method("set_config"):
		grid_system.set_config(shared_config)
	grid_system.set_grid_size(100, 100)
	
	# Criar RoadSystem
	road_system = RoadSystemScript.new()
	add_child(road_system)
	if road_system.has_method("set_config"):
		road_system.set_config(shared_config)
	road_system.set_grid_system(grid_system)
	
	# Criar ZoneSystem
	zone_system = ZoneSystemScript.new()
	add_child(zone_system)
	if zone_system.has_method("set_config"):
		zone_system.set_config(shared_config)
	zone_system.set_grid_system(grid_system)
	
	# Criar BuildingSystem
	building_system = BuildingSystemScript.new()
	add_child(building_system)
	if building_system.has_method("set_config"):
		building_system.set_config(shared_config)
	building_system.set_systems(grid_system, zone_system, event_bus)
	
	# Criar CitizenSystem
	citizen_system = CitizenSystemScript.new()
	add_child(citizen_system)
	if citizen_system.has_method("set_config"):
		citizen_system.set_config(shared_config)
	citizen_system.set_systems(grid_system, building_system, event_bus)
	
	# Criar EconomySystem
	economy_system = EconomySystemScript.new()
	add_child(economy_system)
	if economy_system.has_method("set_config"):
		economy_system.set_config(shared_config)
	economy_system.set_systems(event_bus, building_system)
	
	# Criar FactionSystem
	faction_system = FactionSystemScript.new()
	add_child(faction_system)
	if faction_system.has_method("set_config"):
		faction_system.set_config(shared_config)
	faction_system.set_systems(grid_system, event_bus)
	
	# Conectar sinais
	_connect_signals()
	
	# Criar Renderer
	print("\n🎨 Creating renderer...")
	var RendererScript = load("res://scripts/city/rendering/integrated_renderer.gd")
	city_renderer = RendererScript.new()
	add_child(city_renderer)
	city_renderer.set_systems(grid_system, road_system, building_system, citizen_system, zone_system)
	print("✅ Renderer created!")
	
	# Inicializar cidade
	_initialize_city()
	
	# Posicionar câmera no centro
	_setup_camera()
	
	print("✅ City Map System initialized!")
	print("📊 Grid: 100x100")
	print("🛣️ Roads: %d" % road_system.get_road_count())
	print("🏢 Buildings: %d" % building_system.get_building_count())
	print("👥 Citizens: %d" % citizen_system.get_citizen_count())
	print("💰 Resources: 9 types")
	print("⚔️ Factions: %d" % faction_system.get_faction_count())

func _initialize_city() -> void:
	"""Inicializa a cidade com estrutura básica"""
	
	# Criar algumas estradas
	print("\n🛣️ Creating roads...")
	var road1 = road_system.create_road(Vector2i(10, 50), Vector2i(90, 50), 1)  # PAVED_ROAD
	var road2 = road_system.create_road(Vector2i(50, 10), Vector2i(50, 90), 1)  # PAVED_ROAD
	print("✅ Created %d roads" % road_system.get_road_count())
	
	# Criar zonas
	print("\n🏘️ Creating zones...")
	var residential_tiles = []
	for x in range(20, 40):
		for y in range(20, 40):
			residential_tiles.append(Vector2i(x, y))
	zone_system.create_zone(residential_tiles, 0)  # RESIDENTIAL
	
	var commercial_tiles = []
	for x in range(60, 80):
		for y in range(20, 40):
			commercial_tiles.append(Vector2i(x, y))
	zone_system.create_zone(commercial_tiles, 1)  # COMMERCIAL
	
	print("✅ Created %d zones" % zone_system.get_zone_count())
	
	# Criar alguns edifícios
	print("\n🏢 Creating buildings...")
	var house1 = building_system.construct_building(0, Vector2i(25, 25), Vector2i(3, 3))  # SMALL_HOUSE
	var house2 = building_system.construct_building(1, Vector2i(30, 30), Vector2i(4, 4))  # MEDIUM_HOUSE
	var shop = building_system.construct_building(4, Vector2i(65, 25), Vector2i(3, 3))  # SHOP
	var farm = building_system.construct_building(12, Vector2i(25, 50), Vector2i(5, 5))  # FARM
	
	print("✅ Created %d buildings" % building_system.get_building_count())
	
	# Criar cidadãos
	print("\n👥 Creating citizens...")
	for i in range(5):
		var citizen_id = citizen_system.spawn_citizen("Citizen_%d" % i, Vector2i(50 + i, 50))
		
		# Atribuir casa
		if i < 2:
			citizen_system.assign_home(citizen_id, house1)
		else:
			citizen_system.assign_home(citizen_id, house2)
		
		# Atribuir trabalho
		if i < 1:
			citizen_system.assign_job(citizen_id, shop)
		else:
			citizen_system.assign_job(citizen_id, farm)
		
		# Adicionar skills
		citizen_system.set_citizen_skill(citizen_id, 0, randi_range(30, 80))
		citizen_system.add_trait(citizen_id, "hardworking")
	
	print("✅ Created %d citizens" % citizen_system.get_citizen_count())
	
	# Criar facções
	print("\n⚔️ Creating factions...")
	var player_faction = faction_system.create_faction("Player Settlement", Color.GREEN, true)
	var rival_faction = faction_system.create_faction("Rival Faction", Color.RED, false)
	
	# Reivindicar território
	var player_territory = []
	for x in range(10, 50):
		for y in range(10, 50):
			player_territory.append(Vector2i(x, y))
	faction_system.claim_territory(player_faction, player_territory)
	
	print("✅ Created %d factions" % faction_system.get_faction_count())
	
	# Inicializar economia
	print("\n💰 Initializing economy...")
	economy_system.add_resource(0, 100.0)  # FOOD
	economy_system.add_resource(1, 100.0)  # WATER
	economy_system.add_resource(2, 500.0)  # CAPS
	economy_system.add_resource(3, 200.0)  # MATERIALS
	print("✅ Economy initialized")

func _connect_signals() -> void:
	"""Conecta sinais dos sistemas"""
	if event_bus:
		event_bus.building_constructed.connect(_on_building_constructed)
		event_bus.citizen_spawned.connect(_on_citizen_spawned)
		event_bus.resource_changed.connect(_on_resource_changed)
		event_bus.faction_territory_claimed.connect(_on_faction_territory_claimed)

func _process(delta: float) -> void:
	# Aplicar velocidade do jogo
	Engine.time_scale = game_speed
	
	# Movimento da câmera
	var move_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1
	
	if move_dir != Vector2.ZERO:
		camera.position += move_dir.normalized() * 400.0 * delta
	
	# Atualizar sistemas
	citizen_system.update_citizen_needs(delta)
	economy_system.update_economy(delta)
	
	# Atualizar UI
	_update_ui()
	
	# Processar input
	_handle_input()

func _handle_input() -> void:
	"""Processa input do jogador"""
	if Input.is_action_just_pressed("ui_accept"):
		_toggle_building_mode()
	
	if Input.is_action_just_pressed("ui_cancel"):
		is_building_mode = false
		is_zone_mode = false

func _input(event: InputEvent) -> void:
	# Zoom com scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom + Vector2(zoom_speed, zoom_speed)).clamp(
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom - Vector2(zoom_speed, zoom_speed)).clamp(
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)

func _setup_camera() -> void:
	"""Posiciona câmera no centro da cidade"""
	if city_renderer:
		var center = city_renderer.grid_to_iso(Vector2(50, 50))
		camera.position = center
		camera.zoom = Vector2(0.5, 0.5)
		print("📷 Camera at: %s" % camera.position)

func _toggle_building_mode() -> void:
	"""Alterna modo de construção"""
	is_building_mode = !is_building_mode
	print("🔨 Building mode: %s" % ("ON" if is_building_mode else "OFF"))

func _update_ui() -> void:
	"""Atualiza UI com dados dos sistemas"""
	var citizen_stats = citizen_system.get_citizen_statistics()
	var building_stats = building_system.get_building_statistics()
	var economy_stats = economy_system.get_resource_statistics()
	
	population_label.text = "👥 Pop: %d" % citizen_stats["alive_citizens"]
	buildings_label.text = "🏗️ Build: %d" % building_stats["total_buildings"]
	
	food_label.text = "🍖 %.0f" % economy_system.get_resource_amount(0)  # FOOD
	water_label.text = "💧 %.0f" % economy_system.get_resource_amount(1)  # WATER
	caps_label.text = "💰 %.0f" % economy_system.get_resource_amount(2)  # CAPS
	materials_label.text = "🧱 %.0f" % economy_system.get_resource_amount(3)  # MATERIALS
	
	happiness_label.text = "😊 %.0f%%" % citizen_stats["average_happiness"]
	speed_label.text = "⏱️ %.1fx" % game_speed

func _on_building_constructed(building_id: int, position: Vector2i) -> void:
	"""Callback quando edifício é construído"""
	var building = building_system.get_building(building_id)
	if building:
		print("🏢 Building constructed: type %d at %s" % [building.building_type, position])

func _on_citizen_spawned(citizen_id: int) -> void:
	"""Callback quando cidadão é criado"""
	var citizen = citizen_system.get_citizen(citizen_id)
	if citizen:
		print("👤 Citizen spawned: %s" % citizen.name)

func _on_resource_changed(resource_type: int, old_amount: float, new_amount: float) -> void:
	"""Callback quando recurso muda"""
	pass  # Silencioso para não poluir console

func _on_faction_territory_claimed(faction_id: int, tiles: Array) -> void:
	"""Callback quando território de facção é reivindicado"""
	var faction = faction_system.get_faction(faction_id)
	if faction:
		print("⚔️ %s claimed %d tiles" % [faction.name, tiles.size()])

func get_debug_info() -> String:
	"""Retorna informações de debug"""
	var info = ""
	info += "=== CITY MAP SYSTEM DEBUG ===\n"
	info += "Grid: %dx%d\n" % [grid_system._grid_width, grid_system._grid_height]
	info += "Roads: %d\n" % road_system.get_road_count()
	info += "Zones: %d\n" % zone_system.get_zone_count()
	info += "Buildings: %d\n" % building_system.get_building_count()
	info += "Citizens: %d\n" % citizen_system.get_citizen_count()
	info += "Factions: %d\n" % faction_system.get_faction_count()
	info += "Game Speed: %.1fx\n" % game_speed
	return info

func print_debug_info() -> void:
	"""Imprime informações de debug"""
	print(get_debug_info())
