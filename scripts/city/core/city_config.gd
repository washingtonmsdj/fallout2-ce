## CityConfig - Configurações globais do sistema de cidade
## Todas as constantes e valores configuráveis em um só lugar
class_name CityConfig
extends RefCounted

# =============================================================================
# GRID CONFIGURATION
# =============================================================================
const GRID_SIZE_MIN := Vector2i(50, 50)
const GRID_SIZE_DEFAULT := Vector2i(200, 200)
const GRID_SIZE_MAX := Vector2i(500, 500)

const TILE_SIZE := 32.0
const ISO_TILE_WIDTH := 64.0
const ISO_TILE_HEIGHT := 32.0

# =============================================================================
# ENTITY LIMITS
# =============================================================================
const MAX_CITIZENS := 200
const MAX_BUILDINGS := 500
const MAX_ROADS := 1000
const MAX_ZONES := 100
const MAX_VEHICLES := 50
const MAX_DEFENSES := 200

# =============================================================================
# TERRAIN TYPES
# =============================================================================
enum TerrainType {
	GROUND,
	WATER,
	ROCK,
	SAND,
	CONCRETE,
	RADIATION_ZONE,
	RUBBLE,
	GRASS,
	DIRT
}

const TERRAIN_WALKABLE := {
	TerrainType.GROUND: true,
	TerrainType.WATER: false,
	TerrainType.ROCK: false,
	TerrainType.SAND: true,
	TerrainType.CONCRETE: true,
	TerrainType.RADIATION_ZONE: true,
	TerrainType.RUBBLE: true,
	TerrainType.GRASS: true,
	TerrainType.DIRT: true
}

const TERRAIN_MOVEMENT_COST := {
	TerrainType.GROUND: 1.0,
	TerrainType.WATER: 999.0,
	TerrainType.ROCK: 999.0,
	TerrainType.SAND: 1.5,
	TerrainType.CONCRETE: 0.8,
	TerrainType.RADIATION_ZONE: 2.0,
	TerrainType.RUBBLE: 1.8,
	TerrainType.GRASS: 1.0,
	TerrainType.DIRT: 1.2
}

# =============================================================================
# ROAD TYPES
# =============================================================================
enum RoadType {
	DIRT_PATH,
	PAVED_ROAD,
	HIGHWAY,
	ALLEY,
	BRIDGE
}

const ROAD_SPEED_MODIFIER := {
	RoadType.DIRT_PATH: 1.0,
	RoadType.PAVED_ROAD: 1.5,
	RoadType.HIGHWAY: 2.0,
	RoadType.ALLEY: 0.8,
	RoadType.BRIDGE: 1.2
}

const ROAD_WIDTH := {
	RoadType.DIRT_PATH: 1,
	RoadType.PAVED_ROAD: 2,
	RoadType.HIGHWAY: 4,
	RoadType.ALLEY: 1,
	RoadType.BRIDGE: 2
}

const ROAD_BUILD_COST := {
	RoadType.DIRT_PATH: 5.0,
	RoadType.PAVED_ROAD: 15.0,
	RoadType.HIGHWAY: 50.0,
	RoadType.ALLEY: 8.0,
	RoadType.BRIDGE: 100.0
}

# =============================================================================
# ZONE TYPES
# =============================================================================
enum ZoneType {
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL,
	AGRICULTURAL,
	MILITARY,
	RESTRICTED
}

const ZONE_COLORS := {
	ZoneType.RESIDENTIAL: Color(0.2, 0.7, 0.2, 0.4),
	ZoneType.COMMERCIAL: Color(0.2, 0.2, 0.7, 0.4),
	ZoneType.INDUSTRIAL: Color(0.7, 0.7, 0.2, 0.4),
	ZoneType.AGRICULTURAL: Color(0.5, 0.35, 0.15, 0.4),
	ZoneType.MILITARY: Color(0.7, 0.2, 0.2, 0.4),
	ZoneType.RESTRICTED: Color(0.5, 0.0, 0.5, 0.4)
}

# =============================================================================
# BUILDING TYPES
# =============================================================================
enum BuildingType {
	# Residential (0-9)
	SHACK,
	HOUSE,
	APARTMENT,
	MANSION,
	# Commercial (10-19)
	SHOP = 10,
	BAR,
	RESTAURANT,
	HOTEL,
	CASINO,
	# Services (20-29)
	HOSPITAL = 20,
	POLICE_STATION,
	FIRE_STATION,
	SCHOOL,
	CHURCH,
	# Industrial (30-39)
	FACTORY = 30,
	WORKSHOP,
	WAREHOUSE,
	POWER_PLANT,
	WATER_TREATMENT,
	# Infrastructure (40-49)
	WATER_TOWER = 40,
	RADIO_TOWER,
	BRIDGE_BUILDING,
	BUNKER,
	# Defense (50-59)
	WALL = 50,
	GATE,
	GUARD_TOWER,
	TURRET,
	# Special (60+)
	VAULT = 60,
	MILITARY_BASE
}

enum BuildingCondition {
	PRISTINE,
	GOOD,
	DAMAGED,
	RUINED,
	MAKESHIFT
}

# Building templates: size, capacity, zone, cost
const BUILDING_TEMPLATES := {
	# Residential
	BuildingType.SHACK: {
		"size": Vector2i(2, 2),
		"capacity": 2,
		"zone": ZoneType.RESIDENTIAL,
		"cost": {"materials": 10.0},
		"height": 20.0
	},
	BuildingType.HOUSE: {
		"size": Vector2i(3, 3),
		"capacity": 4,
		"zone": ZoneType.RESIDENTIAL,
		"cost": {"materials": 25.0},
		"height": 25.0
	},
	BuildingType.APARTMENT: {
		"size": Vector2i(4, 6),
		"capacity": 12,
		"zone": ZoneType.RESIDENTIAL,
		"cost": {"materials": 80.0},
		"height": 45.0
	},
	BuildingType.MANSION: {
		"size": Vector2i(6, 6),
		"capacity": 8,
		"zone": ZoneType.RESIDENTIAL,
		"cost": {"materials": 150.0, "caps": 500.0},
		"height": 35.0
	},
	# Commercial
	BuildingType.SHOP: {
		"size": Vector2i(3, 3),
		"capacity": 2,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 30.0},
		"height": 30.0,
		"production": {"caps": 5.0}
	},
	BuildingType.BAR: {
		"size": Vector2i(4, 3),
		"capacity": 4,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 40.0},
		"height": 25.0,
		"production": {"caps": 8.0},
		"consumption": {"water": 2.0}
	},
	BuildingType.RESTAURANT: {
		"size": Vector2i(4, 4),
		"capacity": 6,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 50.0},
		"height": 28.0,
		"consumption": {"food": 5.0, "water": 3.0},
		"production": {"caps": 10.0}
	},
	BuildingType.HOTEL: {
		"size": Vector2i(5, 6),
		"capacity": 20,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 100.0},
		"height": 50.0,
		"production": {"caps": 15.0}
	},
	BuildingType.CASINO: {
		"size": Vector2i(6, 6),
		"capacity": 10,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 200.0, "caps": 1000.0},
		"height": 40.0,
		"production": {"caps": 50.0}
	},
	# Services
	BuildingType.HOSPITAL: {
		"size": Vector2i(6, 8),
		"capacity": 20,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 150.0, "medicine": 50.0},
		"height": 45.0,
		"consumption": {"medicine": 2.0, "power": 10.0}
	},
	BuildingType.POLICE_STATION: {
		"size": Vector2i(5, 5),
		"capacity": 10,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 80.0, "weapons": 20.0},
		"height": 35.0,
		"consumption": {"power": 5.0}
	},
	BuildingType.FIRE_STATION: {
		"size": Vector2i(5, 4),
		"capacity": 8,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 70.0},
		"height": 30.0,
		"consumption": {"water": 5.0, "power": 3.0}
	},
	BuildingType.SCHOOL: {
		"size": Vector2i(6, 5),
		"capacity": 30,
		"zone": ZoneType.COMMERCIAL,
		"cost": {"materials": 60.0},
		"height": 30.0,
		"consumption": {"power": 5.0}
	},
	# Industrial
	BuildingType.FACTORY: {
		"size": Vector2i(8, 10),
		"capacity": 30,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 200.0},
		"height": 40.0,
		"production": {"materials": 10.0, "components": 5.0},
		"consumption": {"power": 20.0}
	},
	BuildingType.WORKSHOP: {
		"size": Vector2i(4, 4),
		"capacity": 5,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 50.0},
		"height": 25.0,
		"production": {"materials": 3.0},
		"consumption": {"power": 5.0}
	},
	BuildingType.WAREHOUSE: {
		"size": Vector2i(6, 8),
		"capacity": 3,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 80.0},
		"height": 30.0
	},
	BuildingType.POWER_PLANT: {
		"size": Vector2i(8, 8),
		"capacity": 10,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 300.0, "components": 50.0},
		"height": 50.0,
		"production": {"power": 100.0},
		"consumption": {"fuel": 10.0}
	},
	BuildingType.WATER_TREATMENT: {
		"size": Vector2i(6, 6),
		"capacity": 5,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 150.0},
		"height": 25.0,
		"production": {"water": 50.0},
		"consumption": {"power": 15.0}
	},
	# Infrastructure
	BuildingType.WATER_TOWER: {
		"size": Vector2i(3, 3),
		"capacity": 1,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 60.0},
		"height": 55.0,
		"production": {"water": 20.0}
	},
	BuildingType.RADIO_TOWER: {
		"size": Vector2i(2, 2),
		"capacity": 2,
		"zone": ZoneType.INDUSTRIAL,
		"cost": {"materials": 100.0, "components": 30.0},
		"height": 80.0,
		"consumption": {"power": 10.0}
	},
	# Defense
	BuildingType.WALL: {
		"size": Vector2i(1, 1),
		"capacity": 0,
		"zone": ZoneType.MILITARY,
		"cost": {"materials": 5.0},
		"height": 15.0,
		"defense_rating": 10.0
	},
	BuildingType.GATE: {
		"size": Vector2i(2, 1),
		"capacity": 0,
		"zone": ZoneType.MILITARY,
		"cost": {"materials": 15.0},
		"height": 18.0,
		"defense_rating": 5.0
	},
	BuildingType.GUARD_TOWER: {
		"size": Vector2i(2, 2),
		"capacity": 2,
		"zone": ZoneType.MILITARY,
		"cost": {"materials": 40.0},
		"height": 40.0,
		"defense_rating": 25.0,
		"range": 10.0
	},
	BuildingType.TURRET: {
		"size": Vector2i(2, 2),
		"capacity": 0,
		"zone": ZoneType.MILITARY,
		"cost": {"materials": 80.0, "weapons": 10.0},
		"height": 20.0,
		"defense_rating": 50.0,
		"range": 15.0,
		"consumption": {"power": 5.0}
	}
}

# =============================================================================
# CITIZEN CONFIGURATION
# =============================================================================
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
	DRINKING,
	SLEEPING,
	SOCIALIZING,
	FLEEING,
	FIGHTING,
	SHOPPING
}

const NEED_DECAY_RATES := {
	NeedType.HUNGER: 0.5,
	NeedType.THIRST: 0.8,
	NeedType.REST: 0.3,
	NeedType.HAPPINESS: 0.1,
	NeedType.HEALTH: 0.05,
	NeedType.SAFETY: 0.2
}

const NEED_CRITICAL_THRESHOLD := 20.0
const NEED_LOW_THRESHOLD := 40.0
const NEED_MAX := 100.0
const NEED_MIN := 0.0

const CITIZEN_MOVE_SPEED := 50.0
const CITIZEN_RUN_SPEED := 100.0

# =============================================================================
# RESOURCE CONFIGURATION
# =============================================================================
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

const RESOURCE_BASE_PRICES := {
	ResourceType.FOOD: 10.0,
	ResourceType.WATER: 8.0,
	ResourceType.CAPS: 1.0,
	ResourceType.MATERIALS: 15.0,
	ResourceType.POWER: 5.0,
	ResourceType.MEDICINE: 50.0,
	ResourceType.WEAPONS: 100.0,
	ResourceType.FUEL: 20.0,
	ResourceType.COMPONENTS: 25.0
}

const RESOURCE_PRICE_VOLATILITY := {
	ResourceType.FOOD: 0.3,
	ResourceType.WATER: 0.4,
	ResourceType.CAPS: 0.0,
	ResourceType.MATERIALS: 0.2,
	ResourceType.POWER: 0.1,
	ResourceType.MEDICINE: 0.5,
	ResourceType.WEAPONS: 0.4,
	ResourceType.FUEL: 0.6,
	ResourceType.COMPONENTS: 0.3
}

# =============================================================================
# FACTION CONFIGURATION
# =============================================================================
enum RelationType {
	ALLIED,
	FRIENDLY,
	NEUTRAL,
	UNFRIENDLY,
	HOSTILE
}

const REPUTATION_MIN := -100
const REPUTATION_MAX := 100
const REPUTATION_DECAY_RATE := 0.01

# =============================================================================
# WEATHER CONFIGURATION
# =============================================================================
enum WeatherType {
	CLEAR,
	CLOUDY,
	DUST_STORM,
	RAD_STORM,
	ACID_RAIN,
	HEAT_WAVE,
	COLD_SNAP
}

const WEATHER_EFFECTS := {
	WeatherType.CLEAR: {
		"visibility": 1.0,
		"movement_modifier": 1.0,
		"radiation": 0.0,
		"damage_per_second": 0.0
	},
	WeatherType.CLOUDY: {
		"visibility": 0.8,
		"movement_modifier": 1.0,
		"radiation": 0.0,
		"damage_per_second": 0.0
	},
	WeatherType.DUST_STORM: {
		"visibility": 0.3,
		"movement_modifier": 0.6,
		"radiation": 0.0,
		"damage_per_second": 0.0
	},
	WeatherType.RAD_STORM: {
		"visibility": 0.5,
		"movement_modifier": 0.8,
		"radiation": 5.0,
		"damage_per_second": 0.5
	},
	WeatherType.ACID_RAIN: {
		"visibility": 0.6,
		"movement_modifier": 0.7,
		"radiation": 0.0,
		"damage_per_second": 1.0
	},
	WeatherType.HEAT_WAVE: {
		"visibility": 0.9,
		"movement_modifier": 0.8,
		"radiation": 0.0,
		"damage_per_second": 0.2
	},
	WeatherType.COLD_SNAP: {
		"visibility": 0.7,
		"movement_modifier": 0.7,
		"radiation": 0.0,
		"damage_per_second": 0.3
	}
}

const DAY_LENGTH_SECONDS := 1440.0  # 24 minutos reais = 24 horas no jogo
const HOUR_LENGTH_SECONDS := 60.0   # 1 minuto real = 1 hora no jogo

# =============================================================================
# DEFENSE CONFIGURATION
# =============================================================================
enum DefenseType {
	WALL,
	GATE,
	GUARD_TOWER,
	TURRET_BALLISTIC,
	TURRET_LASER,
	TRAP_MINE,
	TRAP_SPIKE
}

const DEFENSE_STATS := {
	DefenseType.WALL: {"health": 100.0, "rating": 10.0, "range": 0.0, "damage": 0.0},
	DefenseType.GATE: {"health": 80.0, "rating": 5.0, "range": 0.0, "damage": 0.0},
	DefenseType.GUARD_TOWER: {"health": 150.0, "rating": 25.0, "range": 10.0, "damage": 15.0},
	DefenseType.TURRET_BALLISTIC: {"health": 100.0, "rating": 50.0, "range": 15.0, "damage": 25.0},
	DefenseType.TURRET_LASER: {"health": 80.0, "rating": 60.0, "range": 20.0, "damage": 35.0},
	DefenseType.TRAP_MINE: {"health": 10.0, "rating": 30.0, "range": 2.0, "damage": 100.0},
	DefenseType.TRAP_SPIKE: {"health": 50.0, "rating": 15.0, "range": 1.0, "damage": 20.0}
}

# =============================================================================
# VEHICLE CONFIGURATION
# =============================================================================
enum VehicleType {
	CAR,
	MOTORCYCLE,
	TRUCK,
	VERTIBIRD
}

const VEHICLE_STATS := {
	VehicleType.CAR: {
		"speed": 200.0,
		"fuel_capacity": 100.0,
		"fuel_consumption": 1.0,
		"cargo_capacity": 50.0,
		"health": 100.0,
		"passengers": 4
	},
	VehicleType.MOTORCYCLE: {
		"speed": 250.0,
		"fuel_capacity": 30.0,
		"fuel_consumption": 0.5,
		"cargo_capacity": 10.0,
		"health": 50.0,
		"passengers": 2
	},
	VehicleType.TRUCK: {
		"speed": 120.0,
		"fuel_capacity": 200.0,
		"fuel_consumption": 2.0,
		"cargo_capacity": 200.0,
		"health": 200.0,
		"passengers": 3
	},
	VehicleType.VERTIBIRD: {
		"speed": 400.0,
		"fuel_capacity": 500.0,
		"fuel_consumption": 5.0,
		"cargo_capacity": 100.0,
		"health": 300.0,
		"passengers": 8
	}
}

# =============================================================================
# PATHFINDING CONFIGURATION
# =============================================================================
const PATHFINDING_MAX_ITERATIONS := 10000
const PATHFINDING_TIMEOUT_MS := 16.0
const LANDMARK_COUNT := 16
const PATH_CACHE_SIZE := 100
const PATH_CACHE_TTL := 60.0  # segundos

# =============================================================================
# PERFORMANCE CONFIGURATION
# =============================================================================
const TARGET_FPS := 60
const CITIZEN_UPDATE_BATCH_SIZE := 20
const BUILDING_UPDATE_BATCH_SIZE := 50
const SPATIAL_HASH_CELL_SIZE := 64.0
const LOD_DISTANCE_NEAR := 500.0
const LOD_DISTANCE_FAR := 1500.0

# =============================================================================
# RENDERING CONFIGURATION
# =============================================================================
const CAMERA_ZOOM_MIN := 0.25
const CAMERA_ZOOM_MAX := 4.0
const CAMERA_ZOOM_SPEED := 0.1
const CAMERA_PAN_SPEED := 500.0

const COLOR_ROAD := Color(0.25, 0.22, 0.2)
const COLOR_GROUND := Color(0.6, 0.5, 0.35)
const COLOR_GRID := Color(0.4, 0.4, 0.4, 0.15)
