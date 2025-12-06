## CraftingSystem - Sistema de crafting e fabricação
## Gerencia receitas, bancadas de trabalho, e criação de itens
class_name CraftingSystem
extends Node

# Enums para categorias de crafting
enum CraftingCategory {
	WEAPONS,
	ARMOR,
	CHEMS,
	FOOD,
	COMPONENTS,
	TOOLS,
	AMMO
}

# Enums para tipos de bancada
enum WorkbenchType {
	WEAPON_BENCH,
	ARMOR_BENCH,
	CHEMISTRY_STATION,
	COOKING_STATION,
	ELECTRONICS_BENCH,
	GENERAL_WORKBENCH
}

# Classe para receitas de crafting
class Recipe:
	var id: String
	var name: String
	var category: CraftingCategory
	var required_workbench: WorkbenchType
	var required_materials: Dictionary  # ResourceType -> amount
	var output_item: String
	var output_quantity: int = 1
	var crafting_time: float = 5.0
	var required_skill_level: int = 0
	var skill_type: String = ""  # "repair", "science", etc
	var is_discovered: bool = false
	var quality_affected_by_skill: bool = true
	
	func _init(p_id: String, p_name: String, p_category: CraftingCategory):
		id = p_id
		name = p_name
		category = p_category
	
	func _to_string() -> String:
		return "Recipe(%s, %s)" % [id, name]

# Classe para bancadas de trabalho
class Workbench:
	var id: int
	var type: WorkbenchType
	var position: Vector2i
	var building_id: int = -1
	var is_available: bool = true
	var current_crafter_id: int = -1
	var upgrade_level: int = 1
	var efficiency_bonus: float = 1.0
	
	func _init(p_id: int, p_type: WorkbenchType, p_position: Vector2i):
		id = p_id
		type = p_type
		position = p_position
	
	func _to_string() -> String:
		return "Workbench(id=%d, type=%d, available=%s)" % [id, type, is_available]

# Classe para trabalhos de crafting em progresso
class CraftingJob:
	var id: int
	var recipe_id: String
	var crafter_id: int
	var workbench_id: int
	var start_time: float
	var duration: float
	var progress: float = 0.0
	var quality_modifier: float = 1.0
	var is_complete: bool = false
	
	func _init(p_id: int, p_recipe: String, p_crafter: int, p_workbench: int, p_duration: float):
		id = p_id
		recipe_id = p_recipe
		crafter_id = p_crafter
		workbench_id = p_workbench
		duration = p_duration
		start_time = Time.get_ticks_msec() / 1000.0
	
	func update(delta: float) -> void:
		progress += delta
		if progress >= duration:
			is_complete = true
	
	func get_progress_percentage() -> float:
		return (progress / duration) * 100.0

# Variáveis do sistema
var recipes: Dictionary = {}  # recipe_id -> Recipe
var workbenches: Dictionary = {}  # workbench_id -> Workbench
var crafting_jobs: Dictionary = {}  # job_id -> CraftingJob
var discovered_recipes: Array[String] = []
var next_workbench_id: int = 0
var next_job_id: int = 0

var event_bus: CityEventBus
var economy_system: EconomySystem
var citizen_system: CitizenSystem

func _ready() -> void:
	event_bus = get_tree().root.get_child(0).get_node_or_null("EventBus")
	economy_system = get_tree().root.get_child(0).get_node_or_null("EconomySystem")
	citizen_system = get_tree().root.get_child(0).get_node_or_null("CitizenSystem")
	
	_initialize_recipes()

func _process(delta: float) -> void:
	_update_crafting_jobs(delta)

# =============================================================================
# RECIPE INITIALIZATION
# =============================================================================

func _initialize_recipes() -> void:
	"""Inicializa todas as receitas disponíveis"""
	
	# WEAPONS
	_add_recipe("pipe_pistol", "Pipe Pistol", CraftingCategory.WEAPONS, 
		WorkbenchType.WEAPON_BENCH, {
			CityConfig.ResourceType.MATERIALS: 15.0,
			CityConfig.ResourceType.COMPONENTS: 5.0
		}, "pipe_pistol", 1, 10.0, 1, "repair")
	
	_add_recipe("combat_knife", "Combat Knife", CraftingCategory.WEAPONS,
		WorkbenchType.WEAPON_BENCH, {
			CityConfig.ResourceType.MATERIALS: 10.0
		}, "combat_knife", 1, 5.0, 0, "repair")
	
	_add_recipe("laser_pistol", "Laser Pistol", CraftingCategory.WEAPONS,
		WorkbenchType.WEAPON_BENCH, {
			CityConfig.ResourceType.MATERIALS: 25.0,
			CityConfig.ResourceType.COMPONENTS: 15.0
		}, "laser_pistol", 1, 20.0, 3, "science")
	
	# ARMOR
	_add_recipe("leather_armor", "Leather Armor", CraftingCategory.ARMOR,
		WorkbenchType.ARMOR_BENCH, {
			CityConfig.ResourceType.MATERIALS: 20.0
		}, "leather_armor", 1, 15.0, 1, "repair")
	
	_add_recipe("metal_armor", "Metal Armor", CraftingCategory.ARMOR,
		WorkbenchType.ARMOR_BENCH, {
			CityConfig.ResourceType.MATERIALS: 40.0,
			CityConfig.ResourceType.COMPONENTS: 10.0
		}, "metal_armor", 1, 25.0, 2, "repair")
	
	# CHEMS
	_add_recipe("stimpak", "Stimpak", CraftingCategory.CHEMS,
		WorkbenchType.CHEMISTRY_STATION, {
			CityConfig.ResourceType.MEDICINE: 5.0,
			CityConfig.ResourceType.COMPONENTS: 2.0
		}, "stimpak", 1, 8.0, 1, "science")
	
	_add_recipe("rad_x", "Rad-X", CraftingCategory.CHEMS,
		WorkbenchType.CHEMISTRY_STATION, {
			CityConfig.ResourceType.MEDICINE: 3.0,
			CityConfig.ResourceType.COMPONENTS: 1.0
		}, "rad_x", 1, 6.0, 1, "science")
	
	_add_recipe("psycho", "Psycho", CraftingCategory.CHEMS,
		WorkbenchType.CHEMISTRY_STATION, {
			CityConfig.ResourceType.MEDICINE: 8.0,
			CityConfig.ResourceType.COMPONENTS: 3.0
		}, "psycho", 1, 12.0, 2, "science")
	
	# FOOD
	_add_recipe("cooked_meat", "Cooked Meat", CraftingCategory.FOOD,
		WorkbenchType.COOKING_STATION, {
			CityConfig.ResourceType.FOOD: 2.0
		}, "cooked_meat", 1, 3.0, 0, "survival")
	
	_add_recipe("purified_water", "Purified Water", CraftingCategory.FOOD,
		WorkbenchType.COOKING_STATION, {
			CityConfig.ResourceType.WATER: 2.0
		}, "purified_water", 1, 2.0, 0, "survival")
	
	_add_recipe("wasteland_stew", "Wasteland Stew", CraftingCategory.FOOD,
		WorkbenchType.COOKING_STATION, {
			CityConfig.ResourceType.FOOD: 5.0,
			CityConfig.ResourceType.WATER: 2.0
		}, "wasteland_stew", 1, 8.0, 1, "survival")
	
	# COMPONENTS
	_add_recipe("scrap_metal", "Scrap Metal", CraftingCategory.COMPONENTS,
		WorkbenchType.GENERAL_WORKBENCH, {
			CityConfig.ResourceType.MATERIALS: 5.0
		}, "scrap_metal", 3, 4.0, 0, "repair")
	
	_add_recipe("electronic_parts", "Electronic Parts", CraftingCategory.COMPONENTS,
		WorkbenchType.ELECTRONICS_BENCH, {
			CityConfig.ResourceType.COMPONENTS: 3.0
		}, "electronic_parts", 2, 6.0, 1, "science")
	
	_add_recipe("weapon_parts", "Weapon Parts", CraftingCategory.COMPONENTS,
		WorkbenchType.WEAPON_BENCH, {
			CityConfig.ResourceType.MATERIALS: 10.0,
			CityConfig.ResourceType.COMPONENTS: 5.0
		}, "weapon_parts", 1, 10.0, 2, "repair")
	
	# AMMO
	_add_recipe("10mm_ammo", "10mm Ammo", CraftingCategory.AMMO,
		WorkbenchType.WEAPON_BENCH, {
			CityConfig.ResourceType.MATERIALS: 5.0,
			CityConfig.ResourceType.COMPONENTS: 2.0
		}, "10mm_ammo", 20, 5.0, 1, "repair")
	
	_add_recipe("energy_cell", "Energy Cell", CraftingCategory.AMMO,
		WorkbenchType.ELECTRONICS_BENCH, {
			CityConfig.ResourceType.COMPONENTS: 8.0
		}, "energy_cell", 10, 8.0, 2, "science")

func _add_recipe(id: String, name: String, category: CraftingCategory, 
				workbench: WorkbenchType, materials: Dictionary, 
				output: String, quantity: int, time: float, 
				skill_level: int, skill_type: String) -> void:
	"""Adiciona uma receita ao sistema"""
	var recipe = Recipe.new(id, name, category)
	recipe.required_workbench = workbench
	recipe.required_materials = materials
	recipe.output_item = output
	recipe.output_quantity = quantity
	recipe.crafting_time = time
	recipe.required_skill_level = skill_level
	recipe.skill_type = skill_type
	recipes[id] = recipe

# =============================================================================
# WORKBENCH MANAGEMENT
# =============================================================================

func create_workbench(type: WorkbenchType, position: Vector2i, building_id: int = -1) -> int:
	"""Cria uma nova bancada de trabalho"""
	var workbench_id = next_workbench_id
	next_workbench_id += 1
	
	var workbench = Workbench.new(workbench_id, type, position)
	workbench.building_id = building_id
	workbenches[workbench_id] = workbench
	
	if event_bus:
		event_bus.workbench_used.emit(workbench_id, -1)
	
	return workbench_id

func destroy_workbench(workbench_id: int) -> void:
	"""Destrói uma bancada de trabalho"""
	if not workbenches.has(workbench_id):
		return
	
	# Cancela trabalhos em progresso
	for job in crafting_jobs.values():
		if job.workbench_id == workbench_id:
			cancel_crafting(job.id)
	
	workbenches.erase(workbench_id)

func get_workbench(workbench_id: int) -> Workbench:
	"""Obtém uma bancada de trabalho"""
	return workbenches.get(workbench_id)

func get_workbenches_by_type(type: WorkbenchType) -> Array[Workbench]:
	"""Obtém todas as bancadas de um tipo"""
	var result: Array[Workbench] = []
	for workbench in workbenches.values():
		if workbench.type == type:
			result.append(workbench)
	return result

func get_available_workbenches(type: WorkbenchType) -> Array[Workbench]:
	"""Obtém bancadas disponíveis de um tipo"""
	var result: Array[Workbench] = []
	for workbench in workbenches.values():
		if workbench.type == type and workbench.is_available:
			result.append(workbench)
	return result

func is_workbench_available(workbench_id: int) -> bool:
	"""Verifica se uma bancada está disponível"""
	if not workbenches.has(workbench_id):
		return false
	return workbenches[workbench_id].is_available

func upgrade_workbench(workbench_id: int) -> bool:
	"""Melhora uma bancada de trabalho"""
	if not workbenches.has(workbench_id):
		return false
	
	var workbench = workbenches[workbench_id]
	workbench.upgrade_level += 1
	workbench.efficiency_bonus = 1.0 + (workbench.upgrade_level - 1) * 0.2
	
	return true

# =============================================================================
# RECIPE MANAGEMENT
# =============================================================================

func get_recipe(recipe_id: String) -> Recipe:
	"""Obtém uma receita"""
	return recipes.get(recipe_id)

func get_recipes_by_category(category: CraftingCategory) -> Array[Recipe]:
	"""Obtém receitas por categoria"""
	var result: Array[Recipe] = []
	for recipe in recipes.values():
		if recipe.category == category:
			result.append(recipe)
	return result

func get_craftable_recipes(crafter_id: int) -> Array[Recipe]:
	"""Obtém receitas que podem ser craftadas por um cidadão"""
	var result: Array[Recipe] = []
	
	for recipe in recipes.values():
		if can_craft_recipe(recipe.id, crafter_id):
			result.append(recipe)
	
	return result

func discover_recipe(recipe_id: String) -> bool:
	"""Descobre uma receita"""
	if not recipes.has(recipe_id):
		return false
	
	if recipe_id in discovered_recipes:
		return false
	
	recipes[recipe_id].is_discovered = true
	discovered_recipes.append(recipe_id)
	
	if event_bus:
		event_bus.recipe_discovered.emit(recipe_id)
	
	return true

func is_recipe_discovered(recipe_id: String) -> bool:
	"""Verifica se uma receita foi descoberta"""
	return recipe_id in discovered_recipes

func get_discovered_recipes() -> Array[Recipe]:
	"""Obtém todas as receitas descobertas"""
	var result: Array[Recipe] = []
	for recipe_id in discovered_recipes:
		if recipes.has(recipe_id):
			result.append(recipes[recipe_id])
	return result

# =============================================================================
# CRAFTING OPERATIONS
# =============================================================================

func can_craft_recipe(recipe_id: String, crafter_id: int) -> bool:
	"""Verifica se uma receita pode ser craftada"""
	if not recipes.has(recipe_id):
		return false
	
	var recipe = recipes[recipe_id]
	
	# Verifica se a receita foi descoberta
	if not recipe.is_discovered and recipe_id not in discovered_recipes:
		return false
	
	# Verifica se há bancada disponível
	var available_benches = get_available_workbenches(recipe.required_workbench)
	if available_benches.is_empty():
		return false
	
	# Verifica materiais
	if economy_system:
		for resource_type in recipe.required_materials:
			var required = recipe.required_materials[resource_type]
			var available = economy_system.get_resource_amount(resource_type)
			if available < required:
				return false
	
	# Verifica nível de habilidade (se houver sistema de cidadãos)
	if citizen_system and crafter_id >= 0:
		var citizen = citizen_system.get_citizen(crafter_id)
		if citizen:
			var skill_level = citizen.skills.get(recipe.skill_type, 0)
			if skill_level < recipe.required_skill_level:
				return false
	
	return true

func start_crafting(recipe_id: String, crafter_id: int, workbench_id: int = -1) -> int:
	"""Inicia um trabalho de crafting"""
	if not can_craft_recipe(recipe_id, crafter_id):
		return -1
	
	var recipe = recipes[recipe_id]
	
	# Encontra bancada se não especificada
	if workbench_id < 0:
		var available = get_available_workbenches(recipe.required_workbench)
		if available.is_empty():
			return -1
		workbench_id = available[0].id
	
	var workbench = workbenches.get(workbench_id)
	if not workbench or not workbench.is_available:
		return -1
	
	# Consome materiais
	if economy_system:
		for resource_type in recipe.required_materials:
			var amount = recipe.required_materials[resource_type]
			if not economy_system.consume_resource(resource_type, amount):
				return -1
	
	# Calcula duração com bônus de eficiência
	var duration = recipe.crafting_time / workbench.efficiency_bonus
	
	# Cria trabalho
	var job_id = next_job_id
	next_job_id += 1
	
	var job = CraftingJob.new(job_id, recipe_id, crafter_id, workbench_id, duration)
	
	# Calcula modificador de qualidade baseado em habilidade
	if recipe.quality_affected_by_skill and citizen_system and crafter_id >= 0:
		var citizen = citizen_system.get_citizen(crafter_id)
		if citizen:
			var skill_level = citizen.skills.get(recipe.skill_type, 0)
			job.quality_modifier = 1.0 + (skill_level * 0.1)
	
	crafting_jobs[job_id] = job
	workbench.is_available = false
	workbench.current_crafter_id = crafter_id
	
	if event_bus:
		event_bus.crafting_started.emit(crafter_id, recipe_id)
		event_bus.workbench_used.emit(workbench_id, crafter_id)
	
	return job_id

func cancel_crafting(job_id: int) -> bool:
	"""Cancela um trabalho de crafting"""
	if not crafting_jobs.has(job_id):
		return false
	
	var job = crafting_jobs[job_id]
	
	# Libera bancada
	if workbenches.has(job.workbench_id):
		var workbench = workbenches[job.workbench_id]
		workbench.is_available = true
		workbench.current_crafter_id = -1
	
	crafting_jobs.erase(job_id)
	
	if event_bus:
		event_bus.crafting_failed.emit(job.crafter_id, job.recipe_id, "Cancelled")
	
	return true

func _update_crafting_jobs(delta: float) -> void:
	"""Atualiza trabalhos de crafting em progresso"""
	var completed_jobs: Array[int] = []
	
	for job in crafting_jobs.values():
		job.update(delta)
		
		if job.is_complete:
			completed_jobs.append(job.id)
	
	# Completa trabalhos finalizados
	for job_id in completed_jobs:
		_complete_crafting(job_id)

func _complete_crafting(job_id: int) -> void:
	"""Completa um trabalho de crafting"""
	if not crafting_jobs.has(job_id):
		return
	
	var job = crafting_jobs[job_id]
	var recipe = recipes.get(job.recipe_id)
	
	if not recipe:
		cancel_crafting(job_id)
		return
	
	# Libera bancada
	if workbenches.has(job.workbench_id):
		var workbench = workbenches[job.workbench_id]
		workbench.is_available = true
		workbench.current_crafter_id = -1
	
	# Cria item (aqui você integraria com um sistema de inventário)
	var item_id = recipe.output_item
	var quantity = recipe.output_quantity
	
	crafting_jobs.erase(job_id)
	
	if event_bus:
		event_bus.crafting_completed.emit(job.crafter_id, job.recipe_id, item_id)

func get_crafting_job(job_id: int) -> CraftingJob:
	"""Obtém um trabalho de crafting"""
	return crafting_jobs.get(job_id)

func get_active_jobs() -> Array[CraftingJob]:
	"""Obtém todos os trabalhos ativos"""
	return crafting_jobs.values()

func get_jobs_by_crafter(crafter_id: int) -> Array[CraftingJob]:
	"""Obtém trabalhos de um crafter específico"""
	var result: Array[CraftingJob] = []
	for job in crafting_jobs.values():
		if job.crafter_id == crafter_id:
			result.append(job)
	return result

# =============================================================================
# ITEM MODIFICATION
# =============================================================================

func can_modify_item(item_id: String, modification_id: String) -> bool:
	"""Verifica se um item pode ser modificado"""
	# Implementação básica - expandir conforme necessário
	return true

func modify_item(item_id: String, modification_id: String, crafter_id: int) -> bool:
	"""Modifica um item existente"""
	# Implementação básica - expandir conforme necessário
	if not can_modify_item(item_id, modification_id):
		return false
	
	# Aqui você adicionaria a lógica de modificação
	return true

# =============================================================================
# STATISTICS
# =============================================================================

func get_total_recipes() -> int:
	"""Obtém o número total de receitas"""
	return recipes.size()

func get_discovered_recipe_count() -> int:
	"""Obtém o número de receitas descobertas"""
	return discovered_recipes.size()

func get_discovery_percentage() -> float:
	"""Obtém a porcentagem de receitas descobertas"""
	if recipes.is_empty():
		return 0.0
	return (float(discovered_recipes.size()) / float(recipes.size())) * 100.0

func get_workbench_count() -> int:
	"""Obtém o número de bancadas"""
	return workbenches.size()

func get_active_job_count() -> int:
	"""Obtém o número de trabalhos ativos"""
	return crafting_jobs.size()

func get_crafting_stats() -> Dictionary:
	"""Obtém estatísticas do sistema de crafting"""
	return {
		"total_recipes": get_total_recipes(),
		"discovered_recipes": get_discovered_recipe_count(),
		"discovery_percentage": get_discovery_percentage(),
		"total_workbenches": get_workbench_count(),
		"active_jobs": get_active_job_count(),
		"recipes_by_category": _get_recipes_by_category_stats()
	}

func _get_recipes_by_category_stats() -> Dictionary:
	"""Obtém estatísticas de receitas por categoria"""
	var stats = {}
	for category in CraftingCategory.values():
		stats[category] = 0
	
	for recipe in recipes.values():
		stats[recipe.category] += 1
	
	return stats

# =============================================================================
# SERIALIZATION
# =============================================================================

func serialize() -> Dictionary:
	"""Serializa o estado do sistema de crafting"""
	var workbench_data: Array[Dictionary] = []
	for workbench in workbenches.values():
		workbench_data.append({
			"id": workbench.id,
			"type": workbench.type,
			"position": workbench.position,
			"building_id": workbench.building_id,
			"is_available": workbench.is_available,
			"upgrade_level": workbench.upgrade_level,
			"efficiency_bonus": workbench.efficiency_bonus
		})
	
	var job_data: Array[Dictionary] = []
	for job in crafting_jobs.values():
		job_data.append({
			"id": job.id,
			"recipe_id": job.recipe_id,
			"crafter_id": job.crafter_id,
			"workbench_id": job.workbench_id,
			"progress": job.progress,
			"duration": job.duration,
			"quality_modifier": job.quality_modifier
		})
	
	return {
		"workbenches": workbench_data,
		"crafting_jobs": job_data,
		"discovered_recipes": discovered_recipes.duplicate(),
		"next_workbench_id": next_workbench_id,
		"next_job_id": next_job_id
	}

func deserialize(data: Dictionary) -> void:
	"""Desserializa o estado do sistema de crafting"""
	workbenches.clear()
	crafting_jobs.clear()
	discovered_recipes.clear()
	
	next_workbench_id = data.get("next_workbench_id", 0)
	next_job_id = data.get("next_job_id", 0)
	
	for workbench_data in data.get("workbenches", []):
		var workbench = Workbench.new(
			workbench_data["id"],
			workbench_data["type"],
			workbench_data["position"]
		)
		workbench.building_id = workbench_data.get("building_id", -1)
		workbench.is_available = workbench_data.get("is_available", true)
		workbench.upgrade_level = workbench_data.get("upgrade_level", 1)
		workbench.efficiency_bonus = workbench_data.get("efficiency_bonus", 1.0)
		workbenches[workbench.id] = workbench
	
	for job_data in data.get("crafting_jobs", []):
		var job = CraftingJob.new(
			job_data["id"],
			job_data["recipe_id"],
			job_data["crafter_id"],
			job_data["workbench_id"],
			job_data["duration"]
		)
		job.progress = job_data.get("progress", 0.0)
		job.quality_modifier = job_data.get("quality_modifier", 1.0)
		crafting_jobs[job.id] = job
	
	discovered_recipes = data.get("discovered_recipes", [])
	
	# Marca receitas como descobertas
	for recipe_id in discovered_recipes:
		if recipes.has(recipe_id):
			recipes[recipe_id].is_discovered = true
