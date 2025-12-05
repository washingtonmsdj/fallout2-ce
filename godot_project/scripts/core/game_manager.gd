extends Node

## Gerenciador principal do jogo - Fallout 2 Godot Edition
## Controla estado do jogo, carregamento de mapas, transições
## Fiel ao comportamento do original

signal map_changed(map_name: String)
signal game_state_changed(new_state: int)
signal player_spawned(player_node: Node)

enum GameState {
	MENU,
	EXPLORATION,  # Renomeado de PLAYING para ser mais claro
	COMBAT,
	DIALOG,
	INVENTORY,
	PAUSED,
	WORLDMAP,
	LOADING
}

# Constantes de tempo do jogo (baseado no código original)
const GAME_TIME_TICKS_PER_SECOND = 10  # 1 tick = 0.1 segundo
const GAME_TIME_TICKS_PER_MINUTE = 600  # 60 * 10
const GAME_TIME_TICKS_PER_HOUR = 36000  # 60 * 60 * 10
const GAME_TIME_TICKS_PER_DAY = 864000  # 24 * 60 * 60 * 10
const GAME_TIME_TICKS_PER_YEAR = 315360000  # 365 * 24 * 60 * 60 * 10

# Data inicial do jogo (Fallout 2 começa em 2241)
const GAME_START_YEAR = 2241
const GAME_START_MONTH = 1  # Janeiro
const GAME_START_DAY = 1

# Dias por mês
const DAYS_PER_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

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
var player_name: String = "Chosen One"  # Nome do personagem

# Sistema de tempo do jogo
var game_time_ticks: int = 302400  # Tempo inicial (baseado no original)
var time_speed_multiplier: float = 1.0  # Multiplicador de velocidade do tempo
var is_time_paused: bool = false
var last_time_update: float = 0.0

# Matriz de transições válidas de estado
var valid_transitions: Dictionary = {
	GameState.MENU: [GameState.LOADING, GameState.MENU],
	GameState.EXPLORATION: [GameState.COMBAT, GameState.DIALOG, GameState.INVENTORY, GameState.PAUSED, GameState.WORLDMAP, GameState.LOADING],
	GameState.COMBAT: [GameState.EXPLORATION, GameState.DIALOG, GameState.PAUSED],
	GameState.DIALOG: [GameState.EXPLORATION, GameState.COMBAT, GameState.INVENTORY],
	GameState.INVENTORY: [GameState.EXPLORATION, GameState.DIALOG],
	GameState.PAUSED: [GameState.EXPLORATION, GameState.COMBAT, GameState.MENU],
	GameState.WORLDMAP: [GameState.EXPLORATION, GameState.LOADING],
	GameState.LOADING: [GameState.EXPLORATION, GameState.MENU]
}

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
	
	# Inicializar sistema de tempo
	_initialize_game_time()
	
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
	if current_state != GameState.EXPLORATION:
		return
	
	if player != null and player.has_method("move_to_tile"):
		player.move_to_tile(tile_pos)

func _on_click_object(object: Node):
	"""Callback quando jogador clica em um objeto"""
	if current_state != GameState.EXPLORATION:
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
	"""
	Inicia um novo jogo - IGUAL AO FALLOUT 2 ORIGINAL
	No original, não existe tela de criação de personagem!
	O jogo começa DIRETAMENTE no Temple of Trials (artemple.map)
	"""
	print("GameManager: Iniciando novo jogo - Temple of Trials...")
	
	# Mudar estado
	previous_state = current_state
	current_state = GameState.LOADING
	game_state_changed.emit(current_state)
	
	# Inicializar player com stats padrão do Fallout 2
	_initialize_default_player_stats()
	
	# Carregar Temple of Trials (primeiro mapa)
	_load_temple_of_trials()

func _initialize_default_player_stats():
	"""
	Inicializa player com stats PADRÃO do Fallout 2
	No original, todos começam com SPECIAL 5 em tudo
	"""
	print("GameManager: Inicializando stats padrão do player...")
	
	# SPECIAL padrão (todos 5)
	var default_special = {
		"strength": 5,
		"perception": 5,
		"endurance": 5,
		"charisma": 5,
		"intelligence": 5,
		"agility": 5,
		"luck": 5
	}
	
	# Derived stats
	var default_derived = {
		"hp": 25,
		"max_hp": 25,
		"ap": 8,
		"max_ap": 8,
		"armor_class": 5,
		"melee_damage": 1,
		"carry_weight": 150,
		"sequence": 10,
		"healing_rate": 1,
		"critical_chance": 5
	}
	
	# Armazenar para uso posterior
	set_meta("default_special", default_special)
	set_meta("default_derived", default_derived)

func _load_temple_of_trials():
	"""Carrega o Temple of Trials (primeiro mapa do Fallout 2)"""
	var temple_path = "res://scenes/maps/temple_of_trials.tscn"
	
	if ResourceLoader.exists(temple_path):
		print("GameManager: Carregando Temple of Trials...")
		get_tree().change_scene_to_file(temple_path)
	else:
		push_warning("GameManager: Temple of Trials não encontrado! Usando mapa temporário...")
		# Fallback: carregar game_scene temporário
		_start_game_directly()

func _start_game_directly():
	"""Inicia o jogo diretamente (fallback temporário)"""
	print("GameManager: Iniciando jogo com mapa temporário...")
	
	# Esconder menu
	var main_menu = _find_main_menu()
	if main_menu:
		main_menu.visible = false
	
	# Carregar cena de jogo
	await _load_game_scene()
	
	# Mudar para modo exploração
	change_state(GameState.EXPLORATION)
	
	print("GameManager: Novo jogo iniciado (temporário)")

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
	
	change_state(GameState.EXPLORATION)

func pause_game():
	"""Pausa o jogo"""
	if change_state(GameState.PAUSED):
		get_tree().paused = true
		pause_time()

func resume_game():
	"""Retoma o jogo"""
	if change_state(previous_state):
		get_tree().paused = false
		resume_time()

func enter_combat():
	"""Entra em modo de combate"""
	change_state(GameState.COMBAT)

func exit_combat():
	"""Sai do modo de combate"""
	change_state(GameState.EXPLORATION)

func open_inventory():
	"""Abre inventário"""
	if change_state(GameState.INVENTORY):
		_pause_for_menu()

func close_inventory():
	"""Fecha inventário"""
	if change_state(previous_state):
		_resume_from_menu()

func open_character_screen():
	"""Abre tela de personagem"""
	if change_state(GameState.PAUSED):
		_pause_for_menu()

func close_character_screen():
	"""Fecha tela de personagem"""
	if previous_state == GameState.EXPLORATION:
		if change_state(previous_state):
			_resume_from_menu()

func open_options_screen():
	"""Abre tela de opções"""
	if change_state(GameState.PAUSED):
		_pause_for_menu()

func close_options_screen():
	"""Fecha tela de opções"""
	if previous_state == GameState.EXPLORATION:
		if change_state(previous_state):
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
	change_state(GameState.DIALOG)

func end_dialog():
	"""Termina diálogo"""
	change_state(previous_state)

func quit_to_menu():
	"""Volta ao menu principal"""
	# Limpar cena de jogo
	if current_map:
		current_map.queue_free()
		current_map = null
	
	player = null
	change_state(GameState.MENU)
	
	# Mostrar menu
	var main_menu = _find_main_menu()
	if main_menu:
		main_menu.visible = true

func quit_game():
	"""Sai do jogo"""
	print("GameManager: Saindo do jogo...")
	get_tree().quit()

func _process(delta: float):
	"""Atualiza sistema de tempo do jogo"""
	if not is_time_paused and current_state != GameState.MENU and current_state != GameState.LOADING:
		_update_game_time(delta)

func _input(event):
	"""Processa input global"""
	if event.is_action_pressed("pause"):
		if current_state == GameState.EXPLORATION:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()
	
	if event.is_action_pressed("inventory"):
		if current_state == GameState.EXPLORATION:
			open_inventory()
		elif current_state == GameState.INVENTORY:
			close_inventory()
	
	if event.is_action_pressed("character"):
		if current_state == GameState.EXPLORATION:
			open_character_screen()
		elif current_state == GameState.PAUSED:
			close_character_screen()

# Utilitários
func is_playing() -> bool:
	return current_state == GameState.EXPLORATION

func is_in_combat() -> bool:
	return current_state == GameState.COMBAT

func is_in_dialog() -> bool:
	return current_state == GameState.DIALOG

func can_player_move() -> bool:
	return current_state == GameState.EXPLORATION

# === SISTEMA DE TEMPO DO JOGO ===

func _initialize_game_time():
	"""Inicializa o sistema de tempo do jogo"""
	game_time_ticks = 302400  # Tempo inicial (baseado no original)
	last_time_update = Time.get_ticks_msec() / 1000.0
	is_time_paused = false
	print("GameManager: Sistema de tempo inicializado - ", get_time_string())

func _update_game_time(delta: float):
	"""Atualiza o tempo do jogo baseado no tempo real"""
	if is_time_paused:
		return
	
	# Converter delta (segundos) para ticks do jogo
	var ticks_to_add = int(delta * GAME_TIME_TICKS_PER_SECOND * time_speed_multiplier)
	game_time_ticks += ticks_to_add
	
	# Verificar eventos baseados em tempo
	_check_time_based_events()
	
	# Verificar se passou meia-noite
	if _is_midnight():
		_on_midnight()

func _check_time_based_events():
	"""Verifica eventos baseados em tempo"""
	# Eventos podem ser adicionados aqui
	pass

func _is_midnight() -> bool:
	"""Verifica se é meia-noite (00:00)"""
	var hour = get_game_hour()
	var minute = get_game_minute()
	return hour == 0 and minute == 0

func _on_midnight():
	"""Callback quando passa meia-noite"""
	print("GameManager: Meia-noite! Processando eventos...")
	# Processar eventos de meia-noite (radiação, scripts, etc.)
	# TODO: Implementar processamento de eventos

func get_game_time() -> int:
	"""Retorna o tempo do jogo em ticks"""
	return game_time_ticks

func set_game_time(ticks: int):
	"""Define o tempo do jogo em ticks"""
	if ticks == 0:
		ticks = 1
	game_time_ticks = ticks

func add_game_time_ticks(ticks: int):
	"""Adiciona ticks ao tempo do jogo"""
	game_time_ticks += ticks
	
	# Verificar timeout (13 anos = game over)
	var years = game_time_ticks / GAME_TIME_TICKS_PER_YEAR
	if years >= 13:
		# Game over por timeout
		print("GameManager: Tempo esgotado! Game Over.")
		# TODO: Implementar game over

func add_game_time_seconds(seconds: int):
	"""Adiciona segundos ao tempo do jogo"""
	add_game_time_ticks(seconds * GAME_TIME_TICKS_PER_SECOND)

func add_game_time_minutes(minutes: int):
	"""Adiciona minutos ao tempo do jogo"""
	add_game_time_ticks(minutes * GAME_TIME_TICKS_PER_MINUTE)

func add_game_time_hours(hours: int):
	"""Adiciona horas ao tempo do jogo"""
	add_game_time_ticks(hours * GAME_TIME_TICKS_PER_HOUR)

func get_game_hour() -> int:
	"""Retorna a hora do jogo (0-23)"""
	return (game_time_ticks / GAME_TIME_TICKS_PER_MINUTE) / 60 % 24

func get_game_minute() -> int:
	"""Retorna o minuto do jogo (0-59)"""
	return (game_time_ticks / GAME_TIME_TICKS_PER_MINUTE) % 60

func get_game_hour_minute() -> int:
	"""Retorna hora e minuto em formato militar (hhmm)"""
	return 100 * get_game_hour() + get_game_minute()

func get_time_string() -> String:
	"""Retorna string de tempo formatada (h:mm)"""
	var hour = get_game_hour()
	var minute = get_game_minute()
	return "%d:%02d" % [hour, minute]

func get_date() -> Dictionary:
	"""Retorna data do jogo (mês, dia, ano)"""
	var total_days = game_time_ticks / GAME_TIME_TICKS_PER_DAY + GAME_START_DAY
	var year = total_days / 365 + GAME_START_YEAR
	var month = GAME_START_MONTH - 1  # 0-indexed
	var day = total_days % 365
	
	# Ajustar mês e dia
	while day >= DAYS_PER_MONTH[month]:
		day -= DAYS_PER_MONTH[month]
		month += 1
		if month >= 12:
			year += 1
			month = 0
	
	return {
		"year": year,
		"month": month + 1,  # 1-indexed para retorno
		"day": day + 1  # 1-indexed para retorno
	}

func get_date_string() -> String:
	"""Retorna string de data formatada"""
	var date = get_date()
	var month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d, %d" % [month_names[date.month - 1], date.day, date.year]

func is_daytime() -> bool:
	"""Verifica se é dia (6:00 - 18:00)"""
	var hour = get_game_hour()
	return hour >= 6 and hour < 18

func is_nighttime() -> bool:
	"""Verifica se é noite"""
	return not is_daytime()

func pause_time():
	"""Pausa o tempo do jogo"""
	is_time_paused = true

func resume_time():
	"""Retoma o tempo do jogo"""
	is_time_paused = false

func set_time_speed(multiplier: float):
	"""Define a velocidade do tempo (1.0 = normal, 2.0 = 2x mais rápido)"""
	time_speed_multiplier = max(0.0, multiplier)

# === VALIDAÇÃO DE TRANSIÇÕES DE ESTADO ===

func can_transition_to(new_state: GameState) -> bool:
	"""Verifica se é possível transicionar para um novo estado"""
	if not valid_transitions.has(current_state):
		return false
	return new_state in valid_transitions[current_state]

func change_state(new_state: GameState, force: bool = false) -> bool:
	"""
	Muda o estado do jogo com validação.
	
	Args:
		new_state: Novo estado desejado
		force: Se true, força a transição mesmo se inválida
		
	Returns:
		True se a transição foi bem-sucedida
	"""
	if not force and not can_transition_to(new_state):
		push_warning("GameManager: Transição inválida de %s para %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
		return false
	
	previous_state = current_state
	current_state = new_state
	game_state_changed.emit(current_state)
	
	print("GameManager: Estado mudou de %s para %s" % [GameState.keys()[previous_state], GameState.keys()[current_state]])
	return true
