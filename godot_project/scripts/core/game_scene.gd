extends Node2D

## Cena principal de jogo do Fallout 2
## Gerencia o mundo, objetos e interacoes

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var is_ready: bool = false

func _ready():
	print("GameScene: Inicializando...")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Configurar player
	if player:
		player.add_to_group("player")
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
