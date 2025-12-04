extends Control

## Tela de Personagem do Fallout 2
## Exibe stats SPECIAL, skills e perks

signal closed()

var player: Node = null

# Referências aos elementos da UI
var special_labels: Dictionary = {}
var skills_container: VBoxContainer = null
var perks_container: VBoxContainer = null

func _ready():
	visible = false
	_setup_ui()

func _setup_ui():
	"""Configura elementos da UI"""
	# Criar layout básico
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.name = "Title"
	title.text = "CHARACTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Container de SPECIAL
	var special_container = VBoxContainer.new()
	special_container.name = "SpecialContainer"
	main_vbox.add_child(special_container)
	
	var special_title = Label.new()
	special_title.text = "SPECIAL"
	special_container.add_child(special_title)
	
	# Labels de SPECIAL
	var special_names = ["Strength", "Perception", "Endurance", "Charisma", "Intelligence", "Agility", "Luck"]
	for stat_name in special_names:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = stat_name + ":"
		label.custom_minimum_size = Vector2(100, 20)
		hbox.add_child(label)
		
		var value_label = Label.new()
		value_label.name = stat_name + "Value"
		value_label.text = "5"
		special_labels[stat_name] = value_label
		hbox.add_child(value_label)
		
		special_container.add_child(hbox)
	
	# Container de Skills
	skills_container = VBoxContainer.new()
	skills_container.name = "SkillsContainer"
	main_vbox.add_child(skills_container)
	
	var skills_title = Label.new()
	skills_title.text = "SKILLS"
	skills_container.add_child(skills_title)
	
	# Container de Perks
	perks_container = VBoxContainer.new()
	perks_container.name = "PerksContainer"
	main_vbox.add_child(perks_container)
	
	var perks_title = Label.new()
	perks_title.text = "PERKS"
	perks_container.add_child(perks_title)
	
	# Botão de fechar
	var close_button = Button.new()
	close_button.text = "Close (C)"
	close_button.pressed.connect(_on_close)
	main_vbox.add_child(close_button)

func open():
	"""Abre a tela de personagem"""
	visible = true
	_update_display()

func close():
	"""Fecha a tela de personagem"""
	visible = false
	closed.emit()

func _on_close():
	"""Callback do botão fechar"""
	close()

func _update_display():
	"""Atualiza display com dados do player"""
	if not player:
		# Tentar obter player do GameManager
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			player = gm.player
	
	if not player:
		return
	
	# Atualizar SPECIAL
	if player.has("strength"):
		_update_special_label("Strength", player.strength)
	if player.has("perception"):
		_update_special_label("Perception", player.perception)
	if player.has("endurance"):
		_update_special_label("Endurance", player.endurance)
	if player.has("charisma"):
		_update_special_label("Charisma", player.charisma)
	if player.has("intelligence"):
		_update_special_label("Intelligence", player.intelligence)
	if player.has("agility"):
		_update_special_label("Agility", player.agility)
	if player.has("luck"):
		_update_special_label("Luck", player.luck)
	
	# TODO: Atualizar skills e perks quando sistema estiver implementado

func _update_special_label(stat_name: String, value: int):
	"""Atualiza label de stat SPECIAL"""
	if special_labels.has(stat_name):
		special_labels[stat_name].text = str(value)

func _input(event: InputEvent):
	"""Processa input para fechar tela"""
	if visible and event.is_action_pressed("ui_cancel"):
		close()
	if visible and event.is_action_pressed("character"):
		close()

