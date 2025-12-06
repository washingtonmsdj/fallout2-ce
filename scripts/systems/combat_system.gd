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

# Critical hit system
var critical_hit_table: CriticalHitTable = null

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
		"killed": false,
		"critical_effect": {}
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
			# Usar critical hit table para calcular multiplicador
			var critical_result = _calculate_critical_hit(attacker, defender, hit_location)
			base_damage = int(base_damage * critical_result.damage_multiplier)
			result.critical_effect = critical_result
		
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

## Calcula efeito de crítico usando critical hit table
func _calculate_critical_hit(attacker: Critter, defender: Critter, hit_location: GameConstants.HitLocation) -> Dictionary:
	if not critical_hit_table:
		critical_hit_table = CriticalHitTable.new()
	
	# Roll para determinar nível de efeito
	var roll = randi_range(1, 100)
	var better_criticals = 0  # TODO: Adicionar perk Better Criticals
	
	var effect_level = critical_hit_table.calculate_effect_level(roll, better_criticals)
	var effect = critical_hit_table.get_critical_effect(hit_location, effect_level)
	
	# Aplicar efeito
	return critical_hit_table.apply_critical_effect(defender, effect, hit_location)

## Executa tiro com mira (aimed shot)
func execute_aimed_shot(attacker: Critter, defender: Critter, hit_location: GameConstants.HitLocation) -> Dictionary:
	var result = execute_attack(attacker, defender, hit_location)
	
	# Aimed shots têm penalidade de precisão mas bônus de dano
	var accuracy_penalty = _get_aimed_shot_penalty(hit_location)
	var damage_bonus = _get_aimed_shot_damage_bonus(hit_location)
	
	# Ajustar chance de acerto
	var base_hit_chance = _calculate_hit_chance(attacker, defender, hit_location)
	var adjusted_hit_chance = base_hit_chance - accuracy_penalty
	
	# Roll para acerto
	var roll = randf() * 100.0
	if roll <= adjusted_hit_chance:
		result.hit = true
		# Aplicar bônus de dano
		if result.damage > 0:
			result.damage = int(result.damage * (1.0 + damage_bonus))
	else:
		result.hit = false
		result.damage = 0
	
	return result

## Obtém penalidade de precisão para aimed shot
func _get_aimed_shot_penalty(location: GameConstants.HitLocation) -> float:
	match location:
		GameConstants.HitLocation.HEAD:
			return 40.0
		GameConstants.HitLocation.EYES:
			return 60.0
		GameConstants.HitLocation.GROIN:
			return 30.0
		GameConstants.HitLocation.LEFT_ARM, GameConstants.HitLocation.RIGHT_ARM:
			return 30.0
		GameConstants.HitLocation.LEFT_LEG, GameConstants.HitLocation.RIGHT_LEG:
			return 20.0
		_:
			return 0.0

## Obtém bônus de dano para aimed shot
func _get_aimed_shot_damage_bonus(location: GameConstants.HitLocation) -> float:
	match location:
		GameConstants.HitLocation.HEAD:
			return 0.5  # +50% dano
		GameConstants.HitLocation.EYES:
			return 0.75  # +75% dano
		GameConstants.HitLocation.GROIN:
			return 0.25  # +25% dano
		GameConstants.HitLocation.LEFT_ARM, GameConstants.HitLocation.RIGHT_ARM:
			return 0.15  # +15% dano
		GameConstants.HitLocation.LEFT_LEG, GameConstants.HitLocation.RIGHT_LEG:
			return 0.15  # +15% dano
		_:
			return 0.0

## Executa rajada (burst fire)
func execute_burst_fire(attacker: Critter, defender: Critter, shots: int = 3) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	if not attacker.equipped_weapon:
		return results
	
	var weapon = attacker.equipped_weapon
	var ap_cost = weapon.get_attack_ap_cost(false) * shots
	
	if not attacker.spend_ap(ap_cost):
		return results
	
	# Calcular precisão base
	var base_accuracy = _calculate_hit_chance(attacker, defender, GameConstants.HitLocation.TORSO)
	
	# Cada tiro tem precisão reduzida (cone de fogo)
	for i in range(shots):
		var shot_accuracy = base_accuracy - (i * 10.0)  # -10% por tiro adicional
		shot_accuracy = max(5.0, shot_accuracy)  # Mínimo 5%
		
		var roll = randf() * 100.0
		var result = {
			"hit": roll <= shot_accuracy,
			"damage": 0,
			"critical": false,
			"shot_number": i + 1
		}
		
		if result.hit:
			var base_damage = _calculate_damage(attacker, weapon)
			
			# Chance de crítico reduzida em rajadas
			var critical_chance = attacker.stats.critical_chance * 0.5
			if randf() * 100.0 <= critical_chance:
				result.critical = true
				base_damage = int(base_damage * 1.5)
			
			result.damage = base_damage
			defender.take_damage(result.damage, weapon.damage_type, GameConstants.HitLocation.TORSO)
		
		results.append(result)
		weapon.consume_ammo()
	
	return results

## Calcula knockback
func calculate_knockback(attacker: Critter, defender: Critter, damage: int) -> Vector2:
	if not attacker or not defender:
		return Vector2.ZERO
	
	# Knockback baseado em dano e força do atacante
	var knockback_force = float(damage) * 0.1
	var strength_multiplier = float(attacker.stats.strength) / 10.0
	
	knockback_force *= strength_multiplier
	
	# Direção do knockback (simplificado - em implementação real usar posições)
	var direction = Vector2(1.0, 0.0)  # TODO: Calcular direção real
	
	return direction * knockback_force

## Verifica se arma emperra
func check_weapon_jam(weapon: Weapon, condition: float) -> bool:
	if not weapon:
		return false
	
	# Chance de emperrar baseada na condição
	var jam_chance = (1.0 - condition) * 0.1  # 10% chance quando condição = 0
	
	# Armas automáticas têm maior chance
	if weapon.weapon_type == GameConstants.WeaponType.BIG_GUN or \
	   weapon.weapon_type == GameConstants.WeaponType.SMALL_GUN:
		jam_chance *= 1.5
	
	return randf() < jam_chance

## Repara arma emperrada
func repair_jammed_weapon(weapon: Weapon, repair_skill: int) -> bool:
	if not weapon:
		return false
	
	# Chance de reparo baseada em skill
	var repair_chance = float(repair_skill) / 100.0
	repair_chance = clamp(repair_chance, 0.1, 0.9)  # Entre 10% e 90%
	
	if randf() < repair_chance:
		weapon.is_jammed = false
		return true
	
	return false
