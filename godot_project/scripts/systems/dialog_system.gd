extends Node

## Sistema de Dialogos do Fallout 2
## Baseado no codigo original (src/game_dialog.cc)

signal dialog_started(npc: Node)
signal dialog_ended()
signal dialog_option_selected(option_index: int)
signal dialog_text_changed(text: String)

# Estado do dialogo
var is_active: bool = false
var current_npc: Node = null
var current_dialog: Dictionary = {}
var current_node_id: String = ""
var dialog_history: Array = []

# Referencia ao player
var player: Node = null

func _ready():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(p: Node):
	player = p

# === INICIO/FIM DO DIALOGO ===

func start_dialog(npc: Node, dialog_data: Dictionary = {}):
	"""Inicia dialogo com NPC"""
	if is_active:
		return
	
	current_npc = npc
	current_dialog = dialog_data
	is_active = true
	dialog_history.clear()
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.start_dialog(npc)
	
	# Iniciar no primeiro node
	if current_dialog.has("start"):
		current_node_id = current_dialog["start"]
	else:
		current_node_id = "start"
	
	dialog_started.emit(npc)
	_show_current_node()

func end_dialog():
	"""Termina dialogo"""
	if not is_active:
		return
	
	is_active = false
	current_npc = null
	current_dialog = {}
	current_node_id = ""
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.end_dialog()
	
	dialog_ended.emit()

# === NAVEGACAO ===

func select_option(option_index: int):
	"""Seleciona uma opcao de dialogo"""
	if not is_active:
		return
	
	var node = _get_current_node()
	if not node:
		return
	
	var options = node.get("options", [])
	if option_index < 0 or option_index >= options.size():
		return
	
	var option = options[option_index]
	dialog_option_selected.emit(option_index)
	
	# Adicionar ao historico
	dialog_history.append({
		"node": current_node_id,
		"option": option_index,
		"text": option.get("text", "")
	})
	
	# Executar acoes da opcao
	_execute_option_actions(option)
	
	# Ir para proximo node
	var next_node = option.get("next", "")
	if next_node == "end" or next_node.is_empty():
		end_dialog()
	else:
		current_node_id = next_node
		_show_current_node()

func _show_current_node():
	"""Mostra o node atual do dialogo"""
	var node = _get_current_node()
	if not node:
		end_dialog()
		return
	
	var text = node.get("text", "")
	
	# Substituir variaveis
	text = _process_text(text)
	
	dialog_text_changed.emit(text)

func _get_current_node() -> Dictionary:
	"""Retorna o node atual do dialogo"""
	if not current_dialog.has("nodes"):
		return {}
	
	var nodes = current_dialog["nodes"]
	if nodes.has(current_node_id):
		return nodes[current_node_id]
	
	return {}

func _process_text(text: String) -> String:
	"""Processa texto substituindo variaveis"""
	if not player:
		return text
	
	# Substituir variaveis comuns
	text = text.replace("$PLAYER_NAME", "Chosen One")
	text = text.replace("$NPC_NAME", current_npc.name if current_npc else "NPC")
	
	return text

func _execute_option_actions(option: Dictionary):
	"""Executa acoes de uma opcao"""
	var actions = option.get("actions", [])
	
	for action in actions:
		var action_type = action.get("type", "")
		
		match action_type:
			"give_item":
				_action_give_item(action)
			"take_item":
				_action_take_item(action)
			"give_xp":
				_action_give_xp(action)
			"set_flag":
				_action_set_flag(action)
			"start_combat":
				_action_start_combat()

func _action_give_item(action: Dictionary):
	"""Da item ao player"""
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		var item = action.get("item", {})
		var qty = action.get("quantity", 1)
		inv.add_item(item, qty)

func _action_take_item(action: Dictionary):
	"""Remove item do player"""
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		var item_id = action.get("item_id", "")
		var qty = action.get("quantity", 1)
		inv.remove_item(item_id, qty)

func _action_give_xp(action: Dictionary):
	"""Da XP ao player"""
	if player and player.has_method("add_experience"):
		var amount = action.get("amount", 0)
		player.add_experience(amount)

func _action_set_flag(action: Dictionary):
	"""Define uma flag global"""
	# TODO: Implementar sistema de flags
	pass

func _action_start_combat():
	"""Inicia combate com NPC"""
	end_dialog()
	var combat = get_node_or_null("/root/CombatSystem")
	if combat and current_npc:
		combat.start_combat([current_npc])

# === UTILIDADES ===

func get_current_text() -> String:
	"""Retorna texto atual"""
	var node = _get_current_node()
	return _process_text(node.get("text", ""))

func get_current_options() -> Array:
	"""Retorna opcoes atuais"""
	var node = _get_current_node()
	var options = node.get("options", [])
	
	# Filtrar opcoes baseado em condicoes
	var filtered = []
	for opt in options:
		if _check_option_conditions(opt):
			filtered.append(opt)
	
	return filtered

func _check_option_conditions(option: Dictionary) -> bool:
	"""Verifica se opcao esta disponivel"""
	var conditions = option.get("conditions", [])
	
	for cond in conditions:
		var cond_type = cond.get("type", "")
		
		match cond_type:
			"has_item":
				var inv = get_node_or_null("/root/InventorySystem")
				if inv and not inv.has_item(cond.get("item_id", "")):
					return false
			"skill_check":
				# TODO: Implementar verificacao de skill
				pass
			"stat_check":
				if player:
					var stat = cond.get("stat", "")
					var min_val = cond.get("min", 0)
					if player.has_method("get") and player.get(stat) < min_val:
						return false
	
	return true

# === CRIACAO DE DIALOGOS (para testes) ===

func create_simple_dialog(npc_text: String, options: Array) -> Dictionary:
	"""Cria um dialogo simples"""
	var dialog_options = []
	for i in range(options.size()):
		dialog_options.append({
			"text": options[i],
			"next": "end"
		})
	
	return {
		"start": "node1",
		"nodes": {
			"node1": {
				"text": npc_text,
				"options": dialog_options
			}
		}
	}
