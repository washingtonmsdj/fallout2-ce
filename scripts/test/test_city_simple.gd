## Script de Teste Simples da Renderização
## Sem player, apenas para verificar se a cidade está sendo desenhada
extends Node2D

@onready var city_simulation: CitySimulation = $CitySimulation
@onready var city_renderer: CityRenderer = $CityRenderer
@onready var camera: Camera2D = $Camera2D
@onready var debug_label: Label = $DebugLabel

var camera_speed: float = 500.0
var zoom_speed: float = 0.1

func _ready():
	print("=== TEST CITY SIMPLE ===")
	
	# Conectar renderer ao simulation
	city_renderer.city_simulation = city_simulation
	
	# Posicionar câmera no centro da cidade
	call_deferred("_setup")

func _setup():
	# Centro do grid 50x50 em coordenadas isométricas
	# grid (25, 25) -> iso (0, 800)
	var grid_center = Vector2(25, 25)
	var iso_center = city_renderer.grid_to_iso(grid_center)
	
	camera.position = iso_center
	camera.zoom = Vector2(0.4, 0.4)
	
	print("Camera at: %s" % camera.position)
	print("Zoom: %s" % camera.zoom)
	print("Roads: %d" % city_simulation.roads.size())
	print("Buildings: %d" % city_simulation.buildings.size())
	print("Citizens: %d" % city_simulation.citizens.size())

func _process(delta):
	# Movimento da câmera com setas
	var move = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	
	camera.position += move * camera_speed * delta
	
	# Atualizar debug label
	debug_label.text = "Camera: %s\nZoom: %s\nRoads: %d | Buildings: %d | Citizens: %d" % [
		camera.position,
		camera.zoom,
		city_simulation.roads.size(),
		city_simulation.buildings.size(),
		city_simulation.citizens.size()
	]

func _input(event):
	# Zoom com scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom += Vector2(zoom_speed, zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom -= Vector2(zoom_speed, zoom_speed)
			camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(2.0, 2.0))
