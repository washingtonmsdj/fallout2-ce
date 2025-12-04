extends Node

## PrototypeSystem - Gerencia protótipos de itens e criaturas
## Baseado no código original (src/proto.cc)
## Carrega protótipos JSON e cria instâncias isoladas

signal prototype_loaded(prototype_type: String, prototype_id: String)
signal instance_created(prototype_type: String, instance_id: String)

# Armazenamento de protótipos
var item_prototypes: Dictionary = {}
var critter_prototypes: Dictionary = {}

# Cache de instâncias (opcional, para debug)
var instance_cache: Dictionary = {}

func _ready():
	print("PrototypeSystem: Inicializado")

# === LOADER DE PROTÓTIPOS JSON ===

func load_item_prototypes(path: String = "res://assets/data/item_prototypes.json") -> bool:
	"""
	Carrega protótipos de itens de arquivo JSON
	"""
	print("PrototypeSystem: Carregando protótipos de itens de: ", path)
	
	if not ResourceLoader.exists(path):
		push_error("PrototypeSystem: Arquivo não encontrado: " + path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PrototypeSystem: Erro ao abrir arquivo: " + path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		push_error("PrototypeSystem: Erro ao parsear JSON: " + str(parse_error))
		return false
	
	var data = json.data
	
	# Validar estrutura
	if not (data is Dictionary):
		push_error("PrototypeSystem: Dados devem ser um Dictionary")
		return false
	
	# Carregar cada protótipo
	var loaded_count = 0
	for prototype_id in data:
		var prototype = data[prototype_id]
		if _validate_item_prototype(prototype):
			item_prototypes[prototype_id] = prototype
			loaded_count += 1
			prototype_loaded.emit("item", prototype_id)
	
	print("PrototypeSystem: ", loaded_count, " protótipos de itens carregados")
	return true

func load_critter_prototypes(path: String = "res://assets/data/critter_prototypes.json") -> bool:
	"""
	Carrega protótipos de criaturas de arquivo JSON
	"""
	print("PrototypeSystem: Carregando protótipos de criaturas de: ", path)
	
	if not ResourceLoader.exists(path):
		push_error("PrototypeSystem: Arquivo não encontrado: " + path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PrototypeSystem: Erro ao abrir arquivo: " + path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		push_error("PrototypeSystem: Erro ao parsear JSON: " + str(parse_error))
		return false
	
	var data = json.data
	
	# Validar estrutura
	if not (data is Dictionary):
		push_error("PrototypeSystem: Dados devem ser um Dictionary")
		return false
	
	# Carregar cada protótipo
	var loaded_count = 0
	for prototype_id in data:
		var prototype = data[prototype_id]
		if _validate_critter_prototype(prototype):
			critter_prototypes[prototype_id] = prototype
			loaded_count += 1
			prototype_loaded.emit("critter", prototype_id)
	
	print("PrototypeSystem: ", loaded_count, " protótipos de criaturas carregados")
	return true

func load_all_prototypes():
	"""Carrega todos os protótipos"""
	load_item_prototypes()
	load_critter_prototypes()

func _validate_item_prototype(prototype: Dictionary) -> bool:
	"""Valida estrutura de protótipo de item"""
	if not prototype.has("id"):
		push_error("PrototypeSystem: Protótipo de item deve ter 'id'")
		return false
	
	if not prototype.has("name"):
		push_error("PrototypeSystem: Protótipo de item deve ter 'name'")
		return false
	
	return true

func _validate_critter_prototype(prototype: Dictionary) -> bool:
	"""Valida estrutura de protótipo de criatura"""
	if not prototype.has("id"):
		push_error("PrototypeSystem: Protótipo de criatura deve ter 'id'")
		return false
	
	if not prototype.has("name"):
		push_error("PrototypeSystem: Protótipo de criatura deve ter 'name'")
		return false
	
	return true

# === CRIAÇÃO DE INSTÂNCIAS ===

func create_item_instance(prototype_id: String, instance_id: String = "") -> Dictionary:
	"""
	Cria ItemData a partir de protótipo
	Retorna instância isolada (deep copy)
	"""
	if not item_prototypes.has(prototype_id):
		push_error("PrototypeSystem: Protótipo de item não encontrado: " + prototype_id)
		return {}
	
	var prototype = item_prototypes[prototype_id]
	
	# Criar instância isolada (deep copy)
	var instance = _deep_copy(prototype)
	
	# Adicionar ID de instância se fornecido
	if instance_id != "":
		instance["instance_id"] = instance_id
	else:
		instance["instance_id"] = prototype_id + "_" + str(Time.get_ticks_msec())
	
	instance["prototype_id"] = prototype_id
	
	instance_created.emit("item", instance["instance_id"])
	return instance

func create_critter_instance(prototype_id: String, instance_id: String = "") -> Dictionary:
	"""
	Cria CritterData a partir de protótipo
	Retorna instância isolada (deep copy)
	"""
	if not critter_prototypes.has(prototype_id):
		push_error("PrototypeSystem: Protótipo de criatura não encontrado: " + prototype_id)
		return {}
	
	var prototype = critter_prototypes[prototype_id]
	
	# Criar instância isolada (deep copy)
	var instance = _deep_copy(prototype)
	
	# Adicionar ID de instância se fornecido
	if instance_id != "":
		instance["instance_id"] = instance_id
	else:
		instance["instance_id"] = prototype_id + "_" + str(Time.get_ticks_msec())
	
	instance["prototype_id"] = prototype_id
	
	instance_created.emit("critter", instance["instance_id"])
	return instance

func _deep_copy(source: Dictionary) -> Dictionary:
	"""
	Cria cópia profunda de um Dictionary
	Garante isolamento entre instância e protótipo
	"""
	var copy = {}
	
	for key in source:
		var value = source[key]
		
		if value is Dictionary:
			copy[key] = _deep_copy(value)
		elif value is Array:
			copy[key] = _deep_copy_array(value)
		else:
			copy[key] = value
	
	return copy

func _deep_copy_array(source: Array) -> Array:
	"""Cria cópia profunda de um Array"""
	var copy = []
	
	for item in source:
		if item is Dictionary:
			copy.append(_deep_copy(item))
		elif item is Array:
			copy.append(_deep_copy_array(item))
		else:
			copy.append(item)
	
	return copy

# === ACESSO A PROTÓTIPOS ===

func get_item_prototype(prototype_id: String) -> Dictionary:
	"""Retorna protótipo de item (read-only)"""
	if item_prototypes.has(prototype_id):
		return item_prototypes[prototype_id]
	return {}

func get_critter_prototype(prototype_id: String) -> Dictionary:
	"""Retorna protótipo de criatura (read-only)"""
	if critter_prototypes.has(prototype_id):
		return critter_prototypes[prototype_id]
	return {}

func has_item_prototype(prototype_id: String) -> bool:
	"""Verifica se protótipo de item existe"""
	return item_prototypes.has(prototype_id)

func has_critter_prototype(prototype_id: String) -> bool:
	"""Verifica se protótipo de criatura existe"""
	return critter_prototypes.has(prototype_id)

# === UTILIDADES ===

func get_all_item_prototype_ids() -> Array:
	"""Retorna IDs de todos os protótipos de itens"""
	return item_prototypes.keys()

func get_all_critter_prototype_ids() -> Array:
	"""Retorna IDs de todos os protótipos de criaturas"""
	return critter_prototypes.keys()

func clear_prototypes():
	"""Limpa todos os protótipos carregados"""
	item_prototypes.clear()
	critter_prototypes.clear()
	instance_cache.clear()
	print("PrototypeSystem: Protótipos limpos")

