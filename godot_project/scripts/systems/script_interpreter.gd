extends Node

## Interpretador de Scripts do Fallout 2
## Baseado no codigo original (src/interpreter.cc)
## Executa scripts .INT convertidos

signal script_started(script_name: String)
signal script_ended(script_name: String)
signal script_error(script_name: String, error: String)

# Variaveis globais de script
var global_vars: Dictionary = {}
var local_vars: Dictionary = {}

# Scripts carregados
var loaded_scripts: Dictionary = {}

# Estado de execucao
var is_running: bool = false
var current_script: String = ""
var call_stack: Array = []

func _ready():
	pass

# === CARREGAMENTO ===

func load_script(script_name: String) -> bool:
	"""
	Carrega um script JSON
	Valida sintaxe antes de armazenar
	"""
	if loaded_scripts.has(script_name):
		return true
	
	var path = "res://assets/data/scripts/" + script_name + ".json"
	if not ResourceLoader.exists(path):
		push_error("ScriptInterpreter: Script nao encontrado: " + script_name)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("ScriptInterpreter: Erro ao abrir arquivo: " + path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	if parse_error != OK:
		push_error("ScriptInterpreter: Erro ao parsear JSON: " + str(parse_error))
		return false
	
	var script_data = json.data
	
	# Validar estrutura do script
	if not _validate_script_syntax(script_data):
		push_error("ScriptInterpreter: Sintaxe invalida no script: " + script_name)
		return false
	
	loaded_scripts[script_name] = script_data
	print("ScriptInterpreter: Script carregado: ", script_name)
	return true

func _validate_script_syntax(script_data: Dictionary) -> bool:
	"""
	Valida sintaxe de um script
	Verifica estrutura de triggers e procedures
	"""
	if not script_data is Dictionary:
		push_error("ScriptInterpreter: Script deve ser um Dictionary")
		return false
	
	# Validar procedures
	if script_data.has("procedures"):
		if not script_data.procedures is Dictionary:
			push_error("ScriptInterpreter: 'procedures' deve ser um Dictionary")
			return false
		
		for proc_name in script_data.procedures:
			var procedure = script_data.procedures[proc_name]
			if not _validate_procedure(procedure):
				push_error("ScriptInterpreter: Procedimento invalido: " + proc_name)
				return false
	
	# Validar triggers (opcional)
	if script_data.has("triggers"):
		if not script_data.triggers is Array:
			push_error("ScriptInterpreter: 'triggers' deve ser um Array")
			return false
		
		for trigger in script_data.triggers:
			if not _validate_trigger(trigger):
				push_error("ScriptInterpreter: Trigger invalido")
				return false
	
	return true

func _validate_procedure(procedure: Dictionary) -> bool:
	"""Valida estrutura de um procedimento"""
	if not procedure.has("statements"):
		push_error("ScriptInterpreter: Procedimento deve ter 'statements'")
		return false
	
	if not procedure.statements is Array:
		push_error("ScriptInterpreter: 'statements' deve ser um Array")
		return false
	
	for stmt in procedure.statements:
		if not stmt is Dictionary:
			push_error("ScriptInterpreter: Statement deve ser um Dictionary")
			return false
		
		if not stmt.has("type"):
			push_error("ScriptInterpreter: Statement deve ter 'type'")
			return false
	
	return true

func _validate_trigger(trigger: Dictionary) -> bool:
	"""Valida estrutura de um trigger"""
	if not trigger.has("event"):
		push_error("ScriptInterpreter: Trigger deve ter 'event'")
		return false
	
	if not trigger.has("procedure"):
		push_error("ScriptInterpreter: Trigger deve ter 'procedure'")
		return false
	
	return true

func unload_script(script_name: String):
	"""Descarrega um script"""
	loaded_scripts.erase(script_name)

# === EXECUCAO ===

func run_script(script_name: String, procedure: String = "start") -> Variant:
	"""Executa um script"""
	if not loaded_scripts.has(script_name):
		if not load_script(script_name):
			return null
	
	var script_data = loaded_scripts[script_name]
	var procedures = script_data.get("procedures", {})
	
	if not procedures.has(procedure):
		push_error("ScriptInterpreter: Procedimento nao encontrado: " + procedure)
		return null
	
	is_running = true
	current_script = script_name
	local_vars.clear()
	
	script_started.emit(script_name)
	
	var result = _execute_procedure(procedures[procedure])
	
	is_running = false
	script_ended.emit(script_name)
	
	return result

func _execute_procedure(procedure: Dictionary) -> Variant:
	"""Executa um procedimento"""
	var statements = procedure.get("statements", [])
	var result = null
	
	for stmt in statements:
		result = _execute_statement(stmt)
		
		# Verificar return
		if stmt.get("type") == "return":
			return result
	
	return result

func _execute_statement(stmt: Dictionary) -> Variant:
	"""Executa uma instrucao"""
	var stmt_type = stmt.get("type", "")
	
	match stmt_type:
		"set":
			return _stmt_set(stmt)
		"if":
			return _stmt_if(stmt)
		"call":
			return _stmt_call(stmt)
		"return":
			return _evaluate_expression(stmt.get("value"))
		"display_msg":
			return _stmt_display_msg(stmt)
		"give_xp":
			return _stmt_give_xp(stmt)
		"give_item":
			return _stmt_give_item(stmt)
		"start_combat":
			return _stmt_start_combat(stmt)
		"end_combat":
			return _stmt_end_combat(stmt)
		_:
			push_warning("ScriptInterpreter: Instrucao desconhecida: " + stmt_type)
	
	return null

func _stmt_set(stmt: Dictionary) -> Variant:
	"""Define variavel"""
	var var_name = stmt.get("var", "")
	var value = _evaluate_expression(stmt.get("value"))
	
	if var_name.begins_with("global_"):
		global_vars[var_name] = value
	else:
		local_vars[var_name] = value
	
	return value

func _stmt_if(stmt: Dictionary) -> Variant:
	"""Condicional"""
	var condition = _evaluate_expression(stmt.get("condition"))
	
	if condition:
		var then_block = stmt.get("then", [])
		for s in then_block:
			_execute_statement(s)
	else:
		var else_block = stmt.get("else", [])
		for s in else_block:
			_execute_statement(s)
	
	return null

func _stmt_call(stmt: Dictionary) -> Variant:
	"""Chama procedimento"""
	var proc_name = stmt.get("procedure", "")
	var args = stmt.get("args", [])
	
	# Verificar se e funcao builtin
	if _is_builtin(proc_name):
		return _call_builtin(proc_name, args)
	
	# Chamar procedimento do script
	var script_data = loaded_scripts.get(current_script, {})
	var procedures = script_data.get("procedures", {})
	
	if procedures.has(proc_name):
		call_stack.append({"script": current_script, "vars": local_vars.duplicate()})
		local_vars.clear()
		
		var result = _execute_procedure(procedures[proc_name])
		
		var frame = call_stack.pop_back()
		local_vars = frame["vars"]
		
		return result
	
	return null

func _stmt_display_msg(stmt: Dictionary) -> Variant:
	"""Exibe mensagem"""
	var msg = stmt.get("message", "")
	print("Script: ", msg)
	# TODO: Exibir na interface
	return null

func _stmt_give_xp(stmt: Dictionary) -> Variant:
	"""Da XP ao player"""
	var amount = _evaluate_expression(stmt.get("amount", 0))
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player and gm.player.has_method("add_experience"):
		gm.player.add_experience(amount)
	
	return amount

func _stmt_give_item(stmt: Dictionary) -> Variant:
	"""Da item ao player"""
	var item = stmt.get("item", {})
	var qty = stmt.get("quantity", 1)
	
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.add_item(item, qty)
	
	return true

func _stmt_start_combat(stmt: Dictionary) -> Variant:
	"""Inicia combate"""
	var enemies = stmt.get("enemies", [])
	
	var combat = get_node_or_null("/root/CombatSystem")
	if combat:
		# TODO: Converter IDs para nodes
		pass
	
	return null

func _stmt_end_combat(_stmt: Dictionary) -> Variant:
	"""Termina combate"""
	var combat = get_node_or_null("/root/CombatSystem")
	if combat:
		combat.end_combat()
	
	return null

# === EXPRESSOES ===

func _evaluate_expression(expr) -> Variant:
	"""Avalia uma expressao"""
	if expr == null:
		return null
	
	# Valor literal
	if expr is int or expr is float or expr is String or expr is bool:
		return expr
	
	# Dicionario (expressao complexa)
	if expr is Dictionary:
		var expr_type = expr.get("type", "")
		
		match expr_type:
			"var":
				return _get_variable(expr.get("name", ""))
			"add":
				return _evaluate_expression(expr.get("left")) + _evaluate_expression(expr.get("right"))
			"sub":
				return _evaluate_expression(expr.get("left")) - _evaluate_expression(expr.get("right"))
			"mul":
				return _evaluate_expression(expr.get("left")) * _evaluate_expression(expr.get("right"))
			"div":
				var right = _evaluate_expression(expr.get("right"))
				if right != 0:
					return _evaluate_expression(expr.get("left")) / right
				return 0
			"eq":
				return _evaluate_expression(expr.get("left")) == _evaluate_expression(expr.get("right"))
			"neq":
				return _evaluate_expression(expr.get("left")) != _evaluate_expression(expr.get("right"))
			"lt":
				return _evaluate_expression(expr.get("left")) < _evaluate_expression(expr.get("right"))
			"gt":
				return _evaluate_expression(expr.get("left")) > _evaluate_expression(expr.get("right"))
			"and":
				return _evaluate_expression(expr.get("left")) and _evaluate_expression(expr.get("right"))
			"or":
				return _evaluate_expression(expr.get("left")) or _evaluate_expression(expr.get("right"))
			"not":
				return not _evaluate_expression(expr.get("value"))
			"call":
				return _stmt_call(expr)
	
	return expr

func _get_variable(var_name: String) -> Variant:
	"""Obtem valor de variavel"""
	if local_vars.has(var_name):
		return local_vars[var_name]
	if global_vars.has(var_name):
		return global_vars[var_name]
	return null

# === FUNCOES BUILTIN ===

func _is_builtin(name: String) -> bool:
	"""Verifica se e funcao builtin"""
	return name in [
		"random", "get_critter_stat", "set_critter_stat",
		"has_trait", "get_skill", "roll_vs_skill",
		"obj_is_visible", "obj_is_locked", "obj_lock",
		"message_str", "display_msg", "float_msg",
		"give_item", "add_xp", "set_global_var", "get_global_var"
	]

func _call_builtin(name: String, args: Array) -> Variant:
	"""
	Chama funcao builtin
	Suporta display_msg, give_item, add_xp, etc.
	"""
	match name:
		"random":
			var min_val = args[0] if args.size() > 0 else 0
			var max_val = args[1] if args.size() > 1 else 100
			return randi_range(min_val, max_val)
		"get_critter_stat":
			return _builtin_get_critter_stat(args)
		"set_critter_stat":
			return _builtin_set_critter_stat(args)
		"roll_vs_skill":
			return _builtin_roll_vs_skill(args)
		"display_msg":
			return _builtin_display_msg(args)
		"give_item":
			return _builtin_give_item(args)
		"add_xp":
			return _builtin_add_xp(args)
		"set_global_var":
			return _builtin_set_global_var(args)
		"get_global_var":
			return _builtin_get_global_var(args)
		"message_str":
			return _builtin_message_str(args)
		"float_msg":
			return _builtin_float_msg(args)
		_:
			push_warning("ScriptInterpreter: Builtin nao implementado: " + name)
	
	return null

func _builtin_display_msg(args: Array) -> Variant:
	"""Exibe mensagem na tela"""
	if args.size() == 0:
		return false
	
	var message = str(args[0])
	print("Script [display_msg]: ", message)
	
	# TODO: Exibir na interface do jogo
	# Por enquanto, apenas log
	return true

func _builtin_give_item(args: Array) -> Variant:
	"""Da item ao player"""
	if args.size() < 1:
		return false
	
	var item_data = args[0] if args[0] is Dictionary else {"id": str(args[0])}
	var quantity = args[1] if args.size() > 1 else 1
	
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		return inv.add_item(item_data, quantity)
	
	return false

func _builtin_add_xp(args: Array) -> Variant:
	"""Adiciona XP ao player"""
	if args.size() == 0:
		return false
	
	var amount = int(args[0])
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player and gm.player.has_method("add_experience"):
		gm.player.add_experience(amount)
		return true
	
	return false

func _builtin_set_global_var(args: Array) -> Variant:
	"""Define variavel global via script"""
	if args.size() < 2:
		return false
	
	var var_name = str(args[0])
	var value = args[1]
	
	set_global_var(var_name, value)
	return true

func _builtin_get_global_var(args: Array) -> Variant:
	"""Obtem variavel global via script"""
	if args.size() == 0:
		return null
	
	var var_name = str(args[0])
	var default_value = args[1] if args.size() > 1 else null
	
	return get_global_var(var_name, default_value)

func _builtin_message_str(args: Array) -> Variant:
	"""Retorna string de mensagem (placeholder)"""
	if args.size() == 0:
		return ""
	
	# TODO: Implementar sistema de mensagens
	return str(args[0])

func _builtin_float_msg(args: Array) -> Variant:
	"""Exibe mensagem flutuante (placeholder)"""
	if args.size() < 2:
		return false
	
	var target = args[0]
	var message = str(args[1])
	
	print("Script [float_msg]: ", message, " para ", target)
	# TODO: Exibir mensagem flutuante na tela
	return true

func _builtin_set_critter_stat(args: Array) -> int:
	"""Define stat de critter"""
	if args.size() < 3:
		return 0
	
	# args[0] = critter, args[1] = stat, args[2] = value
	var stat_name = str(args[1])
	var value = int(args[2])
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player:
		if gm.player.has(stat_name):
			gm.player.set(stat_name, value)
			return value
	
	return 0

func _builtin_get_critter_stat(args: Array) -> int:
	"""Obtem stat de critter"""
	if args.size() < 2:
		return 0
	
	# args[0] = critter, args[1] = stat
	var stat_name = args[1]
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player:
		if gm.player.has_method("get"):
			return gm.player.get(stat_name)
	
	return 0

func _builtin_roll_vs_skill(args: Array) -> bool:
	"""Rola contra skill"""
	if args.size() < 2:
		return false
	
	# args[0] = critter, args[1] = skill, args[2] = modifier
	var skill_value = 50  # TODO: Obter skill real
	var modifier = args[2] if args.size() > 2 else 0
	
	var roll = randi() % 100
	return roll < (skill_value + modifier)

# === VARIAVEIS GLOBAIS ===

func set_global_var(name: String, value: Variant):
	"""
	Define variavel global
	Permite leitura/escrita por scripts
	"""
	global_vars[name] = value
	print("ScriptInterpreter: Variavel global definida: ", name, " = ", value)

func get_global_var(name: String, default: Variant = null) -> Variant:
	"""
	Obtem variavel global
	Permite leitura por scripts
	"""
	return global_vars.get(name, default)

func has_global_var(name: String) -> bool:
	"""Verifica se variavel global existe"""
	return global_vars.has(name)

func clear_global_vars():
	"""Limpa variaveis globais"""
	global_vars.clear()
	print("ScriptInterpreter: Variaveis globais limpas")

func get_all_global_vars() -> Dictionary:
	"""Retorna todas as variaveis globais (read-only copy)"""
	return global_vars.duplicate()
