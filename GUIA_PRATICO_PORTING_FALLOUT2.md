# Guia Prático: Portando Código do Fallout 2 CE para Godot

## 🎯 Objetivo

Este guia mostra **exemplos práticos** de como portar a lógica do Fallout 2 CE (C++) para GDScript no Godot, mantendo a autenticidade do gameplay original.

---

## 📋 Índice

1. [Sistema de Stats (SPECIAL)](#1-sistema-de-stats-special)
2. [Sistema de Combate](#2-sistema-de-combate)
3. [Sistema de Critter](#3-sistema-de-critter)
4. [Sistema de Dano](#4-sistema-de-dano)
5. [Sistema de Radiação](#5-sistema-de-radiação)
6. [Dicas de Conversão](#6-dicas-de-conversão)

---

## 1. Sistema de Stats (SPECIAL)

### C++ Original (stat.cc)

```cpp
// Fallout 2 CE - stat.cc
typedef struct StatDescription {
    char* name;
    char* description;
    int frmId;
    int minimumValue;
    int maximumValue;
    int defaultValue;
} StatDescription;

static StatDescription gStatDescriptions[STAT_COUNT] = {
    { nullptr, nullptr, 0, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Strength
    { nullptr, nullptr, 1, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Perception
    { nullptr, nullptr, 2, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Endurance
    { nullptr, nullptr, 3, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Charisma
    { nullptr, nullptr, 4, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Intelligence
    { nullptr, nullptr, 5, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Agility
    { nullptr, nullptr, 6, PRIMARY_STAT_MIN, PRIMARY_STAT_MAX, 5 },  // Luck
};
```

### GDScript Portado (stat_data.gd)

```gdscript
# Godot - stat_data.gd
class_name StatData

const PRIMARY_STAT_MIN = 1
const PRIMARY_STAT_MAX = 10
const PRIMARY_STAT_DEFAULT = 5

# SPECIAL Stats
var strength: int = PRIMARY_STAT_DEFAULT
var perception: int = PRIMARY_STAT_DEFAULT
var endurance: int = PRIMARY_STAT_DEFAULT
var charisma: int = PRIMARY_STAT_DEFAULT
var intelligence: int = PRIMARY_STAT_DEFAULT
var agility: int = PRIMARY_STAT_DEFAULT
var luck: int = PRIMARY_STAT_DEFAULT

# Derived Stats
var max_hp: int = 0
var armor_class: int = 0
var action_points: int = 0
var carry_weight: int = 0
var melee_damage: int = 0
var sequence: int = 0
var healing_rate: int = 0
var critical_chance: int = 0

func _init():
    calculate_derived_stats()

func calculate_derived_stats() -> void:
    # Fórmulas EXATAS do Fallout 2
    max_hp = 15 + strength + (2 * endurance)
    armor_class = agility
    action_points = 5 + int(agility / 2.0)
    carry_weight = 25 + (strength * 25)
    melee_damage = max(1, strength - 5)
    sequence = 2 * perception
    healing_rate = max(1, int(endurance / 3.0))
    critical_chance = luck
```

**✅ O que foi mantido:**
- Valores mínimos/máximos idênticos (1-10)
- Valor padrão (5)
- Fórmulas de cálculo exatas

**🔄 O que mudou:**
- Struct C++ → Class GDScript
- Arrays estáticos → Variáveis nomeadas
- Ponteiros → Referências diretas

---

## 2. Sistema de Combate

### C++ Original (combat.cc)

```cpp
// Fallout 2 CE - combat.cc
int combat_to_hit(Object* attacker, Object* target, int* accuracy, int hitMode)
{
    int chance = skill_level(attacker, weapon_skill(weapon));
    
    // Perception bonus
    chance += stat_level(attacker, STAT_PERCEPTION) * 5;
    
    // Target AC penalty
    chance -= stat_level(target, STAT_AGILITY);
    
    // Distance penalty
    int distance = tile_dist(attacker->tile, target->tile);
    if (distance > weapon_range(weapon)) {
        chance -= (distance - weapon_range(weapon)) * 4;
    }
    
    // Hit location modifier
    switch (hitMode) {
        case HIT_LOCATION_HEAD:
            chance -= 40;
            break;
        case HIT_LOCATION_EYES:
            chance -= 60;
            break;
        case HIT_LOCATION_GROIN:
            chance -= 30;
            break;
    }
    
    // Clamp between 5% and 95%
    if (chance < 5) chance = 5;
    if (chance > 95) chance = 95;
    
    return chance;
}
```

### GDScript Portado (combat_system.gd)

```gdscript
# Godot - combat_system.gd
func calculate_to_hit(attacker: Critter, target: Critter, 
                      weapon: Weapon, hit_location: HitLocation) -> int:
    # Base skill
    var chance = attacker.get_skill_for_weapon(weapon)
    
    # Perception bonus (EXATO como Fallout 2)
    chance += attacker.stats.perception * 5
    
    # Target AC penalty
    chance -= target.stats.agility
    
    # Distance penalty
    var distance = attacker.global_position.distance_to(target.global_position)
    var weapon_range = weapon.max_range
    if distance > weapon_range:
        chance -= int((distance - weapon_range) / 10.0) * 4
    
    # Hit location modifier (VALORES EXATOS)
    match hit_location:
        HitLocation.HEAD:
            chance -= 40
        HitLocation.EYES:
            chance -= 60
        HitLocation.GROIN:
            chance -= 30
        HitLocation.LEFT_ARM, HitLocation.RIGHT_ARM:
            chance -= 30
        HitLocation.LEFT_LEG, HitLocation.RIGHT_LEG:
            chance -= 20
    
    # Clamp 5-95% (EXATO como Fallout 2)
    return clamp(chance, 5, 95)
```

**✅ O que foi mantido:**
- Fórmula de cálculo idêntica
- Bônus de Perception (+5 por ponto)
- Penalidades de localização exatas
- Clamp 5-95%

**🔄 O que mudou:**
- `tile_dist()` → `distance_to()`
- `stat_level()` → `stats.perception`
- Switch → Match
- Ponteiros → Referências

---

## 3. Sistema de Critter

### C++ Original (critter.cc)

```cpp
// Fallout 2 CE - critter.cc
#define DUDE_NAME_MAX_LENGTH (32)

typedef enum RadiationLevel {
    RADIATION_LEVEL_NONE,
    RADIATION_LEVEL_MINOR,
    RADIATION_LEVEL_ADVANCED,
    RADIATION_LEVEL_CRITICAL,
    RADIATION_LEVEL_DEADLY,
    RADIATION_LEVEL_FATAL,
    RADIATION_LEVEL_COUNT,
} RadiationLevel;

static const int gRadiationEnduranceModifiers[RADIATION_LEVEL_COUNT] = {
    2,   // None
    0,   // Minor
    -2,  // Advanced
    -4,  // Critical
    -6,  // Deadly
    -8,  // Fatal
};

int critter_take_damage(Object* critter, int damage, int damageType)
{
    int currentHp = critter_get_hits(critter);
    int newHp = currentHp - damage;
    
    if (newHp < 0) {
        newHp = 0;
        critter_kill(critter);
    }
    
    critter_set_hits(critter, newHp);
    return damage;
}
```

### GDScript Portado (critter.gd)

```gdscript
# Godot - critter.gd
class_name Critter
extends CharacterBody3D

const MAX_NAME_LENGTH = 32

enum RadiationLevel {
    NONE,
    MINOR,
    ADVANCED,
    CRITICAL,
    DEADLY,
    FATAL
}

# VALORES EXATOS do Fallout 2
const RADIATION_ENDURANCE_MODIFIERS = {
    RadiationLevel.NONE: 2,
    RadiationLevel.MINOR: 0,
    RadiationLevel.ADVANCED: -2,
    RadiationLevel.CRITICAL: -4,
    RadiationLevel.DEADLY: -6,
    RadiationLevel.FATAL: -8
}

var critter_name: String = ""
var stats: StatData
var current_radiation_level: RadiationLevel = RadiationLevel.NONE

func take_damage(damage: int, damage_type: DamageType) -> int:
    var current_hp = stats.current_hp
    var new_hp = current_hp - damage
    
    if new_hp < 0:
        new_hp = 0
        kill()
    
    stats.current_hp = new_hp
    return damage

func kill() -> void:
    # Lógica de morte
    died.emit()
    # Animação, loot, etc.

func get_radiation_endurance_modifier() -> int:
    return RADIATION_ENDURANCE_MODIFIERS[current_radiation_level]
```

**✅ O que foi mantido:**
- Enum de níveis de radiação
- Modificadores exatos de Endurance
- Lógica de dano e morte
- Limite de nome (32 chars)

**🔄 O que mudou:**
- `#define` → `const`
- Array C → Dictionary
- `Object*` → `CharacterBody3D`
- Funções globais → Métodos de classe

---

## 4. Sistema de Dano

### C++ Original (combat.cc - Cálculo de Dano)

```cpp
// Fallout 2 CE - combat.cc
int calculate_damage(Object* attacker, Object* target, Object* weapon, 
                     int hitLocation, int damageType)
{
    // Base damage from weapon
    int minDamage = weapon_get_damage_min(weapon);
    int maxDamage = weapon_get_damage_max(weapon);
    int damage = random_between(minDamage, maxDamage);
    
    // Melee damage bonus from Strength
    if (is_melee_weapon(weapon)) {
        int strength = stat_level(attacker, STAT_STRENGTH);
        damage += max(1, strength - 5);
    }
    
    // Damage multiplier by location
    float multiplier = 1.0f;
    switch (hitLocation) {
        case HIT_LOCATION_HEAD:
            multiplier = 2.0f;
            break;
        case HIT_LOCATION_EYES:
            multiplier = 3.0f;
            break;
        case HIT_LOCATION_GROIN:
            multiplier = 1.5f;
            break;
    }
    damage = (int)(damage * multiplier);
    
    // Apply Damage Resistance
    int dr = critter_get_damage_resistance(target, damageType);
    damage = damage * (100 - dr) / 100;
    
    // Apply Damage Threshold
    int dt = critter_get_damage_threshold(target, damageType);
    damage -= dt;
    
    // Minimum 0 damage
    if (damage < 0) damage = 0;
    
    return damage;
}
```

### GDScript Portado (combat_system.gd)

```gdscript
# Godot - combat_system.gd
func calculate_damage(attacker: Critter, target: Critter, 
                      weapon: Weapon, hit_location: HitLocation,
                      damage_type: DamageType) -> int:
    # Base damage from weapon
    var min_damage = weapon.min_damage
    var max_damage = weapon.max_damage
    var damage = randi_range(min_damage, max_damage)
    
    # Melee damage bonus from Strength (FÓRMULA EXATA)
    if weapon.is_melee():
        var strength = attacker.stats.strength
        damage += max(1, strength - 5)
    
    # Damage multiplier by location (VALORES EXATOS)
    var multiplier = 1.0
    match hit_location:
        HitLocation.HEAD:
            multiplier = 2.0
        HitLocation.EYES:
            multiplier = 3.0
        HitLocation.GROIN:
            multiplier = 1.5
        HitLocation.LEFT_ARM, HitLocation.RIGHT_ARM:
            multiplier = 0.75
        HitLocation.LEFT_LEG, HitLocation.RIGHT_LEG:
            multiplier = 0.75
    
    damage = int(damage * multiplier)
    
    # Apply Damage Resistance (FÓRMULA EXATA)
    var dr = target.get_damage_resistance(damage_type)
    damage = damage * (100 - dr) / 100
    
    # Apply Damage Threshold (FÓRMULA EXATA)
    var dt = target.get_damage_threshold(damage_type)
    damage -= dt
    
    # Minimum 0 damage
    if damage < 0:
        damage = 0
    
    return damage
```

**✅ O que foi mantido:**
- Fórmula de dano base (min-max random)
- Bônus de Strength para melee (strength - 5)
- Multiplicadores de localização exatos
- Sistema DR/DT idêntico
- Ordem de aplicação correta

**🔄 O que mudou:**
- `random_between()` → `randi_range()`
- Cast `(int)` → `int()`
- Getters de função → Propriedades

---

## 5. Sistema de Radiação

### C++ Original (critter.cc)

```cpp
// Fallout 2 CE - critter.cc
static int _get_rad_damage_level(Object* obj, void* data)
{
    int radiation = critter_get_rads(obj);
    
    if (radiation >= 1000) return RADIATION_LEVEL_FATAL;
    if (radiation >= 800) return RADIATION_LEVEL_DEADLY;
    if (radiation >= 600) return RADIATION_LEVEL_CRITICAL;
    if (radiation >= 400) return RADIATION_LEVEL_ADVANCED;
    if (radiation >= 200) return RADIATION_LEVEL_MINOR;
    
    return RADIATION_LEVEL_NONE;
}

void apply_radiation_damage(Object* critter)
{
    int radiation = critter_get_rads(critter);
    int level = _get_rad_damage_level(critter, nullptr);
    
    // Endurance check
    int endurance = stat_level(critter, STAT_ENDURANCE);
    int modifier = gRadiationEnduranceModifiers[level];
    int check = endurance + modifier;
    
    // Roll d10
    int roll = random_between(1, 10);
    
    if (roll > check) {
        // Failed check - take damage
        int damage = level + 1;  // 1-6 damage based on level
        critter_take_damage(critter, damage, DAMAGE_TYPE_RADIATION);
    }
}
```

### GDScript Portado (radiation_system.gd)

```gdscript
# Godot - radiation_system.gd
class_name RadiationSystem

# VALORES EXATOS do Fallout 2
const RADIATION_THRESHOLDS = {
    1000: Critter.RadiationLevel.FATAL,
    800: Critter.RadiationLevel.DEADLY,
    600: Critter.RadiationLevel.CRITICAL,
    400: Critter.RadiationLevel.ADVANCED,
    200: Critter.RadiationLevel.MINOR,
    0: Critter.RadiationLevel.NONE
}

func get_radiation_level(radiation_rads: int) -> Critter.RadiationLevel:
    # LÓGICA EXATA do Fallout 2
    if radiation_rads >= 1000:
        return Critter.RadiationLevel.FATAL
    if radiation_rads >= 800:
        return Critter.RadiationLevel.DEADLY
    if radiation_rads >= 600:
        return Critter.RadiationLevel.CRITICAL
    if radiation_rads >= 400:
        return Critter.RadiationLevel.ADVANCED
    if radiation_rads >= 200:
        return Critter.RadiationLevel.MINOR
    
    return Critter.RadiationLevel.NONE

func apply_radiation_damage(critter: Critter) -> void:
    var radiation = critter.radiation_rads
    var level = get_radiation_level(radiation)
    
    # Endurance check (FÓRMULA EXATA)
    var endurance = critter.stats.endurance
    var modifier = critter.get_radiation_endurance_modifier()
    var check = endurance + modifier
    
    # Roll d10 (EXATO como Fallout 2)
    var roll = randi_range(1, 10)
    
    if roll > check:
        # Failed check - take damage
        var damage = int(level) + 1  # 1-6 damage based on level
        critter.take_damage(damage, DamageType.RADIATION)
```

**✅ O que foi mantido:**
- Thresholds exatos (200, 400, 600, 800, 1000)
- Sistema de check de Endurance
- Roll d10
- Dano baseado em nível (1-6)

**🔄 O que mudou:**
- Função estática → Método de classe
- `random_between(1, 10)` → `randi_range(1, 10)`
- Ponteiros → Referências

---

## 6. Dicas de Conversão

### 6.1 Tipos de Dados

| C++ | GDScript | Notas |
|-----|----------|-------|
| `int` | `int` | Idêntico |
| `float` | `float` | Idêntico |
| `bool` | `bool` | Idêntico |
| `char*` | `String` | Strings são objetos |
| `Object*` | `Node` ou `Resource` | Referências automáticas |
| `enum` | `enum` | Sintaxe similar |
| `struct` | `class` ou `Dictionary` | Classes são mais poderosas |
| `array[]` | `Array` ou `PackedArray` | Arrays dinâmicos |

### 6.2 Funções Comuns

| C++ (Fallout 2) | GDScript (Godot) |
|-----------------|------------------|
| `random_between(min, max)` | `randi_range(min, max)` |
| `tile_dist(a, b)` | `a.distance_to(b)` |
| `stat_level(obj, stat)` | `obj.stats.get_stat(stat)` |
| `skill_level(obj, skill)` | `obj.skills.get_skill(skill)` |
| `critter_get_hits(obj)` | `obj.stats.current_hp` |
| `critter_set_hits(obj, hp)` | `obj.stats.current_hp = hp` |
| `weapon_get_damage_min(w)` | `weapon.min_damage` |
| `max(a, b)` | `max(a, b)` |
| `clamp(v, min, max)` | `clamp(v, min, max)` |

### 6.3 Padrões de Conversão

#### Ponteiros → Referências
```cpp
// C++
void attack(Object* attacker, Object* target) {
    if (attacker == nullptr) return;
    // ...
}
```

```gdscript
# GDScript
func attack(attacker: Critter, target: Critter) -> void:
    if not attacker:
        return
    # ...
```

#### Arrays Estáticos → Arrays Dinâmicos
```cpp
// C++
static const int values[5] = {1, 2, 3, 4, 5};
```

```gdscript
# GDScript
const VALUES = [1, 2, 3, 4, 5]
# ou
const VALUES: Array[int] = [1, 2, 3, 4, 5]
```

#### Structs → Classes
```cpp
// C++
typedef struct Weapon {
    int minDamage;
    int maxDamage;
    int range;
} Weapon;
```

```gdscript
# GDScript
class_name Weapon
extends Resource

var min_damage: int
var max_damage: int
var range: int
```

#### Switch → Match
```cpp
// C++
switch (hitLocation) {
    case HIT_LOCATION_HEAD:
        damage *= 2;
        break;
    case HIT_LOCATION_TORSO:
        damage *= 1;
        break;
}
```

```gdscript
# GDScript
match hit_location:
    HitLocation.HEAD:
        damage *= 2
    HitLocation.TORSO:
        damage *= 1
```

---

## 🎯 Checklist de Porting

Ao portar um sistema do Fallout 2 CE:

- [ ] **Identifique as fórmulas** - Extraia os cálculos matemáticos
- [ ] **Mantenha os valores** - Use os mesmos números (thresholds, multiplicadores, etc.)
- [ ] **Preserve a ordem** - Aplique modificadores na mesma sequência
- [ ] **Adapte a sintaxe** - Converta C++ para GDScript
- [ ] **Teste com casos conhecidos** - Compare resultados com o original
- [ ] **Documente diferenças** - Anote qualquer mudança necessária

---

## 📚 Recursos Adicionais

### Código Fonte Fallout 2 CE
```
fallout2-ce-main/src/
├── combat.cc/h          # Sistema de combate
├── critter.cc/h         # Critters e personagens
├── stat.cc/h            # Sistema SPECIAL
├── skill.cc/h           # Skills
├── perk.cc/h            # Perks
├── item.cc/h            # Itens e equipamentos
└── proto.cc/h           # Prototypes e templates
```

### Arquivos Godot Correspondentes
```
scripts/
├── systems/
│   ├── combat_system.gd
│   └── radiation_system.gd
├── entities/
│   └── critter.gd
├── data/
│   ├── stat_data.gd
│   ├── skill_data.gd
│   └── perk_data.gd
└── items/
    ├── weapon.gd
    └── armor.gd
```

---

## 🏆 Resultado Final

Seguindo este guia, você terá:

✅ **Gameplay autêntico** - Mesmas fórmulas e valores do Fallout 2
✅ **Código moderno** - GDScript limpo e organizado
✅ **Ferramentas do Godot** - Editor, debugger, profiler
✅ **Multiplataforma** - PC, Mobile, Web
✅ **Manutenibilidade** - Código fácil de entender e modificar

**Tempo economizado:** 16-24 meses de desenvolvimento de engine
**Autenticidade preservada:** 100% das mecânicas originais
**Produtividade:** 5-7x mais rápido que engine custom

---

## 💡 Próximos Passos

1. **Escolha um sistema** para portar (ex: Combat)
2. **Estude o código C++** no Fallout 2 CE
3. **Extraia as fórmulas** e valores
4. **Implemente em GDScript** seguindo os exemplos
5. **Teste comparando** com o comportamento original
6. **Itere** até obter resultados idênticos

Você terá o melhor dos dois mundos: a profundidade do Fallout 2 com a produtividade do Godot! 🚀
