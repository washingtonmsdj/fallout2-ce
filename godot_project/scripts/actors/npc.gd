extends CharacterBody2D

## NPC do Fallout 2
## Baseado no codigo original (src/critter.cc)

signal interaction_requested(npc: Node)
signal died()

# Identificacao
@export var npc_id: String = ""
@export var npc_name: String = "NPC"
@export var npc_type: String = "human"  # human, critter, robot

# Stats
@export_group("Stats")
@export var hp: int = 20
@export var max_hp: int = 20
@export var action_points: int = 8
@export var max_action_points: int = 8
@export var armor_class: int = 5
@export var sequence: int = 10

# SPECIAL (simplificado)
@export_group("SPECIAL")
@export_range(1, 10) var strength: int = 5
@export_range(1, 10) var perception: int = 5
@export_range(1, 10) var endurance: int = 5
@export_range(1, 10) var charisma: int = 5
@export_range(1, 10) var intelligence: int = 5
@export_range(1, 10) var agility: int = 5
@export_range(1, 10) var luck: int = 5

# Comportamento
@export_group("Behavior")
@export var is_hostile: bool = false
@export var is_merchant: bool = false
@export var can_talk: bool = true
@export var patrol_points: Array[Vector2] = []
@export var detection_range: float = 200.0

# Dialogo
@export var dialog_file: String = ""
var dialog_data: Dictionary = {}

# Estado
var is_dead: bool = false
var current_target: Node = null
var patrol_index: int = 0
var is_patrolling: bool = false

# Movimento
var move_speed: float = 80.0
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

func _ready():
	add_to_group("npc")
	
	if is_hostile:
		add_to_group("enemy")
	
	# Carregar dialogo se especificado
	if not dialog_file.is_empty():
		_load_dialog()

func _physics_process(delta):
	if is_dead:
		return
	
	# IA basica
	if is_hostile:
		_hostile_ai(delta)
	elif is_patrolling and patrol_points.size() > 0:
		_patrol_ai(delta)
	
	# Movimento
	if is_moving:
		_handle_movement(delta)

func _hostile_ai(_delta):
	"""IA para NPCs hostis"""
	# Procurar player
	var player = _find_player()
	if not player:
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist < detection_range:
		current_target = player
		
		# Se nao estiver em combate, iniciar
		var combat = get_node_or_null("/root/CombatSystem")
		if combat and not combat.is_in_combat():
			combat.start_combat([self])

func _patrol_ai(_delta):
	"""IA de patrulha"""
	if patrol_points.is_empty():
		return
	
	var target = patrol_points[patrol_index]
	var dist = global_position.distance_to(target)
	
	if dist < 10:
		# Chegou ao ponto, ir para proximo
		patrol_index = (patrol_index + 1) % patrol_points.size()
	else:
		# Mover para ponto
		target_position = target
		is_moving = true

func _handle_movement(_delta):
	"""Processa movimento"""
	var dir = (target_position - global_position).normalized()
	var dist = global_position.distance_to(target_position)
	
	if dist < 5:
		is_moving = false
		velocity = Vector2.ZERO
	else:
		velocity = dir * move_speed
	
	move_and_slide()

func _find_player() -> Node:
	"""Encontra o player"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

# === INTERACAO ===

func interact(interactor: Node = null):
	"""Chamado quando player interage"""
	if is_dead:
		# Loot do corpo
		_on_loot(interactor)
		return
	
	if can_talk:
		_start_dialog(interactor)
	else:
		interaction_requested.emit(self)

func _start_dialog(_interactor: Node):
	"""Inicia dialogo"""
	var dialog_sys = get_node_or_null("/root/DialogSystem")
	if dialog_sys:
		if dialog_data.is_empty():
			# Dialogo padrao
			dialog_data = dialog_sys.create_simple_dialog(
				"Ola, viajante. O que deseja?",
				["Nada, obrigado.", "Quem e voce?", "Adeus."]
			)
		dialog_sys.start_dialog(self, dialog_data)

func _on_loot(_interactor: Node):
	"""Loot do corpo"""
	print("NPC: Loot de ", npc_name)
	# TODO: Abrir inventario do NPC morto

func _load_dialog():
	"""Carrega arquivo de dialogo"""
	var path = "res://assets/data/dialogs/" + dialog_file + ".json"
	if ResourceLoader.exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				dialog_data = json.data

# === COMBATE ===

func take_damage(amount: int, _source: Node = null):
	"""Recebe dano"""
	if is_dead:
		return
	
	var actual_damage = max(1, amount - (armor_class / 5))
	hp -= actual_damage
	
	print("NPC ", npc_name, " recebeu ", actual_damage, " de dano. HP: ", hp)
	
	if hp <= 0:
		hp = 0
		_die()

func heal(amount: int):
	"""Cura HP"""
	hp = min(hp + amount, max_hp)

func _die():
	"""NPC morreu"""
	is_dead = true
	print("NPC ", npc_name, " morreu!")
	
	# Mudar visual
	var visual = get_node_or_null("Visual")
	if visual:
		visual.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	# Desabilitar colisao
	collision_layer = 0
	collision_mask = 0
	
	died.emit()

func use_action_points(amount: int) -> bool:
	"""Usa action points"""
	if action_points >= amount:
		action_points -= amount
		return true
	return false

func restore_action_points():
	"""Restaura AP"""
	action_points = max_action_points

# === UTILIDADES ===

func get_display_name() -> String:
	"""Retorna nome para exibicao"""
	return npc_name

func is_alive() -> bool:
	"""Verifica se esta vivo"""
	return not is_dead and hp > 0

func set_hostile(hostile: bool):
	"""Define se e hostil"""
	is_hostile = hostile
	if hostile:
		add_to_group("enemy")
	else:
		remove_from_group("enemy")

func start_patrol():
	"""Inicia patrulha"""
	is_patrolling = true

func stop_patrol():
	"""Para patrulha"""
	is_patrolling = false
	is_moving = false
