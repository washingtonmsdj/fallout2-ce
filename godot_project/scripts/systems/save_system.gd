extends Node

## Sistema de Save/Load do Fallout 2
## Baseado no codigo original (src/loadsave.cc)
##
## Funcionalidades:
## - Save/Load completo de estado do jogo
## - 10 slots de save + quicksave
## - Validação de dados com checksum
## - Detecção de saves corrompidos
## - Rastreamento de todos os mapas visitados
## - Serialização de player, inventário, mapas e variáveis globais
## - Metadados (timestamp, localização, level)
##
## Uso:
##   SaveSystem.save_game(1)  # Salvar no slot 1
##   SaveSystem.load_game(1)  # Carregar do slot 1
##   SaveSystem.quicksave()   # F6
##   SaveSystem.quickload()   # F9

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_list_updated(saves: Array)

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SLOTS = 10
const QUICKSAVE_SLOT = 0

# Dados do save
var current_save_data: Dictionary = {}

# Rastreamento de mapas visitados
var visited_maps: Dictionary = {}  # map_name -> map_state

func _ready():
	# Criar diretorio de saves se nao existir
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# === SAVE ===

func save_game(slot: int = -1) -> bool:
	"""Salva o jogo em um slot"""
	if slot < 0:
		slot = _get_next_available_slot()
	
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveSystem: Slot invalido: " + str(slot))
		return false
	
	print("SaveSystem: Salvando no slot ", slot)
	
	# Coletar dados do jogo
	var save_data = _collect_save_data()
	
	# Adicionar metadados (timestamp e localização)
	save_data["meta"] = _create_metadata(slot)
	
	# Calcular checksum
	save_data["checksum"] = _calculate_checksum(save_data)
	
	# Salvar arquivo
	var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if not file:
		push_error("SaveSystem: Erro ao criar arquivo: " + path)
		save_completed.emit(slot, false)
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	print("SaveSystem: Jogo salvo com sucesso!")
	save_completed.emit(slot, true)
	return true

func quicksave() -> bool:
	"""Quicksave (F6)"""
	return save_game(QUICKSAVE_SLOT)

func _collect_save_data() -> Dictionary:
	"""
	Coleta todos os dados para salvar
	Serializar player (posição, stats, inventário)
	Serializar estado do mapa (objetos modificados)
	Serializar variáveis globais
	"""
	var data = {}
	
	# Dados do GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		data["game"] = {
			"current_map": gm.current_map_name,
			"game_difficulty": gm.game_difficulty,
			"combat_difficulty": gm.combat_difficulty,
			"game_state": gm.current_state
		}
	
	# Serializar player (posição, stats, inventário)
	var player = _get_player()
	if player:
		var renderer = get_node_or_null("/root/IsometricRenderer")
		var player_tile = Vector2i(0, 0)
		if renderer:
			player_tile = renderer.screen_to_tile(player.global_position, 0)
		
		data["player"] = {
			"position": {"x": player.global_position.x, "y": player.global_position.y},
			"tile": {"x": player_tile.x, "y": player_tile.y},
			"hp": player.hp,
			"max_hp": player.max_hp,
			"level": player.level,
			"experience": player.experience,
			"action_points": player.action_points,
			"max_action_points": player.max_action_points,
			"strength": player.strength,
			"perception": player.perception,
			"endurance": player.endurance,
			"charisma": player.charisma,
			"intelligence": player.intelligence,
			"agility": player.agility,
			"luck": player.luck,
			"armor_class": player.armor_class,
			"current_direction": player.current_direction
		}
	
	# Serializar inventário completo
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		data["inventory"] = {
			"items": inv.items.duplicate(true),
			"equipped": inv.equipped.duplicate(true),
			"current_weight": inv.current_weight,
			"max_weight": inv.max_weight
		}
	
	# Serializar estado do mapa atual
	var map_system = get_node_or_null("/root/MapSystem")
	if map_system:
		data["map"] = {
			"current_map": map_system.current_map_name,
			"elevation": map_system.current_elevation,
			"map_data": map_system.current_map_data.duplicate(true)
		}
		
		# Salvar estado do mapa atual no histórico de mapas visitados
		if not map_system.current_map_name.is_empty():
			visited_maps[map_system.current_map_name] = {
				"elevation": map_system.current_elevation,
				"map_data": map_system.current_map_data.duplicate(true),
				"last_visited": Time.get_unix_time_from_system()
			}
	
	# Serializar todos os mapas visitados
	data["visited_maps"] = visited_maps.duplicate(true)
	
	# Serializar variáveis globais
	var script_system = get_node_or_null("/root/ScriptInterpreter")
	if script_system:
		data["globals"] = script_system.get_all_global_vars()
	
	return data

# === LOAD ===

func load_game(slot: int) -> bool:
	"""Carrega jogo de um slot"""
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveSystem: Slot invalido: " + str(slot))
		return false
	
	var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(path):
		push_error("SaveSystem: Save nao encontrado: " + path)
		load_completed.emit(slot, false)
		return false
	
	print("SaveSystem: Carregando slot ", slot)
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveSystem: Erro ao abrir arquivo")
		load_completed.emit(slot, false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("SaveSystem: Erro ao parsear JSON")
		load_completed.emit(slot, false)
		return false
	
	var save_data = json.data
	
	# Validar estrutura dos dados
	if not _validate_save_data(save_data):
		push_error("SaveSystem: Dados do save são inválidos")
		load_completed.emit(slot, false)
		return false
	
	# Aplicar dados
	var success = _apply_save_data(save_data)
	
	if not success:
		push_error("SaveSystem: Falha ao aplicar dados do save")
		load_completed.emit(slot, false)
		return false
	
	print("SaveSystem: Jogo carregado com sucesso!")
	load_completed.emit(slot, true)
	return true

func quickload() -> bool:
	"""Quickload (F9)"""
	return load_game(QUICKSAVE_SLOT)

func _apply_save_data(data: Dictionary) -> bool:
	"""
	Aplica dados do save ao jogo
	Restaurar player, mapa e variáveis
	Retorna true se aplicação foi bem-sucedida
	"""
	# Validar checksum antes de aplicar
	if not _validate_checksum(data):
		push_error("SaveSystem: Checksum inválido! Save pode estar corrompido.")
		return false
	
	# Aplicar dados do jogo
	if data.has("game"):
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			var game_data = data["game"]
			gm.game_difficulty = game_data.get("game_difficulty", 1)
			gm.combat_difficulty = game_data.get("combat_difficulty", 1)
			
			# Carregar mapa
			var map_name = game_data.get("current_map", "")
			if not map_name.is_empty():
				gm.load_map(map_name)
	
	# Restaurar player
	if data.has("player"):
		var player = _get_player()
		if player:
			var p_data = data["player"]
			
			if p_data.has("position"):
				player.global_position = Vector2(
					p_data["position"]["x"],
					p_data["position"]["y"]
				)
			
			player.hp = p_data.get("hp", 30)
			player.max_hp = p_data.get("max_hp", 30)
			player.level = p_data.get("level", 1)
			player.experience = p_data.get("experience", 0)
			player.action_points = p_data.get("action_points", 10)
			player.max_action_points = p_data.get("max_action_points", 10)
			player.strength = p_data.get("strength", 5)
			player.perception = p_data.get("perception", 5)
			player.endurance = p_data.get("endurance", 5)
			player.charisma = p_data.get("charisma", 5)
			player.intelligence = p_data.get("intelligence", 5)
			player.agility = p_data.get("agility", 5)
			player.luck = p_data.get("luck", 5)
			player.armor_class = p_data.get("armor_class", 0)
			player.current_direction = p_data.get("current_direction", 1)
			
			# Recalcular stats derivados
			if player.has_method("_calculate_derived_stats"):
				player._calculate_derived_stats()
	
	# Restaurar inventário
	if data.has("inventory"):
		var inv = get_node_or_null("/root/InventorySystem")
		if inv:
			var inv_data = data["inventory"]
			inv.items = inv_data.get("items", [])
			inv.equipped = inv_data.get("equipped", {})
			inv.current_weight = inv_data.get("current_weight", 0)
			inv.max_weight = inv_data.get("max_weight", 150)
			inv.update_weight()
	
	# Restaurar todos os mapas visitados
	if data.has("visited_maps"):
		visited_maps = data["visited_maps"].duplicate(true)
	
	# Restaurar estado do mapa atual
	if data.has("map"):
		var map_system = get_node_or_null("/root/MapSystem")
		if map_system:
			var map_data = data["map"]
			map_system.current_map_name = map_data.get("current_map", "")
			map_system.current_elevation = map_data.get("elevation", 0)
			map_system.current_map_data = map_data.get("map_data", {})
			map_system.set_elevation(map_data.get("elevation", 0))
	
	# Restaurar variáveis globais
	if data.has("globals"):
		var script_system = get_node_or_null("/root/ScriptInterpreter")
		if script_system:
			var globals_data = data["globals"]
			for var_name in globals_data:
				script_system.set_global_var(var_name, globals_data[var_name])
	
	return true

# === GERENCIAMENTO DE SLOTS ===

func get_save_list() -> Array:
	"""Retorna lista de saves disponiveis"""
	var saves = []
	
	for slot in range(MAX_SLOTS):
		var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
		
		if FileAccess.file_exists(path):
			var info = _get_save_info(slot)
			if info:
				saves.append(info)
		else:
			saves.append({
				"slot": slot,
				"empty": true
			})
	
	save_list_updated.emit(saves)
	return saves

func _get_save_info(slot: int) -> Dictionary:
	"""Retorna informacoes de um save"""
	var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
	
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var data = json.data
	var meta = data.get("meta", {})
	var player_data = data.get("player", {})
	var game_data = data.get("game", {})
	
	return {
		"slot": slot,
		"empty": false,
		"datetime": meta.get("datetime", "Unknown"),
		"location": game_data.get("current_map", "Unknown"),
		"level": player_data.get("level", 1),
		"hp": player_data.get("hp", 0),
		"max_hp": player_data.get("max_hp", 0)
	}

func delete_save(slot: int) -> bool:
	"""Deleta um save"""
	var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
	
	if FileAccess.file_exists(path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove("slot_" + str(slot) + SAVE_EXTENSION)
			return true
	
	return false

func _get_next_available_slot() -> int:
	"""Retorna proximo slot disponivel"""
	for slot in range(1, MAX_SLOTS):  # Pular slot 0 (quicksave)
		var path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
		if not FileAccess.file_exists(path):
			return slot
	return 1  # Sobrescrever slot 1 se todos estiverem cheios

func _get_player() -> Node:
	"""Retorna referencia ao player"""
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		return gm.player
	return null

# === RASTREAMENTO DE MAPAS VISITADOS ===

func track_map_visit(map_name: String):
	"""
	Registra visita a um mapa
	Chamado pelo MapSystem quando um mapa é carregado
	"""
	if map_name.is_empty():
		return
	
	var map_system = get_node_or_null("/root/MapSystem")
	if not map_system:
		return
	
	visited_maps[map_name] = {
		"elevation": map_system.current_elevation,
		"map_data": map_system.current_map_data.duplicate(true),
		"last_visited": Time.get_unix_time_from_system()
	}

func get_visited_map_state(map_name: String) -> Dictionary:
	"""
	Retorna estado salvo de um mapa visitado
	Retorna dicionário vazio se mapa não foi visitado
	"""
	return visited_maps.get(map_name, {})

func has_visited_map(map_name: String) -> bool:
	"""Verifica se um mapa já foi visitado"""
	return visited_maps.has(map_name)

func clear_visited_maps():
	"""Limpa histórico de mapas visitados (para novo jogo)"""
	visited_maps.clear()

func new_game():
	"""
	Inicializa dados para um novo jogo
	Limpa histórico de mapas visitados
	"""
	visited_maps.clear()
	current_save_data.clear()
	print("SaveSystem: Novo jogo iniciado, dados limpos")

# === METADADOS ===

func _create_metadata(slot: int) -> Dictionary:
	"""
	Implementar metadados de save
	Capturar timestamp e localização
	"""
	var gm = get_node_or_null("/root/GameManager")
	var map_system = get_node_or_null("/root/MapSystem")
	var player = _get_player()
	
	var location = "Unknown"
	if map_system:
		location = map_system.current_map_name
	if location.is_empty() and gm:
		location = gm.current_map_name
	
	var level = 1
	if player:
		level = player.level
	
	return {
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(),
		"location": location,
		"level": level,
		"version": "0.1"
		# TODO: Capturar screenshot quando sistema de imagem estiver disponível
	}

# === CHECKSUM E VALIDAÇÃO ===

func _calculate_checksum(data: Dictionary) -> String:
	"""
	Calcular checksum do save
	Valida ao carregar
	"""
	# Remover checksum se existir para calcular
	var data_copy = data.duplicate(true)
	data_copy.erase("checksum")
	
	# Converter para string e calcular hash simples
	var json_string = JSON.stringify(data_copy)
	var hash = json_string.hash()
	return str(hash)

func _validate_checksum(data: Dictionary) -> bool:
	"""
	Validar checksum ao carregar
	Detecta corrupção
	"""
	if not data.has("checksum"):
		push_warning("SaveSystem: Save sem checksum (pode ser versão antiga)")
		return true  # Permitir saves antigos
	
	var saved_checksum = data.get("checksum", "")
	var calculated_checksum = _calculate_checksum(data)
	
	var is_valid = saved_checksum == calculated_checksum
	
	if not is_valid:
		push_error("SaveSystem: Checksum inválido!")
		push_error("  Esperado: " + saved_checksum)
		push_error("  Calculado: " + calculated_checksum)
		push_error("  O save pode estar corrompido ou foi modificado manualmente.")
	
	return is_valid

func _validate_save_data(data: Dictionary) -> bool:
	"""
	Valida estrutura e conteúdo dos dados de save
	Retorna true se dados são válidos
	"""
	# Verificar campos obrigatórios
	if not data.has("meta"):
		push_error("SaveSystem: Save sem metadados")
		return false
	
	if not data.has("player"):
		push_error("SaveSystem: Save sem dados do player")
		return false
	
	if not data.has("game"):
		push_error("SaveSystem: Save sem dados do jogo")
		return false
	
	# Validar versão
	var meta = data.get("meta", {})
	var version = meta.get("version", "")
	if version.is_empty():
		push_warning("SaveSystem: Save sem informação de versão")
	
	# Validar dados do player
	var player_data = data.get("player", {})
	if not player_data.has("hp") or not player_data.has("max_hp"):
		push_error("SaveSystem: Dados do player incompletos (falta HP)")
		return false
	
	# Validar HP não é negativo
	if player_data.get("hp", 0) < 0:
		push_error("SaveSystem: HP do player é negativo")
		return false
	
	# Validar level é positivo
	if player_data.get("level", 0) <= 0:
		push_error("SaveSystem: Level do player é inválido")
		return false
	
	return true

# === INPUT ===

func _input(event):
	"""
	Processa atalhos de teclado
	F6 para quicksave, F9 para quickload
	"""
	if event.is_action_pressed("quicksave") or (event is InputEventKey and event.keycode == KEY_F6 and event.pressed):
		quicksave()
	elif event.is_action_pressed("quickload") or (event is InputEventKey and event.keycode == KEY_F9 and event.pressed):
		quickload()
