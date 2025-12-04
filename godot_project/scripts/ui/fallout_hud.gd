extends Control

## HUD do Fallout 2 - Interface original
## Expandido com barras dinâmicas, slot de arma e tooltips

@onready var hp_label: Label = $InterfaceBar/HPLabel
@onready var ac_label: Label = $InterfaceBar/ACLabel
@onready var ap_label: Label = $InterfaceBar/APLabel
@onready var location_label: Label = $LocationLabel

# Barras dinâmicas
var hp_bar: ProgressBar = null
var ap_bar: ProgressBar = null
var weapon_slot: Control = null
var tooltip: Control = null

var player: Node = null
var is_in_combat: bool = false

func _ready():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_spawned.connect(_on_player_spawned)
		gm.game_state_changed.connect(_on_game_state_changed)
	
	# Criar barras dinâmicas se não existirem
	_setup_dynamic_bars()
	
	# Criar slot de arma
	_setup_weapon_slot()
	
	# Criar tooltip
	_setup_tooltip()
	
	visible = false

func _on_player_spawned(p: Node):
	player = p
	visible = true
	
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
	if player.has_signal("ap_changed"):
		player.ap_changed.connect(_on_ap_changed)
	
	_update_display()

func _on_game_state_changed(state: int):
	# 0=MENU, 1=PLAYING
	visible = state != 0

func _on_hp_changed(current: int, maximum: int):
	"""
	Atualiza barra de HP dinâmica
	Atualizar em tempo real e mostrar valor numérico
	"""
	if hp_label:
		hp_label.text = str(current) + "/" + str(maximum)
	
	# Atualizar barra de HP
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current
		# Mudar cor baseado em porcentagem
		var percent = float(current) / float(maximum) if maximum > 0 else 0.0
		if percent > 0.6:
			hp_bar.modulate = Color.GREEN
		elif percent > 0.3:
			hp_bar.modulate = Color.YELLOW
		else:
			hp_bar.modulate = Color.RED

func _on_ap_changed(current: int, maximum: int):
	"""
	Atualiza barra de AP
	Mostrar AP atual/máximo e destacar em combate
	"""
	if ap_label:
		ap_label.text = str(current) + "/" + str(maximum)
	
	# Atualizar barra de AP
	if ap_bar:
		ap_bar.max_value = maximum
		ap_bar.value = current
		
		# Destacar em combate
		if is_in_combat:
			ap_bar.modulate = Color.CYAN
		else:
			ap_bar.modulate = Color.WHITE

func _update_display():
	if not player:
		return
	
	if hp_label and player.has_method("get"):
		hp_label.text = str(player.hp) + "/" + str(player.max_hp)
	
	if ac_label and player.has_method("get"):
		ac_label.text = str(player.armor_class)
	
	if ap_label and player.has_method("get"):
		ap_label.text = str(player.action_points) + "/" + str(player.max_action_points)

func set_location(name: String):
	if location_label:
		location_label.text = name.to_upper()

# === BARRAS DINÂMICAS ===

func _setup_dynamic_bars():
	"""Cria barras dinâmicas de HP e AP"""
	var interface_bar = get_node_or_null("InterfaceBar")
	if not interface_bar:
		return
	
	# Barra de HP
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(200, 20)
	hp_bar.position = Vector2(10, 10)
	interface_bar.add_child(hp_bar)
	
	# Barra de AP
	ap_bar = ProgressBar.new()
	ap_bar.name = "APBar"
	ap_bar.min_value = 0
	ap_bar.max_value = 10
	ap_bar.value = 10
	ap_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ap_bar.custom_minimum_size = Vector2(200, 20)
	ap_bar.position = Vector2(10, 35)
	interface_bar.add_child(ap_bar)

# === SLOT DE ARMA ===

func _setup_weapon_slot():
	"""
	Implementar slot de arma
	Mostrar arma equipada e permitir troca rápida
	"""
	weapon_slot = Control.new()
	weapon_slot.name = "WeaponSlot"
	weapon_slot.custom_minimum_size = Vector2(60, 60)
	weapon_slot.position = Vector2(size.x - 80, 10)
	add_child(weapon_slot)
	
	# Criar botão de arma
	var weapon_button = Button.new()
	weapon_button.name = "WeaponButton"
	weapon_button.text = "W"
	weapon_button.custom_minimum_size = Vector2(60, 60)
	weapon_button.pressed.connect(_on_weapon_slot_clicked)
	weapon_slot.add_child(weapon_button)
	
	# Label de nome da arma
	var weapon_label = Label.new()
	weapon_label.name = "WeaponLabel"
	weapon_label.text = "Nenhuma"
	weapon_label.position = Vector2(0, 65)
	weapon_label.size = Vector2(60, 20)
	weapon_slot.add_child(weapon_label)
	
	# Conectar ao inventário para atualizar
	var inventory = get_node_or_null("/root/InventorySystem")
	if inventory:
		inventory.item_equipped.connect(_on_weapon_equipped)
		inventory.item_unequipped.connect(_on_weapon_unequipped)
		_update_weapon_slot()

func _on_weapon_slot_clicked():
	"""Troca rápida de arma"""
	print("HUD: Troca rápida de arma (placeholder)")

func _on_weapon_equipped(item: Dictionary, slot: String):
	"""Atualiza slot quando arma é equipada"""
	if slot == "right_hand" or slot == "left_hand":
		_update_weapon_slot()

func _on_weapon_unequipped(item: Dictionary, slot: String):
	"""Atualiza slot quando arma é desequipada"""
	if slot == "right_hand" or slot == "left_hand":
		_update_weapon_slot()

func _update_weapon_slot():
	"""Atualiza display do slot de arma"""
	var inventory = get_node_or_null("/root/InventorySystem")
	if not inventory or not weapon_slot:
		return
	
	var weapon = inventory.get_active_weapon()
	var weapon_label = weapon_slot.get_node_or_null("WeaponLabel")
	
	if weapon_label:
		if not weapon.is_empty():
			weapon_label.text = weapon.get("name", "Arma")
		else:
			weapon_label.text = "Nenhuma"

# === TOOLTIPS ===

func _setup_tooltip():
	"""
	Implementar tooltips
	Mostrar info ao passar mouse
	"""
	tooltip = Control.new()
	tooltip.name = "Tooltip"
	tooltip.visible = false
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 1000
	add_child(tooltip)
	
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.size = Vector2(200, 100)
	tooltip.add_child(bg)
	
	# Label de texto
	var tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.text = ""
	tooltip_label.position = Vector2(5, 5)
	tooltip_label.size = Vector2(190, 90)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip.add_child(tooltip_label)

func show_tooltip(text: String, position: Vector2):
	"""Mostra tooltip com texto na posição"""
	if not tooltip:
		return
	
	var tooltip_label = tooltip.get_node_or_null("TooltipLabel")
	if tooltip_label:
		tooltip_label.text = text
	
	tooltip.position = position
	tooltip.visible = true

func hide_tooltip():
	"""Esconde tooltip"""
	if tooltip:
		tooltip.visible = false

func _input(event: InputEvent):
	"""Detecta hover para tooltips"""
	if event is InputEventMouseMotion:
		# Verificar se está sobre elementos com tooltip
		# Por enquanto, placeholder
		pass

# === ATUALIZAÇÕES ===

func set_combat_state(in_combat: bool):
	"""Define se está em combate (para destacar AP)"""
	is_in_combat = in_combat
	if ap_bar:
		if is_in_combat:
			ap_bar.modulate = Color.CYAN
		else:
			ap_bar.modulate = Color.WHITE
