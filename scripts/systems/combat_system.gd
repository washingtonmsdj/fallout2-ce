extends Node
class_name CombatSystem
## Sistema de combate turn-based inspirado no Fallout

signal combat_started
signal combat_ended
signal turn_started(critter: Critter)
signal turn_ended(critter: Critter)
signal attack_executed(attacker: Critter, defender: Critter, result: Dictionary)

var combat_state: GameConstants.CombatState = GameConstants.CombatState.IDLE
var combatants: Array[Critter] = []
var turn_order: Array[Critter] = []
var current_turn_index: int = 0
var current_combatant: Critter = null

func start_combat(participants: Array[Critter]) -> void:
	if combat_state != GameConstants.CombatState.IDLE:
		return
	
	combatants = participants
	_calculate_turn_order()
	combat_state = GameConstants.CombatState.PLAYER_TURN
	current_turn_index = 0
	
	# Inicia primeiro turno
	_start_next_turn()
	combat_started.emit()

func _calculate_turn_order() -> void:
	# Ordena por Sequence (maior primeiro)
	turn_order = combatants.duplicate()
	turn_order.sort_custom(func(a: Critter, b: Critter) -> bool:
		return a.stats.sequence > b.stats.sequence
	)

func _start_next_turn() -> void:
	if current_turn_index >= turn_order.size():
		# Fim da rodada, reinicia
		current_turn_index = 0
	
	current_combatant = turn_order[current_turn_index]
	
	# Pula se morto
	if not current_combatant.stats.is_alive():
		current_turn_index += 1
		_start_next_turn()
		return
	
	current_combatant.start_turn()
	
	if current_combatant.is_player:
		combat_state = GameConstants.CombatState.PLAYER_TURN
	else:
		combat_state = GameConstants.CombatState.ENEMY_TURN
		# IA age automaticamente
		_execute_ai_turn()
	
	turn_started.emit(current_combatant)

func end_turn() -> void:
	if not current_combatant:
		return
	
	turn_ended.emit(current_combatant)
	current_turn_index += 1
	
	# Verifica fim de combate
	if _check_combat_end():
		end_combat()
		return
	
	_start_next_turn()

func _execute_ai_turn() -> void:
	# Implementação básica de IA
	# TODO: Implementar behavior tree completo
	await get_tree().create_timer(0.5).timeout
	
	if current_combatant.equipped_weapon:
		# Encontra alvo mais próximo
		var target := _find_nearest_enemy(current_combatant)
		if target:
			execute_attack(current_combatant, target)
	
	end_turn()

func _find_nearest_enemy(attacker: Critter) -> Critter:
	# Retorna o primeiro inimigo vivo (simplificado para teste)
	for combatant in combatants:
		if combatant == attacker or not combatant.stats.is_alive():
			continue
		
		if combatant.faction == attacker.faction:
			continue
		
		return combatant
	
	return null

func execute_attack(attacker: Critter, defender: Critter, hit_location: GameConstants.HitLocation = GameConstants.HitLocation.UNCALLED, use_secondary: bool = false) -> Dictionary:
	var result := {
		"hit": false,
		"damage": 0,
		"critical": false,
		"location": hit_location,
		"killed": false
	}
	
	# Verifica se tem AP suficiente
	var weapon := attacker.equipped_weapon
	var ap_cost := 4  # Custo padrão
	
	if weapon:
		ap_cost = weapon.get_attack_ap_cost(use_secondary)
		if not weapon.can_attack():
			return result
	
	if not attacker.spend_ap(ap_cost):
		return result
	
	# Calcula chance de acerto
	var hit_chance := _calculate_hit_chance(attacker, defender, hit_location)
	var roll := randf() * 100.0
	
	if roll <= hit_chance:
		result.hit = true
		
		# Calcula dano
		var base_damage := _calculate_damage(attacker, weapon)
		
		# Verifica crítico
		var critical_chance := attacker.stats.critical_chance
		if weapon:
			critical_chance *= weapon.critical_multiplier
		
		if randf() * 100.0 <= critical_chance:
			result.critical = true
			base_damage = int(base_damage * 1.5)
		
		# Aplica dano
		var damage_type := GameConstants.DamageType.NORMAL
		if weapon:
			damage_type = weapon.damage_type
			weapon.consume_ammo()
		
		var damage_result := defender.take_damage(base_damage, damage_type, hit_location)
		result.damage = damage_result.damage
		result.killed = damage_result.killed
	
	attack_executed.emit(attacker, defender, result)
	return result

func _calculate_hit_chance(attacker: Critter, defender: Critter, hit_location: GameConstants.HitLocation) -> float:
	var base_chance := float(attacker.get_attack_skill())
	
	# Nota: Distância removida para simplificar (Critter agora é Node, não tem posição)
	# Em implementação real, usar combat_position ou sistema de grid
	
	# Modificador por localização
	match hit_location:
		GameConstants.HitLocation.HEAD:
			base_chance -= 40
		GameConstants.HitLocation.EYES:
			base_chance -= 60
		GameConstants.HitLocation.GROIN:
			base_chance -= 30
		GameConstants.HitLocation.LEFT_ARM, GameConstants.HitLocation.RIGHT_ARM:
			base_chance -= 30
		GameConstants.HitLocation.LEFT_LEG, GameConstants.HitLocation.RIGHT_LEG:
			base_chance -= 20
	
	# Armor Class do defensor
	base_chance -= defender.stats.armor_class
	
	return clamp(base_chance, 5.0, 95.0)

func _calculate_damage(attacker: Critter, weapon: Weapon) -> int:
	if weapon:
		return weapon.calculate_damage()
	else:
		# Dano desarmado
		var base := attacker.stats.melee_damage
		return max(1, base + randi_range(0, 3))

func _check_combat_end() -> bool:
	# Verifica se todos de uma facção morreram
	var factions := {}
	
	for combatant in combatants:
		if combatant.stats.is_alive():
			factions[combatant.faction] = true
	
	return factions.size() <= 1

func end_combat() -> void:
	combat_state = GameConstants.CombatState.ENDED
	current_combatant = null
	combat_ended.emit()
	
	# Limpa estado
	await get_tree().create_timer(1.0).timeout
	combatants.clear()
	turn_order.clear()
	combat_state = GameConstants.CombatState.IDLE

func get_current_combatant() -> Critter:
	return current_combatant

func is_player_turn() -> bool:
	return combat_state == GameConstants.CombatState.PLAYER_TURN

func can_act() -> bool:
	return combat_state in [GameConstants.CombatState.PLAYER_TURN, GameConstants.CombatState.ENEMY_TURN]
