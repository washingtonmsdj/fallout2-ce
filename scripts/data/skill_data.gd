extends Resource
class_name SkillData
## Sistema de skills inspirado no Fallout

enum Skill {
	# Combat Skills
	SMALL_GUNS,
	BIG_GUNS,
	ENERGY_WEAPONS,
	UNARMED,
	MELEE_WEAPONS,
	THROWING,
	
	# Stealth & Theft
	SNEAK,
	LOCKPICK,
	STEAL,
	TRAPS,
	
	# Social
	SPEECH,
	BARTER,
	
	# Survival
	FIRST_AID,
	DOCTOR,
	SCIENCE,
	REPAIR,
	OUTDOORSMAN,
	GAMBLING
}

const SKILL_COUNT := 18
const MAX_TAGGED_SKILLS := 4
const DEFAULT_TAGGED_SKILLS := 3

# Valores de skill (0-200)
var skill_values: Dictionary = {}

# Skills marcadas como "tagged" (progridem mais rápido)
var tagged_skills: Array[Skill] = []

# Pontos de skill não gastos
var unspent_skill_points: int = 0

func _init() -> void:
	_initialize_skills()

func _initialize_skills() -> void:
	for skill in Skill.values():
		skill_values[skill] = _get_base_skill_value(skill)

func _get_base_skill_value(skill: Skill) -> int:
	# Valor base varia por skill
	match skill:
		Skill.SMALL_GUNS, Skill.FIRST_AID:
			return 30
		Skill.UNARMED, Skill.MELEE_WEAPONS, Skill.THROWING:
			return 40
		_:
			return 0

func get_skill_value(skill: Skill) -> int:
	return skill_values.get(skill, 0)

func increase_skill(skill: Skill, points: int) -> bool:
	if unspent_skill_points < points:
		return false
	
	var current: int = skill_values[skill]
	var cost: int = _calculate_skill_cost(skill, points)
	
	if unspent_skill_points >= cost:
		skill_values[skill] = min(200, current + points)
		unspent_skill_points -= cost
		return true
	
	return false

func _calculate_skill_cost(skill: Skill, points: int) -> int:
	# Tagged skills custam metade
	var multiplier := 0.5 if skill in tagged_skills else 1.0
	return int(points * multiplier)

func tag_skill(skill: Skill) -> bool:
	if tagged_skills.size() >= MAX_TAGGED_SKILLS:
		return false
	
	if skill in tagged_skills:
		return false
	
	tagged_skills.append(skill)
	# Tagged skills ganham +20 imediatamente
	skill_values[skill] += 20
	return true

func is_tagged(skill: Skill) -> bool:
	return skill in tagged_skills

func add_skill_points(points: int) -> void:
	unspent_skill_points += points

func get_skill_name(skill: Skill) -> String:
	return Skill.keys()[skill].replace("_", " ").capitalize()

func get_skill_description(skill: Skill) -> String:
	match skill:
		Skill.SMALL_GUNS:
			return "Uso de pistolas, SMGs e rifles"
		Skill.BIG_GUNS:
			return "Uso de metralhadoras e lança-foguetes"
		Skill.ENERGY_WEAPONS:
			return "Uso de armas laser e plasma"
		Skill.UNARMED:
			return "Combate desarmado e artes marciais"
		Skill.MELEE_WEAPONS:
			return "Uso de facas, espadas e armas brancas"
		Skill.THROWING:
			return "Arremesso de granadas e facas"
		Skill.SNEAK:
			return "Movimentação furtiva e stealth"
		Skill.LOCKPICK:
			return "Abertura de fechaduras"
		Skill.STEAL:
			return "Roubo de itens de NPCs"
		Skill.TRAPS:
			return "Desarmar e criar armadilhas"
		Skill.SPEECH:
			return "Persuasão e diálogos"
		Skill.BARTER:
			return "Negociação e comércio"
		Skill.FIRST_AID:
			return "Cura básica de ferimentos"
		Skill.DOCTOR:
			return "Cura avançada e cirurgia"
		Skill.SCIENCE:
			return "Conhecimento científico e hacking"
		Skill.REPAIR:
			return "Conserto de equipamentos"
		Skill.OUTDOORSMAN:
			return "Sobrevivência no deserto"
		Skill.GAMBLING:
			return "Jogos de azar"
		_:
			return ""

func skill_from_string(skill_name: String) -> int:
	match skill_name.to_upper():
		"SMALL_GUNS":
			return Skill.SMALL_GUNS
		"BIG_GUNS":
			return Skill.BIG_GUNS
		"ENERGY_WEAPONS":
			return Skill.ENERGY_WEAPONS
		"UNARMED":
			return Skill.UNARMED
		"MELEE_WEAPONS":
			return Skill.MELEE_WEAPONS
		"THROWING":
			return Skill.THROWING
		"SNEAK":
			return Skill.SNEAK
		"LOCKPICK":
			return Skill.LOCKPICK
		"STEAL":
			return Skill.STEAL
		"TRAPS":
			return Skill.TRAPS
		"SPEECH":
			return Skill.SPEECH
		"BARTER":
			return Skill.BARTER
		"FIRST_AID":
			return Skill.FIRST_AID
		"DOCTOR":
			return Skill.DOCTOR
		"SCIENCE":
			return Skill.SCIENCE
		"REPAIR":
			return Skill.REPAIR
		"OUTDOORSMAN":
			return Skill.OUTDOORSMAN
		"GAMBLING":
			return Skill.GAMBLING
		_:
			return -1

func modify_skill(skill: Skill, amount: int) -> void:
	var current: int = skill_values.get(skill, 0)
	skill_values[skill] = clamp(current + amount, 0, 200)
