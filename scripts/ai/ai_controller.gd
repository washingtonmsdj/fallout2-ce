extends Node
class_name AIController
## Controlador de IA para personagens não-jogáveis

enum AIPersonality {
	AGGRESSIVE,
	DEFENSIVE,
	COWARD,
	BERSERK
}

enum AIState {
	IDLE,
	PATROL,
	ALERT,
	COMBAT,
	FLEE
}

@export var personality: AIPersonality = AIPersonality.AGGRESSIVE
@export var flee_threshold: float = 0.25  # HP percentage

var current_state: AIState = AIState.IDLE
var target: Critter = null
var behavior_tree: BehaviorTree = null
var controlled_critter: Critter = null

signal state_changed(new_state: AIState)
signal target_acquired(target: Critter)
signal target_lost

func _ready() -> void:
	_setup_behavior_tree()

## Configura a árvore de comportamento
func _setup_behavior_tree() -> void:
	behavior_tree = BehaviorTree.new()
	
	# Criar a estrutura da árvore
	var root = BTSelector.new()
	
	# Seletor principal: Fugir -> Combater -> Patrulhar
	var flee_sequence = BTSequence.new()
	var flee_check = BTAction.new()
	flee_check.set_action("should_flee")
	flee_sequence.add_child(flee_check)
	
	var combat_sequence = BTSequence.new()
	var has_target = BTAction.new()
	has_target.set_action("has_target")
	var attack_action = BTAction.new()
	attack_action.set_action("execute_attack")
	combat_sequence.add_child(has_target)
	combat_sequence.add_child(attack_action)
	
	var patrol_action = BTAction.new()
	patrol_action.set_action("patrol")
	
	root.add_child(flee_sequence)
	root.add_child(combat_sequence)
	root.add_child(patrol_action)
	
	behavior_tree.set_root(root)

## Define o personagem controlado
func set_controlled_critter(critter: Critter) -> void:
	controlled_critter = critter

## Avalia o turno da IA
func evaluate_turn() -> Dictionary:
	if controlled_critter == null:
		return {}
	
	var context = {
		"actor": self,
		"critter": controlled_critter,
		"target": target,
		"state": current_state
	}
	
	if behavior_tree:
		var result = behavior_tree.tick(context)
	
	return _get_best_action()

## Retorna a melhor ação para executar
func _get_best_action() -> Dictionary:
	match current_state:
		AIState.COMBAT:
			return _get_combat_action()
		AIState.FLEE:
			return _get_flee_action()
		AIState.PATROL:
			return _get_patrol_action()
		_:
			return {}

## Retorna uma ação de combate
func _get_combat_action() -> Dictionary:
	if target == null or not target.stats.is_alive():
		target = null
		set_state(AIState.PATROL)
		return {}
	
	var weapon = select_best_weapon()
	if weapon == null:
		return {"action": "attack_unarmed", "target": target}
	
	return {"action": "attack_ranged", "target": target, "weapon": weapon}

## Retorna uma ação de fuga
func _get_flee_action() -> Dictionary:
	var flee_position = find_cover()
	return {"action": "move", "position": flee_position}

## Retorna uma ação de patrulha
func _get_patrol_action() -> Dictionary:
	return {"action": "patrol"}

## Seleciona a melhor arma disponível
func select_best_weapon() -> Weapon:
	if controlled_critter == null:
		return null
	
	var best_weapon = controlled_critter.equipped_weapon
	var best_damage = 0
	
	if best_weapon:
		best_damage = (best_weapon.min_damage + best_weapon.max_damage) / 2
	
	# Procurar por armas melhores no inventário
	for item in controlled_critter.inventory:
		if item is Weapon:
			var avg_damage = (item.min_damage + item.max_damage) / 2
			if avg_damage > best_damage:
				best_weapon = item
				best_damage = avg_damage
	
	return best_weapon

## Encontra uma posição de cobertura
func find_cover() -> Vector2:
	if controlled_critter == null:
		return Vector2.ZERO
	
	# Implementação simplificada: mover para longe do alvo
	if target:
		var direction = (controlled_critter.global_position - target.global_position).normalized()
		return controlled_critter.global_position + direction * 100.0
	
	return controlled_critter.global_position

## Verifica se deve fugir
func should_flee() -> bool:
	if controlled_critter == null:
		return false
	
	var hp_percentage = float(controlled_critter.stats.current_hp) / float(controlled_critter.stats.max_hp)
	
	if hp_percentage < flee_threshold:
		match personality:
			AIPersonality.AGGRESSIVE:
				return false
			AIPersonality.DEFENSIVE:
				return true
			AIPersonality.COWARD:
				return true
			AIPersonality.BERSERK:
				return false
	
	return false

## Verifica se tem um alvo
func has_target() -> bool:
	return target != null and target.stats.is_alive()

## Executa um ataque
func execute_attack(context: Dictionary) -> bool:
	if target == null or not target.stats.is_alive():
		return false
	
	if controlled_critter == null:
		return false
	
	# Verificar AP disponível
	if controlled_critter.stats.current_ap < 5:
		return false
	
	# Executar ataque
	controlled_critter.stats.spend_ap(5)
	return true

## Patrulha
func patrol(context: Dictionary) -> bool:
	# Implementação simplificada
	return true

## Define o alvo
func set_target(new_target: Critter) -> void:
	if new_target != target:
		target = new_target
		if target:
			set_state(AIState.COMBAT)
			target_acquired.emit(target)
		else:
			set_state(AIState.PATROL)
			target_lost.emit()

## Muda o estado da IA
func set_state(new_state: AIState) -> void:
	if new_state != current_state:
		current_state = new_state
		state_changed.emit(new_state)

## Usa um item de cura
func use_healing_item() -> bool:
	if controlled_critter == null:
		return false
	
	# Procurar por itens de cura no inventário
	for item in controlled_critter.inventory:
		if item is Item and item.item_name.contains("Stimpak"):
			# Usar o item
			controlled_critter.heal(25)
			controlled_critter.inventory.erase(item)
			return true
	
	return false

## Retorna informações sobre o estado da IA
func get_ai_info() -> Dictionary:
	return {
		"personality": AIPersonality.keys()[personality],
		"state": AIState.keys()[current_state],
		"has_target": target != null,
		"target_name": target.critter_name if target else "None",
		"flee_threshold": flee_threshold
	}
