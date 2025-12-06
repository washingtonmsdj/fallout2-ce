extends Node
class_name GameConstants
## Constantes globais do jogo inspiradas no sistema Fallout

# SPECIAL Stats (Primary)
enum PrimaryStat {
	STRENGTH,      # Força física, dano corpo-a-corpo
	PERCEPTION,    # Percepção, precisão
	ENDURANCE,     # Resistência, HP
	CHARISMA,      # Carisma, reações sociais
	INTELLIGENCE,  # Inteligência, pontos de skill
	AGILITY,       # Agilidade, Action Points
	LUCK          # Sorte, críticos
}

const PRIMARY_STAT_MIN := 1
const PRIMARY_STAT_MAX := 10
const PRIMARY_STAT_COUNT := 7

# Derived Stats
enum DerivedStat {
	MAX_HP,
	MAX_AP,
	ARMOR_CLASS,
	MELEE_DAMAGE,
	CARRY_WEIGHT,
	SEQUENCE,
	HEALING_RATE,
	CRITICAL_CHANCE
}

# Damage Types
enum DamageType {
	NORMAL,
	LASER,
	FIRE,
	PLASMA,
	ELECTRICAL,
	EMP,
	EXPLOSION,
	POISON
}

# Hit Locations
enum HitLocation {
	HEAD,
	LEFT_ARM,
	RIGHT_ARM,
	TORSO,
	RIGHT_LEG,
	LEFT_LEG,
	EYES,
	GROIN,
	UNCALLED  # Ataque normal sem alvo específico
}

# Combat States
enum CombatState {
	IDLE,
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
	ENDED
}

# Item Types
enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	AMMO,
	MISC,
	QUEST
}

# Weapon Types
enum WeaponType {
	MELEE,
	UNARMED,
	SMALL_GUN,
	BIG_GUN,
	ENERGY_WEAPON,
	THROWING
}

# Armor Types
enum ArmorType {
	LIGHT,
	MEDIUM,
	HEAVY,
	POWER_ARMOR
}

# AI States
enum AIState {
	IDLE,
	PATROL,
	ALERT,
	COMBAT,
	FLEE,
	SEARCH
}

# Game Constants
const MAX_LEVEL := 99
const BASE_AP := 5
const BASE_HP := 20
const XP_MULTIPLIER := 1000

# Combat Constants
const CRITICAL_HIT_BASE_CHANCE := 5.0  # 5%
const HEADSHOT_DAMAGE_MULTIPLIER := 2.0
const BACKSTAB_DAMAGE_MULTIPLIER := 1.5
const MAX_RANGE_PENALTY := 0.5  # 50% de penalidade em alcance máximo
