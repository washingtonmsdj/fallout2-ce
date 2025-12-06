## EventBus - Sistema de comunicação entre sistemas da cidade
## Implementa padrão Observer para desacoplamento
class_name CityEventBus
extends Node

# =============================================================================
# GRID EVENTS
# =============================================================================
signal tile_changed(position: Vector2i, old_type: int, new_type: int)
signal terrain_modified(area: Rect2i)
signal grid_initialized(size: Vector2i)

# =============================================================================
# ROAD EVENTS
# =============================================================================
signal road_created(road_id: int, start: Vector2i, end: Vector2i)
signal road_destroyed(road_id: int)
signal road_damaged(road_id: int, damage: float)
signal road_repaired(road_id: int)
signal intersection_created(position: Vector2i, road_ids: Array)
signal path_calculated(from: Vector2i, to: Vector2i, path: Array)
signal path_blocked(from: Vector2i, to: Vector2i)

# =============================================================================
# ZONE EVENTS
# =============================================================================
signal zone_created(zone_id: int, type: int, area: Rect2i)
signal zone_destroyed(zone_id: int)
signal zone_type_changed(zone_id: int, old_type: int, new_type: int)
signal lot_created(lot_id: int, zone_id: int, position: Vector2i)
signal lot_occupied(lot_id: int, building_id: int)
signal lot_vacated(lot_id: int)

# =============================================================================
# BUILDING EVENTS
# =============================================================================
signal building_constructed(building_id: int, type: int, position: Vector2i)
signal building_destroyed(building_id: int, position: Vector2i)
signal building_upgraded(building_id: int, new_level: int)
signal building_damaged(building_id: int, damage: float, new_health: float)
signal building_repaired(building_id: int, amount: float, new_health: float)
signal building_production_changed(building_id: int, resource: int, rate: float)
signal building_power_changed(building_id: int, connected: bool)
signal building_water_changed(building_id: int, connected: bool)
signal building_occupant_added(building_id: int, citizen_id: int)
signal building_occupant_removed(building_id: int, citizen_id: int)

# =============================================================================
# CITIZEN EVENTS
# =============================================================================
signal citizen_spawned(citizen_id: int, position: Vector2i)
signal citizen_died(citizen_id: int, cause: String)
signal citizen_moved(citizen_id: int, from: Vector2i, to: Vector2i)
signal citizen_need_changed(citizen_id: int, need_type: int, old_value: float, new_value: float)
signal citizen_need_critical(citizen_id: int, need_type: int, value: float)
signal citizen_activity_changed(citizen_id: int, old_activity: int, new_activity: int)
signal citizen_job_assigned(citizen_id: int, building_id: int)
signal citizen_job_lost(citizen_id: int, building_id: int)
signal citizen_home_assigned(citizen_id: int, building_id: int)
signal citizen_home_lost(citizen_id: int, building_id: int)
signal citizen_faction_changed(citizen_id: int, old_faction: int, new_faction: int)

# =============================================================================
# ECONOMY EVENTS
# =============================================================================
signal resource_changed(resource_type: int, old_amount: float, new_amount: float)
signal resource_produced(resource_type: int, amount: float, source_id: int)
signal resource_consumed(resource_type: int, amount: float, consumer_id: int)
signal resource_shortage(resource_type: int, needed: float, available: float)
signal price_updated(resource_type: int, old_price: float, new_price: float)
signal trade_offer_created(offer_id: int, resource: int, amount: float, price: float)
signal trade_completed(buyer_id: int, seller_id: int, resource: int, amount: float)
signal trade_failed(offer_id: int, reason: String)

# =============================================================================
# FACTION EVENTS
# =============================================================================
signal faction_created(faction_id: int, name: String)
signal faction_destroyed(faction_id: int)
signal faction_territory_claimed(faction_id: int, tiles: Array)
signal faction_territory_lost(faction_id: int, tiles: Array)
signal faction_relation_changed(faction_a: int, faction_b: int, old_relation: int, new_relation: int)
signal faction_conflict_started(faction_a: int, faction_b: int, territory: Array)
signal faction_conflict_ended(faction_a: int, faction_b: int, winner: int)
signal player_reputation_changed(faction_id: int, old_rep: int, new_rep: int)

# =============================================================================
# WEATHER EVENTS
# =============================================================================
signal weather_changed(old_weather: int, new_weather: int, intensity: float)
signal weather_intensity_changed(weather: int, old_intensity: float, new_intensity: float)
signal time_of_day_changed(old_hour: int, new_hour: int)
signal day_changed(old_day: int, new_day: int)
signal radiation_level_changed(old_level: float, new_level: float)
signal visibility_changed(old_visibility: float, new_visibility: float)

# =============================================================================
# DEFENSE EVENTS
# =============================================================================
signal defense_built(defense_id: int, type: int, position: Vector2i)
signal defense_destroyed(defense_id: int)
signal defense_damaged(defense_id: int, damage: float)
signal defense_engaged(defense_id: int, target_id: int)
signal defense_ammo_depleted(defense_id: int)
signal guard_assigned(citizen_id: int, route: Array)
signal guard_alert(guard_id: int, threat_position: Vector2i)
signal settlement_alert(threat_type: int, threat_position: Vector2i)
signal raid_started(raid_id: int, attacker_faction: int, strength: float)
signal raid_ended(raid_id: int, result: int, casualties: Dictionary)

# =============================================================================
# POWER SYSTEM EVENTS
# =============================================================================
signal power_source_added(source_id: int, output: float)
signal power_source_removed(source_id: int)
signal power_consumer_added(consumer_id: int, demand: float)
signal power_consumer_removed(consumer_id: int)
signal power_grid_updated(total_supply: float, total_demand: float)
signal power_shortage(deficit: float)
signal power_restored()
signal conduit_placed(from: Vector2i, to: Vector2i)
signal conduit_removed(from: Vector2i, to: Vector2i)

# =============================================================================
# WATER SYSTEM EVENTS
# =============================================================================
signal water_source_added(source_id: int, output: float, quality: int)
signal water_source_removed(source_id: int)
signal water_consumer_added(consumer_id: int, demand: float)
signal water_consumer_removed(consumer_id: int)
signal water_grid_updated(total_supply: float, total_demand: float)
signal water_shortage(deficit: float)
signal water_restored()
signal water_contaminated(source_id: int, contamination_level: float)
signal water_purified(source_id: int)
signal pipe_placed(from: Vector2i, to: Vector2i)
signal pipe_removed(from: Vector2i, to: Vector2i)

# =============================================================================
# VEHICLE EVENTS
# =============================================================================
signal vehicle_spawned(vehicle_id: int, type: int, position: Vector2i)
signal vehicle_destroyed(vehicle_id: int)
signal vehicle_moved(vehicle_id: int, from: Vector2, to: Vector2)
signal vehicle_fuel_changed(vehicle_id: int, old_fuel: float, new_fuel: float)
signal vehicle_fuel_empty(vehicle_id: int)
signal vehicle_damaged(vehicle_id: int, damage: float)
signal vehicle_repaired(vehicle_id: int, amount: float)
signal vehicle_entered(vehicle_id: int, entity_id: int)
signal vehicle_exited(vehicle_id: int, entity_id: int)

# =============================================================================
# CRAFTING EVENTS
# =============================================================================
signal crafting_started(crafter_id: int, recipe_id: int)
signal crafting_completed(crafter_id: int, recipe_id: int, item_id: int)
signal crafting_failed(crafter_id: int, recipe_id: int, reason: String)
signal recipe_discovered(recipe_id: int)
signal workbench_used(workbench_id: int, crafter_id: int)

# =============================================================================
# QUEST EVENTS
# =============================================================================
signal quest_generated(quest_id: int, type: int, source: String)
signal quest_accepted(quest_id: int)
signal quest_objective_updated(quest_id: int, objective_id: int, progress: float)
signal quest_objective_completed(quest_id: int, objective_id: int)
signal quest_completed(quest_id: int, rewards: Dictionary)
signal quest_failed(quest_id: int, reason: String)
signal quest_abandoned(quest_id: int)

# =============================================================================
# EVENT SYSTEM EVENTS
# =============================================================================
signal event_triggered(event_id: int, type: int, data: Dictionary)
signal event_resolved(event_id: int, outcome: int)
signal event_chain_started(chain_id: int, first_event: int)
signal event_chain_progressed(chain_id: int, current_event: int)
signal event_chain_ended(chain_id: int, final_outcome: int)

# =============================================================================
# PLAYER EVENTS
# =============================================================================
signal player_moved(old_pos: Vector2i, new_pos: Vector2i)
signal player_entered_building(building_id: int)
signal player_exited_building(building_id: int)
signal player_interacted(target_type: String, target_id: int)
signal player_karma_changed(old_karma: int, new_karma: int)

# =============================================================================
# SAVE/LOAD EVENTS
# =============================================================================
signal save_started(slot: int)
signal save_completed(slot: int, success: bool)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool)
signal autosave_triggered()

# =============================================================================
# DEBUG EVENTS
# =============================================================================
signal debug_message(system: String, message: String, level: int)
signal performance_warning(system: String, metric: String, value: float)

# =============================================================================
# SINGLETON INSTANCE
# =============================================================================
static var instance: CityEventBus

func _init():
	if instance == null:
		instance = self

func _enter_tree():
	if instance == null:
		instance = self

static func get_instance() -> CityEventBus:
	return instance

# =============================================================================
# UTILITY METHODS
# =============================================================================

## Emite evento de debug
func emit_debug(system: String, message: String, level: int = 0):
	debug_message.emit(system, message, level)

## Emite aviso de performance
func emit_performance_warning(system: String, metric: String, value: float):
	performance_warning.emit(system, metric, value)
