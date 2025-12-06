extends Resource
class_name StatData
## Dados de stats de uma entidade (jogador, NPC, inimigo)

# SPECIAL - Primary Stats
@export var strength: int = 5
@export var perception: int = 5
@export var endurance: int = 5
@export var charisma: int = 5
@export var intelligence: int = 5
@export var agility: int = 5
@export var luck: int = 5

# Derived Stats (calculados)
var max_hp: int = 0
var current_hp: int = 0
var max_ap: int = 0
var current_ap: int = 0
var armor_class: int = 0
var melee_damage: int = 0
var carry_weight: int = 0
var sequence: int = 0
var healing_rate: int = 0
var critical_chance: float = 0.0

# Damage Resistances (%)
var damage_resistance: Dictionary = {
	GameConstants.DamageType.NORMAL: 0,
	GameConstants.DamageType.LASER: 0,
	GameConstants.DamageType.FIRE: 0,
	GameConstants.DamageType.PLASMA: 0,
	GameConstants.DamageType.ELECTRICAL: 0,
	GameConstants.DamageType.EMP: 0,
	GameConstants.DamageType.EXPLOSION: 0,
	GameConstants.DamageType.POISON: 0
}

# Damage Thresholds (redução fixa)
var damage_threshold: Dictionary = {
	GameConstants.DamageType.NORMAL: 0,
	GameConstants.DamageType.LASER: 0,
	GameConstants.DamageType.FIRE: 0,
	GameConstants.DamageType.PLASMA: 0,
	GameConstants.DamageType.ELECTRICAL: 0,
	GameConstants.DamageType.EMP: 0,
	GameConstants.DamageType.EXPLOSION: 0,
	GameConstants.DamageType.POISON: 0
}

func _init() -> void:
	calculate_derived_stats()

func calculate_derived_stats() -> void:
	# HP = 15 + (Strength/2) + (2 * Endurance)
	max_hp = 15 + int(strength / 2.0) + (2 * endurance)
	current_hp = max_hp
	
	# AP = 5 + (Agility/2)
	max_ap = GameConstants.BASE_AP + int(agility / 2.0)
	current_ap = max_ap
	
	# Armor Class = Agility
	armor_class = agility
	
	# Melee Damage = Strength - 5 (mínimo 1)
	melee_damage = max(1, strength - 5)
	
	# Carry Weight = 25 + (Strength * 25)
	carry_weight = 25 + (strength * 25)
	
	# Sequence = 2 * Perception
	sequence = 2 * perception
	
	# Healing Rate = Endurance / 3 (mínimo 1)
	healing_rate = max(1, int(endurance / 3.0))
	
	# Critical Chance = Luck (%)
	critical_chance = float(luck)

func modify_stat(stat: GameConstants.PrimaryStat, amount: int) -> void:
	match stat:
		GameConstants.PrimaryStat.STRENGTH:
			strength = clamp(strength + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.PERCEPTION:
			perception = clamp(perception + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.ENDURANCE:
			endurance = clamp(endurance + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.CHARISMA:
			charisma = clamp(charisma + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.INTELLIGENCE:
			intelligence = clamp(intelligence + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.AGILITY:
			agility = clamp(agility + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
		GameConstants.PrimaryStat.LUCK:
			luck = clamp(luck + amount, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
	
	calculate_derived_stats()

func take_damage(amount: int, damage_type: GameConstants.DamageType = GameConstants.DamageType.NORMAL) -> int:
	# Aplica Damage Threshold
	var dt: int = damage_threshold[damage_type]
	var reduced_damage: int = max(0, amount - dt)
	
	# Aplica Damage Resistance (%)
	var dr: int = damage_resistance[damage_type]
	var resistance_multiplier: float = 1.0 - (dr / 100.0)
	var final_damage: int = int(reduced_damage * resistance_multiplier)
	
	current_hp = max(0, current_hp - final_damage)
	return final_damage

func heal(amount: int) -> int:
	var healed: int = min(amount, max_hp - current_hp)
	current_hp += healed
	return healed

func is_alive() -> bool:
	return current_hp > 0

func restore_ap() -> void:
	current_ap = max_ap

func spend_ap(amount: int) -> bool:
	if current_ap >= amount:
		current_ap -= amount
		return true
	return false
