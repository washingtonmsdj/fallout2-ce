extends Resource
class_name DialogEffect
## Efeito aplicado quando uma opção de diálogo é selecionada

enum EffectType {
	KARMA_CHANGE,      # Modifica karma
	REPUTATION_CHANGE, # Modifica reputação com facção
	QUEST_UPDATE,      # Atualiza estado de quest
	ITEM_GIVE,         # Dá item ao jogador
	ITEM_REMOVE,       # Remove item do jogador
	SKILL_INCREASE,    # Aumenta skill
	MONEY_GIVE,        # Dá dinheiro
	MONEY_REMOVE,      # Remove dinheiro
	NONE               # Sem efeito
}

@export var effect_type: EffectType = EffectType.NONE
@export var karma_amount: int = 0
@export var faction: String = ""
@export var reputation_amount: int = 0
@export var quest_id: String = ""
@export var quest_state: String = ""
@export var item_id: String = ""
@export var item_quantity: int = 1
@export var skill: SkillData.Skill = SkillData.Skill.SPEECH
@export var skill_amount: int = 0
@export var money_amount: int = 0

## Aplica o efeito a um personagem
func apply(critter: Critter) -> void:
	if not critter:
		return
	
	match effect_type:
		EffectType.KARMA_CHANGE:
			critter.karma += karma_amount
		
		EffectType.REPUTATION_CHANGE:
			# Modifica reputação com facção
			# Nota: Sistema completo de reputação por facção será implementado na Phase 7
			# Por enquanto, aplicamos mudança de karma como proxy
			if faction != "":
				# TODO: Implementar sistema de reputação por facção quando disponível
				# Por enquanto, aplicamos como mudança de karma proporcional
				critter.karma += reputation_amount
			else:
				# Se não há facção especificada, aplica diretamente ao karma
				critter.karma += reputation_amount
		
		EffectType.QUEST_UPDATE:
			# Será implementado quando o sistema de quests estiver pronto
			pass
		
		EffectType.ITEM_GIVE:
			# Será implementado quando o sistema de inventário estiver pronto
			pass
		
		EffectType.ITEM_REMOVE:
			# Será implementado quando o sistema de inventário estiver pronto
			pass
		
		EffectType.SKILL_INCREASE:
			critter.skills.modify_skill(skill, skill_amount)
		
		EffectType.MONEY_GIVE:
			# Será implementado quando o sistema de economia estiver pronto
			pass
		
		EffectType.MONEY_REMOVE:
			# Será implementado quando o sistema de economia estiver pronto
			pass
		
		EffectType.NONE:
			pass
