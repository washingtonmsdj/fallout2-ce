extends Item
class_name Armor
## Armadura equipável

@export var armor_type: GameConstants.ArmorType = GameConstants.ArmorType.LIGHT
@export var armor_class_bonus: int = 0

# Damage Resistance (%) por tipo
@export var damage_resistance: Dictionary = {
	GameConstants.DamageType.NORMAL: 0,
	GameConstants.DamageType.LASER: 0,
	GameConstants.DamageType.FIRE: 0,
	GameConstants.DamageType.PLASMA: 0,
	GameConstants.DamageType.ELECTRICAL: 0,
	GameConstants.DamageType.EMP: 0,
	GameConstants.DamageType.EXPLOSION: 0,
	GameConstants.DamageType.POISON: 0
}

# Damage Threshold (redução fixa) por tipo
@export var damage_threshold: Dictionary = {
	GameConstants.DamageType.NORMAL: 0,
	GameConstants.DamageType.LASER: 0,
	GameConstants.DamageType.FIRE: 0,
	GameConstants.DamageType.PLASMA: 0,
	GameConstants.DamageType.ELECTRICAL: 0,
	GameConstants.DamageType.EMP: 0,
	GameConstants.DamageType.EXPLOSION: 0,
	GameConstants.DamageType.POISON: 0
}

# Penalidades
@export var agility_penalty: int = 0
@export var perception_penalty: int = 0

# Durabilidade
@export var max_durability: int = 100
var current_durability: int = 100

func _init() -> void:
	item_type = GameConstants.ItemType.ARMOR
	current_durability = max_durability

func get_resistance(dmg_type: GameConstants.DamageType) -> int:
	var base_resistance: int = damage_resistance.get(dmg_type, 0)
	# Reduz resistência baseado em durabilidade
	var durability_factor: float = float(current_durability) / float(max_durability)
	return int(base_resistance * durability_factor)

func get_threshold(dmg_type: GameConstants.DamageType) -> int:
	var base_threshold: int = damage_threshold.get(dmg_type, 0)
	var durability_factor: float = float(current_durability) / float(max_durability)
	return int(base_threshold * durability_factor)

func take_damage(amount: int) -> void:
	current_durability = max(0, current_durability - amount)

func repair(amount: int) -> int:
	var repaired: int = min(amount, max_durability - current_durability)
	current_durability += repaired
	return repaired

func is_broken() -> bool:
	return current_durability <= 0

func get_condition_percentage() -> float:
	return (float(current_durability) / float(max_durability)) * 100.0
