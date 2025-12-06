extends Resource
class_name DialogCondition
## Condição para exibição de opções de diálogo

enum ConditionType {
	SKILL_CHECK,      # Requer sucesso em teste de skill
	STAT_CHECK,       # Requer valor mínimo de stat
	REPUTATION,       # Requer reputação mínima com facção
	KARMA,            # Requer nível de karma
	QUEST_STATE,      # Requer estado específico de quest
	ITEM_OWNED,       # Requer possuir item
	PERK_OWNED,       # Requer ter perk
	ALWAYS_TRUE       # Sempre verdadeiro (padrão)
}

@export var condition_type: ConditionType = ConditionType.ALWAYS_TRUE
@export var skill: SkillData.Skill = SkillData.Skill.SPEECH
@export var skill_difficulty: int = 50
@export var stat: GameConstants.PrimaryStat = GameConstants.PrimaryStat.CHARISMA
@export var stat_threshold: int = 5
@export var faction: String = ""
@export var reputation_threshold: int = 0
@export var karma_threshold: int = 0
@export var quest_id: String = ""
@export var quest_state: String = ""
@export var item_id: String = ""
@export var perk_id: PerkData.Perk = PerkData.Perk.AWARENESS

## Avalia se a condição é atendida para um personagem
func evaluate(critter: Critter) -> bool:
	if not critter:
		return false
	
	match condition_type:
		ConditionType.ALWAYS_TRUE:
			return true
		
		ConditionType.SKILL_CHECK:
			var skill_value = critter.skills.get_skill_value(skill)
			return skill_value >= skill_difficulty
		
		ConditionType.STAT_CHECK:
			var stat_value = _get_stat_value(critter, stat)
			return stat_value >= stat_threshold
		
		ConditionType.REPUTATION:
			# Será implementado quando o sistema de reputação estiver pronto
			return true
		
		ConditionType.KARMA:
			return critter.karma >= karma_threshold
		
		ConditionType.QUEST_STATE:
			# Será implementado quando o sistema de quests estiver pronto
			return true
		
		ConditionType.ITEM_OWNED:
			return _has_item(critter, item_id)
		
		ConditionType.PERK_OWNED:
			# Será implementado quando o sistema de perks estiver pronto
			return true
		
		_:
			return false

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

## Verifica se o personagem possui um item
func _has_item(critter: Critter, item_id: String) -> bool:
	if not critter or not critter.inventory:
		return false
	
	for item in critter.inventory:
		if item and item.item_id == item_id:
			return true
	
	return false
