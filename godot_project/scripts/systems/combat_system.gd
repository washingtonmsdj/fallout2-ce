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

# Constantes do original (baseado em src/combat.cc)
const AP_COST_MOVE = 1        # AP por hex de movimento
const AP_COST_ATTACK_UNARMED = 3  # AP para ataque desarmado
const AP_COST_ATTACK_MELEE = 3    # AP para ataque melee
const AP_COST_ATTACK_RANGED = 4   # AP para ataque ranged (varia por arma)
const AP_COST_RELOAD = 2      # AP para recarregar
const AP_COST_USE_ITEM = 2    # AP para usar item
const AP_COST_CHANGE_WEAPON = 2   # AP para trocar arma
const AP_COST_PICKUP = 3      # AP para pegar item do chão
const AP_COST_OPEN_DOOR = 3   # AP para abrir porta
const AP_COST_USE_SKILL = 4   # AP para usar skill

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
	
	# Restaurar AP com modificadores
	_restore_action_points(combatant)
	
	turn_started.emit(combatant)
	
	# Se for inimigo, executar IA
	if combatant != player:
		_execute_enemy_ai(combatant)

func _restore_action_points(combatant: Node):
	"""
	Restaura Action Points no início do turno
	Considera perks que modificam AP máximo:
	- Action Boy/Girl: +1 AP por rank
	- Bonus Move: +2 AP
	"""
	if not combatant.has("max_action_points"):
		return
	
	var base_ap = combatant.max_action_points
	var bonus_ap = 0
	
	# Aplicar bônus de perks
	if combatant.has("perks"):
		# Action Boy/Girl: +1 AP por rank (máximo 2 ranks)
		if "action_boy" in combatant.perks:
			bonus_ap += 1
		if "action_boy_2" in combatant.perks:
			bonus_ap += 1
		
		# Bonus Move: +2 AP
		if "bonus_move" in combatant.perks:
			bonus_ap += 2
	
	# Restaurar AP total
	if combatant.has_method("restore_action_points"):
		combatant.restore_action_points()
		# Adicionar bônus
		if bonus_ap > 0 and combatant.has("action_points"):
			combatant.action_points += bonus_ap
			print("CombatSystem: ", combatant.name, " recebeu +", bonus_ap, " AP de perks")
	elif combatant.has("action_points"):
		combatant.action_points = base_ap + bonus_ap

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

func can_attack(attacker: Node, weapon = null) -> bool:
	"""Verifica se pode atacar"""
	if current_state == CombatState.INACTIVE:
		return false
	if not attacker.has("action_points"):
		return true
	
	var ap_cost = get_attack_ap_cost(attacker, weapon)
	return attacker.action_points >= ap_cost

func get_attack_ap_cost(attacker: Node, weapon = null) -> int:
	"""
	Calcula custo de AP para ataque (baseado no Fallout 2)
	Considera:
	- Tipo de arma (unarmed, melee, ranged)
	- AP cost específico da arma
	- Perks que reduzem AP (Bonus HtH Attacks, Bonus Ranged Damage, etc.)
	"""
	var base_cost = AP_COST_ATTACK_UNARMED
	
	# Determinar custo base pela arma
	if weapon:
		if weapon.has("ap_cost"):
			base_cost = weapon.ap_cost
		elif weapon.has("is_ranged"):
			base_cost = AP_COST_ATTACK_RANGED if weapon.is_ranged else AP_COST_ATTACK_MELEE
	
	# Aplicar modificadores de perks
	var perk_modifier = 0
	if attacker.has("perks"):
		# Bonus HtH Attacks: -1 AP para ataques melee/unarmed
		if "bonus_hth_attacks" in attacker.perks:
			if not weapon or (weapon.has("is_ranged") and not weapon.is_ranged):
				perk_modifier -= 1
		
		# Bonus Rate of Fire: -1 AP para ataques ranged
		if "bonus_rate_of_fire" in attacker.perks:
			if weapon and weapon.has("is_ranged") and weapon.is_ranged:
				perk_modifier -= 1
		
		# Fast Shot trait: -1 AP mas não pode mirar
		if "fast_shot" in attacker.perks:
			perk_modifier -= 1
	
	var final_cost = base_cost + perk_modifier
	
	# Mínimo de 1 AP
	return max(1, final_cost)

func get_move_ap_cost(attacker: Node, distance_hexes: int) -> int:
	"""
	Calcula custo de AP para movimento
	Formula: AP_COST_MOVE * distance
	Modificadores:
	- Fleet of Foot perk: reduz custo
	"""
	var base_cost = AP_COST_MOVE * distance_hexes
	
	# Aplicar modificadores de perks
	if attacker.has("perks"):
		# Fleet of Foot: reduz custo de movimento
		if "fleet_of_foot" in attacker.perks:
			base_cost = int(base_cost * 0.75)  # 25% de redução
	
	return max(1, base_cost)

func get_reload_ap_cost(attacker: Node, weapon = null) -> int:
	"""
	Calcula custo de AP para recarregar
	"""
	var base_cost = AP_COST_RELOAD
	
	if weapon and weapon.has("reload_ap_cost"):
		base_cost = weapon.reload_ap_cost
	
	# Quick Pockets perk reduz custo de reload
	if attacker.has("perks") and "quick_pockets" in attacker.perks:
		base_cost = int(base_cost * 0.5)
	
	return max(1, base_cost)

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
	var is_critical_hit = false
	var is_critical_miss = false
	var critical_effect = ""
	
	# Verificar critical miss (sempre possível, mesmo com alta skill)
	if roll >= 95:  # 5% de chance de critical miss
		is_critical_miss = true
		critical_effect = _apply_critical_miss(attacker, weapon)
		print("CombatSystem: ", attacker.name, " CRITICAL MISS! ", critical_effect)
	elif hit:
		# Calcular dano base
		damage = _calculate_damage(attacker, target, weapon)
		
		# Verificar critical hit
		var crit_chance = _calculate_critical_chance(attacker, target, weapon)
		var crit_roll = randi() % 100
		
		if crit_roll < crit_chance:
			is_critical_hit = true
			var crit_result = _apply_critical_hit(attacker, target, weapon, damage)
			damage = crit_result.damage
			critical_effect = crit_result.effect
			print("CombatSystem: ", attacker.name, " CRITICAL HIT em ", target.name, "! ", critical_effect)
		
		# Aplicar dano
		if target.has_method("take_damage"):
			target.take_damage(damage, attacker)
		
		if is_critical_hit:
			print("CombatSystem: ", attacker.name, " acertou ", target.name, " por ", damage, " dano (CRITICO!)")
		else:
			print("CombatSystem: ", attacker.name, " acertou ", target.name, " por ", damage, " dano")
	else:
		print("CombatSystem: ", attacker.name, " errou ", target.name)
	
	# Gastar AP (custo calculado baseado na arma e perks)
	if attacker.has_method("use_action_points"):
		var ap_cost = get_attack_ap_cost(attacker, weapon)
		attacker.use_action_points(ap_cost)
	
	attack_performed.emit(attacker, target, damage, hit)
	
	# Verificar morte
	if target.has_method("get") and target.hp <= 0:
		_on_combatant_death(target)
	
	current_state = CombatState.PLAYER_TURN if turn_order[current_combatant_index] == player else CombatState.ENEMY_TURN

func _calculate_hit_chance(attacker: Node, target: Node, weapon) -> int:
	"""
	Calcula chance de acerto (fórmula fiel ao Fallout 2)
	Formula original: Hit% = Skill - (Distance * 4) - Target_AC + (Perception * 2)
	Modificadores adicionais:
	- Lighting conditions
	- Target stance (standing, crouching, prone)
	- Attacker stance
	- Weapon accuracy modifier
	Clamped entre 5% e 95%
	"""
	# Skill de arma base
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
	
	# Distância em hexes (32 pixels por hex no Fallout 2)
	var distance_pixels = attacker.global_position.distance_to(target.global_position)
	var distance_hexes = int(distance_pixels / 32.0)
	var distance_penalty = distance_hexes * 4
	
	# Modificador de arma (accuracy)
	var weapon_accuracy = 0
	if weapon and weapon.has("accuracy_modifier"):
		weapon_accuracy = weapon.accuracy_modifier
	
	# Fórmula base do Fallout 2
	var hit_chance = weapon_skill - distance_penalty - target_ac + (attacker_perception * 2) + weapon_accuracy
	
	# Modificadores de stance (se implementado)
	if target.has("is_crouching") and target.is_crouching:
		hit_chance -= 20  # Alvo agachado é mais difícil de acertar
	
	if attacker.has("is_aiming") and attacker.is_aiming:
		hit_chance += 20  # Mirar aumenta precisão
	
	# Clampar entre 5% e 95% (limites do Fallout 2)
	return clamp(hit_chance, 5, 95)

func _calculate_damage(attacker: Node, target: Node, weapon) -> int:
	"""
	Calcula dano (fórmula fiel ao Fallout 2)
	Formula original do Fallout 2:
	1. Calcular dano base: Weapon_Damage + Strength_Bonus (para melee)
	2. Aplicar Damage Threshold (DT): Se dano < DT, dano = 0
	3. Aplicar Damage Resistance (DR): Damage = Damage * (1 - DR/100)
	4. Mínimo de 0 de dano (pode ser 0 se DT bloquear tudo)
	
	DT = Damage Threshold (valor fixo subtraído)
	DR = Damage Resistance (porcentagem de redução)
	"""
	# Dano base da arma
	var weapon_damage = 5  # Padrão
	var damage_type = "normal"  # normal, laser, fire, plasma, explosive, etc.
	
	if weapon and weapon.has("damage"):
		weapon_damage = weapon.damage
	elif weapon and weapon.has("damage_min") and weapon.has("damage_max"):
		weapon_damage = randi_range(weapon.damage_min, weapon.damage_max)
	
	if weapon and weapon.has("damage_type"):
		damage_type = weapon.damage_type
	
	# Bônus de força (apenas para armas melee/unarmed)
	var strength_bonus = 0
	var is_melee = true
	if weapon and weapon.has("is_ranged"):
		is_melee = not weapon.is_ranged
	
	if is_melee:
		if attacker.has("melee_damage"):
			strength_bonus = attacker.melee_damage
		elif attacker.has("strength"):
			# Calcular melee damage: max(1, Strength - 5)
			strength_bonus = max(0, attacker.strength - 5)
	
	# Dano total antes das resistências
	var total_damage = weapon_damage + strength_bonus
	
	# Damage Threshold (DT) do alvo - valor fixo subtraído
	var target_dt = 0
	if target.has("damage_threshold"):
		if target.damage_threshold is Dictionary:
			target_dt = target.damage_threshold.get(damage_type, 0)
		else:
			target_dt = target.damage_threshold
	
	# Aplicar DT: Se dano não ultrapassar DT, não causa dano
	total_damage -= target_dt
	if total_damage <= 0:
		return 0  # DT bloqueou todo o dano
	
	# Damage Resistance (DR) do alvo - porcentagem de redução
	var target_dr = 0
	if target.has("damage_resistance"):
		if target.damage_resistance is Dictionary:
			target_dr = target.damage_resistance.get(damage_type, 0)
		else:
			target_dr = target.damage_resistance
	elif target.has("armor_class"):
		# Simplificação: AC/2 = DR aproximado
		target_dr = target.armor_class / 2
	
	# Clampar DR entre 0% e 90% (limite do Fallout 2)
	target_dr = clamp(target_dr, 0, 90)
	
	# Aplicar DR: Damage = Damage * (1 - DR/100)
	var dr_multiplier = 1.0 - (target_dr / 100.0)
	var final_damage = int(total_damage * dr_multiplier)
	
	# Mínimo de 0 de dano (pode ser 0 se resistências forem altas)
	return max(0, final_damage)

func _calculate_critical_chance(attacker: Node, target: Node, weapon) -> int:
	"""
	Calcula chance de critical hit (baseado no Fallout 2)
	Formula: Base_Crit_Chance + Luck + (Better Criticals perk * 20)
	Base é geralmente 5% (Luck stat)
	"""
	var base_crit = 0
	
	# Luck do atacante determina chance base
	if attacker.has("luck"):
		base_crit = attacker.luck
	elif attacker.has("critical_chance"):
		base_crit = attacker.critical_chance
	else:
		base_crit = 5  # Padrão
	
	# Modificador de arma
	var weapon_crit_mod = 0
	if weapon and weapon.has("critical_chance_modifier"):
		weapon_crit_mod = weapon.critical_chance_modifier
	
	# Perks (Better Criticals, More Criticals, etc.)
	var perk_bonus = 0
	if attacker.has("perks"):
		if "more_criticals" in attacker.perks:
			perk_bonus += 10
		if "sniper" in attacker.perks:
			perk_bonus += 10
	
	var total_crit_chance = base_crit + weapon_crit_mod + perk_bonus
	
	# Clampar entre 0% e 95%
	return clamp(total_crit_chance, 0, 95)

func _apply_critical_hit(attacker: Node, target: Node, weapon, base_damage: int) -> Dictionary:
	"""
	Aplica efeitos de critical hit (baseado no Fallout 2)
	Efeitos variam por tipo de arma e localização do hit
	Retorna: {damage: int, effect: String}
	"""
	var crit_multiplier = 2.0  # Multiplicador base
	var effect = "Dano crítico!"
	
	# Better Criticals perk aumenta multiplicador
	if attacker.has("perks") and "better_criticals" in attacker.perks:
		crit_multiplier = 2.5
		effect = "Dano crítico devastador!"
	
	# Efeitos especiais baseados em sorte
	var luck = attacker.luck if attacker.has("luck") else 5
	var effect_roll = randi() % 100
	
	if effect_roll < luck * 2:  # Chance baseada em Luck
		# Efeitos especiais
		var special_effects = [
			"Nocauteado!",
			"Cegado temporariamente!",
			"Aleijado!",
			"Arma derrubada!",
			"Atordoado!"
		]
		effect = special_effects[randi() % special_effects.size()]
		crit_multiplier += 0.5  # Efeitos especiais causam mais dano
	
	var final_damage = int(base_damage * crit_multiplier)
	
	return {
		"damage": final_damage,
		"effect": effect
	}

func _apply_critical_miss(attacker: Node, weapon) -> String:
	"""
	Aplica efeitos de critical miss (baseado no Fallout 2)
	Efeitos negativos para o atacante
	Retorna: String descrevendo o efeito
	"""
	var effects = [
		"Perdeu o equilíbrio!",
		"Arma travou!",
		"Deixou cair a arma!",
		"Acertou a si mesmo!",
		"Tropeçou!"
	]
	
	var effect_index = randi() % effects.size()
	var effect = effects[effect_index]
	
	# Aplicar efeito mecânico
	match effect_index:
		0:  # Perdeu equilíbrio - perde AP extra
			if attacker.has_method("use_action_points"):
				attacker.use_action_points(2)
		1:  # Arma travou - precisa recarregar
			pass  # TODO: Implementar estado de arma travada
		2:  # Deixou cair arma - perde turno
			if attacker.has_method("use_action_points"):
				attacker.action_points = 0
		3:  # Acertou a si mesmo - toma dano
			if attacker.has_method("take_damage"):
				var self_damage = randi_range(1, 5)
				attacker.take_damage(self_damage, attacker)
		4:  # Tropeçou - perde AP
			if attacker.has_method("use_action_points"):
				attacker.use_action_points(3)
	
	return effect

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

enum AIBehavior {
	AGGRESSIVE,   # Ataca sempre, prioriza dano
	DEFENSIVE,    # Mantém distância, usa cobertura
	BERSERK,      # Ataca sem considerar HP próprio
	COWARD,       # Foge quando HP baixo
	TACTICAL,     # Usa itens, posicionamento inteligente
	SUPPORT       # Cura aliados, usa buffs
}

func _execute_enemy_ai(enemy: Node):
	"""
	Executa IA de inimigo baseada em comportamento
	Implementa diferentes estratégias de combate
	"""
	if not player or player.hp <= 0:
		end_turn()
		return
	
	# Determinar comportamento do inimigo
	var behavior = _get_enemy_behavior(enemy)
	
	# Executar comportamento
	match behavior:
		AIBehavior.AGGRESSIVE:
			await _ai_aggressive(enemy)
		AIBehavior.DEFENSIVE:
			await _ai_defensive(enemy)
		AIBehavior.BERSERK:
			await _ai_berserk(enemy)
		AIBehavior.COWARD:
			await _ai_coward(enemy)
		AIBehavior.TACTICAL:
			await _ai_tactical(enemy)
		AIBehavior.SUPPORT:
			await _ai_support(enemy)
		_:
			await _ai_aggressive(enemy)  # Fallback
	
	# Terminar turno
	await get_tree().create_timer(0.3).timeout
	end_turn()

func _get_enemy_behavior(enemy: Node) -> AIBehavior:
	"""
	Determina comportamento do inimigo baseado em:
	- Tipo de NPC
	- HP atual
	- Personalidade/traits
	"""
	# Verificar se tem comportamento definido
	if enemy.has("ai_behavior"):
		return enemy.ai_behavior
	
	# Determinar baseado em HP
	var hp_percent = (float(enemy.hp) / float(enemy.max_hp)) * 100.0 if enemy.has("max_hp") else 100.0
	
	if hp_percent < 25:
		# HP baixo: fugir ou berserk
		if enemy.has("intelligence") and enemy.intelligence > 5:
			return AIBehavior.COWARD
		else:
			return AIBehavior.BERSERK
	elif hp_percent < 50:
		# HP médio: tático ou defensivo
		if enemy.has("intelligence") and enemy.intelligence > 6:
			return AIBehavior.TACTICAL
		else:
			return AIBehavior.DEFENSIVE
	else:
		# HP alto: agressivo
		return AIBehavior.AGGRESSIVE

func _ai_aggressive(enemy: Node):
	"""
	IA Agressiva: Ataca sempre que possível
	Prioriza causar dano máximo
	"""
	var weapon = _get_enemy_weapon(enemy)
	
	while enemy.action_points > 0:
		var dist = enemy.global_position.distance_to(player.global_position)
		var attack_range = _get_weapon_range(weapon)
		
		if dist <= attack_range and can_attack(enemy, weapon):
			# Atacar
			perform_attack(enemy, player, weapon)
			await get_tree().create_timer(0.5).timeout
		else:
			# Mover em direção ao player
			var move_cost = get_move_ap_cost(enemy, 1)
			if enemy.action_points >= move_cost:
				_move_towards(enemy, player.global_position, 32)
				enemy.use_action_points(move_cost)
				await get_tree().create_timer(0.2).timeout
			else:
				break

func _ai_defensive(enemy: Node):
	"""
	IA Defensiva: Mantém distância, ataca quando seguro
	Prioriza sobrevivência
	"""
	var weapon = _get_enemy_weapon(enemy)
	var dist = enemy.global_position.distance_to(player.global_position)
	var optimal_range = _get_weapon_range(weapon) * 0.8  # 80% do alcance máximo
	
	while enemy.action_points > 0:
		dist = enemy.global_position.distance_to(player.global_position)
		
		if dist < optimal_range * 0.5:
			# Muito perto: recuar
			var move_cost = get_move_ap_cost(enemy, 1)
			if enemy.action_points >= move_cost:
				_move_away_from(enemy, player.global_position, 32)
				enemy.use_action_points(move_cost)
				await get_tree().create_timer(0.2).timeout
			else:
				break
		elif dist <= optimal_range and can_attack(enemy, weapon):
			# Distância boa: atacar
			perform_attack(enemy, player, weapon)
			await get_tree().create_timer(0.5).timeout
		else:
			# Muito longe: aproximar
			var move_cost = get_move_ap_cost(enemy, 1)
			if enemy.action_points >= move_cost:
				_move_towards(enemy, player.global_position, 32)
				enemy.use_action_points(move_cost)
				await get_tree().create_timer(0.2).timeout
			else:
				break

func _ai_berserk(enemy: Node):
	"""
	IA Berserk: Ataca sem parar, ignora HP próprio
	Gasta todo AP em ataques
	"""
	var weapon = _get_enemy_weapon(enemy)
	
	# Gastar todo AP em ataques ou movimento para atacar
	while enemy.action_points > 0:
		var dist = enemy.global_position.distance_to(player.global_position)
		var attack_range = _get_weapon_range(weapon)
		
		if dist <= attack_range and can_attack(enemy, weapon):
			perform_attack(enemy, player, weapon)
			await get_tree().create_timer(0.3).timeout  # Mais rápido
		else:
			# Correr em direção ao player
			var move_cost = get_move_ap_cost(enemy, 1)
			if enemy.action_points >= move_cost:
				_move_towards(enemy, player.global_position, 48)  # Movimento mais rápido
				enemy.use_action_points(move_cost)
				await get_tree().create_timer(0.1).timeout
			else:
				break

func _ai_coward(enemy: Node):
	"""
	IA Covarde: Foge do combate
	Tenta maximizar distância do player
	"""
	# Gastar todo AP fugindo
	while enemy.action_points > 0:
		var move_cost = get_move_ap_cost(enemy, 1)
		if enemy.action_points >= move_cost:
			_move_away_from(enemy, player.global_position, 48)
			enemy.use_action_points(move_cost)
			await get_tree().create_timer(0.2).timeout
		else:
			break

func _ai_tactical(enemy: Node):
	"""
	IA Tática: Usa itens, posicionamento inteligente
	Considera uso de stimpaks, granadas, etc.
	"""
	var weapon = _get_enemy_weapon(enemy)
	var hp_percent = (float(enemy.hp) / float(enemy.max_hp)) * 100.0
	
	# Se HP baixo, tentar usar stimpack
	if hp_percent < 40 and enemy.action_points >= AP_COST_USE_ITEM:
		if _try_use_healing_item(enemy):
			await get_tree().create_timer(0.5).timeout
			return
	
	# Comportamento similar ao agressivo, mas mais inteligente
	await _ai_aggressive(enemy)

func _ai_support(enemy: Node):
	"""
	IA Suporte: Cura aliados, usa buffs
	Prioriza manter time vivo
	"""
	# Procurar aliados feridos
	var allies = _find_allies(enemy)
	var wounded_ally = null
	var lowest_hp_percent = 100.0
	
	for ally in allies:
		if ally.has("hp") and ally.has("max_hp"):
			var hp_percent = (float(ally.hp) / float(ally.max_hp)) * 100.0
			if hp_percent < lowest_hp_percent and hp_percent < 60:
				lowest_hp_percent = hp_percent
				wounded_ally = ally
	
	# Se encontrou aliado ferido, tentar curar
	if wounded_ally and enemy.action_points >= AP_COST_USE_ITEM:
		if _try_heal_ally(enemy, wounded_ally):
			await get_tree().create_timer(0.5).timeout
			return
	
	# Caso contrário, comportamento defensivo
	await _ai_defensive(enemy)

# === UTILIDADES DE IA ===

func _get_enemy_weapon(enemy: Node):
	"""Retorna arma equipada do inimigo"""
	if enemy.has("equipped_weapon"):
		return enemy.equipped_weapon
	return null

func _get_weapon_range(weapon) -> float:
	"""Retorna alcance da arma em pixels"""
	if weapon and weapon.has("range"):
		return weapon.range * 32.0  # Converter hexes para pixels
	return 64.0  # Alcance padrão (2 hexes)

func _move_towards(enemy: Node, target_pos: Vector2, distance: float):
	"""Move inimigo em direção a uma posição"""
	var dir = (target_pos - enemy.global_position).normalized()
	enemy.global_position += dir * distance

func _move_away_from(enemy: Node, target_pos: Vector2, distance: float):
	"""Move inimigo para longe de uma posição"""
	var dir = (enemy.global_position - target_pos).normalized()
	enemy.global_position += dir * distance

func _try_use_healing_item(enemy: Node) -> bool:
	"""Tenta usar item de cura"""
	# TODO: Implementar sistema de inventário de NPCs
	# Por enquanto, apenas simular cura
	if enemy.has_method("heal"):
		enemy.heal(10)
		enemy.use_action_points(AP_COST_USE_ITEM)
		print("CombatSystem: ", enemy.name, " usou stimpack")
		return true
	return false

func _try_heal_ally(enemy: Node, ally: Node) -> bool:
	"""Tenta curar aliado"""
	# TODO: Implementar sistema de cura de aliados
	if ally.has_method("heal"):
		ally.heal(10)
		enemy.use_action_points(AP_COST_USE_ITEM)
		print("CombatSystem: ", enemy.name, " curou ", ally.name)
		return true
	return false

func _find_allies(enemy: Node) -> Array:
	"""Encontra aliados do inimigo"""
	var allies: Array = []
	for combatant in combatants:
		if combatant != enemy and combatant != player:
			allies.append(combatant)
	return allies

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
