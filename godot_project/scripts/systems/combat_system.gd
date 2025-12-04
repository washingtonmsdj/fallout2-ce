extends Node

## Sistema de Combate por Turnos do Fallout 2
## Baseado no codigo original (src/combat.cc)
## Implementa combate tatico com Action Points

signal combat_started()
signal combat_ended()
signal turn_started(combatant: Node)
signal turn_ended(combatant: Node)
signal attack_performed(attacker: Node, target: Node, damage: int, hit: bool)
signal combatant_died(combatant: Node)

enum CombatState { INACTIVE, PLAYER_TURN, ENEMY_TURN, ANIMATING }

# Constantes do original
const AP_COST_MOVE = 1        # AP por hex de movimento
const AP_COST_ATTACK = 3      # AP base para ataque
const AP_COST_RELOAD = 2      # AP para recarregar
const AP_COST_USE_ITEM = 2    # AP para usar item

# Estado
var current_state: CombatState = CombatState.INACTIVE
var combatants: Array = []
var current_combatant_index: int = 0
var turn_order: Array = []

# Referencia ao player
var player: Node = null

func _ready():
	# Conectar ao GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(p: Node):
	player = p

# === INICIO/FIM DO COMBATE ===

func start_combat(enemies: Array):
	"""Inicia combate com lista de inimigos"""
	if current_state != CombatState.INACTIVE:
		return
	
	print("CombatSystem: Iniciando combate com ", enemies.size(), " inimigos")
	
	# Adicionar combatentes
	combatants.clear()
	if player:
		combatants.append(player)
	combatants.append_array(enemies)
	
	# Calcular ordem de turno baseado em Sequence
	_calculate_turn_order()
	
	current_state = CombatState.PLAYER_TURN if turn_order[0] == player else CombatState.ENEMY_TURN
	current_combatant_index = 0
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.enter_combat()
	
	combat_started.emit()
	_start_turn(turn_order[0])

func end_combat():
	"""Termina o combate"""
	if current_state == CombatState.INACTIVE:
		return
	
	print("CombatSystem: Combate terminado")
	
	current_state = CombatState.INACTIVE
	combatants.clear()
	turn_order.clear()
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.exit_combat()
	
	combat_ended.emit()

func _calculate_turn_order():
	"""
	Calcula ordem de turno baseado em Sequence (igual ao original)
	Sequence = Perception * 2
	Combatentes com maior Sequence agem primeiro
	"""
	turn_order = combatants.duplicate()
	
	# Ordenar por Sequence (maior primeiro)
	turn_order.sort_custom(func(a, b):
		var seq_a = _get_sequence(a)
		var seq_b = _get_sequence(b)
		return seq_a > seq_b
	)
	
	print("CombatSystem: Ordem de turno calculada:")
	for i in range(turn_order.size()):
		var c = turn_order[i]
		print("  ", i + 1, ". ", c.name, " (Sequence: ", _get_sequence(c), ")")

func _get_sequence(combatant: Node) -> int:
	"""
	Calcula Sequence de um combatente
	Formula: Perception * 2
	"""
	if combatant.has("sequence"):
		return combatant.sequence
	elif combatant.has("perception"):
		return combatant.perception * 2
	else:
		return 10  # Valor padrão

# === TURNOS ===

func _start_turn(combatant: Node):
	"""Inicia turno de um combatente"""
	print("CombatSystem: Turno de ", combatant.name)
	
	# Restaurar AP
	if combatant.has_method("restore_action_points"):
		combatant.restore_action_points()
	
	turn_started.emit(combatant)
	
	# Se for inimigo, executar IA
	if combatant != player:
		_execute_enemy_ai(combatant)

func end_turn():
	"""Termina turno atual e passa para proximo"""
	var current = turn_order[current_combatant_index]
	turn_ended.emit(current)
	
	# Proximo combatente
	current_combatant_index += 1
	if current_combatant_index >= turn_order.size():
		current_combatant_index = 0
	
	# Verificar se combate acabou
	if _check_combat_end():
		end_combat()
		return
	
	# Iniciar proximo turno
	var next = turn_order[current_combatant_index]
	current_state = CombatState.PLAYER_TURN if next == player else CombatState.ENEMY_TURN
	_start_turn(next)

func _check_combat_end() -> bool:
	"""
	Verifica se o combate deve terminar
	Condições:
	- Todos os inimigos estão mortos (HP <= 0)
	- Player está morto
	"""
	var alive_enemies = 0
	var player_alive = false
	
	for c in combatants:
		var is_alive = _is_combatant_alive(c)
		
		if c == player:
			player_alive = is_alive
		elif is_alive:
			alive_enemies += 1
	
	# Combate termina se player morreu OU todos inimigos morreram
	var should_end = not player_alive or alive_enemies == 0
	
	if should_end:
		if not player_alive:
			print("CombatSystem: Player morreu - Combate terminado")
		elif alive_enemies == 0:
			print("CombatSystem: Todos inimigos derrotados - Combate terminado")
	
	return should_end

func _is_combatant_alive(combatant: Node) -> bool:
	"""Verifica se um combatente está vivo"""
	if combatant.has("hp"):
		return combatant.hp > 0
	return true  # Se não tem HP, assume vivo

# === ACOES DE COMBATE ===

func can_attack(attacker: Node, ap_cost: int = AP_COST_ATTACK) -> bool:
	"""Verifica se pode atacar"""
	if current_state == CombatState.INACTIVE:
		return false
	if not attacker.has_method("get"):
		return true
	return attacker.action_points >= ap_cost

func perform_attack(attacker: Node, target: Node, weapon = null):
	"""Executa um ataque"""
	if not can_attack(attacker):
		print("CombatSystem: AP insuficiente para atacar")
		return
	
	current_state = CombatState.ANIMATING
	
	# Calcular hit chance (igual ao original)
	var hit_chance = _calculate_hit_chance(attacker, target, weapon)
	var roll = randi() % 100
	var hit = roll < hit_chance
	
	var damage = 0
	var critical = false
	
	if hit:
		# Calcular dano
		damage = _calculate_damage(attacker, target, weapon)
		
		# Verificar critico
		var crit_chance = attacker.critical_chance if attacker.has_method("get") else 5
		if randi() % 100 < crit_chance:
			critical = true
			damage *= 2
		
		# Aplicar dano
		if target.has_method("take_damage"):
			target.take_damage(damage, attacker)
		
		print("CombatSystem: ", attacker.name, " acertou ", target.name, " por ", damage, " dano", " (CRITICO!)" if critical else "")
	else:
		print("CombatSystem: ", attacker.name, " errou ", target.name)
	
	# Gastar AP
	if attacker.has_method("use_action_points"):
		attacker.use_action_points(AP_COST_ATTACK)
	
	attack_performed.emit(attacker, target, damage, hit)
	
	# Verificar morte
	if target.has_method("get") and target.hp <= 0:
		_on_combatant_death(target)
	
	current_state = CombatState.PLAYER_TURN if turn_order[current_combatant_index] == player else CombatState.ENEMY_TURN

func _calculate_hit_chance(attacker: Node, target: Node, weapon) -> int:
	"""
	Calcula chance de acerto (fórmula fiel ao Fallout 2)
	Formula: Hit = Skill - (Distance * 4) - Target_AC + (Perception * 2)
	Clamped entre 5% e 95%
	"""
	# Skill de arma (simplificado - em produção viria do personagem)
	var weapon_skill = 50
	if attacker.has("weapon_skill"):
		weapon_skill = attacker.weapon_skill
	elif weapon and weapon.has("skill_type"):
		# Poderia buscar skill específica do personagem
		weapon_skill = 50
	
	# Perception do atacante
	var attacker_perception = attacker.perception if attacker.has("perception") else 5
	
	# Armor Class do alvo
	var target_ac = target.armor_class if target.has("armor_class") else 0
	
	# Distância em hexes
	var distance_pixels = attacker.global_position.distance_to(target.global_position)
	var distance_hexes = int(distance_pixels / 32.0)  # 32 pixels por hex
	var distance_penalty = distance_hexes * 4
	
	# Fórmula do Fallout 2
	var hit_chance = weapon_skill - distance_penalty - target_ac + (attacker_perception * 2)
	
	# Clampar entre 5% e 95%
	return clamp(hit_chance, 5, 95)

func _calculate_damage(attacker: Node, target: Node, weapon) -> int:
	"""
	Calcula dano (fórmula fiel ao Fallout 2)
	Formula: Damage = Weapon_Damage + Strength_Bonus - (DR * Damage / 100)
	Mínimo de 1 de dano
	"""
	# Dano base da arma
	var weapon_damage = 5  # Padrão
	if weapon and weapon.has("damage"):
		weapon_damage = weapon.damage
	elif weapon and weapon.has("damage_min") and weapon.has("damage_max"):
		weapon_damage = randi_range(weapon.damage_min, weapon.damage_max)
	
	# Bônus de força (melee damage)
	var strength_bonus = 0
	if attacker.has("melee_damage"):
		strength_bonus = attacker.melee_damage
	elif attacker.has("strength"):
		# Calcular melee damage: max(1, Strength - 5)
		strength_bonus = max(0, attacker.strength - 5)
	
	# Dano total antes da redução
	var total_damage = weapon_damage + strength_bonus
	
	# Damage Resistance (DR) do alvo
	var target_dr = 0
	if target.has("damage_resistance"):
		target_dr = target.damage_resistance
	elif target.has("armor_class"):
		# Simplificação: AC/2 = DR aproximado
		target_dr = target.armor_class / 2
	
	# Aplicar DR: Damage = Damage - (DR * Damage / 100)
	var dr_reduction = (target_dr * total_damage) / 100
	var final_damage = total_damage - dr_reduction
	
	# Mínimo de 1 de dano
	return max(1, int(final_damage))

func _on_combatant_death(combatant: Node):
	"""Chamado quando um combatente morre"""
	print("CombatSystem: ", combatant.name, " morreu!")
	combatant_died.emit(combatant)
	
	# Remover da ordem de turno
	var idx = turn_order.find(combatant)
	if idx != -1:
		turn_order.remove_at(idx)
		if current_combatant_index > idx:
			current_combatant_index -= 1

# === IA DE INIMIGOS ===

func _execute_enemy_ai(enemy: Node):
	"""Executa IA basica de inimigo"""
	if not player or player.hp <= 0:
		end_turn()
		return
	
	# IA simples: atacar player se tiver AP
	while can_attack(enemy):
		var dist = enemy.global_position.distance_to(player.global_position)
		
		if dist < 100:  # Alcance de ataque
			perform_attack(enemy, player)
			await get_tree().create_timer(0.5).timeout
		else:
			# Mover em direcao ao player
			if enemy.has_method("use_action_points") and enemy.action_points >= AP_COST_MOVE:
				var dir = (player.global_position - enemy.global_position).normalized()
				enemy.global_position += dir * 32
				enemy.use_action_points(AP_COST_MOVE)
			else:
				break
	
	# Terminar turno
	await get_tree().create_timer(0.3).timeout
	end_turn()

# === UTILIDADES ===

func get_current_combatant() -> Node:
	"""Retorna combatente atual"""
	if turn_order.is_empty():
		return null
	return turn_order[current_combatant_index]

func is_player_turn() -> bool:
	"""Verifica se e turno do player"""
	return current_state == CombatState.PLAYER_TURN

func is_in_combat() -> bool:
	"""Verifica se esta em combate"""
	return current_state != CombatState.INACTIVE
