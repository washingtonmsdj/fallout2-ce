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
	"""Carrega um script"""
	if loaded_scripts.has(script_name):
		return true
	
	var path = "res://assets/data/scripts/" + script_name + ".json"
	if not ResourceLoader.exists(path):
		push_error("ScriptInterpreter: Script nao encontrado: " + script_name)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("ScriptInterpreter: Erro ao parsear script: " + script_name)
		return false
	
	loaded_scripts[script_name] = json.data
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
		"message_str", "display_msg", "float_msg"
	]

func _call_builtin(name: String, args: Array) -> Variant:
	"""Chama funcao builtin"""
	match name:
		"random":
			var min_val = args[0] if args.size() > 0 else 0
			var max_val = args[1] if args.size() > 1 else 100
			return randi_range(min_val, max_val)
		"get_critter_stat":
			return _builtin_get_critter_stat(args)
		"roll_vs_skill":
			return _builtin_roll_vs_skill(args)
		_:
			push_warning("ScriptInterpreter: Builtin nao implementado: " + name)
	
	return null

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
	"""Define variavel global"""
	global_vars[name] = value

func get_global_var(name: String, default: Variant = null) -> Variant:
	"""Obtem variavel global"""
	return global_vars.get(name, default)

func clear_global_vars():
	"""Limpa variaveis globais"""
	global_vars.clear()
