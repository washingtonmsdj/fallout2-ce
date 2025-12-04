extends Area2D

## Objeto Interagivel do Fallout 2
## Base para containers, portas, switches, etc.

signal interacted(interactor: Node)
signal state_changed(new_state: String)

enum InteractableType { CONTAINER, DOOR, SWITCH, SCENERY, EXIT }

@export var interactable_id: String = ""
@export var display_name: String = "Object"
@export var interactable_type: InteractableType = InteractableType.SCENERY
@export var is_locked: bool = false
@export var lock_difficulty: int = 0
@export var is_trapped: bool = false
@export var trap_damage: int = 0

# Para containers
@export var container_items: Array[Dictionary] = []

# Para portas
@export var is_open: bool = false
@export var blocks_movement: bool = true

# Para exits
@export var target_map: String = ""
@export var target_entrance: int = 0

# Estado
var current_state: String = "default"

func _ready():
	add_to_group("interactable")
	
	# Conectar sinais de area
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interact(interactor: Node = null):
	"""Chamado quando player interage"""
	# Verificar trap
	if is_trapped:
		_trigger_trap(interactor)
		return
	
	# Verificar lock
	if is_locked:
		_try_unlock(interactor)
		return
	
	# Executar acao baseada no tipo
	match interactable_type:
		InteractableType.CONTAINER:
			_open_container(interactor)
		InteractableType.DOOR:
			_toggle_door()
		InteractableType.SWITCH:
			_activate_switch()
		InteractableType.EXIT:
			_use_exit()
		InteractableType.SCENERY:
			_examine()
	
	interacted.emit(interactor)

func _trigger_trap(interactor: Node):
	"""Dispara armadilha"""
	print("Interactable: Armadilha disparada!")
	is_trapped = false
	
	if interactor and interactor.has_method("take_damage"):
		interactor.take_damage(trap_damage)

func _try_unlock(interactor: Node):
	"""Tenta destrancar"""
	# TODO: Verificar skill de lockpick
	print("Interactable: ", display_name, " esta trancado")
	
	# Por enquanto, sempre falha
	# Implementar verificacao de skill depois

func _open_container(_interactor: Node):
	"""Abre container"""
	print("Interactable: Abrindo container ", display_name)
	
	# TODO: Abrir interface de container
	# Por enquanto, listar itens
	for item in container_items:
		print("  - ", item.get("name", "Item"))

func _toggle_door():
	"""Abre/fecha porta"""
	is_open = not is_open
	
	if is_open:
		print("Interactable: Porta aberta")
		current_state = "open"
		blocks_movement = false
	else:
		print("Interactable: Porta fechada")
		current_state = "closed"
		blocks_movement = true
	
	state_changed.emit(current_state)
	
	# Atualizar visual
	_update_visual()

func _activate_switch():
	"""Ativa switch"""
	print("Interactable: Switch ativado")
	
	if current_state == "on":
		current_state = "off"
	else:
		current_state = "on"
	
	state_changed.emit(current_state)
	_update_visual()

func _use_exit():
	"""Usa saida para outro mapa"""
	if target_map.is_empty():
		print("Interactable: Saida sem destino configurado")
		return
	
	print("Interactable: Saindo para ", target_map)
	
	var map_sys = get_node_or_null("/root/MapSystem")
	if map_sys:
		map_sys.transition_to(target_map, target_entrance)

func _examine():
	"""Examina objeto"""
	print("Interactable: ", display_name)
	# TODO: Mostrar descricao na interface

func _update_visual():
	"""Atualiza visual baseado no estado"""
	# Procurar sprite ou visual
	var visual = get_node_or_null("Sprite2D")
	if not visual:
		visual = get_node_or_null("Visual")
	
	if visual and visual.has_method("set_frame"):
		match current_state:
			"open":
				visual.frame = 1
			"closed", "default":
				visual.frame = 0
			"on":
				visual.frame = 1
			"off":
				visual.frame = 0

func _on_body_entered(body: Node2D):
	"""Chamado quando algo entra na area"""
	if body.is_in_group("player"):
		# Highlight ou mostrar nome
		pass

func _on_body_exited(body: Node2D):
	"""Chamado quando algo sai da area"""
	if body.is_in_group("player"):
		# Remover highlight
		pass

# === CONTAINER ===

func add_item(item: Dictionary, quantity: int = 1):
	"""Adiciona item ao container"""
	for existing in container_items:
		if existing.get("id") == item.get("id"):
			existing["quantity"] = existing.get("quantity", 1) + quantity
			return
	
	var new_item = item.duplicate()
	new_item["quantity"] = quantity
	container_items.append(new_item)

func remove_item(item_id: String, quantity: int = 1) -> bool:
	"""Remove item do container"""
	for i in range(container_items.size()):
		if container_items[i].get("id") == item_id:
			var current_qty = container_items[i].get("quantity", 1)
			if current_qty <= quantity:
				container_items.remove_at(i)
			else:
				container_items[i]["quantity"] = current_qty - quantity
			return true
	return false

func get_items() -> Array:
	"""Retorna itens do container"""
	return container_items

# === LOCK ===

func lock(difficulty: int = 50):
	"""Tranca o objeto"""
	is_locked = true
	lock_difficulty = difficulty

func unlock():
	"""Destranca o objeto"""
	is_locked = false

# === TRAP ===

func set_trap(damage: int):
	"""Coloca armadilha"""
	is_trapped = true
	trap_damage = damage

func disarm_trap() -> bool:
	"""Desarma armadilha"""
	# TODO: Verificar skill de traps
	is_trapped = false
	return true
