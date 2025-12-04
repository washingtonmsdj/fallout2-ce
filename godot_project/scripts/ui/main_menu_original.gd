extends Control

## Menu principal usando assets originais do Fallout 2
## QUALIDADE AAA - Fiel ao original mas melhorado

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var buttons_container: VBoxContainer = $ButtonsContainer

# Texturas do menu original
var menu_background: Texture2D
var button_normal: Texture2D
var button_pressed: Texture2D

func _ready():
	print("MainMenuOriginal: Carregando menu original do Fallout 2")
	
	# Tentar carregar texturas originais
	load_original_textures()
	
	# Se não conseguir, usar fallback
	if not menu_background:
		print("MainMenuOriginal: Texturas originais não encontradas, usando fallback")
		setup_fallback_menu()

func load_original_textures():
	"""Carrega texturas do menu original do Fallout 2"""
	# Tentar carregar MAINMENU.FRM convertido
	var bg_path = "res://assets/sprites/ui/mainmenu.png"
	if ResourceLoader.exists(bg_path):
		menu_background = load(bg_path)
		if menu_background and background_texture:
			background_texture.texture = menu_background
			print("MainMenuOriginal: Background carregado")
	
	# Tentar carregar MENUUP.FRM convertido
	var btn_normal_path = "res://assets/sprites/ui/menuup.png"
	if ResourceLoader.exists(btn_normal_path):
		button_normal = load(btn_normal_path)
	
	# Tentar carregar MENUDOWN.FRM convertido
	var btn_pressed_path = "res://assets/sprites/ui/menudown.png"
	if ResourceLoader.exists(btn_pressed_path):
		button_pressed = load(btn_pressed_path)

func setup_fallback_menu():
	"""Cria menu de fallback se texturas originais não estiverem disponíveis"""
	# Este será o menu atual que já funciona
	pass

