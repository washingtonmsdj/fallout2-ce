extends Resource
class_name CriticalHitTable
## Tabela de efeitos de críticos por localização

enum CriticalEffectLevel {
	NORMAL,      # 0-20: Efeito normal
	MINOR,       # 21-45: Efeito menor
	MODERATE,    # 46-70: Efeito moderado
	SEVERE,      # 71-90: Efeito severo
	MASSIVE,     # 91-100: Crítico massivo
	EXTREME      # 101+: Crítico extremo
}

class CriticalHitEffect extends Resource:
	@export var damage_multiplier: float = 2.0
	@export var flags: int = 0  # DAM_KNOCKED_OUT, DAM_CRIP_*, etc
	@export var message_id: String = ""
	@export var stat_check: String = ""  # Stat para massive critical check
	@export var stat_modifier: int = 0
	@export var massive_critical_flags: int = 0
	@export var massive_critical_message_id: String = ""
	@export var limb_cripple_chance: float = 0.0  # Chance de aleijar membro

# Tabela de críticos: {hit_location: {effect_level: CriticalHitEffect}}
var critical_table: Dictionary = {}

func _init() -> void:
	_initialize_default_table()

## Inicializa tabela padrão de críticos
func _initialize_default_table() -> void:
	# TORSO
	critical_table[GameConstants.HitLocation.TORSO] = {
		CriticalEffectLevel.NORMAL: _create_effect(2.0, 0, "critical_torso_normal"),
		CriticalEffectLevel.MINOR: _create_effect(2.5, 0, "critical_torso_minor"),
		CriticalEffectLevel.MODERATE: _create_effect(3.0, 0, "critical_torso_moderate"),
		CriticalEffectLevel.SEVERE: _create_effect(4.0, 0, "critical_torso_severe", "endurance", -2),
		CriticalEffectLevel.MASSIVE: _create_effect(5.0, 0, "critical_torso_massive", "endurance", -3),
		CriticalEffectLevel.EXTREME: _create_effect(6.0, 0, "critical_torso_extreme", "endurance", -4)
	}
	
	# HEAD
	critical_table[GameConstants.HitLocation.HEAD] = {
		CriticalEffectLevel.NORMAL: _create_effect(2.0, 0, "critical_head_normal"),
		CriticalEffectLevel.MINOR: _create_effect(3.0, 0, "critical_head_minor"),
		CriticalEffectLevel.MODERATE: _create_effect(4.0, 0, "critical_head_moderate", "perception", -1),
		CriticalEffectLevel.SEVERE: _create_effect(5.0, 0, "critical_head_severe", "perception", -2),
		CriticalEffectLevel.MASSIVE: _create_effect(6.0, 0, "critical_head_massive", "perception", -3),
		CriticalEffectLevel.EXTREME: _create_effect(8.0, 0, "critical_head_extreme", "perception", -4)
	}
	
	# EYES
	critical_table[GameConstants.HitLocation.EYES] = {
		CriticalEffectLevel.NORMAL: _create_effect(3.0, 0, "critical_eyes_normal", "perception", -1),
		CriticalEffectLevel.MINOR: _create_effect(4.0, 0, "critical_eyes_minor", "perception", -2),
		CriticalEffectLevel.MODERATE: _create_effect(5.0, 0, "critical_eyes_moderate", "perception", -3),
		CriticalEffectLevel.SEVERE: _create_effect(6.0, 0, "critical_eyes_severe", "perception", -4),
		CriticalEffectLevel.MASSIVE: _create_effect(8.0, 0, "critical_eyes_massive", "perception", -5),
		CriticalEffectLevel.EXTREME: _create_effect(10.0, 0, "critical_eyes_extreme", "perception", -6)
	}
	
	# GROIN
	critical_table[GameConstants.HitLocation.GROIN] = {
		CriticalEffectLevel.NORMAL: _create_effect(2.0, 0, "critical_groin_normal"),
		CriticalEffectLevel.MINOR: _create_effect(2.5, 0, "critical_groin_minor"),
		CriticalEffectLevel.MODERATE: _create_effect(3.0, 0, "critical_groin_moderate"),
		CriticalEffectLevel.SEVERE: _create_effect(4.0, 0, "critical_groin_severe"),
		CriticalEffectLevel.MASSIVE: _create_effect(5.0, 0, "critical_groin_massive"),
		CriticalEffectLevel.EXTREME: _create_effect(6.0, 0, "critical_groin_extreme")
	}
	
	# LEFT_ARM / RIGHT_ARM
	var arm_effect = {
		CriticalEffectLevel.NORMAL: _create_effect(2.0, 0, "critical_arm_normal", "", 0, 0.1),
		CriticalEffectLevel.MINOR: _create_effect(2.5, 0, "critical_arm_minor", "", 0, 0.2),
		CriticalEffectLevel.MODERATE: _create_effect(3.0, 0, "critical_arm_moderate", "", 0, 0.3),
		CriticalEffectLevel.SEVERE: _create_effect(4.0, 0, "critical_arm_severe", "", 0, 0.5),
		CriticalEffectLevel.MASSIVE: _create_effect(5.0, 0, "critical_arm_massive", "", 0, 0.7),
		CriticalEffectLevel.EXTREME: _create_effect(6.0, 0, "critical_arm_extreme", "", 0, 1.0)
	}
	critical_table[GameConstants.HitLocation.LEFT_ARM] = arm_effect.duplicate(true)
	critical_table[GameConstants.HitLocation.RIGHT_ARM] = arm_effect.duplicate(true)
	
	# LEFT_LEG / RIGHT_LEG
	var leg_effect = {
		CriticalEffectLevel.NORMAL: _create_effect(2.0, 0, "critical_leg_normal", "", 0, 0.1),
		CriticalEffectLevel.MINOR: _create_effect(2.5, 0, "critical_leg_minor", "", 0, 0.2),
		CriticalEffectLevel.MODERATE: _create_effect(3.0, 0, "critical_leg_moderate", "", 0, 0.3),
		CriticalEffectLevel.SEVERE: _create_effect(4.0, 0, "critical_leg_severe", "", 0, 0.5),
		CriticalEffectLevel.MASSIVE: _create_effect(5.0, 0, "critical_leg_massive", "", 0, 0.7),
		CriticalEffectLevel.EXTREME: _create_effect(6.0, 0, "critical_leg_extreme", "", 0, 1.0)
	}
	critical_table[GameConstants.HitLocation.LEFT_LEG] = leg_effect.duplicate(true)
	critical_table[GameConstants.HitLocation.RIGHT_LEG] = leg_effect.duplicate(true)

## Cria um efeito de crítico
func _create_effect(multiplier: float, flags: int, message: String, stat: String = "", stat_mod: int = 0, cripple_chance: float = 0.0) -> CriticalHitEffect:
	var effect = CriticalHitEffect.new()
	effect.damage_multiplier = multiplier
	effect.flags = flags
	effect.message_id = message
	effect.stat_check = stat
	effect.stat_modifier = stat_mod
	effect.limb_cripple_chance = cripple_chance
	return effect

## Obtém efeito de crítico baseado em localização e nível
func get_critical_effect(hit_location: GameConstants.HitLocation, effect_level: CriticalEffectLevel) -> CriticalHitEffect:
	if not hit_location in critical_table:
		# Fallback para TORSO
		hit_location = GameConstants.HitLocation.TORSO
	
	if not hit_location in critical_table:
		return _create_effect(2.0, 0, "critical_default")
	
	var location_table = critical_table[hit_location]
	if not effect_level in location_table:
		# Fallback para nível normal
		effect_level = CriticalEffectLevel.NORMAL
	
	return location_table[effect_level]

## Calcula nível de efeito baseado em roll
func calculate_effect_level(roll: int, better_criticals: int = 0) -> CriticalEffectLevel:
	var adjusted_roll = roll + better_criticals
	
	if adjusted_roll <= 20:
		return CriticalEffectLevel.NORMAL
	elif adjusted_roll <= 45:
		return CriticalEffectLevel.MINOR
	elif adjusted_roll <= 70:
		return CriticalEffectLevel.MODERATE
	elif adjusted_roll <= 90:
		return CriticalEffectLevel.SEVERE
	elif adjusted_roll <= 100:
		return CriticalEffectLevel.MASSIVE
	else:
		return CriticalEffectLevel.EXTREME

## Aplica efeito de crítico a um critter
func apply_critical_effect(target: Critter, effect: CriticalHitEffect, hit_location: GameConstants.HitLocation) -> Dictionary:
	var result = {
		"damage_multiplier": effect.damage_multiplier,
		"flags": effect.flags,
		"message": effect.message_id,
		"crippled_limb": false,
		"massive_critical": false
	}
	
	# Verificar massive critical
	if effect.stat_check != "":
		if _check_massive_critical(target, effect):
			result.massive_critical = true
			result.damage_multiplier *= 1.5
			result.message = effect.massive_critical_message_id if effect.massive_critical_message_id != "" else effect.message_id
			result.flags |= effect.massive_critical_flags
	
	# Verificar aleijamento de membro
	if effect.limb_cripple_chance > 0.0:
		if randf() < effect.limb_cripple_chance:
			result.crippled_limb = true
			result.flags |= _get_cripple_flag_for_location(hit_location)
	
	# Aplicar penalidades de stat
	if effect.stat_check != "" and effect.stat_modifier != 0:
		_apply_stat_penalty(target, effect.stat_check, effect.stat_modifier)
	
	return result

## Verifica massive critical
func _check_massive_critical(target: Critter, effect: CriticalHitEffect) -> bool:
	if not target or not target.stats or effect.stat_check == "":
		return false
	
	var stat_value = _get_stat_value(target, effect.stat_check)
	var roll = randi_range(1, 20)  # D20 roll
	
	# Roll deve ser menor ou igual ao stat modificado
	return roll <= (stat_value + effect.stat_modifier)

## Obtém valor de stat
func _get_stat_value(target: Critter, stat_name: String) -> int:
	match stat_name.to_lower():
		"strength":
			return target.stats.strength
		"perception":
			return target.stats.perception
		"endurance":
			return target.stats.endurance
		"charisma":
			return target.stats.charisma
		"intelligence":
			return target.stats.intelligence
		"agility":
			return target.stats.agility
		"luck":
			return target.stats.luck
		_:
			return 5  # Default

## Aplica penalidade de stat
func _apply_stat_penalty(target: Critter, stat_name: String, penalty: int) -> void:
	if not target or not target.stats:
		return
	
	match stat_name.to_lower():
		"strength":
			target.stats.strength = max(1, target.stats.strength + penalty)
		"perception":
			target.stats.perception = max(1, target.stats.perception + penalty)
		"endurance":
			target.stats.endurance = max(1, target.stats.endurance + penalty)
		"charisma":
			target.stats.charisma = max(1, target.stats.charisma + penalty)
		"intelligence":
			target.stats.intelligence = max(1, target.stats.intelligence + penalty)
		"agility":
			target.stats.agility = max(1, target.stats.agility + penalty)
		"luck":
			target.stats.luck = max(1, target.stats.luck + penalty)
	
	target.stats.calculate_derived_stats()

## Obtém flag de aleijamento para localização
func _get_cripple_flag_for_location(location: GameConstants.HitLocation) -> int:
	match location:
		GameConstants.HitLocation.LEFT_ARM:
			return 1  # DAM_CRIP_LEFT_ARM
		GameConstants.HitLocation.RIGHT_ARM:
			return 2  # DAM_CRIP_RIGHT_ARM
		GameConstants.HitLocation.LEFT_LEG:
			return 4  # DAM_CRIP_LEFT_LEG
		GameConstants.HitLocation.RIGHT_LEG:
			return 8  # DAM_CRIP_RIGHT_LEG
		GameConstants.HitLocation.EYES:
			return 16  # DAM_CRIP_EYES
		_:
			return 0
