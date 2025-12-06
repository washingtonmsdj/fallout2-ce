## Script de Teste da Simulação de Cidade com Player
## Integra sistemas do Fallout com a cidade isométrica
extends Node2D

@onready var city_simulation: CitySimulation = $CitySimulation
@onready var city_renderer: CityRenderer = $CityRenderer
@onready var camera: Camera2D = $Camera2D
@onready var player: PlayerCity = $Player

## UI Labels - Stats da Cidade
@onready var population_label: Label = %PopulationLabel
@onready var buildings_label: Label = %BuildingsLabel
@onready var food_label: Label = %FoodLabel
@onready var water_label: Label = %WaterLabel
@onready var caps_label: Label = %CapsLabel
@onready var materials_label: Label = %MaterialsLabel
@onready var happiness_label: Label = %HappinessLabel
@onready var speed_label: Label = %SpeedLabel

## UI Labels - Stats do Player
@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_hp_label: Label = %PlayerHPLabel
@onready var player_level_label: Label = %PlayerLevelLabel
@onready var player_pos_label: Label = %PlayerPosLabel

## Buttons
@onready var build_house_btn: Button = %BuildHouseBtn
@onready var build_shop_btn: Button = %BuildShopBtn
@onready var build_farm_btn: Button = %BuildFarmBtn
@onready var build_water_btn: Button = %BuildWaterBtn
@onready var slow_btn: Button = %SlowBtn
@onready var fast_btn: Button = %FastBtn

## Configurações de câmera
var zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 2.0
var camera_smoothing: float = 5.0

## Velocidade do jogo
var game_speed: float = 1.0

func _ready():
	# Conectar renderer ao simulation
	city_renderer.city_simulation = city_simulation
	
	# Conectar sinais da cidade
	city_simulation.city_updated.connect(_update_city_ui)
	city_simulation.building_constructed.connect(_on_building_constructed)
	city_simulation.citizen_spawned.connect(_on_citizen_spawned)
	
	# Conectar player à simulação e spawnar na estrada
	player.city_simulation = city_simulation
	player.spawn_on_road()
	
	# Conectar sinais do player
	player.moved.connect(_on_player_moved)
	
	# Conectar botões
	build_house_btn.pressed.connect(_on_build_house)
	build_shop_btn.pressed.connect(_on_build_shop)
	build_farm_btn.pressed.connect(_on_build_farm)
	build_water_btn.pressed.connect(_on_build_water)
	slow_btn.pressed.connect(_on_slow_down)
	fast_btn.pressed.connect(_on_speed_up)
	
	# Posicionar câmera no player
	camera.position = player.position
	
	# Atualizar UI inicial
	_update_city_ui()
	_update_player_ui()
	
	print("🏙️ City Simulation Started!")
	print("👤 Player: %s" % player.critter.critter_name)
	print("Use WASD to move, scroll to zoom")

func _process(delta):
	# Câmera segue o player suavemente
	camera.position = camera.position.lerp(player.position, camera_smoothing * delta)
	
	# Aplicar velocidade do jogo
	Engine.time_scale = game_speed
	
	# Atualizar UI do player
	_update_player_ui()

func _input(event):
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

func _update_city_ui():
	var stats = city_simulation.get_stats()
	
	population_label.text = "👥 Pop: %d" % stats.population
	buildings_label.text = "🏗️ Build: %d" % stats.buildings
	
	food_label.text = "🍖 %.0f" % stats.resources[CitySimulation.CityResource.FOOD]
	water_label.text = "💧 %.0f" % stats.resources[CitySimulation.CityResource.WATER]
	caps_label.text = "💰 %.0f" % stats.resources[CitySimulation.CityResource.CAPS]
	materials_label.text = "🧱 %.0f" % stats.resources[CitySimulation.CityResource.MATERIALS]
	
	happiness_label.text = "😊 %.0f%%" % stats.happiness
	speed_label.text = "⏱️ %.1fx" % game_speed

func _update_player_ui():
	var stats = player.get_stats()
	
	player_name_label.text = stats.name
	player_hp_label.text = "❤️ %d/%d" % [stats.hp, stats.max_hp]
	player_level_label.text = "⭐ Lv.%d" % stats.level
	player_pos_label.text = "📍 %d,%d" % [player.grid_position.x, player.grid_position.y]

func _on_player_moved(new_pos: Vector2i):
	print("Player moved to: %s" % new_pos)

func _on_building_constructed(building: Variant, pos: Vector2):
	print("🏗️ Built %s at %s" % [_get_building_name(building["type"]), pos])

func _on_citizen_spawned(citizen: Variant):
	print("👤 %s moved to the city!" % citizen["name"])

func _get_building_name(type: CitySimulation.BuildingType) -> String:
	match type:
		CitySimulation.BuildingType.HOUSE: return "House"
		CitySimulation.BuildingType.SHOP: return "Shop"
		CitySimulation.BuildingType.WORKSHOP: return "Workshop"
		CitySimulation.BuildingType.FARM: return "Farm"
		CitySimulation.BuildingType.WATER_TOWER: return "Water Tower"
		CitySimulation.BuildingType.POWER_PLANT: return "Power Plant"
		CitySimulation.BuildingType.CLINIC: return "Clinic"
		CitySimulation.BuildingType.BAR: return "Bar"
		CitySimulation.BuildingType.HOTEL: return "Hotel"
		CitySimulation.BuildingType.WAREHOUSE: return "Warehouse"
		_: return "Unknown"

## Botões de construção
func _on_build_house():
	if city_simulation.force_build(CitySimulation.BuildingType.HOUSE):
		print("✅ House construction started!")
	else:
		print("❌ Cannot build house")

func _on_build_shop():
	if city_simulation.force_build(CitySimulation.BuildingType.SHOP):
		print("✅ Shop construction started!")
	else:
		print("❌ Cannot build shop")

func _on_build_farm():
	if city_simulation.force_build(CitySimulation.BuildingType.FARM):
		print("✅ Farm construction started!")
	else:
		print("❌ Cannot build farm")

func _on_build_water():
	if city_simulation.force_build(CitySimulation.BuildingType.WATER_TOWER):
		print("✅ Water Tower construction started!")
	else:
		print("❌ Cannot build water tower")

## Controle de velocidade
func _on_slow_down():
	game_speed = max(0.25, game_speed / 2.0)
	_update_city_ui()

func _on_speed_up():
	game_speed = min(8.0, game_speed * 2.0)
	_update_city_ui()
