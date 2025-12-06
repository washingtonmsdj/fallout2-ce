extends Node
class_name DialogSystem
## Sistema de diálogos do jogo

signal dialog_started(npc: Critter, tree: DialogTree)
signal dialog_ended
signal option_selected(option: DialogOption)
signal skill_check_performed(skill: SkillData.Skill, difficulty: int, success: bool)
signal stat_check_performed(stat: GameConstants.PrimaryStat, threshold: int, success: bool)
signal node_changed(node: DialogNode)

var current_dialog: DialogTree = null
var current_node: DialogNode = null
var current_npc: Critter = null
var player: Critter = null
var dialog_history: Array[DialogNode] = []

## Inicia um diálogo com um NPC
func start_dialog(npc: Critter, dialog_tree: DialogTree, player_critter: Critter) -> void:
	if not npc or not dialog_tree or not player_critter:
		return
	
	current_npc = npc
	current_dialog = dialog_tree
	player = player_critter
	dialog_history.clear()
	
	# Obtém o nó de saudação apropriado
	var greeting_node = dialog_tree.get_greeting(player)
	if greeting_node:
		_set_current_node(greeting_node)
		dialog_started.emit(npc, dialog_tree)
	else:
		push_error("No greeting node found for dialog tree: %s" % dialog_tree.id)

## Seleciona uma opção de diálogo
func select_option(option: DialogOption) -> void:
	if not option or not current_node or not current_dialog or not player:
		return
	
	# Aplica os efeitos da opção
	option.apply_effects(player)
	option_selected.emit(option)
	
	# Determina o próximo nó
	var next_node_id: String
	
	if option.is_skill_check:
		# Realiza o teste de skill
		var success = check_skill(option.skill_check_skill, option.skill_check_difficulty)
		next_node_id = option.get_next_node_id(success)
	else:
		next_node_id = option.next_node_id
	
	# Navega para o próximo nó
	if next_node_id:
		var next_node = current_dialog.get_node(next_node_id)
		if next_node:
			_set_current_node(next_node)
		else:
			push_error("Next node not found: %s" % next_node_id)
	else:
		# Fim do diálogo
		end_dialog()

## Realiza um teste de skill
func check_skill(skill: SkillData.Skill, difficulty: int) -> bool:
	if not player:
		return false
	
	var skill_value = player.skills.get_skill_value(skill)
	
	# Fórmula: (skill - difficulty + 50) / 100, clamped entre 0.05 e 0.95
	var success_chance = clamp((skill_value - difficulty + 50) / 100.0, 0.05, 0.95)
	var success = randf() < success_chance
	
	skill_check_performed.emit(skill, difficulty, success)
	return success

## Realiza um teste de stat
func check_stat(stat: GameConstants.PrimaryStat, threshold: int) -> bool:
	if not player:
		return false
	
	var stat_value = _get_stat_value(player, stat)
	var success = stat_value >= threshold
	
	stat_check_performed.emit(stat, threshold, success)
	return success

## Encerra o diálogo
func end_dialog() -> void:
	dialog_ended.emit()
	current_dialog = null
	current_node = null
	current_npc = null
	dialog_history.clear()

## Define o nó atual e adiciona ao histórico
func _set_current_node(node: DialogNode) -> void:
	if not node:
		return
	
	current_node = node
	dialog_history.append(node)
	
	# Aplica os efeitos do nó
	node.apply_effects(player)
	
	node_changed.emit(node)

## Obtém o valor de um stat primário
func _get_stat_value(critter: Critter, stat: GameConstants.PrimaryStat) -> int:
	if not critter or not critter.stats:
		return 0
	
	match stat:
		GameConstants.PrimaryStat.STRENGTH:
			return critter.stats.strength
		GameConstants.PrimaryStat.PERCEPTION:
			return critter.stats.perception
		GameConstants.PrimaryStat.ENDURANCE:
			return critter.stats.endurance
		GameConstants.PrimaryStat.CHARISMA:
			return critter.stats.charisma
		GameConstants.PrimaryStat.INTELLIGENCE:
			return critter.stats.intelligence
		GameConstants.PrimaryStat.AGILITY:
			return critter.stats.agility
		GameConstants.PrimaryStat.LUCK:
			return critter.stats.luck
		_:
			return 0

## Retorna o nó atual
func get_current_node() -> DialogNode:
	return current_node

## Retorna as opções disponíveis para o nó atual
func get_available_options() -> Array[DialogOption]:
	if not current_node or not player:
		return []
	
	return current_node.get_available_options(player)

## Retorna o histórico de diálogo
func get_dialog_history() -> Array[DialogNode]:
	return dialog_history.duplicate()

## Verifica se um diálogo está em andamento
func is_dialog_active() -> bool:
	return current_dialog != null and current_node != null
