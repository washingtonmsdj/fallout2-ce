extends Control

## Tela de Opções do Fallout 2
## Volume de áudio, dificuldade, controles

signal closed()

var game_manager: Node = null

# Referências
var master_volume_slider: HSlider = null
var music_volume_slider: HSlider = null
var sfx_volume_slider: HSlider = null
var difficulty_option: OptionButton = null

func _ready():
	visible = false
	game_manager = get_node_or_null("/root/GameManager")
	_setup_ui()

func _setup_ui():
	"""Configura elementos da UI"""
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Volume Master
	var master_container = _create_volume_control("Master Volume", 0.0, 1.0)
	master_volume_slider = master_container.get_node("HSlider")
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	main_vbox.add_child(master_container)
	
	# Volume Música
	var music_container = _create_volume_control("Music Volume", 0.0, 1.0)
	music_volume_slider = music_container.get_node("HSlider")
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	main_vbox.add_child(music_container)
	
	# Volume SFX
	var sfx_container = _create_volume_control("SFX Volume", 0.0, 1.0)
	sfx_volume_slider = sfx_container.get_node("HSlider")
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	main_vbox.add_child(sfx_container)
	
	# Dificuldade
	var difficulty_container = HBoxContainer.new()
	var difficulty_label = Label.new()
	difficulty_label.text = "Difficulty:"
	difficulty_label.custom_minimum_size = Vector2(150, 20)
	difficulty_container.add_child(difficulty_label)
	
	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Hard")
	difficulty_option.selected = 1
	difficulty_option.item_selected.connect(_on_difficulty_changed)
	difficulty_container.add_child(difficulty_option)
	main_vbox.add_child(difficulty_container)
	
	# Botão fechar
	var close_button = Button.new()
	close_button.text = "Close (ESC)"
	close_button.pressed.connect(_on_close)
	main_vbox.add_child(close_button)

func _create_volume_control(label_text: String, min_val: float, max_val: float) -> HBoxContainer:
	"""Cria controle de volume"""
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(150, 20)
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.name = "HSlider"
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(200, 20)
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "100%"
	value_label.custom_minimum_size = Vector2(50, 20)
	container.add_child(value_label)
	
	# Conectar slider ao label
	slider.value_changed.connect(func(val): value_label.text = str(int(val * 100)) + "%")
	
	return container

func open():
	"""Abre a tela de opções"""
	visible = true
	_load_settings()

func close():
	"""Fecha a tela de opções"""
	visible = false
	closed.emit()

func _on_close():
	"""Callback do botão fechar"""
	close()

func _load_settings():
	"""Carrega configurações atuais"""
	if not game_manager:
		return
	
	# Carregar volumes
	if master_volume_slider:
		master_volume_slider.value = game_manager.master_volume
	if music_volume_slider:
		music_volume_slider.value = game_manager.music_volume
	if sfx_volume_slider:
		sfx_volume_slider.value = game_manager.sfx_volume
	
	# Carregar dificuldade
	if difficulty_option:
		difficulty_option.selected = game_manager.game_difficulty

func _on_master_volume_changed(value: float):
	"""Aplica volume master"""
	if game_manager:
		game_manager.master_volume = value
		# TODO: Aplicar ao AudioManager

func _on_music_volume_changed(value: float):
	"""Aplica volume de música"""
	if game_manager:
		game_manager.music_volume = value
		# TODO: Aplicar ao AudioManager

func _on_sfx_volume_changed(value: float):
	"""Aplica volume de SFX"""
	if game_manager:
		game_manager.sfx_volume = value
		# TODO: Aplicar ao AudioManager

func _on_difficulty_changed(index: int):
	"""Aplica dificuldade"""
	if game_manager:
		game_manager.game_difficulty = index
		print("OptionsScreen: Dificuldade alterada para: ", index)

func _input(event: InputEvent):
	"""Processa input para fechar tela"""
	if visible and event.is_action_pressed("ui_cancel"):
		close()

