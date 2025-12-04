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

# Inventário (para loot após morte)
var inventory: Array[Dictionary] = []
var prototype_data: Dictionary = {}

# Comércio (para NPCs mercadores)
var merchant_inventory: Array[Dictionary] = []
var merchant_caps: int = 1000  # Dinheiro do mercador
var buy_multiplier: float = 0.5  # Multiplicador de compra (NPC compra por 50% do valor)
var sell_multiplier: float = 1.5  # Multiplicador de venda (NPC vende por 150% do valor)

# Movimento
var move_speed: float = 80.0
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

# Animação
var animation_controller: AnimationController = null

func _ready():
	add_to_group("npc")
	
	if is_hostile:
		add_to_group("enemy")
	
	# Integrar com PrototypeSystem se houver prototype_id
	if npc_id != "":
		_load_from_prototype()
	
	# Carregar dialogo se especificado
	if not dialog_file.is_empty():
		_load_dialog()
	
	# Criar AnimationController
	_setup_animation_controller()

func _setup_animation_controller():
	"""Configura AnimationController para o NPC"""
	animation_controller = AnimationController.new()
	animation_controller.name = "AnimationController"
	add_child(animation_controller)
	
	# Carregar spritesheets do protótipo se disponível
	if prototype_data.has("spritesheets"):
		var sheets = prototype_data.get("spritesheets", {})
		for state_name in sheets:
			var state = _get_animation_state_from_string(state_name)
			var paths = sheets[state_name]
			if paths is Array and paths.size() == 6:
				animation_controller.load_spritesheets_for_state(state, paths)

func _get_animation_state_from_string(state_name: String) -> AnimationController.AnimationState:
	"""Converte string para AnimationState"""
	match state_name.to_lower():
		"idle":
			return AnimationController.AnimationState.IDLE
		"walk":
			return AnimationController.AnimationState.WALK
		"attack":
			return AnimationController.AnimationState.ATTACK
		"death":
			return AnimationController.AnimationState.DEATH
		"hurt":
			return AnimationController.AnimationState.HURT
		_:
			return AnimationController.AnimationState.IDLE

func _load_from_prototype():
	"""
	Carrega stats e comportamento do protótipo
	Aplica aparência (sprites) do protótipo
	"""
	var prototype_system = get_node_or_null("/root/PrototypeSystem")
	if not prototype_system:
		return
	
	# Tentar carregar protótipo de criatura
	var prototype = prototype_system.get_critter_prototype(npc_id)
	if prototype.is_empty():
		# Tentar usar npc_id diretamente
		prototype = prototype_system.get_critter_prototype(npc_id)
	
	if prototype.is_empty():
		push_warning("NPC: Protótipo não encontrado: " + npc_id)
		return
	
	# Armazenar dados do protótipo
	prototype_data = prototype
	
	# Aplicar stats do protótipo
	if prototype.has("name"):
		npc_name = prototype.name
	
	if prototype.has("hp"):
		max_hp = prototype.get("hp", 20)
		hp = max_hp
	
	if prototype.has("strength"):
		strength = prototype.get("strength", 5)
	if prototype.has("perception"):
		perception = prototype.get("perception", 5)
	if prototype.has("endurance"):
		endurance = prototype.get("endurance", 5)
	if prototype.has("charisma"):
		charisma = prototype.get("charisma", 5)
	if prototype.has("intelligence"):
		intelligence = prototype.get("intelligence", 5)
	if prototype.has("agility"):
		agility = prototype.get("agility", 5)
	if prototype.has("luck"):
		luck = prototype.get("luck", 5)
	
	# Aplicar comportamento
	if prototype.has("is_hostile"):
		is_hostile = prototype.get("is_hostile", false)
		if is_hostile:
			add_to_group("enemy")
	
	if prototype.has("is_merchant"):
		is_merchant = prototype.get("is_merchant", false)
	
	if prototype.has("can_talk"):
		can_talk = prototype.get("can_talk", true)
	
	# Carregar inventário inicial do protótipo
	if prototype.has("inventory"):
		inventory = prototype.get("inventory", []).duplicate()
	
	# Carregar estoque do mercador se for mercador
	if is_merchant and prototype.has("merchant_inventory"):
		merchant_inventory = prototype.get("merchant_inventory", []).duplicate()
	if is_merchant and prototype.has("merchant_caps"):
		merchant_caps = prototype.get("merchant_caps", 1000)
	
	# Aplicar aparência (sprites)
	if prototype.has("sprite") or prototype.has("texture"):
		var sprite_path = prototype.get("sprite", prototype.get("texture", ""))
		if sprite_path != "":
			_apply_sprite(sprite_path)
	
	# Calcular stats derivados
	_calculate_derived_stats()
	
	print("NPC: Carregado do protótipo: ", npc_name)

func _apply_sprite(sprite_path: String):
	"""Aplica sprite do protótipo"""
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	var texture = load(sprite_path)
	if texture:
		sprite.texture = texture
	else:
		push_warning("NPC: Sprite não encontrado: " + sprite_path)

func _calculate_derived_stats():
	"""Calcula stats derivados baseado em SPECIAL"""
	armor_class = agility
	sequence = 2 * perception
	max_action_points = 5 + (agility / 2)
	action_points = max_action_points

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

func _hostile_ai(delta):
	"""
	IA para NPCs hostis
	Detecta player em range e inicia combate automaticamente
	"""
	if is_dead:
		return
	
	# Procurar player
	var player = _find_player()
	if not player:
		current_target = null
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Detectar player em range
	if dist < detection_range:
		current_target = player
		
		# Se não estiver em combate, iniciar
		var combat = get_node_or_null("/root/CombatSystem")
		if combat:
			if not combat.is_in_combat():
				# Iniciar combate com este NPC como inimigo
				combat.start_combat([self])
				print("NPC: Combate iniciado! ", npc_name, " atacando player")
			else:
				# Já está em combate, verificar se precisa se mover
				if dist > 50:  # Se muito longe, aproximar
					target_position = player.global_position
					is_moving = true
	else:
		# Player fora de range
		current_target = null
		is_moving = false

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

func _handle_movement(delta):
	"""Processa movimento"""
	var dir = (target_position - global_position).normalized()
	var dist = global_position.distance_to(target_position)
	
	if dist < 5:
		is_moving = false
		velocity = Vector2.ZERO
	else:
		velocity = dir * move_speed
	
	# Sincronizar AnimationController com movimento
	if animation_controller:
		animation_controller.sync_with_movement(is_moving, dir)
	
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

func _start_dialog(interactor: Node):
	"""Inicia dialogo"""
	var dialog_sys = get_node_or_null("/root/DialogSystem")
	if dialog_sys:
		if dialog_data.is_empty():
			# Dialogo padrao
			if is_merchant:
				dialog_data = dialog_sys.create_simple_dialog(
					"Bem-vindo! O que voce gostaria de comprar?",
					["Ver mercadoria", "Vender itens", "Nada, obrigado."]
				)
			else:
				dialog_data = dialog_sys.create_simple_dialog(
					"Ola, viajante. O que deseja?",
					["Nada, obrigado.", "Quem e voce?", "Adeus."]
				)
		dialog_sys.start_dialog(self, dialog_data)
		
		# Se for mercador, oferecer comércio após diálogo
		if is_merchant:
			# Adicionar opção de comércio ao diálogo
			call_deferred("_offer_trade", interactor)

func _on_loot(interactor: Node):
	"""
	Loot do corpo
	Abre inventário do NPC morto para transferir itens
	"""
	if not is_dead:
		return
	
	print("NPC: Loot de ", npc_name)
	
	# Abrir interface de loot
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	# Criar interface de loot (simplificada)
	_open_loot_interface(interactor)

func _open_loot_interface(interactor: Node):
	"""Abre interface de loot do corpo"""
	# Por enquanto, transferir todos os itens automaticamente
	# TODO: Criar interface visual de loot
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		return
	
	var transferred = 0
	for item in inventory:
		if inventory_system.add_item(item, item.get("quantity", 1)):
			transferred += 1
			print("NPC: Item transferido: ", item.get("name", "Unknown"))
	
	# Limpar inventário após transferência
	if transferred > 0:
		inventory.clear()
		set_meta("inventory", [])
		print("NPC: ", transferred, " itens transferidos do corpo")

func get_corpse_inventory() -> Array[Dictionary]:
	"""Retorna inventário do corpo (para acesso externo)"""
	if is_dead:
		return inventory.duplicate()
	return []

func has_items_in_corpse() -> bool:
	"""Verifica se o corpo ainda tem itens"""
	return is_dead and inventory.size() > 0

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
	"""
	NPC morreu
	Cria corpo com inventário acessível
	Mantém corpo no mapa
	"""
	is_dead = true
	print("NPC ", npc_name, " morreu!")
	
	# Criar corpo (corpse) - manter no mapa
	_create_corpse()
	
	# Atualizar animação para morte
	if animation_controller:
		animation_controller.set_death()
	
	# Mudar visual para indicar morte
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	# Desabilitar colisão de movimento, mas manter interação
	collision_layer = 0
	collision_mask = 0
	
	# Adicionar ao grupo de corpos
	add_to_group("corpse")
	remove_from_group("npc")
	if is_in_group("enemy"):
		remove_from_group("enemy")
	
	died.emit()

func _create_corpse():
	"""
	Cria corpo com inventário acessível
	O corpo permanece no mapa e pode ser lootado
	"""
	# Marcar como corpo
	set_meta("is_corpse", true)
	set_meta("corpse_name", npc_name)
	set_meta("inventory", inventory)
	
	# Criar área de interação para loot
	var interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	add_child(interaction_area)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	interaction_area.add_child(collision)
	
	# Configurar para detectar player
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 1  # Player layer
	
	print("NPC: Corpo criado com ", inventory.size(), " itens no inventário")

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

# === COMÉRCIO (NPC MERCADOR) ===

func _offer_trade(interactor: Node):
	"""Oferece interface de comércio"""
	if not is_merchant:
		return
	
	print("NPC Mercador: Abrindo interface de comércio")
	_open_trade_interface(interactor)

func _open_trade_interface(interactor: Node):
	"""
	Abre interface de comércio
	Gerenciar estoque do mercador
	"""
	# Por enquanto, apenas log
	# TODO: Criar interface visual de comércio
	
	print("NPC Mercador: Estoque disponível:")
	for item in merchant_inventory:
		var price = _calculate_sell_price(item)
		print("  - ", item.get("name", "Unknown"), ": ", price, " caps")
	
	print("NPC Mercador: Caps disponíveis: ", merchant_caps)
	print("NPC Mercador: Interface de comércio (placeholder)")

func _calculate_sell_price(item: Dictionary) -> int:
	"""Calcula preço de venda do item"""
	var base_value = item.get("value", 0)
	return int(base_value * sell_multiplier)

func _calculate_buy_price(item: Dictionary) -> int:
	"""Calcula preço de compra do item (quanto NPC paga)"""
	var base_value = item.get("value", 0)
	return int(base_value * buy_multiplier)

func buy_item_from_player(item: Dictionary, quantity: int = 1) -> bool:
	"""
	NPC compra item do player
	Retorna true se compra foi bem-sucedida
	"""
	var price = _calculate_buy_price(item) * quantity
	
	if merchant_caps < price:
		print("NPC Mercador: Sem caps suficientes")
		return false
	
	# Adicionar item ao estoque do mercador
	var item_copy = item.duplicate()
	item_copy["quantity"] = quantity
	merchant_inventory.append(item_copy)
	
	# Deduzir caps
	merchant_caps -= price
	
	print("NPC Mercador: Comprou ", quantity, "x ", item.get("name", "Unknown"), " por ", price, " caps")
	return true

func sell_item_to_player(item_id: String, quantity: int = 1) -> Dictionary:
	"""
	NPC vende item ao player
	Retorna item se venda foi bem-sucedida, {} caso contrário
	"""
	# Procurar item no estoque
	for i in range(merchant_inventory.size()):
		var item = merchant_inventory[i]
		if item.get("id") == item_id:
			var available_qty = item.get("quantity", 1)
			
			if available_qty < quantity:
				print("NPC Mercador: Estoque insuficiente")
				return {}
			
			# Criar item para venda
			var sold_item = item.duplicate()
			sold_item["quantity"] = quantity
			
			# Remover do estoque
			if available_qty == quantity:
				merchant_inventory.remove_at(i)
			else:
				item["quantity"] = available_qty - quantity
			
			# Adicionar caps
			var price = _calculate_sell_price(item) * quantity
			merchant_caps += price
			
			print("NPC Mercador: Vendeu ", quantity, "x ", item.get("name", "Unknown"), " por ", price, " caps")
			return sold_item
	
	print("NPC Mercador: Item não encontrado no estoque")
	return {}

func get_merchant_inventory() -> Array[Dictionary]:
	"""Retorna estoque do mercador"""
	return merchant_inventory.duplicate()

func get_merchant_caps() -> int:
	"""Retorna caps disponíveis do mercador"""
	return merchant_caps
