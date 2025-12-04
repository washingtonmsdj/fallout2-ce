extends Control

## Menu Principal do Fallout 2 - IGUAL AO ORIGINAL
## QUALIDADE AAA - Recriação fiel do menu original
## Posições e textos exatamente iguais ao código original

var background_texture: TextureRect
var buttons_container: Control

# Texturas originais
var menu_background: Texture2D = null
var button_normal: Texture2D = null
var button_pressed: Texture2D = null

# Constantes do original (640x480 window)
const MENU_WINDOW_WIDTH = 640
const MENU_WINDOW_HEIGHT = 480

# Offset padrão (pode ser configurável como no original)
var offset_x: int = 0
var offset_y: int = 0

# Posições EXATAS dos botões (igual ao original: offsetX + 30, offsetY + 19 + index * 42 - index)
var button_positions = [
	Vector2(30, 19),      # Intro (index 0: 19 + 0*42 - 0)
	Vector2(30, 60),      # New Game (index 1: 19 + 1*42 - 1)
	Vector2(30, 101),     # Load Game (index 2: 19 + 2*42 - 2)
	Vector2(30, 142),     # Options (index 3: 19 + 3*42 - 3)
	Vector2(30, 183),     # Credits (index 4: 19 + 4*42 - 4)
	Vector2(30, 224),     # Exit (index 5: 19 + 5*42 - 5)
]

# Tamanho dos botões (igual ao original: 26x26)
const BUTTON_SIZE = Vector2(26, 26)

# Textos dos botões (igual ao original - mensagens 9-14 do misc.msg)
var button_texts = [
	"Intro",      # msg.num = 9
	"New Game",   # msg.num = 10
	"Load Game",  # msg.num = 11
	"Options",    # msg.num = 12
	"Credits",    # msg.num = 13
	"Exit",       # msg.num = 14
]

# Posições dos textos (igual ao original: offsetX + 126 - (len/2), offsetY + 42*index - index + 20)
var text_center_x: int = 126  # Centro dos textos (640/2 aproximadamente)

# Atalhos de teclado (igual ao original)
var button_keys = [
	KEY_I,  # Intro
	KEY_N,  # New Game
	KEY_L,  # Load Game
	KEY_O,  # Options
	KEY_C,  # Credits
	KEY_E,  # Exit
]

var buttons: Array[Control] = []
var button_labels: Array[Label] = []

func _ready():
	print("MainMenuOriginal: Carregando menu original do Fallout 2")
	
	# Aguardar próximo frame para garantir que tudo está carregado
	call_deferred("_initialize_menu")

func _initialize_menu():
	"""Inicializa o menu de forma segura"""
	print("MainMenuOriginal: Inicializando menu...")
	
	# Verificar se estamos na árvore
	if not is_inside_tree():
		print("MainMenuOriginal: AVISO - Node não está na árvore, aguardando...")
		await get_tree().process_frame
		if not is_inside_tree():
			print("MainMenuOriginal: ERRO CRÍTICO - Node ainda não está na árvore!")
			return
	
	# Buscar nodes de forma segura
	background_texture = get_node_or_null("BackgroundTexture")
	buttons_container = get_node_or_null("ButtonsContainer")
	
	if not background_texture:
		print("MainMenuOriginal: ERRO - BackgroundTexture não encontrado!")
		return
	
	if not buttons_container:
		print("MainMenuOriginal: ERRO - ButtonsContainer não encontrado!")
		return
	
	print("MainMenuOriginal: Nodes encontrados, carregando texturas...")
	
	# Carregar texturas originais
	load_original_textures()
	
	print("MainMenuOriginal: Criando interface...")
	
	# Criar interface igual ao original
	create_original_interface()
	
	# Configurar entrada
	set_process_input(true)
	
	print("MainMenuOriginal: Menu inicializado com sucesso!")

func load_original_textures():
	"""Carrega texturas originais do Fallout 2"""
	# Tentar carregar MAINMENU.FRM convertido
	var possible_bg_paths = [
		"res://assets/sprites/ui/sprites/MAINMENU/mainmenu_0.png",
		"res://assets/sprites/ui/mainmenu/mainmenu_0.png",
	]
	for bg_path in possible_bg_paths:
		if ResourceLoader.exists(bg_path):
			var loaded = load(bg_path)
			if loaded:
				menu_background = loaded
				print("MainMenuOriginal: Background carregado de: ", bg_path)
				break
			else:
				print("MainMenuOriginal: AVISO - Não foi possível carregar: ", bg_path)
	
	# Tentar carregar MENUUP.FRM
	var possible_up_paths = [
		"res://assets/sprites/ui/sprites/MENUUP/menuup_0.png",
		"res://assets/sprites/ui/menuup/menuup_0.png",
	]
	for btn_up_path in possible_up_paths:
		if ResourceLoader.exists(btn_up_path):
			var loaded = load(btn_up_path)
			if loaded:
				button_normal = loaded
				print("MainMenuOriginal: Botão normal carregado de: ", btn_up_path)
				break
	
	# Tentar carregar MENUDOWN.FRM
	var possible_down_paths = [
		"res://assets/sprites/ui/sprites/MENUDOWN/menudown_0.png",
		"res://assets/sprites/ui/menudown/menudown_0.png",
	]
	for btn_down_path in possible_down_paths:
		if ResourceLoader.exists(btn_down_path):
			var loaded = load(btn_down_path)
			if loaded:
				button_pressed = loaded
				print("MainMenuOriginal: Botão pressionado carregado de: ", btn_down_path)
				break

func create_original_interface():
	"""Cria interface igual ao original"""
	if not background_texture or not buttons_container:
		print("MainMenuOriginal: ERRO - Nodes não inicializados!")
		return
	
	# Background
	if menu_background:
		background_texture.texture = menu_background
		background_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		print("MainMenuOriginal: Usando sprite de background original")
	else:
		# Fallback: cor escura igual ao Fallout 2
		background_texture.modulate = Color(0.1, 0.05, 0.05, 1)
		print("MainMenuOriginal: Usando fallback de background (sprites ainda não convertidos)")
	
	# Criar botões nas posições originais
	for i in range(button_texts.size()):
		create_menu_button(i, button_texts[i], button_positions[i], button_keys[i])
	
	print("MainMenuOriginal: Interface criada com %d botões" % button_texts.size())

func create_menu_button(index: int, text: String, button_pos: Vector2, _key: Key):
	"""Cria botão do menu igual ao original - posições e tamanhos exatos"""
	if not buttons_container:
		print("MainMenuOriginal: ERRO - ButtonsContainer não existe!")
		return
	
	var final_pos = button_pos + Vector2(offset_x, offset_y)
	
	# Criar botão com textura (igual ao original: TextureButton 26x26)
	var texture_button = TextureButton.new()
	texture_button.name = "Button_" + text.replace(" ", "_")
	texture_button.position = final_pos
	texture_button.size = BUTTON_SIZE
	
	# Carregar texturas se disponíveis
	if button_normal:
		texture_button.texture_normal = button_normal
	if button_pressed:
		texture_button.texture_pressed = button_pressed
	
	# Se não tiver textura, criar um botão simples como fallback
	if not button_normal:
		texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	buttons_container.add_child(texture_button)
	texture_button.pressed.connect(_on_button_pressed.bind(index))
	buttons.append(texture_button)
	
	# Criar label com texto (igual ao original: fonte 104, cor _colorTable[21091])
	# Posição: offsetX + 126 - (len/2), offsetY + 42*index - index + 20
	var label = Label.new()
	label.name = "Label_" + text.replace(" ", "_")
	label.text = text
	label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5, 1))  # Cor dourada do original
	label.add_theme_font_size_override("font_size", 16)  # Fonte 104 equivalente
	
	# Calcular posição do texto (centralizado em 126)
	# Usar estimativa simples de largura baseada no texto
	# Aproximadamente 8 pixels por caractere na fonte 16
	var text_width = text.length() * 8.0
	var text_x = final_pos.x + text_center_x - (text_width / 2)
	var text_y = final_pos.y + 20  # offsetY + 42*index - index + 20 (posição relativa ao botão)
	
	label.position = Vector2(text_x, text_y)
	
	# Adicionar com segurança
	if buttons_container:
		buttons_container.add_child(label)
		button_labels.append(label)
	else:
		print("MainMenuOriginal: ERRO - ButtonsContainer não disponível para label")

func _input(event):
	"""Processa atalhos de teclado"""
	if event is InputEventKey and event.pressed:
		for i in range(button_keys.size()):
			if event.keycode == button_keys[i]:
				_on_button_pressed(i)
				break

func _on_button_pressed(index: int):
	"""Handler quando botão é pressionado"""
	if index < 0 or index >= button_texts.size():
		print("MainMenuOriginal: ERRO - Índice de botão inválido: ", index)
		return
	
	var gm = get_node_or_null("/root/GameManager")
	
	match index:
		0:  # Intro
			print("MainMenuOriginal: Intro")
			# TODO: Reproduzir intro
		1:  # New Game
			print("MainMenuOriginal: New Game")
			if gm:
				gm.start_new_game()
			else:
				print("MainMenuOriginal: ERRO - GameManager não encontrado!")
			visible = false
		2:  # Load Game
			print("MainMenuOriginal: Load Game")
			# TODO: Abrir tela de load
		3:  # Options
			print("MainMenuOriginal: Options")
			# TODO: Abrir opções
		4:  # Credits
			print("MainMenuOriginal: Credits")
			# TODO: Mostrar créditos
		5:  # Exit
			print("MainMenuOriginal: Exit")
			if get_tree():
				get_tree().quit()
			else:
				print("MainMenuOriginal: ERRO - Scene tree não disponível!")
