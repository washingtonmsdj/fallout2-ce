extends Resource
class_name PerkEffect
## Representa um efeito de perk que pode ser aplicado a um personagem

enum EffectType {
	STAT_BONUS,        # Bônus permanente em um stat primário
	SKILL_BONUS,       # Bônus permanente em uma skill
	DAMAGE_BONUS,      # Bônus de dano em combate
	SPECIAL_ABILITY    # Habilidade especial (requer lógica customizada)
}

@export var effect_type: EffectType
@export var target: String  # Nome do stat/skill ou ID da habilidade
@export var value: float    # Magnitude do efeito
@export var condition: String = ""  # Condição opcional para ativação

## Aplica o efeito a um personagem
func apply_effect(critter: Critter) -> void:
	if not critter:
		push_error("PerkEffect.apply_effect: critter is null")
		return
	
	match effect_type:
		EffectType.STAT_BONUS:
			_apply_stat_bonus(critter)
		EffectType.SKILL_BONUS:
			_apply_skill_bonus(critter)
		EffectType.DAMAGE_BONUS:
			_apply_damage_bonus(critter)
		EffectType.SPECIAL_ABILITY:
			_apply_special_ability(critter)

## Remove o efeito de um personagem
func remove_effect(critter: Critter) -> void:
	if not critter:
		push_error("PerkEffect.remove_effect: critter is null")
		return
	
	match effect_type:
		EffectType.STAT_BONUS:
			_remove_stat_bonus(critter)
		EffectType.SKILL_BONUS:
			_remove_skill_bonus(critter)
		EffectType.DAMAGE_BONUS:
			_remove_damage_bonus(critter)
		EffectType.SPECIAL_ABILITY:
			_remove_special_ability(critter)

## Verifica se o efeito pode ser aplicado baseado na condição
func can_apply(critter: Critter) -> bool:
	if condition.is_empty():
		return true
	
	# Implementar lógica de condição conforme necessário
	# Por enquanto, sempre retorna true se não há condição
	return true

## Aplica bônus de stat primário
func _apply_stat_bonus(critter: Critter) -> void:
	var stat: GameConstants.PrimaryStat = _parse_stat(target)
	if stat >= 0:
		critter.stats.modify_stat(stat, int(value))

## Remove bônus de stat primário
func _remove_stat_bonus(critter: Critter) -> void:
	var stat: GameConstants.PrimaryStat = _parse_stat(target)
	if stat >= 0:
		critter.stats.modify_stat(stat, -int(value))

## Aplica bônus de skill
func _apply_skill_bonus(critter: Critter) -> void:
	if not critter.skills:
		return
	
	var skill: SkillData.Skill = _parse_skill(target)
	if skill >= 0:
		critter.skills.modify_skill(skill, int(value))

## Remove bônus de skill
func _remove_skill_bonus(critter: Critter) -> void:
	if not critter.skills:
		return
	
	var skill: SkillData.Skill = _parse_skill(target)
	if skill >= 0:
		critter.skills.modify_skill(skill, -int(value))

## Aplica bônus de dano
func _apply_damage_bonus(critter: Critter) -> void:
	if not critter.has_meta("perk_damage_bonus"):
		critter.set_meta("perk_damage_bonus", 0)
	
	var current: int = critter.get_meta("perk_damage_bonus")
	critter.set_meta("perk_damage_bonus", current + int(value))

## Remove bônus de dano
func _remove_damage_bonus(critter: Critter) -> void:
	if critter.has_meta("perk_damage_bonus"):
		var current: int = critter.get_meta("perk_damage_bonus")
		critter.set_meta("perk_damage_bonus", current - int(value))

## Aplica habilidade especial
func _apply_special_ability(critter: Critter) -> void:
	# Adicionar a habilidade especial à lista de habilidades do personagem
	if not critter.has_meta("special_abilities"):
		critter.set_meta("special_abilities", [])
	
	var abilities: Array = critter.get_meta("special_abilities")
	if target not in abilities:
		abilities.append(target)

## Remove habilidade especial
func _remove_special_ability(critter: Critter) -> void:
	if critter.has_meta("special_abilities"):
		var abilities: Array = critter.get_meta("special_abilities")
		if target in abilities:
			abilities.erase(target)

## Converte string para PrimaryStat enum
func _parse_stat(stat_name: String) -> int:
	match stat_name.to_upper():
		"STRENGTH":
			return GameConstants.PrimaryStat.STRENGTH
		"PERCEPTION":
			return GameConstants.PrimaryStat.PERCEPTION
		"ENDURANCE":
			return GameConstants.PrimaryStat.ENDURANCE
		"CHARISMA":
			return GameConstants.PrimaryStat.CHARISMA
		"INTELLIGENCE":
			return GameConstants.PrimaryStat.INTELLIGENCE
		"AGILITY":
			return GameConstants.PrimaryStat.AGILITY
		"LUCK":
			return GameConstants.PrimaryStat.LUCK
	
	push_error("PerkEffect._parse_stat: Unknown stat '%s'" % stat_name)
	return -1

## Converte string para Skill enum
func _parse_skill(skill_name: String) -> int:
	# Usar SkillData para converter
	return SkillData.skill_from_string(skill_name)
