## Test BuildingRenderer - Verifica renderização de edifícios
## Tests the BuildingRenderer implementation for 3D isometric cubes with shading and visual variants

class_name TestBuildingRenderer
extends GdUnitTestSuite

var building_renderer: BuildingRenderer
var building_system: BuildingSystem
var grid_system: GridSystem
var building_templates: BuildingTemplates
var event_bus: EventBus
var test_canvas: Node2D

func before_each() -> void:
	# Inicializar sistemas
	event_bus = EventBus.new()
	grid_system = GridSystem.new()
	building_system = BuildingSystem.new()
	building_templates = BuildingTemplates.new()
	building_renderer = BuildingRenderer.new()
	test_canvas = Node2D.new()
	
	# Configurar sistemas
	grid_system.initialize(Vector2i(50, 50))
	building_system.set_systems(grid_system, null, event_bus)
	building_templates._ready()
	building_renderer.set_systems(grid_system, building_system, building_templates)
	building_renderer.set_tile_size(64.0, 32.0)

func after_each() -> void:
	if test_canvas:
		test_canvas.free()

## Test visual variants based on building condition
func test_visual_variants() -> void:
	# Criar edifício de teste
	var building_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE,
		Vector2i(10, 10),
		Vector2i(3, 3)
	)
	
	assert_that(building_id).is_greater_than_or_equal_to(0)
	var building = building_system.get_building(building_id)
	assert_that(building).is_not_null()
	
	# Testar variantes baseadas na condição
	building.condition = 95.0
	var variant = building_renderer.get_visual_variant(building)
	assert_that(variant).is_equal(BuildingRenderer.VisualVariant.PRISTINE)
	
	building.condition = 75.0
	variant = building_renderer.get_visual_variant(building)
	assert_that(variant).is_equal(BuildingRenderer.VisualVariant.GOOD)
	
	building.condition = 50.0
	variant = building_renderer.get_visual_variant(building)
	assert_that(variant).is_equal(BuildingRenderer.VisualVariant.DAMAGED)
	
	building.condition = 20.0
	variant = building_renderer.get_visual_variant(building)
	assert_that(variant).is_equal(BuildingRenderer.VisualVariant.RUINED)
	
	building.condition = 5.0
	variant = building_renderer.get_visual_variant(building)
	assert_that(variant).is_equal(BuildingRenderer.VisualVariant.MAKESHIFT)

## Test building colors for different types
func test_building_colors() -> void:
	# Testar cores para diferentes tipos
	var house_color = building_renderer.get_building_base_color(BuildingSystem.BuildingType.SMALL_HOUSE)
	assert_that(house_color).is_not_equal(Color.WHITE)
	
	var shop_color = building_renderer.get_building_base_color(BuildingSystem.BuildingType.SHOP)
	assert_that(shop_color).is_not_equal(house_color)
	
	var factory_color = building_renderer.get_building_base_color(BuildingSystem.BuildingType.FACTORY)
	assert_that(factory_color).is_not_equal(shop_color)
	
	# Testar modificadores de variante
	var base_color = Color(0.5, 0.5, 0.5)
	var pristine = building_renderer.apply_variant_modifier(base_color, BuildingRenderer.VisualVariant.PRISTINE)
	var damaged = building_renderer.apply_variant_modifier(base_color, BuildingRenderer.VisualVariant.DAMAGED)
	
	assert_that(pristine.v).is_greater_than(base_color.v)
	assert_that(damaged.v).is_less_than(base_color.v)

## Test building heights for different types and levels
func test_building_heights() -> void:
	# Testar alturas para diferentes tipos
	var house_height = building_renderer.get_building_height(BuildingSystem.BuildingType.SMALL_HOUSE, 1)
	var apartment_height = building_renderer.get_building_height(BuildingSystem.BuildingType.APARTMENT, 1)
	var tower_height = building_renderer.get_building_height(BuildingSystem.BuildingType.WATCHTOWER, 1)
	
	assert_that(house_height).is_greater_than(0.0)
	assert_that(apartment_height).is_greater_than(house_height)
	assert_that(tower_height).is_greater_than(apartment_height)
	
	# Testar que níveis aumentam altura
	var level1_height = building_renderer.get_building_height(BuildingSystem.BuildingType.SMALL_HOUSE, 1)
	var level2_height = building_renderer.get_building_height(BuildingSystem.BuildingType.SMALL_HOUSE, 2)
	var level3_height = building_renderer.get_building_height(BuildingSystem.BuildingType.SMALL_HOUSE, 3)
	
	assert_that(level2_height).is_greater_than(level1_height)
	assert_that(level3_height).is_greater_than(level2_height)

## Test grid to isometric coordinate conversion
func test_grid_to_iso_conversion() -> void:
	# Testar conversão de coordenadas
	var grid_pos = Vector2(10, 10)
	var iso_pos = building_renderer.grid_to_iso(grid_pos)
	
	assert_that(iso_pos).is_not_equal(grid_pos)
	assert_that(iso_pos.x).is_equal(0.0)
	assert_that(iso_pos.y).is_greater_than(0.0)
	
	# Testar origem
	var origin_iso = building_renderer.grid_to_iso(Vector2(0, 0))
	assert_that(origin_iso).is_equal(Vector2(0, 0))
	
	# Testar que diferentes posições geram diferentes coordenadas iso
	var pos1_iso = building_renderer.grid_to_iso(Vector2(5, 5))
	var pos2_iso = building_renderer.grid_to_iso(Vector2(10, 5))
	assert_that(pos1_iso).is_not_equal(pos2_iso)

## Test drawing individual buildings
func test_draw_building() -> void:
	# Criar vários edifícios de teste
	var buildings = []
	
	# Casa pequena
	var house_id = building_system.construct_building(
		BuildingSystem.BuildingType.SMALL_HOUSE,
		Vector2i(5, 5),
		Vector2i(3, 3)
	)
	buildings.append(house_id)
	
	# Loja
	var shop_id = building_system.construct_building(
		BuildingSystem.BuildingType.SHOP,
		Vector2i(10, 5),
		Vector2i(3, 3)
	)
	buildings.append(shop_id)
	
	# Fábrica
	var factory_id = building_system.construct_building(
		BuildingSystem.BuildingType.FACTORY,
		Vector2i(15, 5),
		Vector2i(6, 6)
	)
	buildings.append(factory_id)
	
	# Verificar que todos foram criados
	for building_id in buildings:
		assert_that(building_id).is_greater_than_or_equal_to(0)
		var building = building_system.get_building(building_id)
		assert_that(building).is_not_null()
		
		# Testar que podemos obter propriedades de renderização
		var color = building_renderer.get_building_base_color(building.building_type)
		var height = building_renderer.get_building_height(building.building_type, building.level)
		assert_that(height).is_greater_than(0.0)
		
		var variant = building_renderer.get_visual_variant(building)
		assert_that(variant).is_between(0, 4)
	
	# Testar renderização (não podemos testar visualmente, mas podemos verificar que não crashe)
	building_renderer.draw_building(test_canvas, building_system.get_building(house_id))
	building_renderer.draw_building(test_canvas, building_system.get_building(shop_id))
	building_renderer.draw_building(test_canvas, building_system.get_building(factory_id))

## Test drawing all buildings in batch
func test_draw_all_buildings() -> void:
	# Criar múltiplos edifícios
	for i in range(5):
		building_system.construct_building(
			BuildingSystem.BuildingType.SMALL_HOUSE,
			Vector2i(i * 4, 5),
			Vector2i(3, 3)
		)
	
	# Testar renderização em batch (não deve crashar)
	building_renderer.draw_all_buildings(test_canvas)
	
	# Verificar que todos os edifícios foram considerados
	var all_buildings = building_system.get_all_buildings()
	assert_that(all_buildings.size()).is_equal(5)

## Test that different building types have distinct visual properties
func test_building_type_distinctiveness() -> void:
	var types_to_test = [
		BuildingSystem.BuildingType.SMALL_HOUSE,
		BuildingSystem.BuildingType.SHOP,
		BuildingSystem.BuildingType.FACTORY,
		BuildingSystem.BuildingType.FARM,
		BuildingSystem.BuildingType.MEDICAL_CLINIC,
		BuildingSystem.BuildingType.WATCHTOWER
	]
	
	var colors = []
	var heights = []
	
	for building_type in types_to_test:
		var color = building_renderer.get_building_base_color(building_type)
		var height = building_renderer.get_building_height(building_type, 1)
		
		colors.append(color)
		heights.append(height)
	
	# Verificar que há variedade nas cores e alturas
	var unique_colors = []
	for color in colors:
		var is_unique = true
		for existing in unique_colors:
			if color.is_equal_approx(existing):
				is_unique = false
				break
		if is_unique:
			unique_colors.append(color)
	
	# Deve haver pelo menos 4 cores distintas
	assert_that(unique_colors.size()).is_greater_than_or_equal_to(4)
	
	# Deve haver pelo menos 4 alturas distintas
	var unique_heights = []
	for height in heights:
		if height not in unique_heights:
			unique_heights.append(height)
	assert_that(unique_heights.size()).is_greater_than_or_equal_to(4)
