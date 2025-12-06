extends Resource
class_name DialogOption
## Opção de diálogo que o jogador pode selecionar

@export var id: String = ""
@export var text: String = ""
@export var next_node_id: String = ""
@export var conditions: Array[DialogCondition] = []
@export var effects: Array[DialogEffect] = []
@export var is_skill_check: bool = false
@export var skill_check_skill: SkillData.Skill = SkillData.Skill.SPEECH
@export var skill_check_difficulty: int = 50
@export var success_node_id: String = ""
@export var failure_node_id: String = ""

## Verifica se a opção pode ser exibida para um personagem
func is_available(critter: Critter) -> bool:
	if not critter:
		return false
	
	# Todas as condições devem ser atendidas
	for condition in conditions:
		if condition and not condition.evaluate(critter):
			return false
	
	return true

## Executa os efeitos da opção
func apply_effects(critter: Critter) -> void:
	if not critter:
		return
	
	for effect in effects:
		if effect:
			effect.apply(critter)

## Obtém o próximo nó após selecionar esta opção
func get_next_node_id(skill_check_success: bool = true) -> String:
	if is_skill_check:
		return success_node_id if skill_check_success else failure_node_id
	return next_node_id

## Retorna o texto da opção com informações de teste se aplicável
func get_display_text() -> String:
	var display = text
	if is_skill_check:
		var skill_name = SkillData.new().get_skill_name(skill_check_skill)
		display += " [%s DC %d]" % [skill_name, skill_check_difficulty]
	return display
