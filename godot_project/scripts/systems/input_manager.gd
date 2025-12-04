extends Node

## Sistema de Gerenciamento de Input do Fallout 2
## Processa clicks do mouse, detecta objetos interagíveis e converte coordenadas

signal left_click_tile(tile_pos: Vector2i, elevation: int)
signal left_click_object(object: Node)
signal right_click(screen_pos: Vector2)
signal cursor_mode_changed(new_mode: CursorMode)

enum CursorMode {
	MOVEMENT,    # Modo padrão - movimento
	ATTACK,      # Modo de ataque
	USE,         # Modo de usar item/skill
	EXAMINE,     # Modo de examinar
	TALK         # Modo de conversar
}

# Estado atual
var current_mode: CursorMode = CursorMode.MOVEMENT
var current_elevation: int = 0

# Referências
var renderer: Node = null
var camera: Camera2D = null

func _ready():
	# Obter referências aos sistemas
	renderer = get_node_or_null("/root/IsometricRenderer")
	
	if renderer == null:
		push_error("InputManager: IsometricRenderer não encontrado!")
	
	print("InputManager: Inicializado")

func _unhandled_input(event: InputEvent):
	# Processar clicks do mouse
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_handle_left_click(event.position)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_handle_right_click(event.position)
	
	# Processar atalhos de teclado
	if event is InputEventKey and event.pressed:
		_handle_keyboard_shortcut(event)

func _handle_left_click(screen_pos: Vector2):
	"""
	Processa click esquerdo
	- Converte posição de tela para tile
	- Detecta objetos interagíveis
	- Emite sinais apropriados
	"""
	if renderer == null:
		return
	
	# Obter posição no mundo (considerando câmera)
	var world_pos = _screen_to_world(screen_pos)
	
	# Converter para coordenadas de tile
	var tile_pos = renderer.screen_to_tile(world_pos, current_elevation)
	
	# Verificar se há objeto interagível na posição
	var clicked_object = _get_object_at_position(world_pos)
	
	if clicked_object != null:
		# Click em objeto
		left_click_object.emit(clicked_object)
		print("InputManager: Click em objeto - ", clicked_object.name)
	else:
		# Click no chão
		left_click_tile.emit(tile_pos, current_elevation)
		print("InputManager: Click no tile - ", tile_pos)

func _handle_right_click(screen_pos: Vector2):
	"""
	Processa click direito
	- Alterna entre modos de cursor
	"""
	# Alternar modo do cursor
	var next_mode = (current_mode + 1) % CursorMode.size()
	set_cursor_mode(next_mode)
	
	right_click.emit(screen_pos)

func set_cursor_mode(mode: CursorMode):
	"""Define o modo atual do cursor"""
	if mode != current_mode:
		current_mode = mode
		cursor_mode_changed.emit(mode)
		print("InputManager: Modo alterado para ", CursorMode.keys()[mode])

func get_cursor_mode() -> CursorMode:
	"""Retorna o modo atual do cursor"""
	return current_mode

func set_elevation(elevation: int):
	"""Define a elevação atual para conversão de coordenadas"""
	current_elevation = clamp(elevation, 0, 2)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	"""
	Converte posição de tela para posição no mundo
	Considera a posição e zoom da câmera
	"""
	if camera == null:
		# Tentar obter câmera
		camera = get_viewport().get_camera_2d()
	
	if camera != null:
		# Ajustar pela câmera
		var camera_offset = camera.get_screen_center_position()
		var zoom_factor = camera.zoom.x
		return (screen_pos - get_viewport().size / 2) / zoom_factor + camera_offset
	else:
		# Sem câmera, usar posição direta
		return screen_pos

func _get_object_at_position(world_pos: Vector2) -> Node:
	"""
	Detecta objeto interagível na posição do mundo
	Usa raycast ou área de detecção
	"""
	# Obter espaço de física 2D
	var space_state = get_world_2d().direct_space_state
	
	# Criar query para ponto
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Executar query
	var results = space_state.intersect_point(query, 10)  # Máximo 10 resultados
	
	# Procurar primeiro objeto interagível
	for result in results:
		var collider = result.collider
		# Verificar se tem método interact ou é interagível
		if collider.has_method("interact") or collider.has_meta("interactable"):
			return collider
	
	return null

func get_tile_at_mouse() -> Vector2i:
	"""
	Retorna o tile na posição atual do mouse
	Útil para preview de ações
	"""
	if renderer == null:
		return Vector2i(-1, -1)
	
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = _screen_to_world(mouse_pos)
	return renderer.screen_to_tile(world_pos, current_elevation)

func get_object_at_mouse() -> Node:
	"""
	Retorna o objeto na posição atual do mouse
	Útil para tooltips e highlight
	"""
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = _screen_to_world(mouse_pos)
	return _get_object_at_position(world_pos)

func _handle_keyboard_shortcut(event: InputEventKey):
	"""
	Processa atalhos de teclado
	Integra com GameManager para abrir menus
	"""
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		return
	
	# Mapear teclas para ações
	match event.keycode:
		KEY_I:
			# Abrir inventário
			if game_manager.has_method("toggle_inventory"):
				game_manager.toggle_inventory()
			print("InputManager: Atalho - Inventário")
		
		KEY_C:
			# Abrir tela de personagem
			if game_manager.has_method("toggle_character_screen"):
				game_manager.toggle_character_screen()
			print("InputManager: Atalho - Personagem")
		
		KEY_P:
			# Abrir Pipboy
			if game_manager.has_method("toggle_pipboy"):
				game_manager.toggle_pipboy()
			print("InputManager: Atalho - Pipboy")
		
		KEY_ESCAPE:
			# Pausar/Menu
			if game_manager.has_method("toggle_pause_menu"):
				game_manager.toggle_pause_menu()
			print("InputManager: Atalho - Pause")
		
		KEY_S:
			# Skilldex (se não estiver em movimento)
			if not Input.is_action_pressed("move_down"):
				if game_manager.has_method("toggle_skilldex"):
					game_manager.toggle_skilldex()
				print("InputManager: Atalho - Skilldex")
		
		KEY_F6:
			# Quicksave
			if game_manager.has_method("quicksave"):
				game_manager.quicksave()
			print("InputManager: Atalho - Quicksave")
		
		KEY_F9:
			# Quickload
			if game_manager.has_method("quickload"):
				game_manager.quickload()
			print("InputManager: Atalho - Quickload")
		
		KEY_TAB:
			# Alternar modo de combate
			if game_manager.has_method("toggle_combat_mode"):
				game_manager.toggle_combat_mode()
			print("InputManager: Atalho - Toggle Combat")
