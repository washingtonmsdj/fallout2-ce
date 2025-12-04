extends Node

## Sistema de Save/Load do Fallout 2
## Baseado no codigo original (src/loadsave.cc)

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_list_updated(saves: Array)

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SLOTS = 10
const QUICKSAVE_SLOT = 0

# Dados do save
var current_save_data: Dictionary = {}

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
	
	# Adicionar metadados
	save_data["meta"] = {
		"slot": slot,
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(),
		"version": "0.1"
	}
	
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
	"""Coleta todos os dados para salvar"""
	var data = {}
	
	# Dados do GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		data["game"] = {
			"current_map": gm.current_map_name,
			"game_difficulty": gm.game_difficulty,
			"combat_difficulty": gm.combat_difficulty
		}
	
	# Dados do Player
	var player = _get_player()
	if player:
		data["player"] = {
			"position": {"x": player.global_position.x, "y": player.global_position.y},
			"hp": player.hp,
			"max_hp": player.max_hp,
			"level": player.level,
			"experience": player.experience,
			"action_points": player.action_points,
			"strength": player.strength,
			"perception": player.perception,
			"endurance": player.endurance,
			"charisma": player.charisma,
			"intelligence": player.intelligence,
			"agility": player.agility,
			"luck": player.luck
		}
	
	# Dados do Inventario
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		data["inventory"] = {
			"items": inv.items,
			"equipped": inv.equipped
		}
	
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
	
	# Aplicar dados
	_apply_save_data(save_data)
	
	print("SaveSystem: Jogo carregado com sucesso!")
	load_completed.emit(slot, true)
	return true

func quickload() -> bool:
	"""Quickload (F9)"""
	return load_game(QUICKSAVE_SLOT)

func _apply_save_data(data: Dictionary):
	"""Aplica dados do save ao jogo"""
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
	
	# Aplicar dados do player
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
			player.strength = p_data.get("strength", 5)
			player.perception = p_data.get("perception", 5)
			player.endurance = p_data.get("endurance", 5)
			player.charisma = p_data.get("charisma", 5)
			player.intelligence = p_data.get("intelligence", 5)
			player.agility = p_data.get("agility", 5)
			player.luck = p_data.get("luck", 5)
	
	# Aplicar inventario
	if data.has("inventory"):
		var inv = get_node_or_null("/root/InventorySystem")
		if inv:
			var inv_data = data["inventory"]
			inv.items = inv_data.get("items", [])
			inv.equipped = inv_data.get("equipped", {})

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

# === INPUT ===

func _input(event):
	"""Processa atalhos de teclado"""
	if event.is_action_pressed("quicksave"):
		quicksave()
	elif event.is_action_pressed("quickload"):
		quickload()
