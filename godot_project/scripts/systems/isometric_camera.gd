extends Camera2D
class_name IsometricCamera

## Câmera Isométrica do Fallout 2
## Sistema completo de câmera com seguimento suave, limites e zoom

# Configurações de seguimento
@export_group("Seguimento")
@export var follow_smoothing: float = 5.0  ## Velocidade de suavização (0 = instantâneo, maior = mais suave)
@export var follow_enabled: bool = true  ## Habilitar seguimento automático do alvo

# Configurações de zoom
@export_group("Zoom")
@export var zoom_min: float = 0.5  ## Zoom mínimo (mais afastado)
@export var zoom_max: float = 2.0  ## Zoom máximo (mais próximo)
@export var zoom_speed: float = 0.1  ## Velocidade de transição do zoom
@export var zoom_step: float = 0.1  ## Incremento por scroll do mouse

# Configurações de limites
@export_group("Limites")
@export var bounds_enabled: bool = true  ## Habilitar limites de câmera
@export var map_bounds: Rect2 = Rect2(0, 0, 8000, 8000)  ## Limites do mapa atual

# Estado interno
var target_node: Node2D = null
var current_zoom: float = 1.0
var target_zoom: float = 1.0

func _ready():
	# Configurar zoom inicial
	current_zoom = 1.0
	target_zoom = 1.0
	zoom = Vector2(current_zoom, current_zoom)
	
	# Configurar suavização
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing
	
	print("IsometricCamera: Inicializada")

func _process(delta: float):
	# Atualizar seguimento do alvo
	if follow_enabled and target_node != null:
		follow_target(delta)
	
	# Atualizar zoom suavemente
	if abs(current_zoom - target_zoom) > 0.01:
		current_zoom = lerp(current_zoom, target_zoom, zoom_speed)
		zoom = Vector2(current_zoom, current_zoom)
	
	# Aplicar limites de câmera
	if bounds_enabled:
		apply_bounds()

func follow_target(delta: float):
	"""
	Segue o alvo com suavização configurável
	Usa lerp para movimento suave
	"""
	if target_node == null:
		return
	
	var target_pos = target_node.global_position
	
	# Interpolar posição com suavização
	var lerp_weight = 1.0 - exp(-follow_smoothing * delta)
	global_position = global_position.lerp(target_pos, lerp_weight)

func set_follow_target(node: Node2D):
	"""Define o node que a câmera deve seguir (geralmente o player)"""
	target_node = node
	if node != null:
		global_position = node.global_position

func set_smoothing(smoothing: float):
	"""Ajusta a suavização do seguimento (0 = instantâneo, maior = mais suave)"""
	follow_smoothing = clamp(smoothing, 0.0, 20.0)
	position_smoothing_speed = follow_smoothing

func apply_bounds():
	"""
	Aplica limites de câmera para não mostrar área fora do mapa
	Calcula viewport e clamp a posição
	"""
	# Obter tamanho do viewport em coordenadas do mundo
	var viewport_size = get_viewport_rect().size / zoom
	var half_viewport = viewport_size / 2.0
	
	# Calcular limites considerando o viewport
	var min_x = map_bounds.position.x + half_viewport.x
	var max_x = map_bounds.end.x - half_viewport.x
	var min_y = map_bounds.position.y + half_viewport.y
	var max_y = map_bounds.end.y - half_viewport.y
	
	# Se o viewport é maior que o mapa, centralizar
	if max_x < min_x:
		var center_x = (map_bounds.position.x + map_bounds.end.x) / 2.0
		global_position.x = center_x
	else:
		global_position.x = clamp(global_position.x, min_x, max_x)
	
	if max_y < min_y:
		var center_y = (map_bounds.position.y + map_bounds.end.y) / 2.0
		global_position.y = center_y
	else:
		global_position.y = clamp(global_position.y, min_y, max_y)

func set_map_bounds(bounds: Rect2):
	"""Define os limites do mapa atual"""
	map_bounds = bounds
	print("IsometricCamera: Limites definidos - ", bounds)

func zoom_in():
	"""Aumenta o zoom (aproxima)"""
	target_zoom = clamp(target_zoom + zoom_step, zoom_min, zoom_max)

func zoom_out():
	"""Diminui o zoom (afasta)"""
	target_zoom = clamp(target_zoom - zoom_step, zoom_min, zoom_max)

func set_zoom_level(level: float):
	"""Define o nível de zoom diretamente"""
	target_zoom = clamp(level, zoom_min, zoom_max)

func _unhandled_input(event: InputEvent):
	"""Processa input de zoom com scroll do mouse"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_out()

func center_on_position(pos: Vector2):
	"""Centraliza a câmera em uma posição específica"""
	global_position = pos
	if bounds_enabled:
		apply_bounds()

