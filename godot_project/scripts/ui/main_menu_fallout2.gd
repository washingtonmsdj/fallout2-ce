extends Control

## Menu Principal do Fallout 2 - Usando sprites originais
## Posicoes baseadas no codigo original (src/mainmenu.cc)

const BUTTON_KEYS = [KEY_I, KEY_N, KEY_L, KEY_O, KEY_C, KEY_E]

func _ready():
	print("MainMenu: Carregado com sprites originais")

func _on_intro_pressed():
	print("MainMenu: INTRO")

func _on_new_game_pressed():
	print("MainMenu: NEW GAME - Iniciando...")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_new_game()
		visible = false

func _on_load_game_pressed():
	print("MainMenu: LOAD GAME")

func _on_options_pressed():
	print("MainMenu: OPTIONS")

func _on_credits_pressed():
	print("MainMenu: CREDITS")

func _on_exit_pressed():
	print("MainMenu: EXIT")
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
