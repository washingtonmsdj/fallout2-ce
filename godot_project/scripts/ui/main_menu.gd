extends Control

## Menu principal do jogo
## QUALIDADE AAA - Interface profissional e funcional

func _ready():
	print("MainMenu: Carregado")
	# GameManager é autoload, sempre disponível
	GameManager.game_state_changed.connect(_on_game_state_changed)
	# Garantir que menu está visível
	visible = true

func _on_new_game_pressed():
	"""Botão New Game pressionado"""
	print("MainMenu: New Game pressionado")
	GameManager.start_new_game()
	# Ocultar menu
	visible = false

func _on_exit_pressed():
	"""Botão Exit pressionado"""
	print("MainMenu: Exit pressionado")
	get_tree().quit()

func _on_game_state_changed(new_state: String):
	"""Callback quando estado do jogo muda"""
	print("MainMenu: Estado mudou para: ", new_state)
	match new_state:
		"menu":
			visible = true
		"playing":
			visible = false

