extends Resource
class_name TimedEffect
## Efeito temporário aplicado a um critter

enum EffectType {
	STAT_MODIFIER,      # Modifica stats (HP, AP, etc)
	SKILL_MODIFIER,     # Modifica skills
	DAMAGE_OVER_TIME,   # Dano contínuo
	HEALING_OVER_TIME,  # Cura contínua
	MOVEMENT_MODIFIER,  # Modifica velocidade de movimento
	VISIBILITY_MODIFIER # Modifica visibilidade
}

@export var id: String = ""
@export var name: String = ""
@export var effect_type: EffectType = EffectType.STAT_MODIFIER
@export var duration: float = 0.0  # Duração em horas de jogo
@export var remaining_duration: float = 0.0  # Duração restante
@export var is_addiction: bool = false
@export var addiction_severity: int = 0  # 0-100

# Modificadores de stats
@export var stat_modifiers: Dictionary = {}  # {stat_name: amount}

# Modificadores de skills
@export var skill_modifiers: Dictionary = {}  # {skill_name: amount}

# Efeitos de dano/cura
@export var damage_per_hour: float = 0.0
@export var healing_per_hour: float = 0.0

# Modificadores gerais
@export var movement_speed_multiplier: float = 1.0
@export var visibility_multiplier: float = 1.0

# Efeitos de membros aleijados
@export var crippled_limbs: Dictionary = {}  # {limb_name: severity}

func _init() -> void:
	remaining_duration = duration

## Aplica o efeito a um critter
func apply_to(critter: Critter) -> void:
	if not critter:
		return
	
	# Aplicar modificadores de stats
	for stat_name in stat_modifiers:
		var amount = stat_modifiers[stat_name]
		_apply_stat_modifier(critter, stat_name, amount)
	
	# Aplicar modificadores de skills
	for skill_name in skill_modifiers:
		var amount = skill_modifiers[skill_name]
		_apply_skill_modifier(critter, skill_name, amount)
	
	# Aplicar efeitos de membros aleijados
	for limb_name in crippled_limbs:
		var severity = crippled_limbs[limb_name]
		_apply_limb_effect(critter, limb_name, severity)

## Remove o efeito de um critter
func remove_from(critter: Critter) -> void:
	if not critter:
		return
	
	# Reverter modificadores de stats
	for stat_name in stat_modifiers:
		var amount = stat_modifiers[stat_name]
		_apply_stat_modifier(critter, stat_name, -amount)
	
	# Reverter modificadores de skills
	for skill_name in skill_modifiers:
		var amount = skill_modifiers[skill_name]
		_apply_skill_modifier(critter, skill_name, -amount)
	
	# Reverter efeitos de membros aleijados
	for limb_name in crippled_limbs:
		_remove_limb_effect(critter, limb_name)

## Aplica modificador de stat
func _apply_stat_modifier(critter: Critter, stat_name: String, amount: int) -> void:
	if not critter.stats:
		return
	
	match stat_name:
		"strength":
			critter.stats.strength = clamp(critter.stats.strength + amount, 1, 10)
		"perception":
			critter.stats.perception = clamp(critter.stats.perception + amount, 1, 10)
		"endurance":
			critter.stats.endurance = clamp(critter.stats.endurance + amount, 1, 10)
		"charisma":
			critter.stats.charisma = clamp(critter.stats.charisma + amount, 1, 10)
		"intelligence":
			critter.stats.intelligence = clamp(critter.stats.intelligence + amount, 1, 10)
		"agility":
			critter.stats.agility = clamp(critter.stats.agility + amount, 1, 10)
		"luck":
			critter.stats.luck = clamp(critter.stats.luck + amount, 1, 10)
		"max_hp":
			critter.stats.max_hp += amount
			critter.stats.max_hp = max(1, critter.stats.max_hp)
		"max_ap":
			critter.stats.max_ap += amount
			critter.stats.max_ap = max(1, critter.stats.max_ap)
		"armor_class":
			critter.stats.armor_class += amount
		"healing_rate":
			critter.stats.healing_rate += amount
			critter.stats.healing_rate = max(1, critter.stats.healing_rate)
		"critical_chance":
			critter.stats.critical_chance += float(amount)
	
	critter.stats.calculate_derived_stats()

## Aplica modificador de skill
func _apply_skill_modifier(critter: Critter, skill_name: String, amount: int) -> void:
	if not critter.skills:
		return
	
	# Converter nome de skill para enum
	var skill_enum = _get_skill_enum(skill_name)
	if skill_enum != -1:
		var current_value = critter.skills.get_skill_value(skill_enum)
		critter.skills.skill_values[skill_enum] = clamp(current_value + amount, 0, 200)

## Obtém enum de skill pelo nome
func _get_skill_enum(skill_name: String) -> int:
	var skill_map = {
		"small_guns": SkillData.Skill.SMALL_GUNS,
		"big_guns": SkillData.Skill.BIG_GUNS,
		"energy_weapons": SkillData.Skill.ENERGY_WEAPONS,
		"unarmed": SkillData.Skill.UNARMED,
		"melee_weapons": SkillData.Skill.MELEE_WEAPONS,
		"throwing": SkillData.Skill.THROWING,
		"first_aid": SkillData.Skill.FIRST_AID,
		"doctor": SkillData.Skill.DOCTOR,
		"speech": SkillData.Skill.SPEECH,
		"barter": SkillData.Skill.BARTER,
		"gambling": SkillData.Skill.GAMBLING,
		"outdoorsman": SkillData.Skill.OUTDOORSMAN,
		"lockpick": SkillData.Skill.LOCKPICK,
		"steal": SkillData.Skill.STEAL,
		"traps": SkillData.Skill.TRAPS,
		"science": SkillData.Skill.SCIENCE,
		"repair": SkillData.Skill.REPAIR,
		"sneak": SkillData.Skill.SNEAK
	}
	
	if skill_name.to_lower() in skill_map:
		return skill_map[skill_name.to_lower()]
	return -1

## Aplica efeito de membro aleijado
func _apply_limb_effect(critter: Critter, limb_name: String, severity: int) -> void:
	if not critter.stats:
		return
	
	# Aplicar penalidades baseadas no membro aleijado
	match limb_name.to_lower():
		"head":
			critter.stats.perception = max(1, critter.stats.perception - severity / 10)
		"left_arm", "right_arm":
			# Reduz habilidades que requerem braços
			if critter.skills:
				critter.skills.skill_values[SkillData.Skill.MELEE_WEAPONS] = max(0, 
					critter.skills.skill_values[SkillData.Skill.MELEE_WEAPONS] - severity)
				critter.skills.skill_values[SkillData.Skill.SMALL_GUNS] = max(0, 
					critter.skills.skill_values[SkillData.Skill.SMALL_GUNS] - severity)
		"left_leg", "right_leg":
			critter.stats.agility = max(1, critter.stats.agility - severity / 10)
			critter.stats.max_ap = max(1, critter.stats.max_ap - severity / 5)
		"eyes":
			critter.stats.perception = max(1, critter.stats.perception - severity / 5)
	
	critter.stats.calculate_derived_stats()

## Remove efeito de membro aleijado
func _remove_limb_effect(critter: Critter, limb_name: String) -> void:
	# Reverter penalidades (simplificado - em implementação real, precisaria armazenar valores originais)
	# Por enquanto, apenas recalcular stats
	if critter.stats:
		critter.stats.calculate_derived_stats()

## Verifica se o efeito expirou
func is_expired() -> bool:
	return remaining_duration <= 0.0

## Reduz duração do efeito
func tick(time_passed: float) -> void:
	remaining_duration = max(0.0, remaining_duration - time_passed)

## Obtém modificador total de um stat
func get_stat_modifier(stat_name: String) -> int:
	if stat_name in stat_modifiers:
		return stat_modifiers[stat_name]
	return 0

## Obtém modificador total de uma skill
func get_skill_modifier(skill_name: String) -> int:
	if skill_name in skill_modifiers:
		return skill_modifiers[skill_name]
	return 0
