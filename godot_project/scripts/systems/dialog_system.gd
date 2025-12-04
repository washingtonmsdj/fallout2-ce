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
	"""
	Processa texto substituindo variaveis
	Suporta placeholders {var_name} e $VAR_NAME
	"""
	if not player:
		return text
	
	# Substituir variaveis com formato {var_name}
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	var result = regex.search_all(text)
	
	for match in result:
		var var_name = match.get_string(1)
		var value = _get_variable_value(var_name)
		text = text.replace("{" + var_name + "}", str(value))
	
	# Substituir variaveis com formato $VAR_NAME (legado)
	text = text.replace("$PLAYER_NAME", _get_variable_value("player_name"))
	text = text.replace("$NPC_NAME", _get_variable_value("npc_name"))
	
	return text

func _get_variable_value(var_name: String) -> String:
	"""
	Retorna valor de uma variavel do game state
	Suporta player stats, inventario, flags, etc
	"""
	if not player:
		return ""
	
	# Variaveis do player
	match var_name:
		"player_name":
			return player.get("name") if player.has("name") else "Chosen One"
		"npc_name":
			return current_npc.name if current_npc else "NPC"
		"player_level":
			return str(player.get("level") if player.has("level") else 1)
		"player_hp":
			return str(player.get("hp") if player.has("hp") else 0)
		"player_max_hp":
			return str(player.get("max_hp") if player.has("max_hp") else 0)
		"player_strength":
			return str(player.get("strength") if player.has("strength") else 0)
		"player_perception":
			return str(player.get("perception") if player.has("perception") else 0)
		"player_endurance":
			return str(player.get("endurance") if player.has("endurance") else 0)
		"player_charisma":
			return str(player.get("charisma") if player.has("charisma") else 0)
		"player_intelligence":
			return str(player.get("intelligence") if player.has("intelligence") else 0)
		"player_agility":
			return str(player.get("agility") if player.has("agility") else 0)
		"player_luck":
			return str(player.get("luck") if player.has("luck") else 0)
		_:
			# Tentar obter do player diretamente
			if player.has(var_name):
				return str(player.get(var_name))
			
			# Tentar obter de flags globais (TODO: implementar)
			# Por enquanto, retornar vazio
			return ""

func _execute_option_actions(option: Dictionary):
	"""
	Executa acoes de uma opcao
	Suporta: dar/remover item, XP, reputacao, iniciar combate, abrir comercio
	"""
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
			"give_reputation":
				_action_give_reputation(action)
			"set_flag":
				_action_set_flag(action)
			"start_combat":
				_action_start_combat()
			"open_trade":
				_action_open_trade()

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

func _action_give_reputation(action: Dictionary):
	"""Da reputacao ao player com uma faccao"""
	var faction = action.get("faction", "")
	var amount = action.get("amount", 0)
	
	# TODO: Implementar sistema de reputacao completo
	# Por enquanto, apenas log
	print("DialogSystem: Reputacao +", amount, " com ", faction)

func _action_set_flag(action: Dictionary):
	"""Define uma flag global"""
	var flag_name = action.get("flag", "")
	var value = action.get("value", true)
	
	# TODO: Implementar sistema de flags global
	# Por enquanto, apenas log
	print("DialogSystem: Flag '", flag_name, "' = ", value)

func _action_start_combat():
	"""Inicia combate com NPC"""
	end_dialog()
	var combat = get_node_or_null("/root/CombatSystem")
	if combat and current_npc:
		combat.start_combat([current_npc])

func _action_open_trade():
	"""Abre interface de comercio com NPC"""
	# TODO: Implementar sistema de comercio
	# Por enquanto, apenas log
	print("DialogSystem: Abrindo comercio com ", current_npc.name if current_npc else "NPC")

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
	"""
	Verifica se opcao esta disponivel baseado em requisitos
	Checa skill, stat, item, reputacao
	"""
	var requirements = option.get("requirements", [])
	if requirements.is_empty():
		# Sem requisitos, opcao sempre disponivel
		return true
	
	for req in requirements:
		var req_type = req.get("type", "")
		
		match req_type:
			"skill":
				# Verificacao de skill (ex: Speech, Lockpick, etc)
				if not _check_skill_requirement(req):
					return false
			
			"stat":
				# Verificacao de stat SPECIAL
				if not _check_stat_requirement(req):
					return false
			
			"item":
				# Verificacao de item no inventario
				if not _check_item_requirement(req):
					return false
			
			"reputation":
				# Verificacao de reputacao com faccao
				if not _check_reputation_requirement(req):
					return false
			
			"flag":
				# Verificacao de flag global
				if not _check_flag_requirement(req):
					return false
	
	return true

func _check_skill_requirement(req: Dictionary) -> bool:
	"""Verifica requisito de skill"""
	if not player:
		return false
	
	var skill_name = req.get("skill", "")
	var min_value = req.get("min", 0)
	
	# TODO: Implementar sistema de skills completo
	# Por enquanto, usar stats como fallback
	if player.has(skill_name):
		return player.get(skill_name) >= min_value
	
	return false

func _check_stat_requirement(req: Dictionary) -> bool:
	"""Verifica requisito de stat SPECIAL"""
	if not player:
		return false
	
	var stat_name = req.get("stat", "")
	var min_value = req.get("min", 0)
	
	if player.has(stat_name):
		return player.get(stat_name) >= min_value
	
	return false

func _check_item_requirement(req: Dictionary) -> bool:
	"""Verifica requisito de item"""
	var inv = get_node_or_null("/root/InventorySystem")
	if not inv:
		return false
	
	var item_id = req.get("item_id", "")
	var quantity = req.get("quantity", 1)
	
	return inv.has_item(item_id, quantity)

func _check_reputation_requirement(req: Dictionary) -> bool:
	"""Verifica requisito de reputacao"""
	# TODO: Implementar sistema de reputacao completo
	# Por enquanto, sempre retorna true
	var faction = req.get("faction", "")
	var min_reputation = req.get("min", 0)
	
	# Placeholder - implementar quando sistema de reputacao existir
	return true

func _check_flag_requirement(req: Dictionary) -> bool:
	"""Verifica requisito de flag global"""
	var flag_name = req.get("flag", "")
	var required_value = req.get("value", true)
	
	# TODO: Implementar sistema de flags global
	# Por enquanto, sempre retorna true
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
