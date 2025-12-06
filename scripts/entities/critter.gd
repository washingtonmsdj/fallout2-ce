extends Node
class_name Critter
## Entidade base para personagens (jogador, NPCs, inimigos)
## Nota: Para uso em cenas 3D, crie um nó CharacterBody3D e adicione este script como filho

signal health_changed(old_value: int, new_value: int)
signal died
signal ap_changed(old_value: int, new_value: int)
signal level_up(new_level: int)

@export var critter_name: String = "Unknown"
@export var is_player: bool = false
@export var faction: String = "neutral"

# Dados do personagem
var stats: StatData
var skills: SkillData
var inventory: Array[Item] = []
var equipped_weapon: Weapon = null
var equipped_armor: Armor = null

# Progressão
var level: int = 1
var experience: int = 0
var reputation: int = 0
var karma: int = 0

# Estado de combate
var is_in_combat: bool = false
var combat_position: int = 0

func _ready() -> void:
	if not stats:
		stats = StatData.new()
	if not skills:
		skills = SkillData.new()

func take_damage(amount: int, damage_type: GameConstants.DamageType = GameConstants.DamageType.NORMAL, hit_location: GameConstants.HitLocation = GameConstants.HitLocation.UNCALLED) -> Dictionary:
	var old_hp := stats.current_hp
	
	# Aplica modificadores por localização
	var location_multiplier := _get_location_damage_multiplier(hit_location)
	var modified_damage := int(amount * location_multiplier)
	
	# Aplica dano considerando armadura
	var final_damage := stats.take_damage(modified_damage, damage_type)
	
	health_changed.emit(old_hp, stats.current_hp)
	
	# Verifica morte
	if not stats.is_alive():
		die()
	
	return {
		"damage": final_damage,
		"location": hit_location,
		"killed": not stats.is_alive()
	}

func _get_location_damage_multiplier(location: GameConstants.HitLocation) -> float:
	match location:
		GameConstants.HitLocation.HEAD:
			return 2.0
		GameConstants.HitLocation.EYES:
			return 3.0
		GameConstants.HitLocation.GROIN:
			return 1.5
		GameConstants.HitLocation.TORSO:
			return 1.0
		GameConstants.HitLocation.LEFT_ARM, GameConstants.HitLocation.RIGHT_ARM:
			return 0.75
		GameConstants.HitLocation.LEFT_LEG, GameConstants.HitLocation.RIGHT_LEG:
			return 0.75
		_:
			return 1.0

func heal(amount: int) -> int:
	var old_hp := stats.current_hp
	var healed := stats.heal(amount)
	health_changed.emit(old_hp, stats.current_hp)
	return healed

func die() -> void:
	died.emit()
	# Implementar lógica de morte (animação, loot, etc)

func add_experience(amount: int) -> void:
	experience += amount
	_check_level_up()

func _check_level_up() -> void:
	var xp_needed := _calculate_xp_for_level(level + 1)
	if experience >= xp_needed:
		level += 1
		_on_level_up()
		level_up.emit(level)

func _calculate_xp_for_level(target_level: int) -> int:
	# Fórmula: level * 1000 (simplificada)
	return target_level * GameConstants.XP_MULTIPLIER

func _on_level_up() -> void:
	# Recalcula stats
	stats.calculate_derived_stats()
	
	# Adiciona pontos de skill baseado em Intelligence
	var skill_points := 5 + stats.intelligence
	skills.add_skill_points(skill_points)
	
	# Cura completa no level up
	stats.current_hp = stats.max_hp

func equip_weapon(weapon: Weapon) -> bool:
	if not weapon:
		return false
	
	equipped_weapon = weapon
	return true

func equip_armor(armor: Armor) -> bool:
	if not armor:
		return false
	
	# Remove resistências da armadura antiga
	if equipped_armor:
		_remove_armor_bonuses(equipped_armor)
	
	equipped_armor = armor
	_apply_armor_bonuses(armor)
	return true

func _apply_armor_bonuses(armor: Armor) -> void:
	for damage_type in armor.damage_resistance:
		stats.damage_resistance[damage_type] += armor.damage_resistance[damage_type]
		stats.damage_threshold[damage_type] += armor.damage_threshold[damage_type]
	
	stats.armor_class += armor.armor_class_bonus

func _remove_armor_bonuses(armor: Armor) -> void:
	for damage_type in armor.damage_resistance:
		stats.damage_resistance[damage_type] -= armor.damage_resistance[damage_type]
		stats.damage_threshold[damage_type] -= armor.damage_threshold[damage_type]
	
	stats.armor_class -= armor.armor_class_bonus

func start_turn() -> void:
	stats.restore_ap()
	ap_changed.emit(0, stats.current_ap)

func spend_ap(amount: int) -> bool:
	var old_ap := stats.current_ap
	if stats.spend_ap(amount):
		ap_changed.emit(old_ap, stats.current_ap)
		return true
	return false

func can_afford_action(ap_cost: int) -> bool:
	return stats.current_ap >= ap_cost

func add_item(item: Item) -> bool:
	# Verifica peso
	var total_weight := _calculate_total_weight()
	if total_weight + item.weight > stats.carry_weight:
		return false
	
	inventory.append(item)
	return true

func remove_item(item: Item) -> bool:
	var index := inventory.find(item)
	if index != -1:
		inventory.remove_at(index)
		return true
	return false

func _calculate_total_weight() -> float:
	var total := 0.0
	for item in inventory:
		total += item.weight
	return total

func get_attack_skill() -> int:
	if not equipped_weapon:
		return skills.get_skill_value(SkillData.Skill.UNARMED)
	
	match equipped_weapon.weapon_type:
		GameConstants.WeaponType.SMALL_GUN:
			return skills.get_skill_value(SkillData.Skill.SMALL_GUNS)
		GameConstants.WeaponType.BIG_GUN:
			return skills.get_skill_value(SkillData.Skill.BIG_GUNS)
		GameConstants.WeaponType.ENERGY_WEAPON:
			return skills.get_skill_value(SkillData.Skill.ENERGY_WEAPONS)
		GameConstants.WeaponType.MELEE:
			return skills.get_skill_value(SkillData.Skill.MELEE_WEAPONS)
		GameConstants.WeaponType.UNARMED:
			return skills.get_skill_value(SkillData.Skill.UNARMED)
		GameConstants.WeaponType.THROWING:
			return skills.get_skill_value(SkillData.Skill.THROWING)
		_:
			return 0
