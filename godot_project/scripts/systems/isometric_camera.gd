extends Camera2D

## Câmera Isométrica do Fallout 2
## QUALIDADE AAA - Câmera isométrica profissional

# Offset para visão isométrica (45 graus)
@export var isometric_offset: Vector2 = Vector2(0, -100)
@export var zoom_level: float = 0.75

func _ready():
	# Configurar câmera isométrica
	offset = isometric_offset
	zoom = Vector2(zoom_level, zoom_level)
	
	# Suavizar movimento da câmera
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0
	
	print("IsometricCamera: Configurada")

func set_target_position(target_pos: Vector2):
	"""Define posição alvo da câmera com offset isométrico"""
	var isometric_pos = target_pos + isometric_offset
	global_position = isometric_pos

