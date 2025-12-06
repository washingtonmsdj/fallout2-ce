# Design Document: City Map System AAA

## Overview

Este documento descreve a arquitetura e design de um sistema de mapa/cidade AAA para Fallout 2: Godot Edition. O sistema é inspirado no Citybound mas adaptado para o estilo pós-apocalíptico do Fallout, com foco em modularidade, performance e extensibilidade.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CityManager                               │
│  (Coordena todos os sistemas, gerencia ciclo de vida)           │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  GridSystem   │     │ RoadSystem    │     │ ZoneSystem    │
│  (Terreno)    │     │ (Pathfinding) │     │ (Zoneamento)  │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│BuildingSystem │     │CitizenSystem  │     │EconomySystem  │
│ (Construções) │     │ (NPCs)        │     │ (Recursos)    │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ PowerSystem   │     │ WaterSystem   │     │DefenseSystem  │
│ (Eletricidade)│     │ (Água)        │     │ (Defesas)     │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│FactionSystem  │     │WeatherSystem  │     │ EventSystem   │
│ (Facções)     │     │ (Clima)       │     │ (Eventos)     │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│VehicleSystem  │     │CraftingSystem │     │ QuestSystem   │
│ (Veículos)    │     │ (Crafting)    │     │ (Quests)      │
└───────────────┘     └───────────────┘     └───────────────┘
                                │
                                ▼
                    ┌───────────────────┐
                    │  CityRenderer     │
                    │  (Visualização)   │
                    └───────────────────┘
```

### Event Bus Pattern

```gdscript
# Comunicação entre sistemas via sinais
class_name EventBus
extends Node

# Grid Events
signal tile_changed(position: Vector2i, old_type: int, new_type: int)
signal terrain_modified(area: Rect2i)

# Building Events
signal building_constructed(building_id: int, position: Vector2i)
signal building_destroyed(building_id: int)
signal building_upgraded(building_id: int, new_level: int)

# Citizen Events
signal citizen_spawned(citizen_id: int)
signal citizen_died(citizen_id: int)
signal citizen_need_critical(citizen_id: int, need_type: int)

# Economy Events
signal resource_changed(resource_type: int, old_amount: float, new_amount: float)
signal price_updated(resource_type: int, new_price: float)
signal trade_completed(buyer_id: int, seller_id: int, deal: Dictionary)

# Faction Events
signal faction_territory_changed(faction_id: int, tiles: Array)
signal faction_relation_changed(faction_a: int, faction_b: int, new_relation: int)

# Weather Events
signal weather_changed(old_weather: int, new_weather: int)
signal time_of_day_changed(hour: int)

# Combat/Defense Events
signal raid_started(raid_data: Dictionary)
signal raid_ended(result: int)
signal defense_alert(threat_position: Vector2i)
```

## Components and Interfaces

### 1. GridSystem

```gdscript
class_name GridSystem
extends Node

# Tile data structure
class TileData:
    var terrain_type: TerrainType
    var elevation: float
    var walkable: bool
    var radiation_level: float
    var zone_id: int = -1
    var building_id: int = -1
    var road_id: int = -1

enum TerrainType {
    GROUND,
    WATER,
    ROCK,
    SAND,
    CONCRETE,
    RADIATION_ZONE,
    RUBBLE
}

# Interface
func get_tile(pos: Vector2i) -> TileData
func set_tile(pos: Vector2i, data: TileData) -> void
func is_walkable(pos: Vector2i) -> bool
func get_tiles_in_area(rect: Rect2i) -> Array[TileData]
func get_neighbors(pos: Vector2i) -> Array[Vector2i]
func raycast(from: Vector2i, to: Vector2i) -> Array[Vector2i]
```

### 2. RoadSystem

```gdscript
class_name RoadSystem
extends Node

class RoadSegment:
    var id: int
    var start: Vector2i
    var end: Vector2i
    var control_points: Array[Vector2]  # Para curvas Bezier
    var road_type: RoadType
    var width: int  # 1-4 lanes
    var condition: float  # 0-100%
    var tiles: Array[Vector2i]

enum RoadType {
    DIRT_PATH,
    PAVED_ROAD,
    HIGHWAY,
    ALLEY,
    BRIDGE
}

class PathResult:
    var path: Array[Vector2i]
    var cost: float
    var estimated_time: float

# Interface
func create_road(start: Vector2i, end: Vector2i, type: RoadType) -> int
func create_curved_road(points: Array[Vector2], type: RoadType) -> int
func remove_road(road_id: int) -> void
func find_path(from: Vector2i, to: Vector2i, mode: PathMode) -> PathResult
func get_road_at(pos: Vector2i) -> RoadSegment
func get_connected_roads(road_id: int) -> Array[int]

# Pathfinding com landmarks
class Landmark:
    var position: Vector2i
    var connections: Dictionary  # landmark_id -> distance

func precompute_landmarks() -> void
func find_path_with_landmarks(from: Vector2i, to: Vector2i) -> PathResult
```

### 3. BuildingSystem

```gdscript
class_name BuildingSystem
extends Node

class BuildingData:
    var id: int
    var type: BuildingType
    var variant: int  # Visual variant
    var position: Vector2i
    var size: Vector2i
    var rotation: int  # 0, 90, 180, 270
    var level: int
    var health: float
    var condition: BuildingCondition
    var occupants: Array[int]  # citizen_ids
    var owner_faction: int
    var power_connected: bool
    var water_connected: bool
    var production: Dictionary  # resource -> rate
    var consumption: Dictionary  # resource -> rate

enum BuildingType {
    # Residential
    SHACK, HOUSE, APARTMENT, MANSION,
    # Commercial
    SHOP, BAR, RESTAURANT, HOTEL, CASINO,
    # Services
    HOSPITAL, POLICE_STATION, FIRE_STATION, SCHOOL,
    # Industrial
    FACTORY, WORKSHOP, WAREHOUSE, POWER_PLANT,
    # Infrastructure
    WATER_TOWER, RADIO_TOWER, BRIDGE, BUNKER,
    # Defense
    WALL, GATE, GUARD_TOWER, TURRET
}

enum BuildingCondition {
    PRISTINE,
    GOOD,
    DAMAGED,
    RUINED,
    MAKESHIFT
}

# Building templates with sizes
const BUILDING_TEMPLATES = {
    BuildingType.SHACK: {"size": Vector2i(2, 2), "capacity": 2},
    BuildingType.HOUSE: {"size": Vector2i(3, 3), "capacity": 4},
    BuildingType.APARTMENT: {"size": Vector2i(4, 6), "capacity": 12},
    BuildingType.HOSPITAL: {"size": Vector2i(6, 8), "capacity": 20},
    BuildingType.POLICE_STATION: {"size": Vector2i(5, 5), "capacity": 10},
    BuildingType.FACTORY: {"size": Vector2i(8, 10), "capacity": 30},
    # ... etc
}

# Interface
func construct_building(type: BuildingType, pos: Vector2i, faction: int) -> int
func destroy_building(building_id: int) -> void
func upgrade_building(building_id: int) -> bool
func repair_building(building_id: int, amount: float) -> void
func get_building(building_id: int) -> BuildingData
func get_buildings_in_area(rect: Rect2i) -> Array[BuildingData]
func get_buildings_by_type(type: BuildingType) -> Array[BuildingData]
```

### 4. CitizenSystem

```gdscript
class_name CitizenSystem
extends Node

class CitizenData:
    var id: int
    var name: String
    var faction_id: int
    var home_id: int  # building_id
    var job_id: int   # building_id
    var position: Vector2
    var grid_position: Vector2i
    var needs: Dictionary  # NeedType -> float (0-100)
    var skills: Dictionary  # SkillType -> int
    var schedule: Array[ScheduleEntry]
    var current_activity: Activity
    var path: Array[Vector2i]
    var path_index: int
    var relationships: Dictionary  # citizen_id -> relationship_value

enum NeedType {
    HUNGER,
    THIRST,
    REST,
    HAPPINESS,
    HEALTH,
    SAFETY
}

enum Activity {
    IDLE,
    WALKING,
    WORKING,
    EATING,
    SLEEPING,
    SOCIALIZING,
    FLEEING,
    FIGHTING
}

class ScheduleEntry:
    var hour: int
    var activity: Activity
    var location_id: int

# Interface
func spawn_citizen(faction: int, home_id: int) -> int
func remove_citizen(citizen_id: int) -> void
func get_citizen(citizen_id: int) -> CitizenData
func update_citizen_need(citizen_id: int, need: NeedType, delta: float) -> void
func assign_job(citizen_id: int, building_id: int) -> bool
func get_citizens_in_area(rect: Rect2i) -> Array[CitizenData]
func get_citizens_by_faction(faction_id: int) -> Array[CitizenData]
```

### 5. EconomySystem

```gdscript
class_name EconomySystem
extends Node

enum ResourceType {
    FOOD,
    WATER,
    CAPS,
    MATERIALS,
    POWER,
    MEDICINE,
    WEAPONS,
    FUEL,
    COMPONENTS
}

class ResourceData:
    var amount: float
    var production_rate: float
    var consumption_rate: float
    var price: float
    var price_history: Array[float]

class TradeOffer:
    var seller_id: int  # building or external
    var resource: ResourceType
    var amount: float
    var price_per_unit: float
    var duration: float

# Interface
func get_resource(type: ResourceType) -> ResourceData
func add_resource(type: ResourceType, amount: float) -> void
func consume_resource(type: ResourceType, amount: float) -> bool
func get_price(type: ResourceType) -> float
func create_trade_offer(offer: TradeOffer) -> int
func accept_trade(offer_id: int, buyer_id: int) -> bool
func get_economic_report() -> Dictionary
```

### 6. FactionSystem

```gdscript
class_name FactionSystem
extends Node

class FactionData:
    var id: int
    var name: String
    var color: Color
    var territory: Array[Vector2i]
    var headquarters_id: int  # building_id
    var resources: Dictionary
    var relations: Dictionary  # faction_id -> RelationType
    var player_reputation: int  # -100 to 100

enum RelationType {
    ALLIED,
    FRIENDLY,
    NEUTRAL,
    UNFRIENDLY,
    HOSTILE
}

# Interface
func create_faction(name: String, color: Color) -> int
func claim_territory(faction_id: int, tiles: Array[Vector2i]) -> void
func get_faction_at(pos: Vector2i) -> int
func get_relation(faction_a: int, faction_b: int) -> RelationType
func set_relation(faction_a: int, faction_b: int, relation: RelationType) -> void
func modify_player_reputation(faction_id: int, delta: int) -> void
```

### 7. WeatherSystem

```gdscript
class_name WeatherSystem
extends Node

enum WeatherType {
    CLEAR,
    CLOUDY,
    DUST_STORM,
    RAD_STORM,
    ACID_RAIN,
    HEAT_WAVE,
    COLD_SNAP
}

class WeatherData:
    var type: WeatherType
    var intensity: float  # 0-1
    var duration: float
    var effects: Dictionary

# Interface
func get_current_weather() -> WeatherData
func get_time_of_day() -> int  # 0-23
func is_daytime() -> bool
func get_visibility() -> float
func get_radiation_modifier() -> float
func force_weather(type: WeatherType, duration: float) -> void
```

### 8. DefenseSystem

```gdscript
class_name DefenseSystem
extends Node

class DefenseStructure:
    var id: int
    var type: DefenseType
    var position: Vector2i
    var health: float
    var ammo: int
    var range: float
    var damage: float
    var target_id: int

enum DefenseType {
    WALL,
    GATE,
    GUARD_TOWER,
    TURRET_BALLISTIC,
    TURRET_LASER,
    TRAP_MINE,
    TRAP_SPIKE
}

class GuardData:
    var citizen_id: int
    var patrol_route: Array[Vector2i]
    var current_waypoint: int
    var alert_level: int

# Interface
func build_defense(type: DefenseType, pos: Vector2i) -> int
func get_defense_rating() -> float
func assign_guard(citizen_id: int, route: Array[Vector2i]) -> void
func trigger_alert(threat_pos: Vector2i) -> void
func process_raid(raid_data: Dictionary) -> Dictionary
```

## Data Models

### Save Data Structure

```gdscript
class CityState:
    var version: int
    var timestamp: int
    var grid_data: PackedByteArray  # Compressed tile data
    var buildings: Array[Dictionary]
    var citizens: Array[Dictionary]
    var roads: Array[Dictionary]
    var zones: Array[Dictionary]
    var factions: Array[Dictionary]
    var resources: Dictionary
    var weather_state: Dictionary
    var time_state: Dictionary
    var event_queue: Array[Dictionary]
    var player_state: Dictionary
```

### Configuration Data

```gdscript
# res://config/city_config.gd
class_name CityConfig

const GRID_SIZE = Vector2i(200, 200)
const TILE_SIZE = 32.0
const ISO_TILE_WIDTH = 64.0
const ISO_TILE_HEIGHT = 32.0

const MAX_CITIZENS = 200
const MAX_BUILDINGS = 500

const NEED_DECAY_RATES = {
    CitizenSystem.NeedType.HUNGER: 0.5,
    CitizenSystem.NeedType.THIRST: 0.8,
    CitizenSystem.NeedType.REST: 0.3,
    CitizenSystem.NeedType.HAPPINESS: 0.1,
    CitizenSystem.NeedType.HEALTH: 0.05,
    CitizenSystem.NeedType.SAFETY: 0.2
}

const RESOURCE_BASE_PRICES = {
    EconomySystem.ResourceType.FOOD: 10.0,
    EconomySystem.ResourceType.WATER: 8.0,
    EconomySystem.ResourceType.CAPS: 1.0,
    EconomySystem.ResourceType.MATERIALS: 15.0,
    EconomySystem.ResourceType.POWER: 5.0,
    EconomySystem.ResourceType.MEDICINE: 50.0,
    EconomySystem.ResourceType.WEAPONS: 100.0,
    EconomySystem.ResourceType.FUEL: 20.0
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Grid Consistency
*For any* tile position within grid bounds, accessing that tile SHALL return valid TileData with all fields initialized
**Validates: Requirements 1.4**

### Property 2: Pathfinding Validity
*For any* path returned by the pathfinding system, all tiles in the path SHALL be walkable and adjacent to each other
**Validates: Requirements 2.3, 2.5**

### Property 3: Building Placement Integrity
*For any* building placed on the grid, all tiles within the building footprint SHALL be marked as occupied and non-walkable
**Validates: Requirements 4.1, 4.3**

### Property 4: Citizen Need Bounds
*For any* citizen, all need values SHALL remain within the range [0, 100] after any update operation
**Validates: Requirements 5.1, 5.3**

### Property 5: Resource Conservation
*For any* resource transaction, the total resources in the system (production - consumption) SHALL equal the net change in stored resources
**Validates: Requirements 6.2, 6.3**

### Property 6: Faction Territory Exclusivity
*For any* tile, it SHALL belong to at most one faction at any given time
**Validates: Requirements 12.2**

### Property 7: Road Connectivity
*For any* road segment, if it has an endpoint adjacent to another road segment, they SHALL be connected in the road graph
**Validates: Requirements 2.2**

### Property 8: Power Grid Consistency
*For any* building marked as power_connected, there SHALL exist a valid path through power conduits to a power source
**Validates: Requirements 19.3, 19.4**

### Property 9: Save/Load Round Trip
*For any* valid city state, serializing then deserializing SHALL produce an equivalent city state
**Validates: Requirements 10.1, 10.3**

### Property 10: Defense Rating Calculation
*For any* settlement, the defense rating SHALL equal the sum of all active defense structure ratings
**Validates: Requirements 15.2**

## Error Handling

### Grid System Errors
- Out of bounds access: Return null/default and log warning
- Invalid terrain type: Clamp to valid range

### Pathfinding Errors
- No path found: Return empty PathResult with cost = INF
- Timeout: Return partial path with flag

### Building Errors
- Invalid placement: Return -1 and emit error signal
- Insufficient resources: Return false, do not modify state

### Citizen Errors
- Invalid home/job assignment: Log error, assign to fallback
- Path blocked: Recalculate or wait

### Economy Errors
- Negative resources: Clamp to 0, emit warning
- Division by zero in price calc: Use base price

## Testing Strategy

### Unit Testing
- Test each system in isolation with mock dependencies
- Test boundary conditions for all numeric values
- Test state transitions for all enums

### Property-Based Testing (GdUnit4)
- Use GdUnit4 for property-based testing in GDScript
- Generate random valid inputs and verify properties hold
- Test invariants after sequences of operations

### Integration Testing
- Test system interactions through EventBus
- Test save/load cycle with complex states
- Test performance with maximum entity counts

### Performance Testing
- Benchmark pathfinding with various grid sizes
- Measure frame time with max entities
- Profile memory usage over extended play

## File Structure

```
scripts/
├── city/
│   ├── core/
│   │   ├── city_manager.gd
│   │   ├── event_bus.gd
│   │   └── city_config.gd
│   ├── systems/
│   │   ├── grid_system.gd
│   │   ├── road_system.gd
│   │   ├── zone_system.gd
│   │   ├── building_system.gd
│   │   ├── citizen_system.gd
│   │   ├── economy_system.gd
│   │   ├── faction_system.gd
│   │   ├── weather_system.gd
│   │   ├── defense_system.gd
│   │   ├── power_system.gd
│   │   ├── water_system.gd
│   │   ├── vehicle_system.gd
│   │   ├── crafting_system.gd
│   │   ├── quest_system.gd
│   │   └── event_system.gd
│   ├── data/
│   │   ├── building_templates.gd
│   │   ├── citizen_templates.gd
│   │   ├── faction_templates.gd
│   │   └── resource_config.gd
│   ├── rendering/
│   │   ├── city_renderer.gd
│   │   ├── building_renderer.gd
│   │   ├── citizen_renderer.gd
│   │   ├── road_renderer.gd
│   │   └── weather_renderer.gd
│   └── utils/
│       ├── pathfinding.gd
│       ├── spatial_hash.gd
│       └── serialization.gd
├── entities/
│   └── player_city.gd
└── test/
    └── test_city_systems.gd

scenes/
└── city/
    ├── CityMap.tscn
    ├── CityUI.tscn
    └── prefabs/
        ├── buildings/
        └── citizens/
```
