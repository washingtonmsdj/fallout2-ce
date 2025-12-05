extends Control

## Menu Principal do Fallout 2 - Usando sprites originais
## Posicoes baseadas no codigo original (src/mainmenu.cc)

const BUTTON_KEYS = [KEY_I, KEY_N, KEY_L, KEY_O, KEY_C, KEY_E]

@onready var btn_intro: Button = $MenuContainer/BtnIntro
@onready var btn_new_game: Button = $MenuContainer/BtnNewGame
@onready var btn_load_game: Button = $MenuContainer/BtnLoadGame
@onready var btn_options: Button = $MenuContainer/BtnOptions
@onready var btn_credits: Button = $MenuContainer/BtnCredits
@onready var btn_exit: Button = $MenuContainer/BtnExit

func _ready():
	print("MainMenu: Carregado com sprites originais")
	
	# Conectar sinais programaticamente como backup
	if btn_intro and not btn_intro.pressed.is_connected(_on_intro_pressed):
		btn_intro.pressed.connect(_on_intro_pressed)
	if btn_new_game and not btn_new_game.pressed.is_connected(_on_new_game_pressed):
		btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_load_game and not btn_load_game.pressed.is_connected(_on_load_game_pressed):
		btn_load_game.pressed.connect(_on_load_game_pressed)
	if btn_options and not btn_options.pressed.is_connected(_on_options_pressed):
		btn_options.pressed.connect(_on_options_pressed)
	if btn_credits and not btn_credits.pressed.is_connected(_on_credits_pressed):
		btn_credits.pressed.connect(_on_credits_pressed)
	if btn_exit and not btn_exit.pressed.is_connected(_on_exit_pressed):
		btn_exit.pressed.connect(_on_exit_pressed)
	
	print("MainMenu: Botoes configurados")

func _on_intro_pressed():
	print("MainMenu: INTRO pressionado")

func _on_new_game_pressed():
	print("MainMenu: NEW GAME pressionado - Iniciando Temple of Trials...")
	
	# IGUAL AO ORIGINAL: Carregar DIRETAMENTE o primeiro mapa
	# No Fallout 2, não existe tela de criação de personagem
	# O jogo começa direto no Temple of Trials (artemple.map)
	
	# Tentar carregar o mapa convertido do original
	var artemple_path = "res://scenes/maps/artemple.tscn"
	var temple_path = "res://scenes/maps/temple_of_trials.tscn"
	
	if ResourceLoader.exists(artemple_path):
		print("MainMenu: Carregando artemple.tscn (mapa original convertido)...")
		get_tree().change_scene_to_file(artemple_path)
	elif ResourceLoader.exists(temple_path):
		print("MainMenu: Carregando temple_of_trials.tscn (fallback)...")
		get_tree().change_scene_to_file(temple_path)
	else:
		print("MainMenu: Nenhum mapa encontrado, carregando game_scene...")
		_load_game_scene_directly()

func _load_game_scene_directly():
	"""Carrega a cena de jogo temporária (até termos o Temple of Trials)"""
	print("MainMenu: Carregando game_scene.tscn temporário...")
	var game_scene_path = "res://scenes/game/game_scene.tscn"
	if ResourceLoader.exists(game_scene_path):
		get_tree().change_scene_to_file(game_scene_path)
		print("MainMenu: Cena de jogo carregada!")
	else:
		push_error("MainMenu: ERRO - Cena de jogo não encontrada!")

func _on_load_game_pressed():
	print("MainMenu: LOAD GAME pressionado")

func _on_options_pressed():
	print("MainMenu: OPTIONS pressionado")

func _on_credits_pressed():
	print("MainMenu: CREDITS pressionado")

func _on_exit_pressed():
	print("MainMenu: EXIT pressionado")
	get_tree().quit()

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_I: _on_intro_pressed()
			KEY_N: _on_new_game_pressed()
			KEY_L: _on_load_game_pressed()
			KEY_O: _on_options_pressed()
			KEY_C: _on_credits_pressed()
			KEY_E: _on_exit_pressed()
