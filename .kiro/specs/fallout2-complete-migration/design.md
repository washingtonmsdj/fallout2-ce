# Design Document

## Overview

Este documento descreve a arquitetura e design técnico para a migração completa do Fallout 2 Community Edition para Godot Engine 4.5. O sistema será construído de forma modular, permitindo que cada componente funcione independentemente enquanto se integra ao todo.

A arquitetura segue os padrões do Godot: Nodes para entidades, Resources para dados, Signals para comunicação, e Autoloads para managers globais.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GAME MANAGER                              │
│  (Estado global, ciclo de vida, transições de cena)             │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  COMBAT       │     │  WORLD        │     │  UI           │
│  SYSTEM       │     │  SYSTEM       │     │  SYSTEM       │
├───────────────┤     ├───────────────┤     ├───────────────┤
│ - Turn Order  │     │ - Map Manager │     │ - Pipboy      │
│ - Attack Calc │     │ - Worldmap    │     │ - HUD         │
│ - AI System   │     │ - Pathfinding │     │ - Dialogs     │
│ - Effects     │     │ - Triggers    │     │ - Inventory   │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  (Resources: Stats, Skills, Perks, Items, Quests, Dialogs)      │
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Perk System

```gdscript
# scripts/data/perk_data.gd
class_name PerkData extends Resource

enum Perk { AWARENESS, BONUS_HTH_ATTACKS, ... } # 119 perks

@export var perk_id: Perk
@export var name: String
@export var description: String
@export var max_ranks: int = 1
@export var level_requirement: int
@export var stat_requirements: Dictionary  # {stat: min_value}
@export var skill_requirements: Dictionary # {skill: min_value}
@export var effects: Array[PerkEffect]

func can_acquire(critter: Critter) -> bool
func apply_effects(critter: Critter) -> void
func remove_effects(critter: Critter) -> void
```

```gdscript
# scripts/systems/perk_system.gd
class_name PerkSystem extends Node

signal perk_acquired(perk: PerkData)
signal perk_removed(perk: PerkData)

var all_perks: Dictionary  # {Perk: PerkData}
var acquired_perks: Dictionary  # {Perk: rank}

func get_available_perks(critter: Critter) -> Array[PerkData]
func acquire_perk(perk: PerkData) -> bool
func has_perk(perk: Perk) -> bool
func get_perk_rank(perk: Perk) -> int
```

### 2. AI Combat System

```gdscript
# scripts/ai/ai_controller.gd
class_name AIController extends Node

enum AIPersonality { AGGRESSIVE, DEFENSIVE, COWARD, BERSERK }
enum AIState { IDLE, PATROL, ALERT, COMBAT, FLEE }

@export var personality: AIPersonality
@export var flee_threshold: float = 0.25  # HP percentage

var current_state: AIState
var target: Critter
var behavior_tree: BehaviorTree

func evaluate_turn() -> AIAction
func select_best_weapon() -> Weapon
func find_cover() -> Vector2
func should_flee() -> bool
func use_healing_item() -> bool
```

```gdscript
# scripts/ai/behavior_tree.gd
class_name BehaviorTree extends Resource

var root: BTNode

func tick(context: Dictionary) -> BTStatus
```

### 3. Map System

```gdscript
# scripts/systems/map_system.gd
class_name MapSystem extends Node

signal map_loaded(map_name: String)
signal tile_clicked(position: Vector2i)
signal object_interacted(object: MapObject)

var current_map: MapData
var tilemap: TileMap
var objects: Array[MapObject]
var triggers: Array[TriggerZone]

func load_map(map_name: String) -> void
func get_tile_at(position: Vector2i) -> TileData
func is_walkable(position: Vector2i) -> bool
func get_objects_at(position: Vector2i) -> Array[MapObject]
```

```gdscript
# scripts/world/map_object.gd
class_name MapObject extends Node2D

enum ObjectType { DOOR, CONTAINER, SCENERY, CRITTER }

@export var object_type: ObjectType
@export var is_locked: bool
@export var lock_difficulty: int
@export var script_id: String

func interact(player: Critter) -> void
func unlock(key: Item) -> bool
```

### 4. Worldmap System

```gdscript
# scripts/systems/worldmap_system.gd
class_name WorldmapSystem extends Node

signal travel_started(from: Location, to: Location)
signal travel_completed(location: Location)
signal encounter_triggered(encounter: RandomEncounter)
signal location_discovered(location: Location)

var player_position: Vector2
var discovered_locations: Array[Location]
var current_vehicle: Vehicle

func start_travel(destination: Location) -> void
func calculate_travel_time(from: Vector2, to: Vector2) -> float
func check_random_encounter() -> RandomEncounter
func discover_location(location: Location) -> void
```

### 5. Dialog System

```gdscript
# scripts/systems/dialog_system.gd
class_name DialogSystem extends Node

signal dialog_started(npc: Critter)
signal dialog_ended
signal option_selected(option: DialogOption)
signal skill_check_result(skill: SkillData.Skill, success: bool)

var current_dialog: DialogTree
var current_node: DialogNode
var dialog_history: Array[DialogNode]

func start_dialog(npc: Critter) -> void
func select_option(option: DialogOption) -> void
func check_skill(skill: SkillData.Skill, difficulty: int) -> bool
func check_stat(stat: GameConstants.PrimaryStat, threshold: int) -> bool
func end_dialog() -> void
```

```gdscript
# scripts/data/dialog_tree.gd
class_name DialogTree extends Resource

@export var npc_id: String
@export var root_node: DialogNode
@export var nodes: Dictionary  # {id: DialogNode}

func get_greeting(player: Critter) -> DialogNode
func get_node(id: String) -> DialogNode
```

### 6. Quest System

```gdscript
# scripts/systems/quest_system.gd
class_name QuestSystem extends Node

signal quest_added(quest: Quest)
signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_failed(quest: Quest)
signal objective_completed(quest: Quest, objective: QuestObjective)

var active_quests: Array[Quest]
var completed_quests: Array[Quest]
var failed_quests: Array[Quest]

func add_quest(quest: Quest) -> void
func update_objective(quest_id: String, objective_id: String, progress: int) -> void
func complete_quest(quest: Quest) -> void
func fail_quest(quest: Quest) -> void
func get_quest(quest_id: String) -> Quest
```

### 7. Pipboy UI

```gdscript
# scripts/ui/pipboy/pipboy_ui.gd
class_name PipboyUI extends Control

enum Tab { STATUS, INVENTORY, MAP, DATA }

var current_tab: Tab
var player: Critter

@onready var status_panel: StatusPanel
@onready var inventory_panel: InventoryPanel
@onready var map_panel: MapPanel
@onready var data_panel: DataPanel

func open() -> void
func close() -> void
func switch_tab(tab: Tab) -> void
func refresh_current_tab() -> void
```

### 8. Character Editor

```gdscript
# scripts/ui/character_editor/character_editor.gd
class_name CharacterEditor extends Control

signal character_created(critter: Critter)

const TOTAL_SPECIAL_POINTS := 40
const MIN_STAT := 1
const MAX_STAT := 10
const MAX_TRAITS := 2
const TAGGED_SKILLS := 3

var special_points_remaining: int
var selected_traits: Array[TraitData.Trait]
var tagged_skills: Array[SkillData.Skill]
var character_name: String

func allocate_stat(stat: GameConstants.PrimaryStat, delta: int) -> bool
func select_trait(trait: TraitData.Trait) -> bool
func tag_skill(skill: SkillData.Skill) -> bool
func set_name(name: String) -> bool
func finalize_character() -> Critter
```

### 9. Party System

```gdscript
# scripts/systems/party_system.gd
class_name PartySystem extends Node

signal companion_joined(companion: Critter)
signal companion_left(companion: Critter)
signal companion_died(companion: Critter)

const MAX_PARTY_SIZE := 5

var party_members: Array[Critter]
var player: Critter

func add_companion(companion: Critter) -> bool
func remove_companion(companion: Critter) -> void
func get_party_for_combat() -> Array[Critter]
func is_party_full() -> bool
func heal_party(amount: int) -> void
```

### 10. Effect Queue System

```gdscript
# scripts/systems/effect_queue.gd
class_name EffectQueue extends Node

signal effect_applied(effect: TimedEffect)
signal effect_expired(effect: TimedEffect)
signal addiction_gained(drug: String)

var active_effects: Array[TimedEffect]
var addictions: Dictionary  # {drug_name: severity}

func add_effect(effect: TimedEffect) -> void
func remove_effect(effect: TimedEffect) -> void
func tick_effects(time_passed: float) -> void
func apply_drug(drug: DrugItem) -> void
func check_addiction(drug: String) -> bool
func get_total_stat_modifier(stat: GameConstants.PrimaryStat) -> int
```

## Data Models

### PerkEffect
```gdscript
class_name PerkEffect extends Resource

enum EffectType { STAT_BONUS, SKILL_BONUS, DAMAGE_BONUS, SPECIAL_ABILITY }

@export var effect_type: EffectType
@export var target: String  # stat/skill name or ability id
@export var value: float
@export var condition: String  # optional condition for activation
```

### Location
```gdscript
class_name Location extends Resource

@export var id: String
@export var name: String
@export var position: Vector2
@export var map_scene: PackedScene
@export var danger_level: int  # 0-10
@export var is_city: bool
@export var faction: String
```

### RandomEncounter
```gdscript
class_name RandomEncounter extends Resource

@export var id: String
@export var enemies: Array[CritterTemplate]
@export var terrain_type: String
@export var min_player_level: int
@export var max_player_level: int
@export var probability: float
```

### Quest
```gdscript
class_name Quest extends Resource

enum QuestState { INACTIVE, ACTIVE, COMPLETED, FAILED }

@export var id: String
@export var title: String
@export var description: String
@export var objectives: Array[QuestObjective]
@export var rewards: QuestRewards
@export var state: QuestState
```

### DialogNode
```gdscript
class_name DialogNode extends Resource

@export var id: String
@export var speaker: String
@export var text: String
@export var options: Array[DialogOption]
@export var conditions: Array[DialogCondition]
@export var effects: Array[DialogEffect]
```

### TimedEffect
```gdscript
class_name TimedEffect extends Resource

@export var id: String
@export var name: String
@export var duration: float  # in game hours
@export var stat_modifiers: Dictionary
@export var skill_modifiers: Dictionary
@export var is_addiction: bool
```

### Vehicle
```gdscript
class_name Vehicle extends Resource

@export var id: String
@export var name: String
@export var speed_multiplier: float
@export var fuel_consumption: float
@export var trunk_capacity: float
@export var current_fuel: float
@export var max_fuel: float
@export var condition: float
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Perk Definition Completeness
*For any* perk ID in the Perk enum, the perk system SHALL have a corresponding PerkData with non-empty name, description, and at least one effect.
**Validates: Requirements 1.1**

### Property 2: Perk Availability Filtering
*For any* critter and perk, if the perk is returned as available, then the critter's level, stats, and skills SHALL meet all the perk's requirements.
**Validates: Requirements 1.2**

### Property 3: Perk Effect Application
*For any* perk with stat bonuses, acquiring the perk SHALL increase the critter's relevant stats by exactly the specified amount.
**Validates: Requirements 1.3, 1.5, 1.6**

### Property 4: Perk Rank Bounds
*For any* perk with max_ranks > 1, the acquired rank SHALL never exceed max_ranks and SHALL start at 0.
**Validates: Requirements 1.4**

### Property 5: AI Action Validity
*For any* AI-controlled critter in combat, evaluate_turn() SHALL return a valid AIAction that the critter can execute with current AP and resources.
**Validates: Requirements 2.1**

### Property 6: AI Flee Behavior
*For any* AI critter with HP below flee_threshold percentage, should_flee() SHALL return true if personality is not BERSERK.
**Validates: Requirements 2.2**

### Property 7: AI Weapon Selection
*For any* AI critter with multiple weapons, select_best_weapon() SHALL return the weapon with highest expected damage against current target.
**Validates: Requirements 2.3**

### Property 8: AI Ammo Management
*For any* AI critter with a ranged weapon at 0 ammo, the AI SHALL either reload or switch to a melee weapon.
**Validates: Requirements 2.6**

### Property 9: Map Data Integrity
*For any* loaded map, all tiles, objects, and critters referenced in MapData SHALL exist in the scene tree.
**Validates: Requirements 3.1**

### Property 10: Pathfinding Validity
*For any* walkable destination tile, pathfinding SHALL return a path where every tile in the path is walkable.
**Validates: Requirements 3.2**

### Property 11: Door State Transitions
*For any* door object, interacting SHALL cycle through states: closed→open or locked→(unlock required)→closed→open.
**Validates: Requirements 3.3**

### Property 12: Travel Time Calculation
*For any* two locations, travel time SHALL equal distance / (base_speed * outdoorsman_modifier * vehicle_modifier).
**Validates: Requirements 4.2, 4.6**

### Property 13: Encounter Probability Bounds
*For any* travel segment, random encounter probability SHALL be between 0 and danger_level / 10.
**Validates: Requirements 4.3**

### Property 14: Location Discovery Persistence
*For any* discovered location, it SHALL remain in discovered_locations across save/load cycles.
**Validates: Requirements 4.5**

### Property 15: Dialog Option Filtering
*For any* dialog node, only options whose conditions evaluate to true for the current player state SHALL be displayed.
**Validates: Requirements 5.2**

### Property 16: Skill Check Probability
*For any* skill check with difficulty D and skill value S, success probability SHALL be clamp((S - D + 50) / 100, 0.05, 0.95).
**Validates: Requirements 5.3**

### Property 17: Reputation Change Application
*For any* dialog effect that modifies reputation, the karma and faction values SHALL change by exactly the specified amounts.
**Validates: Requirements 5.6**

### Property 18: Quest State Transitions
*For any* quest, state transitions SHALL follow: INACTIVE→ACTIVE→(COMPLETED|FAILED), never backwards.
**Validates: Requirements 6.1, 6.2, 6.3, 6.6**

### Property 19: Quest Reward Distribution
*For any* completed quest, the player SHALL receive exactly the XP, items, and reputation specified in QuestRewards.
**Validates: Requirements 6.4**

### Property 20: SPECIAL Bounds Enforcement
*For any* stat allocation, the value SHALL be clamped between MIN_STAT (1) and MAX_STAT (10).
**Validates: Requirements 8.2**

### Property 21: Trait Limit Enforcement
*For any* character, selected_traits.size() SHALL never exceed MAX_TRAITS (2).
**Validates: Requirements 8.3**

### Property 22: Tagged Skill Bonus
*For any* tagged skill, the skill value SHALL include a +20 bonus and skill point cost SHALL be halved.
**Validates: Requirements 8.4**

### Property 23: Derived Stat Calculation
*For any* finalized character, derived stats SHALL be calculated from SPECIAL using the standard formulas.
**Validates: Requirements 8.6**

### Property 24: Party Size Limit
*For any* party, party_members.size() SHALL never exceed MAX_PARTY_SIZE (5).
**Validates: Requirements 9.6**

### Property 25: Party Combat Inclusion
*For any* combat with party members, all living party members SHALL appear in turn_order sorted by Sequence.
**Validates: Requirements 9.2**

### Property 26: Effect Duration Decrement
*For any* timed effect, after tick_effects(T) is called, the effect's remaining duration SHALL decrease by T.
**Validates: Requirements 10.2**

### Property 27: Effect Stacking Calculation
*For any* stat with multiple active effects, get_total_stat_modifier() SHALL return the sum of all effect values.
**Validates: Requirements 10.6**

### Property 28: Critical Hit Location Effects
*For any* critical hit at a specific location, the applied effect SHALL match the critical table entry for that location.
**Validates: Requirements 11.1**

### Property 29: Aimed Shot Modifiers
*For any* aimed shot at location L, accuracy penalty and damage multiplier SHALL match the location modifier table.
**Validates: Requirements 11.5**

### Property 30: Trade Value Calculation
*For any* trade, the displayed value SHALL equal sum(item.value * barter_modifier) for all items.
**Validates: Requirements 12.1, 12.2**

### Property 31: Trade Execution Integrity
*For any* confirmed trade, items SHALL be removed from seller and added to buyer, and caps SHALL transfer correctly.
**Validates: Requirements 12.3**

### Property 32: Karma Title Assignment
*For any* karma value, the assigned title SHALL match the karma threshold table.
**Validates: Requirements 13.3**

### Property 33: Save/Load Round Trip
*For any* game state, saving then loading SHALL produce an equivalent game state.
**Validates: Requirements 14.1, 14.2**

### Property 34: Skill Usage Success Rate
*For any* skill usage with skill value S and difficulty D, success rate over many trials SHALL approximate the expected probability.
**Validates: Requirements 17.1, 17.2, 17.3, 17.4, 17.5, 17.6**

### Property 35: Weight Limit Enforcement
*For any* inventory operation, if adding an item would exceed carry_weight, the operation SHALL fail.
**Validates: Requirements 18.2**

### Property 36: Darkness Accuracy Penalty
*For any* attack in darkness without Night Vision, accuracy SHALL be reduced by the darkness penalty value.
**Validates: Requirements 19.3, 19.4**

### Property 37: Vehicle Fuel Consumption
*For any* travel with a vehicle, fuel consumed SHALL equal distance * fuel_consumption_rate.
**Validates: Requirements 20.3**

## Error Handling

### Input Validation
- All stat values clamped to valid ranges (1-10 for SPECIAL)
- Skill values clamped to 0-200
- Negative damage converted to 0
- Invalid enum values rejected with error logging

### Resource Loading
- Missing perk/item/quest data logged and skipped
- Corrupted save files detected via checksum validation
- Missing map scenes show error screen with return to main menu

### Combat Errors
- Invalid targets (dead, out of range) rejected gracefully
- Insufficient AP shows feedback message
- Missing weapon defaults to unarmed attack

### Dialog Errors
- Missing dialog nodes show generic response
- Failed skill checks show appropriate failure text
- Invalid NPC references logged and dialog skipped

### Save/Load Errors
- Corrupted saves detected and user notified
- Version mismatch handled with migration or rejection
- Disk full errors caught and reported

## Testing Strategy

### Property-Based Testing Framework
The project will use **GdUnit4** for property-based testing in Godot.

### Unit Tests
- Test each system in isolation
- Mock dependencies where needed
- Cover edge cases (empty inventories, zero HP, max stats)

### Property-Based Tests
Each correctness property will have a corresponding property test:

```gdscript
# Example: Property 20 - SPECIAL Bounds Enforcement
func test_special_bounds_property() -> void:
    # **Feature: fallout2-complete-migration, Property 20: SPECIAL Bounds Enforcement**
    # **Validates: Requirements 8.2**
    for i in 100:
        var random_value = randi_range(-100, 100)
        var stat_data = StatData.new()
        stat_data.strength = random_value
        stat_data.calculate_derived_stats()
        assert_true(stat_data.strength >= 1 and stat_data.strength <= 10)
```

### Integration Tests
- Test combat flow from start to end
- Test quest completion paths
- Test save/load with complex game states
- Test dialog trees with skill checks

### Test Coverage Goals
- 90% coverage on core systems (combat, stats, skills)
- 80% coverage on UI logic
- 100% coverage on save/load serialization
