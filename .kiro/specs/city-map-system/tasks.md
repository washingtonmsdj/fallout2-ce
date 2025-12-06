# Implementation Plan

## Phase 1: Core Infrastructure

- [ ] 1. Set up project structure and core systems
  - [ ] 1.1 Create directory structure for city systems
    - Create `scripts/city/core/`, `scripts/city/systems/`, `scripts/city/data/`, `scripts/city/rendering/`, `scripts/city/utils/`
    - _Requirements: 23.1_
  - [ ] 1.2 Implement EventBus for inter-system communication
    - Create `scripts/city/core/event_bus.gd` with all signals defined in design
    - Implement singleton pattern for global access
    - _Requirements: 23.4_
  - [ ] 1.3 Create CityConfig with all constants
    - Create `scripts/city/core/city_config.gd` with grid sizes, decay rates, prices
    - _Requirements: 23.6_
  - [ ] 1.4 Implement CityManager coordinator
    - Create `scripts/city/core/city_manager.gd` to initialize and coordinate all systems
    - Implement system lifecycle management (init, update, cleanup)
    - _Requirements: 23.1, 23.3_

- [ ] 2. Checkpoint - Ensure core infrastructure works
  - Ensure all tests pass, ask the user if questions arise.

## Phase 2: Grid and Terrain System

- [ ] 3. Implement GridSystem
  - [ ] 3.1 Create TileData class and TerrainType enum
    - Implement `scripts/city/systems/grid_system.gd`
    - Define TileData with terrain_type, elevation, walkable, radiation_level
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ] 3.2 Implement grid storage with Dictionary for O(1) access
    - Use Vector2i keys for tile lookup
    - Support configurable grid sizes 50x50 to 500x500
    - _Requirements: 1.1, 1.4_
  - [ ] 3.3 Write property test for grid consistency
    - **Property 1: Grid Consistency**
    - **Validates: Requirements 1.4**
  - [ ] 3.4 Implement grid utility functions
    - get_tile, set_tile, is_walkable, get_tiles_in_area, get_neighbors, raycast
    - _Requirements: 1.2, 1.4_
  - [ ] 3.5 Implement grid serialization
    - Serialize to PackedByteArray for efficient save/load
    - _Requirements: 1.5_
  - [ ] 3.6 Write property test for serialization round-trip
    - **Property 9: Save/Load Round Trip**
    - **Validates: Requirements 1.5, 10.1**

- [ ] 4. Checkpoint - Grid system complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 3: Road System and Pathfinding

- [ ] 5. Implement RoadSystem
  - [ ] 5.1 Create RoadSegment class and RoadType enum
    - Implement `scripts/city/systems/road_system.gd`
    - Support curved roads with Bezier control points
    - _Requirements: 2.1, 21.1, 21.2_
  - [ ] 5.2 Implement road creation with organic layouts
    - create_road, create_curved_road functions
    - Avoid perfect grids, support curves and diagonals
    - _Requirements: 21.4, 21.5_
  - [ ] 5.3 Implement road connectivity
    - Automatically connect adjacent road segments
    - Track intersections and connections
    - _Requirements: 2.2_
  - [ ] 5.4 Write property test for road connectivity
    - **Property 7: Road Connectivity**
    - **Validates: Requirements 2.2**

- [ ] 6. Implement Pathfinding
  - [ ] 6.1 Create pathfinding utility
    - Implement `scripts/city/utils/pathfinding.gd`
    - A* algorithm with heuristics
    - _Requirements: 2.3_
  - [ ] 6.2 Implement landmark system for optimization
    - Precompute landmarks at key intersections
    - Cache frequently used routes
    - _Requirements: 2.3, 2.4_
  - [ ] 6.3 Implement PathResult class
    - Return path, cost, estimated_time
    - Support road-only and off-road modes
    - _Requirements: 2.5_
  - [ ] 6.4 Write property test for pathfinding validity
    - **Property 2: Pathfinding Validity**
    - **Validates: Requirements 2.3, 2.5**

- [ ] 7. Checkpoint - Roads and pathfinding complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 4: Zone and Building Systems

- [ ] 8. Implement ZoneSystem
  - [ ] 8.1 Create ZoneData class and ZoneType enum
    - Implement `scripts/city/systems/zone_system.gd`
    - Support 6 zone types: Residential, Commercial, Industrial, Agricultural, Military, Restricted
    - _Requirements: 3.1_
  - [ ] 8.2 Implement zone creation with lot subdivision
    - Automatically create buildable lots within zones
    - Track zone statistics
    - _Requirements: 3.2, 3.4_
  - [ ] 8.3 Implement zone restrictions
    - Enforce building type restrictions per zone
    - _Requirements: 3.3_

- [ ] 9. Implement BuildingSystem
  - [ ] 9.1 Create BuildingData class and BuildingType enum
    - Implement `scripts/city/systems/building_system.gd`
    - Define 20+ building types with unique sizes
    - _Requirements: 4.1, 22.1-22.6_
  - [ ] 9.2 Create building templates data
    - Implement `scripts/city/data/building_templates.gd`
    - Define sizes, capacities, production/consumption for each type
    - _Requirements: 22.6, 4.5_
  - [ ] 9.3 Implement building construction
    - construct_building with resource deduction and time
    - Mark tiles as occupied
    - _Requirements: 4.3_
  - [ ] 9.4 Write property test for building placement
    - **Property 3: Building Placement Integrity**
    - **Validates: Requirements 4.1, 4.3**
  - [ ] 9.5 Implement building upgrades and destruction
    - upgrade_building, destroy_building, repair_building
    - Handle occupant displacement
    - _Requirements: 4.4, 4.6_

- [ ] 10. Checkpoint - Zones and buildings complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 5: Citizen System

- [ ] 11. Implement CitizenSystem
  - [ ] 11.1 Create CitizenData class and enums
    - Implement `scripts/city/systems/citizen_system.gd`
    - Define NeedType, Activity enums
    - _Requirements: 5.1, 5.2_
  - [ ] 11.2 Implement need tracking and decay
    - Track 6 needs: hunger, thirst, rest, happiness, health, safety
    - Implement decay rates from config
    - _Requirements: 5.1_
  - [ ] 11.3 Write property test for need bounds
    - **Property 4: Citizen Need Bounds**
    - **Validates: Requirements 5.1**
  - [ ] 11.4 Implement autonomous decision-making
    - Priority-based need fulfillment
    - Seek resources when needs are critical
    - _Requirements: 5.2, 5.3_
  - [ ] 11.5 Implement daily schedules
    - ScheduleEntry class with hour, activity, location
    - Work, rest, leisure activities
    - _Requirements: 5.5_
  - [ ] 11.6 Implement citizen attributes
    - Skills, faction affiliation, relationships
    - _Requirements: 5.6_
  - [ ] 11.7 Implement home and job assignment
    - assign_job, housing capacity checks
    - Immigration slowdown when over capacity
    - _Requirements: 5.4, 5.7_

- [ ] 12. Checkpoint - Citizens complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 6: Economy System

- [ ] 13. Implement EconomySystem
  - [ ] 13.1 Create ResourceData class and ResourceType enum
    - Implement `scripts/city/systems/economy_system.gd`
    - Track 9 resources: Food, Water, Caps, Materials, Power, Medicine, Weapons, Fuel, Components
    - _Requirements: 6.1_
  - [ ] 13.2 Implement production and consumption tracking
    - Calculate rates from all buildings
    - _Requirements: 6.2, 6.3_
  - [ ] 13.3 Write property test for resource conservation
    - **Property 5: Resource Conservation**
    - **Validates: Requirements 6.2, 6.3**
  - [ ] 13.4 Implement dynamic pricing
    - Price increases when demand > supply
    - Price decreases when supply > demand
    - _Requirements: 6.4, 6.5_
  - [ ] 13.5 Implement trade system
    - TradeOffer class, external settlement trade
    - _Requirements: 6.6_
  - [ ] 13.6 Implement economic reports
    - Statistics and trends
    - _Requirements: 6.7_

- [ ] 14. Checkpoint - Economy complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 7: Faction System

- [ ] 15. Implement FactionSystem
  - [ ] 15.1 Create FactionData class and RelationType enum
    - Implement `scripts/city/systems/faction_system.gd`
    - _Requirements: 12.1_
  - [ ] 15.2 Implement territory control
    - claim_territory, get_faction_at
    - Ensure territory exclusivity
    - _Requirements: 12.2_
  - [ ] 15.3 Write property test for territory exclusivity
    - **Property 6: Faction Territory Exclusivity**
    - **Validates: Requirements 12.2**
  - [ ] 15.4 Implement faction relations
    - Allied, Friendly, Neutral, Unfriendly, Hostile
    - _Requirements: 12.3_
  - [ ] 15.5 Implement territorial disputes
    - Trigger conflicts when factions clash
    - _Requirements: 12.4_
  - [ ] 15.6 Implement player reputation
    - Track reputation per faction
    - _Requirements: 12.6, 17.1-17.5_

- [ ] 16. Checkpoint - Factions complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 8: Infrastructure Systems

- [ ] 17. Implement PowerSystem
  - [ ] 17.1 Create power grid implementation
    - Implement `scripts/city/systems/power_system.gd`
    - Track generation and consumption
    - _Requirements: 19.1, 19.2_
  - [ ] 17.2 Implement power connections
    - Connection range, conduits
    - _Requirements: 19.3, 19.5_
  - [ ] 17.3 Write property test for power grid consistency
    - **Property 8: Power Grid Consistency**
    - **Validates: Requirements 19.3, 19.4**
  - [ ] 17.4 Implement power shortage effects
    - Reduce building functionality when power insufficient
    - _Requirements: 19.4_

- [ ] 18. Implement WaterSystem
  - [ ] 18.1 Create water network implementation
    - Implement `scripts/city/systems/water_system.gd`
    - Track sources: Wells, Purifiers, Rivers
    - _Requirements: 20.1, 20.2_
  - [ ] 18.2 Implement pipe network
    - Distribution through pipes
    - _Requirements: 20.3_
  - [ ] 18.3 Implement water quality
    - Dirty, clean, purified levels
    - Health effects from contamination
    - _Requirements: 20.4, 20.5_

- [ ] 19. Checkpoint - Infrastructure complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 9: Weather and Events

- [ ] 20. Implement WeatherSystem
  - [ ] 20.1 Create weather implementation
    - Implement `scripts/city/systems/weather_system.gd`
    - Support 7 weather types
    - _Requirements: 13.1_
  - [ ] 20.2 Implement weather effects
    - Visibility, movement speed, radiation damage
    - Citizens seek shelter during hazards
    - _Requirements: 13.2, 13.3, 13.4_
  - [ ] 20.3 Implement day/night cycle
    - 24-hour simulation
    - Affect resource production
    - _Requirements: 13.5, 13.6_

- [ ] 21. Implement EventSystem
  - [ ] 21.1 Create event implementation
    - Implement `scripts/city/systems/event_system.gd`
    - Support Raids, Traders, Disasters, Opportunities
    - _Requirements: 9.1_
  - [ ] 21.2 Implement event triggers and notifications
    - Notify player and affected citizens
    - _Requirements: 9.2_
  - [ ] 21.3 Implement event scaling
    - Frequency and intensity based on prosperity
    - _Requirements: 9.3_
  - [ ] 21.4 Implement event chains
    - Consequences and branching outcomes
    - _Requirements: 9.4_

- [ ] 22. Checkpoint - Weather and events complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 10: Defense System

- [ ] 23. Implement DefenseSystem
  - [ ] 23.1 Create defense structures
    - Implement `scripts/city/systems/defense_system.gd`
    - Walls, Gates, Guard Towers, Turrets, Traps
    - _Requirements: 15.1_
  - [ ] 23.2 Implement defense rating calculation
    - Sum of all active defense structures
    - _Requirements: 15.2_
  - [ ] 23.3 Write property test for defense rating
    - **Property 10: Defense Rating Calculation**
    - **Validates: Requirements 15.2**
  - [ ] 23.4 Implement automatic engagement
    - Defenses engage hostiles during raids
    - Track ammunition
    - _Requirements: 15.3, 15.4_
  - [ ] 23.5 Implement guard patrols
    - Guard NPCs with patrol routes
    - _Requirements: 15.5_
  - [ ] 23.6 Implement early warning
    - Alert for incoming threats
    - _Requirements: 15.6_

- [ ] 24. Checkpoint - Defense complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 11: Additional Systems

- [ ] 25. Implement VehicleSystem
  - [ ] 25.1 Create vehicle implementation
    - Implement `scripts/city/systems/vehicle_system.gd`
    - Car, Motorcycle, Truck, Vertibird
    - _Requirements: 14.1_
  - [ ] 25.2 Implement vehicle mechanics
    - Condition, fuel, cargo capacity
    - Physics with acceleration and turning
    - _Requirements: 14.2, 14.4_
  - [ ] 25.3 Implement vehicle combat and upgrades
    - Damage, customization
    - _Requirements: 14.5, 14.6_

- [ ] 26. Implement CraftingSystem
  - [ ] 26.1 Create crafting implementation
    - Implement `scripts/city/systems/crafting_system.gd`
    - Weapons, Armor, Chems, Food, Components
    - _Requirements: 18.1_
  - [ ] 26.2 Implement workbench requirements
    - Different benches for different crafting
    - _Requirements: 18.2_
  - [ ] 26.3 Implement crafting mechanics
    - Material consumption, skill levels, recipes
    - _Requirements: 18.3, 18.4, 18.5_

- [ ] 27. Implement QuestSystem
  - [ ] 27.1 Create quest implementation
    - Implement `scripts/city/systems/quest_system.gd`
    - Generate quests from city problems
    - _Requirements: 16.1_
  - [ ] 27.2 Implement quest types
    - Fetch, Eliminate, Escort, Build, Investigate
    - _Requirements: 16.2_
  - [ ] 27.3 Implement quest tracking and rewards
    - Progress, objectives, completion rewards
    - _Requirements: 16.3, 16.4_
  - [ ] 27.4 Implement quest chains
    - Branching outcomes, faction integration
    - _Requirements: 16.5, 16.6_

- [ ] 28. Checkpoint - Additional systems complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 12: Rendering System

- [ ] 29. Implement CityRenderer
  - [ ] 29.1 Create main renderer
    - Implement `scripts/city/rendering/city_renderer.gd`
    - Isometric projection with proper tile rendering
    - _Requirements: 7.1_
  - [ ] 29.2 Implement depth sorting
    - Correct visual layering for all entities
    - _Requirements: 7.2_
  - [ ] 29.3 Implement camera controls
    - Smooth movement, zoom 0.25x to 4x
    - _Requirements: 7.3_

- [ ] 30. Implement specialized renderers
  - [ ] 30.1 Create BuildingRenderer
    - 3D-looking isometric cubes with shading
    - Visual variants (damaged, pristine, makeshift)
    - _Requirements: 7.4, 22.7_
  - [ ] 30.2 Create CitizenRenderer
    - Animated citizens moving along paths
    - _Requirements: 7.5_
  - [ ] 30.3 Create RoadRenderer
    - Curved roads, intersections, sidewalks
    - _Requirements: 21.1, 21.6_
  - [ ] 30.4 Create WeatherRenderer
    - Day/night cycle, weather effects
    - _Requirements: 7.6_

- [ ] 31. Checkpoint - Rendering complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 13: Player Integration

- [ ] 32. Implement Player System
  - [ ] 32.1 Update PlayerCity for new systems
    - Integrate with GridSystem for movement
    - Restrict to walkable tiles
    - _Requirements: 8.1, 8.2_
  - [ ] 32.2 Implement camera follow
    - Smooth follow with configurable offset
    - _Requirements: 8.3_
  - [ ] 32.3 Implement building interaction
    - Enable interaction when approaching buildings
    - _Requirements: 8.4_
  - [ ] 32.4 Integrate with Critter/SPECIAL system
    - Display player stats in UI
    - _Requirements: 8.5, 8.6_

- [ ] 33. Checkpoint - Player integration complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 14: Save/Load and Performance

- [ ] 34. Implement Save System
  - [ ] 34.1 Create CityState serialization
    - Implement `scripts/city/utils/serialization.gd`
    - Serialize all system states
    - _Requirements: 10.1_
  - [ ] 34.2 Implement save slots
    - Multiple save support
    - _Requirements: 10.2_
  - [ ] 34.3 Implement load with validation
    - Restore exact state, validate integrity
    - _Requirements: 10.3, 10.4_

- [ ] 35. Implement Performance Optimizations
  - [ ] 35.1 Create SpatialHash utility
    - Implement `scripts/city/utils/spatial_hash.gd`
    - Efficient entity queries
    - _Requirements: 11.2_
  - [ ] 35.2 Implement LOD system
    - Level of detail for distant entities
    - _Requirements: 11.3_
  - [ ] 35.3 Implement draw call batching
    - Batch similar entities
    - _Requirements: 11.4_
  - [ ] 35.4 Implement object pooling
    - Pool frequently created/destroyed objects
    - _Requirements: 11.5_

- [ ] 36. Checkpoint - Save/Load and performance complete
  - Ensure all tests pass, ask the user if questions arise.

## Phase 15: Scene and UI

- [ ] 37. Create City Scene
  - [ ] 37.1 Create CityMap.tscn
    - Main scene with all systems
    - _Requirements: All_
  - [ ] 37.2 Create CityUI.tscn
    - UI panels for city stats, player stats, building menu
    - _Requirements: 8.5_
  - [ ] 37.3 Create building prefabs
    - Visual prefabs for each building type
    - _Requirements: 22.1-22.5_

- [ ] 38. Final Integration
  - [ ] 38.1 Wire all systems together
    - Connect EventBus signals
    - Initialize systems in correct order
    - _Requirements: 23.1, 23.4_
  - [ ] 38.2 Create debug tools
    - Debug overlays for each system
    - _Requirements: 23.5_

- [ ] 39. Final Checkpoint - All systems integrated
  - Ensure all tests pass, ask the user if questions arise.
