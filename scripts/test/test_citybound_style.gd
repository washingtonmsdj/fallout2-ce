## Teste do Sistema de Cidade estilo Citybound
## Demonstra renderização procedural similar ao Citybound
extends Node2D

# Sistemas
var grid_system
var road_system
var zone_system
var building_system
var citizen_system
var economy_system
var event_bus
var shared_config

# Renderer estilo Citybound
var city_renderer

# UI
@onready var camera: Camera2D = $Camera2D
@onready var info_label: Label = $UI/InfoPanel/InfoLabel
@onready var stats_label: Label = $UI/InfoPanel/StatsLabel

# Controles
var game_speed: float = 1.0
var zoom_level: float = 0.6
var camera_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	print("============================================================")
	print("🏙️ CITYBOUND-STYLE CITY RENDERER TEST")
	print("============================================================")
	
	_initialize_systems()
	_create_city()
	_setup_camera()
	
	print("\n✅ City initialized!")
	print("📊 Buildings: %d" % building_system.get_building_count())
	print("👥 Citizens: %d" % citizen_system.get_citizen_count())
	print("🛣️ Roads: %d" % road_system.get_road_count())
	print("\n🎮 Controls:")
	print("  WASD/Arrows - Move camera")
	print("  Mouse wheel - Zoom")
	print("  Space - Add random building")
	print("  C - Add citizen")
	print("  +/- - Game speed")

func _initialize_systems() -> void:
	"""Inicializa todos os sistemas da cidade"""
	
	# Carregar scripts
	var CityConfigScript = load("res://scripts/city/core/city_config.gd")
	var EventBusScript = load("res://scripts/city/core/event_bus.gd")
	var GridSystemScript = load("res://scripts/city/systems/grid_system.gd")
	var RoadSystemScript = load("res://scripts/city/systems/road_system.gd")
	var ZoneSystemScript = load("res://scripts/city/systems/zone_system.gd")
	var BuildingSystemScript = load("res://scripts/city/systems/building_system.gd")
	var CitizenSystemScript = load("res://scripts/city/systems/citizen_system.gd")
	var EconomySystemScript = load("res://scripts/city/systems/economy_system.gd")
	
	# Config compartilhado
	shared_config = CityConfigScript.new()
	
	# EventBus
	event_bus = EventBusScript.new()
	add_child(event_bus)
	
	# Grid 100x100
	grid_system = GridSystemScript.new()
	add_child(grid_system)
	if grid_system.has_method("set_config"):
		grid_system.set_config(shared_config)
	grid_system.set_grid_size(100, 100)
	
	# Roads
	road_system = RoadSystemScript.new()
	add_child(road_system)
	if road_system.has_method("set_config"):
		road_system.set_config(shared_config)
	road_system.set_grid_system(grid_system)
	
	# Zones
	zone_system = ZoneSystemScript.new()
	add_child(zone_system)
	if zone_system.has_method("set_config"):
		zone_system.set_config(shared_config)
	zone_system.set_grid_system(grid_system)
	
	# Buildings
	building_system = BuildingSystemScript.new()
	add_child(building_system)
	if building_system.has_method("set_config"):
		building_system.set_config(shared_config)
	building_system.set_systems(grid_system, zone_system, event_bus)
	
	# Citizens
	citizen_system = CitizenSystemScript.new()
	add_child(citizen_system)
	if citizen_system.has_method("set_config"):
		citizen_system.set_config(shared_config)
	citizen_system.set_systems(grid_system, building_system, event_bus)
	
	# Economy
	economy_system = EconomySystemScript.new()
	add_child(economy_system)
	if economy_system.has_method("set_config"):
		economy_system.set_config(shared_config)
	economy_system.set_systems(event_bus, building_system)
	
	# Renderer estilo Citybound
	var RendererScript = load("res://scripts/city/rendering/citybound_renderer.gd")
	city_renderer = RendererScript.new()
	add_child(city_renderer)
	city_renderer.set_systems(grid_system, road_system, building_system, citizen_system, zone_system)
	
	print("✅ All systems initialized")

func _create_city() -> void:
	"""Cria uma cidade de exemplo com vários tipos de edifícios"""
	
	# === ESTRADAS ===
	print("\n🛣️ Creating roads...")
	
	# Estrada principal horizontal
	road_system.create_road(Vector2i(10, 50), Vector2i(90, 50), 1)
	# Estrada principal vertical
	road_system.create_road(Vector2i(50, 10), Vector2i(50, 90), 1)
	# Estradas secundárias
	road_system.create_road(Vector2i(20, 30), Vector2i(80, 30), 0)
	road_system.create_road(Vector2i(20, 70), Vector2i(80, 70), 0)
	road_system.create_road(Vector2i(30, 20), Vector2i(30, 80), 0)
	road_system.create_road(Vector2i(70, 20), Vector2i(70, 80), 0)
	
	# === ZONAS ===
	print("🏘️ Creating zones...")
	
	# Zona residencial (noroeste)
	var residential_tiles = []
	for x in range(15, 28):
		for y in range(15, 28):
			residential_tiles.append(Vector2i(x, y))
	zone_system.create_zone(residential_tiles, 0)  # RESIDENTIAL
	
	# Zona comercial (nordeste)
	var commercial_tiles = []
	for x in range(55, 68):
		for y in range(15, 28):
			commercial_tiles.append(Vector2i(x, y))
	zone_system.create_zone(commercial_tiles, 1)  # COMMERCIAL
	
	# Zona industrial (sudeste)
	var industrial_tiles = []
	for x in range(55, 68):
		for y in range(55, 68):
			industrial_tiles.append(Vector2i(x, y))
	zone_system.create_zone(industrial_tiles, 2)  # INDUSTRIAL
	
	# Zona agrícola (sudoeste)
	var agricultural_tiles = []
	for x in range(15, 28):
		for y in range(55, 68):
			agricultural_tiles.append(Vector2i(x, y))
	zone_system.create_zone(agricultural_tiles, 3)  # AGRICULTURAL
	
	# === EDIFÍCIOS ===
	print("🏢 Creating buildings...")
	
	# Casas na zona residencial
	building_system.construct_building(0, Vector2i(17, 17), Vector2i(3, 3))  # SMALL_HOUSE
	building_system.construct_building(1, Vector2i(22, 17), Vector2i(4, 3))  # MEDIUM_HOUSE
	building_system.construct_building(2, Vector2i(17, 22), Vector2i(4, 4))  # LARGE_HOUSE
	building_system.construct_building(3, Vector2i(22, 22), Vector2i(5, 4))  # APARTMENT
	
	# Lojas na zona comercial
	building_system.construct_building(4, Vector2i(57, 17), Vector2i(4, 3))  # SHOP
	building_system.construct_building(5, Vector2i(62, 17), Vector2i(5, 4))  # MARKET
	building_system.construct_building(4, Vector2i(57, 22), Vector2i(3, 3))  # SHOP
	building_system.construct_building(4, Vector2i(62, 22), Vector2i(4, 3))  # SHOP
	
	# Indústrias na zona industrial
	building_system.construct_building(7, Vector2i(57, 57), Vector2i(6, 5))  # FACTORY
	building_system.construct_building(6, Vector2i(57, 63), Vector2i(5, 4))  # WAREHOUSE
	building_system.construct_building(8, Vector2i(63, 57), Vector2i(4, 4))  # WORKSHOP
	
	# Fazendas na zona agrícola
	building_system.construct_building(12, Vector2i(17, 57), Vector2i(6, 6))  # FARM
	building_system.construct_building(12, Vector2i(17, 64), Vector2i(5, 5))  # FARM
	
	# Infraestrutura
	building_system.construct_building(10, Vector2i(45, 45), Vector2i(3, 3))  # WATER_TOWER
	building_system.construct_building(11, Vector2i(52, 45), Vector2i(5, 4))  # POWER_PLANT
	building_system.construct_building(9, Vector2i(45, 52), Vector2i(5, 4))  # HOSPITAL
	
	# === CIDADÃOS ===
	print("👥 Creating citizens...")
	
	for i in range(15):
		var spawn_pos = Vector2i(
			randi_range(20, 80),
			randi_range(20, 80)
		)
		var citizen_id = citizen_system.spawn_citizen("Citizen_%d" % i, spawn_pos)
		
		# Atribuir skills aleatórias
		citizen_system.set_citizen_skill(citizen_id, 0, randi_range(20, 80))
		citizen_system.set_citizen_skill(citizen_id, 1, randi_range(20, 80))
	
	# === ECONOMIA ===
	print("💰 Initializing economy...")
	economy_system.add_resource(0, 500.0)   # FOOD
	economy_system.add_resource(1, 500.0)   # WATER
	economy_system.add_resource(2, 1000.0)  # CAPS
	economy_system.add_resource(3, 300.0)   # MATERIALS

func _setup_camera() -> void:
	"""Configura a câmera no centro da cidade"""
	camera_target = city_renderer.grid_to_iso(Vector2(50, 50))
	camera.position = camera_target
	camera.zoom = Vector2(zoom_level, zoom_level)

func _process(delta: float) -> void:
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
		camera_target += move_dir.normalized() * 300.0 * delta
	
	# Suavizar movimento da câmera
	camera.position = camera.position.lerp(camera_target, 5.0 * delta)
	
	# Atualizar sistemas
	citizen_system.update_citizen_needs(delta)
	economy_system.update_economy(delta)
	
	# Atualizar UI
	_update_ui()

func _input(event: InputEvent) -> void:
	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clamp(zoom_level + 0.1, 0.2, 2.0)
			camera.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clamp(zoom_level - 0.1, 0.2, 2.0)
			camera.zoom = Vector2(zoom_level, zoom_level)
	
	# Teclas
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_add_random_building()
			KEY_C:
				_add_citizen()
			KEY_EQUAL, KEY_KP_ADD:
				game_speed = min(game_speed + 0.5, 5.0)
			KEY_MINUS, KEY_KP_SUBTRACT:
				game_speed = max(game_speed - 0.5, 0.5)
			KEY_R:
				city_renderer.rebuild_cache()

func _add_random_building() -> void:
	"""Adiciona um edifício aleatório"""
	var building_types = [0, 1, 2, 3, 4, 5, 6, 7, 8, 12]
	var building_type = building_types[randi() % building_types.size()]
	var pos = Vector2i(randi_range(15, 85), randi_range(15, 85))
	var size = Vector2i(randi_range(3, 6), randi_range(3, 5))
	
	var building_id = building_system.construct_building(building_type, pos, size)
	if building_id >= 0:
		var building = building_system.get_building(building_id)
		city_renderer.add_building(building)
		print("🏗️ Added building type %d at %s" % [building_type, pos])

func _add_citizen() -> void:
	"""Adiciona um cidadão"""
	var pos = Vector2i(randi_range(20, 80), randi_range(20, 80))
	var citizen_id = citizen_system.spawn_citizen("NewCitizen_%d" % randi(), pos)
	print("👤 Added citizen at %s" % pos)

func _update_ui() -> void:
	"""Atualiza a interface"""
	var building_count = building_system.get_building_count()
	var citizen_count = citizen_system.get_citizen_count()
	var road_count = road_system.get_road_count()
	
	info_label.text = """🏙️ CITYBOUND-STYLE RENDERER

🏗️ Buildings: %d
👥 Citizens: %d
🛣️ Roads: %d
⏱️ Speed: %.1fx
🔍 Zoom: %.0f%%""" % [building_count, citizen_count, road_count, game_speed, zoom_level * 100]
	
	stats_label.text = """💰 Caps: %.0f
🍖 Food: %.0f
💧 Water: %.0f
🧱 Materials: %.0f""" % [
		economy_system.get_resource_amount(2),
		economy_system.get_resource_amount(0),
		economy_system.get_resource_amount(1),
		economy_system.get_resource_amount(3)
	]
