extends Node2D

## Cena principal de jogo do Fallout 2
## Gerencia o mundo, objetos e interacoes

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var is_ready: bool = false
var iso_renderer: Node = null

func _ready():
	print("GameScene: Inicializando...")
	
	# Obter renderer isométrico
	iso_renderer = get_node_or_null("/root/IsometricRenderer")
	if not iso_renderer:
		push_warning("GameScene: IsometricRenderer não encontrado!")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Converter tiles para posições isométricas
	_convert_tiles_to_isometric()
	
	# Configurar player
	if player:
		player.add_to_group("player")
		
		# Converter posição do player para isométrica
		if iso_renderer:
			var tile_pos = Vector2i(5, 5)  # Posição central no grid
			player.position = iso_renderer.tile_to_screen(tile_pos, 0)
		
		print("GameScene: Player configurado em ", player.position)
		
		# Garantir camera ativa
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = true
			camera.make_current()
	
	# Configurar NPCs
	_setup_npcs()
	
	is_ready = true
	print("GameScene: Pronto!")

func _convert_tiles_to_isometric():
	"""Converte tiles de grid cartesiano para isométrico"""
	if not iso_renderer or not world:
		return
	
	var ground = world.get_node_or_null("Ground")
	if not ground:
		return
	
	print("GameScene: Convertendo tiles para isométrico...")
	
	# Percorrer todos os tiles e converter suas posições
	for child in ground.get_children():
		if child is Sprite2D:
			# Extrair coordenadas do nome (Row0_Col0, etc)
			var parts = child.name.split("_")
			if parts.size() >= 2:
				var row = int(parts[0].replace("Row", ""))
				var col = int(parts[1].replace("Col", ""))
				
				# Converter para posição isométrica
				var tile_pos = Vector2i(col, row)
				var screen_pos = iso_renderer.tile_to_screen(tile_pos, 0)
				child.position = screen_pos
	
	print("GameScene: Conversão isométrica concluída")

func _setup_npcs():
	"""Configura NPCs na cena"""
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.has_signal("interaction_requested"):
			npc.interaction_requested.connect(_on_npc_interaction)

func _on_npc_interaction(npc: Node):
	"""Chamado quando player interage com NPC"""
	print("GameScene: Interacao com ", npc.name)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_dialog(npc)

func _input(event):
	"""Processa input da cena"""
	if not is_ready:
		return
	
	# Click para mover
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(event.position)

func _handle_left_click(screen_pos: Vector2):
	"""Processa click esquerdo"""
	var gm = get_node_or_null("/root/GameManager")
	if gm and not gm.is_playing():
		return
	
	# Converter para posicao do mundo
	var world_pos = get_global_mouse_position()
	
	# Verificar se clicou em algo interagivel
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 2  # Layer de interagiveis
	
	var results = space.intersect_point(query, 5)
	
	if results.size() > 0:
		# Clicou em algo - interagir
		var obj = results[0].collider
		if obj.has_method("interact"):
			obj.interact(player)
		elif obj.has_method("on_click"):
			obj.on_click(player)
	else:
		# Clicou no chao - mover
		if player and player.has_method("move_to"):
			player.move_to(world_pos)

func _handle_right_click(_screen_pos: Vector2):
	"""Processa click direito"""
	# No original, click direito muda modo do cursor
	# Por enquanto, apenas para movimento
	if player and player.has_method("stop_movement"):
		player.stop_movement()

func get_player() -> CharacterBody2D:
	"""Retorna referencia ao player"""
	return player

func get_objects_at(pos: Vector2) -> Array:
	"""Retorna objetos em uma posicao"""
	var objects = []
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	
	var results = space.intersect_point(query, 10)
	for result in results:
		objects.append(result.collider)
	
	return objects
