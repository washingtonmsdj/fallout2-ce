extends Node

## Sistema de Gerenciamento de Cursor Contextual
## Muda o cursor baseado no modo e objetos sob o mouse
## Mostra tooltips com informações

# Referências
var input_manager: Node = null
var tooltip_label: Label = null

# Estado
var current_object: Node = null
var tooltip_visible: bool = false

# Cursores customizados (paths para texturas)
var cursor_textures = {
	InputManager.CursorMode.MOVEMENT: null,    # Usar cursor padrão
	InputManager.CursorMode.ATTACK: null,      # Cursor de mira
	InputManager.CursorMode.USE: null,         # Cursor de mão
	InputManager.CursorMode.EXAMINE: null,     # Cursor de lupa
	InputManager.CursorMode.TALK: null         # Cursor de balão de fala
}

func _ready():
	# Obter referência ao InputManager
	input_manager = get_node_or_null("/root/InputManager")
	
	if input_manager == null:
		push_error("CursorManager: InputManager não encontrado!")
		return
	
	# Conectar sinais
	input_manager.cursor_mode_changed.connect(_on_cursor_mode_changed)
	
	# Criar tooltip label
	_create_tooltip()
	
	print("CursorManager: Inicializado")

func _process(_delta: float):
	# Atualizar cursor baseado no objeto sob o mouse
	_update_cursor_for_object()
	
	# Atualizar tooltip
	_update_tooltip()

func _create_tooltip():
	"""Cria o label de tooltip"""
	tooltip_label = Label.new()
	tooltip_label.name = "CursorTooltip"
	tooltip_label.z_index = 1000  # Sempre no topo
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Estilo do tooltip
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Adicionar à árvore
	get_tree().root.add_child(tooltip_label)
	tooltip_label.hide()

func _update_cursor_for_object():
	"""
	Atualiza o cursor baseado no objeto sob o mouse
	"""
	if input_manager == null:
		return
	
	var object = input_manager.get_object_at_mouse()
	
	# Verificar se mudou de objeto
	if object != current_object:
		current_object = object
		_apply_cursor()

func _apply_cursor():
	"""
	Aplica o cursor apropriado baseado no modo e objeto atual
	"""
	var mode = input_manager.get_cursor_mode()
	
	# Se há objeto interagível, pode usar cursor especial
	if current_object != null:
		# Cursor contextual baseado no tipo de objeto
		if current_object.has_method("get_cursor_type"):
			var cursor_type = current_object.get_cursor_type()
			_set_custom_cursor(cursor_type)
			return
	
	# Usar cursor do modo atual
	var cursor_texture = cursor_textures.get(mode)
	if cursor_texture != null:
		Input.set_custom_mouse_cursor(cursor_texture)
	else:
		Input.set_custom_mouse_cursor(null)  # Cursor padrão

func _set_custom_cursor(cursor_type: String):
	"""Define cursor customizado por tipo"""
	# Aqui você pode carregar texturas específicas
	# Por enquanto, usar cursor padrão
	Input.set_custom_mouse_cursor(null)

func _update_tooltip():
	"""
	Atualiza o tooltip com informações do objeto sob o mouse
	"""
	if tooltip_label == null:
		return
	
	if current_object != null and current_object.has_method("get_display_name"):
		# Mostrar tooltip
		var display_name = current_object.get_display_name()
		tooltip_label.text = display_name
		
		# Posicionar próximo ao mouse
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip_label.position = mouse_pos + Vector2(15, 15)
		
		if not tooltip_visible:
			tooltip_label.show()
			tooltip_visible = true
	else:
		# Esconder tooltip
		if tooltip_visible:
			tooltip_label.hide()
			tooltip_visible = false

func _on_cursor_mode_changed(new_mode: int):
	"""Callback quando o modo do cursor muda"""
	print("CursorManager: Modo alterado para ", InputManager.CursorMode.keys()[new_mode])
	_apply_cursor()

func set_cursor_texture(mode: int, texture_path: String):
	"""
	Define a textura do cursor para um modo específico
	"""
	var texture = load(texture_path)
	if texture != null:
		cursor_textures[mode] = texture
		print("CursorManager: Textura definida para modo ", InputManager.CursorMode.keys()[mode])
	else:
		push_error("CursorManager: Falha ao carregar textura - ", texture_path)

func show_custom_tooltip(text: String, duration: float = 2.0):
	"""
	Mostra um tooltip customizado temporariamente
	"""
	if tooltip_label == null:
		return
	
	tooltip_label.text = text
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip_label.position = mouse_pos + Vector2(15, 15)
	tooltip_label.show()
	tooltip_visible = true
	
	# Esconder após duração
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		if tooltip_label.text == text:  # Só esconder se ainda for o mesmo texto
			tooltip_label.hide()
			tooltip_visible = false
