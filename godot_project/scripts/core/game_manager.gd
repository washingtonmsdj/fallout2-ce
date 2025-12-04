extends Node

## Gerenciador principal do jogo - Fallout 2 Godot Edition
## Controla estado do jogo, carregamento de mapas, transições
## Fiel ao comportamento do original

signal map_changed(map_name: String)
signal game_state_changed(new_state: int)
signal player_spawned(player_node: Node)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	DIALOG,
	INVENTORY,
	COMBAT,
	WORLDMAP,
	LOADING
}

# Constantes do jogo original
const ORIGINAL_WIDTH = 640
const ORIGINAL_HEIGHT = 480
const TILE_WIDTH = 80
const TILE_HEIGHT = 36

var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU
var current_map: Node2D = null
var current_map_name: String = ""
var player: CharacterBody2D = null

# Configurações
var game_difficulty: int = 1  # 0=Easy, 1=Normal, 2=Hard
var combat_difficulty: int = 1
var violence_level: int = 3  # 0-3
var target_highlight: int = 2
var combat_speed: int = 50
var text_delay: float = 0.0
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var speech_volume: float = 1.0

func _ready():
	print("GameManager: Inicializando Fallout 2 Godot Edition")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectar sinais do InputManager
	_connect_input_signals()
	
	# Conectar ao AudioManager
	_connect_audio_manager()
	
	# Aguardar cena estar pronta

func _connect_audio_manager():
	"""Conecta GameManager ao AudioManager para volumes"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.set_master_volume(master_volume)
		audio_manager.set_music_volume(music_volume)
		audio_manager.set_sfx_volume(sfx_volume)
		audio_manager.set_voice_volume(speech_volume)
		print("GameManager: AudioManager conectado")

func _connect_input_signals():
	"""Conecta sinais do InputManager para controle do jogo"""
	var input_manager = get_node_or_null("/root/InputManager")
	if input_manager:
		input_manager.left_click_tile.connect(_on_click_tile)
		input_manager.left_click_object.connect(_on_click_object)
		print("GameManager: Sinais do InputManager conectados")

func _on_click_tile(tile_pos: Vector2i, _elevation: int):
	"""Callback quando jogador clica em um tile"""
	if current_state != GameState.PLAYING:
		return
	
	if player != null and player.has_method("move_to_tile"):
		player.move_to_tile(tile_pos)

func _on_click_object(object: Node):
	"""Callback quando jogador clica em um objeto"""
	if current_state != GameState.PLAYING:
		return
	
	print("GameManager: Click em objeto - ", object.name)
	# Aqui pode adicionar lógica de interação
	await get_tree().process_frame
	_initialize_game()

func _initialize_game():
	"""Inicializa o jogo e mostra menu principal"""
	current_state = GameState.MENU
	game_state_changed.emit(current_state)
	
	# Encontrar e mostrar menu
	var main_menu = _find_main_menu()
	if main_menu:
		main_menu.visible = true
		main_menu.show()
	
	print("GameManager: Menu principal carregado")

func _find_main_menu() -> Control:
	"""Encontra o menu principal na cena atual"""
	var scene = get_tree().current_scene
	if not scene:
		return null
	
	# Tentar encontrar menu original primeiro
	var paths = [
		"UI/MainMenuOriginal",
		"UI/MainMenu",
		"MainMenuOriginal",
		"MainMenu"
	]
	
	for path in paths:
		var menu = scene.get_node_or_null(path)
		if menu and menu is Control:
			return menu
	
	return null

func start_new_game():
	"""Inicia um novo jogo - igual ao original"""
	print("GameManager: Iniciando novo jogo...")
	
	# Esconder menu
	var main_menu = _find_main_menu()
	if main_menu:
		main_menu.visible = false
	
	# Mudar estado
	previous_state = current_state
	current_state = GameState.LOADING
	game_state_changed.emit(current_state)
	
	# Carregar cena de jogo
	await _load_game_scene()
	
	# Carregar primeiro mapa (Arroyo - Temple of Trials no original)
	# Por enquanto, carregar mapa de teste
	current_state = GameState.PLAYING
	game_state_changed.emit(current_state)
	
	print("GameManager: Novo jogo iniciado")

func _load_game_scene():
	"""Carrega a cena principal de jogo"""
	var game_scene_path = "res://scenes/game/game_scene.tscn"
	
	if ResourceLoader.exists(game_scene_path):
		var game_scene = load(game_scene_path)
		if game_scene:
			var instance = game_scene.instantiate()
			instance.name = "GameScene"
			
			# Remover cena anterior se existir
			var old_scene = get_tree().current_scene.get_node_or_null("GameScene")
			if old_scene:
				old_scene.queue_free()
				await get_tree().process_frame
			
			get_tree().current_scene.add_child(instance)
			current_map = instance
			
			# Aguardar frames para garantir inicialização
			await get_tree().process_frame
			await get_tree().process_frame
			
			# Encontrar e registrar player
			_setup_player(instance)
			return
	
	# Fallback: criar cena básica
	print("GameManager: Criando cena de jogo básica")
	_create_fallback_game_scene()

func _setup_player(scene: Node):
	"""Configura o player na cena"""
	var player_node = scene.get_node_or_null("Player")
	if not player_node:
		player_node = scene.find_child("Player", true, false)
	
	if player_node:
		player = player_node
		if not player.is_in_group("player"):
			player.add_to_group("player")
		
		player_spawned.emit(player)
		print("GameManager: Player configurado em ", player.global_position)
		
		# Configurar câmera
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = true
			camera.make_current()
	else:
		push_warning("GameManager: Player não encontrado na cena!")

func _create_fallback_game_scene():
	"""Cria cena de jogo básica como fallback"""
	var scene = Node2D.new()
	scene.name = "GameScene"
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.12, 0.08)
	bg.size = Vector2(2048, 2048)
	bg.position = Vector2(-512, -512)
	scene.add_child(bg)
	
	# Criar player básico
	var player_scene = load("res://scenes/characters/player.tscn")
	if player_scene:
		var p = player_scene.instantiate()
		p.position = Vector2(512, 384)
		scene.add_child(p)
		player = p
	
	get_tree().current_scene.add_child(scene)
	current_map = scene
	
	if player:
		player_spawned.emit(player)

func load_game(slot: int = -1):
	"""Carrega jogo salvo"""
	print("GameManager: Carregando jogo do slot ", slot)
	# TODO: Implementar sistema de save/load
	pass

func save_game(slot: int = -1):
	"""Salva jogo"""
	print("GameManager: Salvando jogo no slot ", slot)
	# TODO: Implementar sistema de save/load
	pass

func load_map(map_name: String, entrance: int = 0):
	"""Carrega um mapa específico"""
	print("GameManager: Carregando mapa: ", map_name)
	
	previous_state = current_state
	current_state = GameState.LOADING
	game_state_changed.emit(current_state)
	
	# Remover mapa atual
	if current_map:
		current_map.queue_free()
		current_map = null
		await get_tree().process_frame
	
	# Tentar carregar mapa
	var map_path = "res://scenes/maps/" + map_name + ".tscn"
	if ResourceLoader.exists(map_path):
		var map_scene = load(map_path)
		if map_scene:
			current_map = map_scene.instantiate()
			get_tree().current_scene.add_child(current_map)
			current_map_name = map_name
			map_changed.emit(map_name)
	
	current_state = GameState.PLAYING
	game_state_changed.emit(current_state)

func pause_game():
	"""Pausa o jogo"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.PAUSED
		game_state_changed.emit(current_state)
		get_tree().paused = true

func resume_game():
	"""Retoma o jogo"""
	if current_state == GameState.PAUSED:
		current_state = previous_state
		game_state_changed.emit(current_state)
		get_tree().paused = false

func enter_combat():
	"""Entra em modo de combate"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.COMBAT
		game_state_changed.emit(current_state)

func exit_combat():
	"""Sai do modo de combate"""
	if current_state == GameState.COMBAT:
		current_state = GameState.PLAYING
		game_state_changed.emit(current_state)

func open_inventory():
	"""Abre inventário"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.INVENTORY
		game_state_changed.emit(current_state)
		_pause_for_menu()

func close_inventory():
	"""Fecha inventário"""
	if current_state == GameState.INVENTORY:
		current_state = previous_state
		game_state_changed.emit(current_state)
		_resume_from_menu()

func open_character_screen():
	"""Abre tela de personagem"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.PAUSED
		game_state_changed.emit(current_state)
		_pause_for_menu()

func close_character_screen():
	"""Fecha tela de personagem"""
	if current_state == GameState.PAUSED and previous_state == GameState.PLAYING:
		current_state = previous_state
		game_state_changed.emit(current_state)
		_resume_from_menu()

func open_options_screen():
	"""Abre tela de opções"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.PAUSED
		game_state_changed.emit(current_state)
		_pause_for_menu()

func close_options_screen():
	"""Fecha tela de opções"""
	if current_state == GameState.PAUSED and previous_state == GameState.PLAYING:
		current_state = previous_state
		game_state_changed.emit(current_state)
		_resume_from_menu()

func _pause_for_menu():
	"""
	Pausa jogo quando menu abre
	Não pausa em combate
	"""
	if current_state == GameState.COMBAT:
		# Não pausar em combate
		return
	
	get_tree().paused = true

func _resume_from_menu():
	"""Retoma jogo quando menu fecha"""
	if current_state == GameState.COMBAT:
		# Não pausar em combate
		return
	
	get_tree().paused = false

func start_dialog(npc: Node):
	"""Inicia diálogo com NPC"""
	if current_state == GameState.PLAYING:
		previous_state = current_state
		current_state = GameState.DIALOG
		game_state_changed.emit(current_state)

func end_dialog():
	"""Termina diálogo"""
	if current_state == GameState.DIALOG:
		current_state = previous_state
		game_state_changed.emit(current_state)

func quit_to_menu():
	"""Volta ao menu principal"""
	# Limpar cena de jogo
	if current_map:
		current_map.queue_free()
		current_map = null
	
	player = null
	current_state = GameState.MENU
	game_state_changed.emit(current_state)
	
	# Mostrar menu
	var main_menu = _find_main_menu()
	if main_menu:
		main_menu.visible = true

func quit_game():
	"""Sai do jogo"""
	print("GameManager: Saindo do jogo...")
	get_tree().quit()

func _input(event):
	"""Processa input global"""
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()
	
	if event.is_action_pressed("inventory"):
		if current_state == GameState.PLAYING:
			open_inventory()
		elif current_state == GameState.INVENTORY:
			close_inventory()
	
	if event.is_action_pressed("character"):
		if current_state == GameState.PLAYING:
			open_character_screen()
		elif current_state == GameState.PAUSED:
			close_character_screen()

# Utilitários
func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_in_combat() -> bool:
	return current_state == GameState.COMBAT

func is_in_dialog() -> bool:
	return current_state == GameState.DIALOG

func can_player_move() -> bool:
	return current_state == GameState.PLAYING
