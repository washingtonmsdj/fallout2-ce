## Script de Teste V2 - Estilo Citybound
## Com UI funcional e controles de câmera
extends Node2D

@onready var city_simulation: CitySimulation = $CitySimulation
@onready var city_renderer: CityRendererV2 = $CityRenderer
@onready var camera: Camera2D = $Camera2D

## UI - Top Bar
@onready var pop_label: Label = %PopLabel
@onready var build_label: Label = %BuildLabel
@onready var food_label: Label = %FoodLabel
@onready var water_label: Label = %WaterLabel
@onready var caps_label: Label = %CapsLabel
@onready var speed_label: Label = %SpeedLabel

## UI - Bottom Bar Buttons
@onready var build_house_btn: Button = %BuildHouseBtn
@onready var build_shop_btn: Button = %BuildShopBtn
@onready var build_farm_btn: Button = %BuildFarmBtn
@onready var build_water_btn: Button = %BuildWaterBtn
@onready var slow_btn: Button = %SlowBtn
@onready var fast_btn: Button = %FastBtn
@onready var pause_btn: Button = %PauseBtn

## Configurações
var camera_speed: float = 400.0
var zoom_speed: float = 0.1
var min_zoom: float = 0.2
var max_zoom: float = 2.0
var game_speed: float = 1.0
var is_paused: bool = false

func _ready():
	print("🏙️ TestCityV2 - Citybound Style!")
	
	# Conectar renderer ao simulation
	city_renderer.city_simulation = city_simulation
	
	# Conectar sinais
	city_simulation.city_updated.connect(_update_ui)
	city_simulation.building_constructed.connect(_on_building_constructed)
	city_simulation.citizen_spawned.connect(_on_citizen_spawned)
	
	# Conectar botões
	build_house_btn.pressed.connect(func(): _build(CitySimulation.BuildingType.HOUSE))
	build_shop_btn.pressed.connect(func(): _build(CitySimulation.BuildingType.SHOP))
	build_farm_btn.pressed.connect(func(): _build(CitySimulation.BuildingType.FARM))
	build_water_btn.pressed.connect(func(): _build(CitySimulation.BuildingType.WATER_TOWER))
	slow_btn.pressed.connect(_slow_down)
	fast_btn.pressed.connect(_speed_up)
	pause_btn.pressed.connect(_toggle_pause)
	
	# Posicionar câmera no centro da cidade
	call_deferred("_setup_camera")
	
	# Atualizar UI
	_update_ui()

func _setup_camera():
	# Centro do grid em coordenadas isométricas
	var grid_center = Vector2(city_simulation.grid_size.x / 2.0, city_simulation.grid_size.y / 2.0)
	var iso_center = city_renderer.grid_to_iso(grid_center)
	camera.position = iso_center
	camera.zoom = Vector2(0.6, 0.6)
	print("📷 Camera at: %s" % camera.position)

func _process(delta):
	if is_paused:
		return
	
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
		camera.position += move_dir.normalized() * camera_speed * delta
	
	# Aplicar velocidade do jogo
	Engine.time_scale = game_speed

func _input(event):
	# Zoom com scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera.zoom = (camera.zoom + Vector2(zoom_speed, zoom_speed)).clamp(
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.zoom = (camera.zoom - Vector2(zoom_speed, zoom_speed)).clamp(
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)

func _update_ui():
	var stats = city_simulation.get_stats()
	
	pop_label.text = "👥 %d" % stats.population
	build_label.text = "🏗️ %d" % stats.buildings
	food_label.text = "🍖 %.0f" % stats.resources[CitySimulation.CityResource.FOOD]
	water_label.text = "💧 %.0f" % stats.resources[CitySimulation.CityResource.WATER]
	caps_label.text = "💰 %.0f" % stats.resources[CitySimulation.CityResource.CAPS]
	
	var speed_text = "⏸️ PAUSED" if is_paused else "⏱️ %.1fx" % game_speed
	speed_label.text = speed_text

func _build(type: CitySimulation.BuildingType):
	if city_simulation.force_build(type):
		print("✅ Built %s!" % _get_type_name(type))
	else:
		print("❌ Cannot build %s" % _get_type_name(type))

func _get_type_name(type: CitySimulation.BuildingType) -> String:
	match type:
		CitySimulation.BuildingType.HOUSE: return "House"
		CitySimulation.BuildingType.SHOP: return "Shop"
		CitySimulation.BuildingType.FARM: return "Farm"
		CitySimulation.BuildingType.WATER_TOWER: return "Water Tower"
		_: return "Building"

func _slow_down():
	game_speed = max(0.25, game_speed / 2.0)
	_update_ui()

func _speed_up():
	game_speed = min(4.0, game_speed * 2.0)
	_update_ui()

func _toggle_pause():
	is_paused = !is_paused
	pause_btn.text = "▶️ Play" if is_paused else "⏸️ Pause"
	_update_ui()

func _on_building_constructed(building: Variant, pos: Vector2):
	print("🏗️ Building constructed at %s" % pos)
	_update_ui()

func _on_citizen_spawned(citizen: Variant):
	print("👤 %s joined the settlement!" % citizen["name"])
	_update_ui()
