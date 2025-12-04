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
	print("MainMenu: NEW GAME pressionado - Iniciando...")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		print("MainMenu: GameManager encontrado, chamando start_new_game()")
		gm.start_new_game()
		visible = false
	else:
		print("MainMenu: ERRO - GameManager nao encontrado!")
		# Fallback: tentar carregar a cena de jogo diretamente
		_load_game_scene_directly()

func _load_game_scene_directly():
	"""Carrega a cena de jogo diretamente como fallback"""
	print("MainMenu: Tentando carregar cena de jogo diretamente...")
	var game_scene = load("res://scenes/game/game_scene.tscn")
	if game_scene:
		var instance = game_scene.instantiate()
		get_tree().current_scene.add_child(instance)
		visible = false
		print("MainMenu: Cena de jogo carregada com sucesso!")
	else:
		print("MainMenu: ERRO - Nao foi possivel carregar a cena de jogo!")

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
