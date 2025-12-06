extends Item
class_name Weapon
## Arma equipável

@export var weapon_type: GameConstants.WeaponType = GameConstants.WeaponType.MELEE
@export var damage_type: GameConstants.DamageType = GameConstants.DamageType.NORMAL
@export var min_damage: int = 1
@export var max_damage: int = 5
@export var ap_cost_primary: int = 4
@export var ap_cost_secondary: int = 5
@export var range: int = 1
@export var accuracy_modifier: int = 0
@export var critical_multiplier: float = 1.0

# Munição (se aplicável)
@export var uses_ammo: bool = false
@export var ammo_type: String = ""
@export var magazine_size: int = 0
@export var current_ammo: int = 0
@export var ap_cost_reload: int = 2

# Modos de ataque
@export var has_secondary_mode: bool = false
@export var secondary_mode_name: String = "Burst"

func _init() -> void:
	item_type = GameConstants.ItemType.WEAPON
	if uses_ammo:
		current_ammo = magazine_size

func calculate_damage() -> int:
	return randi_range(min_damage, max_damage)

func can_attack() -> bool:
	if uses_ammo:
		return current_ammo > 0
	return true

func consume_ammo(amount: int = 1) -> bool:
	if not uses_ammo:
		return true
	
	if current_ammo >= amount:
		current_ammo -= amount
		return true
	return false

func reload(ammo_count: int) -> int:
	if not uses_ammo:
		return 0
	
	var space: int = magazine_size - current_ammo
	var loaded: int = min(ammo_count, space)
	current_ammo += loaded
	return loaded

func needs_reload() -> bool:
	return uses_ammo and current_ammo == 0

func get_attack_ap_cost(use_secondary: bool = false) -> int:
	return ap_cost_secondary if use_secondary else ap_cost_primary

func get_effective_range() -> int:
	return range

func apply_accuracy_modifier(base_chance: float) -> float:
	return base_chance + accuracy_modifier
