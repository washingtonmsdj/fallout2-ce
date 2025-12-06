## ProceduralBuilding - Geração procedural de edifícios estilo Citybound
## Gera geometria 3D isométrica com variação baseada em seed
class_name ProceduralBuilding
extends RefCounted

## Materiais de construção (baseado no Citybound)
enum BuildingMaterial {
	WHITE_WALL,
	TILED_ROOF,
	FLAT_ROOF,
	FIELD_WHEAT,
	FIELD_ROWS,
	FIELD_PLANT,
	FIELD_MEADOW,
	WOODEN_FENCE,
	METAL_FENCE,
	LOT_ASPHALT,
	BRICK_WALL,
	CONCRETE,
	RUSTY_METAL,
	WOOD_PLANKS
}

## Props/decorações
enum Prop {
	SMALL_WINDOW,
	SHOP_WINDOW_GLASS,
	SHOP_WINDOW_BANNER,
	NARROW_DOOR,
	WIDE_DOOR,
	CHIMNEY,
	ANTENNA,
	AC_UNIT,
	SIGN
}

## Estilos de edifício
enum Style {
	FAMILY_HOUSE,
	APARTMENT,
	GROCERY_SHOP,
	WAREHOUSE,
	FACTORY,
	FARM_FIELD,
	WATER_TOWER,
	POWER_PLANT,
	BUNKER,
	SHACK
}

## Cores dos materiais (linear float como no Citybound)
const MATERIAL_COLORS = {
	BuildingMaterial.WHITE_WALL: Color(0.95, 0.95, 0.95),
	BuildingMaterial.TILED_ROOF: Color(0.8, 0.5, 0.2),
	BuildingMaterial.FLAT_ROOF: Color(0.5, 0.5, 0.5),
	BuildingMaterial.FIELD_WHEAT: Color(0.7, 0.7, 0.2),
	BuildingMaterial.FIELD_ROWS: Color(0.62, 0.56, 0.5),
	BuildingMaterial.FIELD_PLANT: Color(0.39, 0.58, 0.27),
	BuildingMaterial.FIELD_MEADOW: Color(0.49, 0.68, 0.37),
	BuildingMaterial.WOODEN_FENCE: Color(0.9, 0.8, 0.7),
	BuildingMaterial.METAL_FENCE: Color(0.8, 0.8, 0.8),
	BuildingMaterial.LOT_ASPHALT: Color(0.65, 0.65, 0.65),
	BuildingMaterial.BRICK_WALL: Color(0.72, 0.45, 0.35),
	BuildingMaterial.CONCRETE: Color(0.7, 0.7, 0.68),
	BuildingMaterial.RUSTY_METAL: Color(0.55, 0.4, 0.3),
	BuildingMaterial.WOOD_PLANKS: Color(0.6, 0.45, 0.3)
}

## Dados do edifício gerado
var seed_value: int
var style: int
var position: Vector2
var footprint_width: float
var footprint_depth: float
var floors: int
var floor_height: float
var total_height: float
var wall_material: int
var roof_material: int
var roof_type: int  # 0=flat, 1=gable, 2=hip
var props: Array = []  # [{type, position, direction, color}]
var condition: float = 100.0  # 0-100, afeta aparência

## RNG local para variação
var _rng: RandomNumberGenerator

func _init(p_seed: int = 0) -> void:
	seed_value = p_seed if p_seed != 0 else randi()
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

## Gera um edifício baseado no estilo
func generate(p_style: int, p_position: Vector2, p_condition: float = 100.0) -> void:
	style = p_style
	position = p_position
	condition = p_condition
	_rng.seed = seed_value
	
	match style:
		Style.FAMILY_HOUSE:
			_generate_family_house()
		Style.APARTMENT:
			_generate_apartment()
		Style.GROCERY_SHOP:
			_generate_shop()
		Style.WAREHOUSE:
			_generate_warehouse()
		Style.FACTORY:
			_generate_factory()
		Style.FARM_FIELD:
			_generate_farm()
		Style.WATER_TOWER:
			_generate_water_tower()
		Style.POWER_PLANT:
			_generate_power_plant()
		Style.BUNKER:
			_generate_bunker()
		Style.SHACK:
			_generate_shack()
		_:
			_generate_family_house()

func _generate_family_house() -> void:
	footprint_width = _rng.randf_range(8.0, 14.0)
	footprint_depth = _rng.randf_range(6.0, 10.0)
	floors = _rng.randi_range(1, 2)
	floor_height = _rng.randf_range(2.8, 3.5)
	total_height = floors * floor_height
	
	# Material baseado na condição
	if condition > 70:
		wall_material = BuildingMaterial.WHITE_WALL
	elif condition > 40:
		wall_material = BuildingMaterial.BRICK_WALL
	else:
		wall_material = BuildingMaterial.WOOD_PLANKS
	
	roof_material = BuildingMaterial.TILED_ROOF
	roof_type = 1  # Gable roof
	
	# Gerar props (janelas e porta)
	_generate_windows(2, floors)
	_add_door()

func _generate_apartment() -> void:
	footprint_width = _rng.randf_range(12.0, 20.0)
	footprint_depth = _rng.randf_range(10.0, 16.0)
	floors = _rng.randi_range(3, 6)
	floor_height = _rng.randf_range(2.5, 3.0)
	total_height = floors * floor_height
	
	wall_material = BuildingMaterial.CONCRETE if condition > 50 else BuildingMaterial.BRICK_WALL
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0
	
	_generate_windows(4, floors)
	_add_door()

func _generate_shop() -> void:
	footprint_width = _rng.randf_range(10.0, 16.0)
	footprint_depth = _rng.randf_range(8.0, 12.0)
	floors = _rng.randi_range(1, 2)
	floor_height = _rng.randf_range(3.5, 4.5)
	total_height = floors * floor_height
	
	wall_material = BuildingMaterial.WHITE_WALL
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0
	
	# Shop windows no térreo
	_add_shop_windows()
	_add_door()
	_add_sign()

func _generate_warehouse() -> void:
	footprint_width = _rng.randf_range(20.0, 35.0)
	footprint_depth = _rng.randf_range(15.0, 25.0)
	floors = 1
	floor_height = _rng.randf_range(6.0, 10.0)
	total_height = floor_height
	
	wall_material = BuildingMaterial.RUSTY_METAL if condition < 60 else BuildingMaterial.METAL_FENCE
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0
	
	_add_wide_door()

func _generate_factory() -> void:
	footprint_width = _rng.randf_range(25.0, 40.0)
	footprint_depth = _rng.randf_range(20.0, 30.0)
	floors = _rng.randi_range(2, 3)
	floor_height = _rng.randf_range(4.0, 5.0)
	total_height = floors * floor_height
	
	wall_material = BuildingMaterial.CONCRETE
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0
	
	_generate_windows(6, floors)
	_add_chimney()

func _generate_farm() -> void:
	footprint_width = _rng.randf_range(30.0, 60.0)
	footprint_depth = _rng.randf_range(30.0, 60.0)
	floors = 0
	floor_height = 0.0
	total_height = 0.5
	
	var field_types = [BuildingMaterial.FIELD_WHEAT, BuildingMaterial.FIELD_ROWS, BuildingMaterial.FIELD_PLANT, BuildingMaterial.FIELD_MEADOW]
	wall_material = field_types[_rng.randi() % field_types.size()]
	roof_material = wall_material
	roof_type = -1  # Sem telhado

func _generate_water_tower() -> void:
	footprint_width = _rng.randf_range(6.0, 10.0)
	footprint_depth = footprint_width
	floors = 1
	floor_height = _rng.randf_range(15.0, 25.0)
	total_height = floor_height
	
	wall_material = BuildingMaterial.METAL_FENCE
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0

func _generate_power_plant() -> void:
	footprint_width = _rng.randf_range(20.0, 30.0)
	footprint_depth = _rng.randf_range(15.0, 25.0)
	floors = 2
	floor_height = _rng.randf_range(5.0, 7.0)
	total_height = floors * floor_height
	
	wall_material = BuildingMaterial.CONCRETE
	roof_material = BuildingMaterial.FLAT_ROOF
	roof_type = 0
	
	_add_chimney()
	_add_chimney()

func _generate_bunker() -> void:
	footprint_width = _rng.randf_range(15.0, 25.0)
	footprint_depth = _rng.randf_range(12.0, 20.0)
	floors = 1
	floor_height = _rng.randf_range(3.0, 4.0)
	total_height = floor_height
	
	wall_material = BuildingMaterial.CONCRETE
	roof_material = BuildingMaterial.CONCRETE
	roof_type = 0

func _generate_shack() -> void:
	footprint_width = _rng.randf_range(4.0, 8.0)
	footprint_depth = _rng.randf_range(3.0, 6.0)
	floors = 1
	floor_height = _rng.randf_range(2.0, 2.8)
	total_height = floor_height
	
	wall_material = BuildingMaterial.WOOD_PLANKS if _rng.randf() > 0.5 else BuildingMaterial.RUSTY_METAL
	roof_material = BuildingMaterial.RUSTY_METAL
	roof_type = 1
	
	_generate_windows(1, 1)
	_add_door()

## Helpers para gerar props
func _generate_windows(per_floor: int, num_floors: int) -> void:
	var spacing = footprint_width / (per_floor + 1)
	for floor_idx in range(num_floors):
		var y_offset = floor_height * (floor_idx + 0.5)
		for w in range(per_floor):
			var x_offset = spacing * (w + 1) - footprint_width / 2.0
			props.append({
				"type": Prop.SMALL_WINDOW,
				"position": Vector3(x_offset, y_offset, 0),
				"direction": Vector2(0, 1),
				"color": Color(0.7, 0.6, 0.6) if condition > 50 else Color(0.3, 0.3, 0.3)
			})

func _add_door() -> void:
	props.append({
		"type": Prop.NARROW_DOOR,
		"position": Vector3(0, 0, footprint_depth / 2.0),
		"direction": Vector2(0, 1),
		"color": Color(0.5, 0.4, 0.3)
	})

func _add_wide_door() -> void:
	props.append({
		"type": Prop.WIDE_DOOR,
		"position": Vector3(0, 0, footprint_depth / 2.0),
		"direction": Vector2(0, 1),
		"color": Color(0.4, 0.4, 0.4)
	})

func _add_shop_windows() -> void:
	var num_windows = int(footprint_width / 4.0)
	var spacing = footprint_width / (num_windows + 1)
	for w in range(num_windows):
		var x_offset = spacing * (w + 1) - footprint_width / 2.0
		props.append({
			"type": Prop.SHOP_WINDOW_GLASS,
			"position": Vector3(x_offset, floor_height * 0.4, footprint_depth / 2.0),
			"direction": Vector2(0, 1),
			"color": Color(0.7, 0.8, 0.9, 0.6)
		})
		# Banner colorido
		props.append({
			"type": Prop.SHOP_WINDOW_BANNER,
			"position": Vector3(x_offset, floor_height * 0.8, footprint_depth / 2.0),
			"direction": Vector2(0, 1),
			"color": Color(_rng.randf_range(0.3, 0.8), _rng.randf_range(0.3, 0.8), _rng.randf_range(0.3, 0.8))
		})

func _add_sign() -> void:
	props.append({
		"type": Prop.SIGN,
		"position": Vector3(0, total_height + 1.0, footprint_depth / 2.0),
		"direction": Vector2(0, 1),
		"color": Color(_rng.randf_range(0.5, 1.0), _rng.randf_range(0.5, 1.0), _rng.randf_range(0.5, 1.0))
	})

func _add_chimney() -> void:
	props.append({
		"type": Prop.CHIMNEY,
		"position": Vector3(_rng.randf_range(-footprint_width * 0.3, footprint_width * 0.3), total_height, 0),
		"direction": Vector2(0, 1),
		"color": Color(0.4, 0.4, 0.4)
	})

## Retorna a cor do material com modificadores de condição
func get_material_color(mat: int) -> Color:
	var base_color = MATERIAL_COLORS.get(mat, Color.WHITE)
	
	# Aplicar degradação baseada na condição
	if condition < 30:
		return base_color.darkened(0.4).lerp(Color(0.4, 0.35, 0.3), 0.5)
	elif condition < 60:
		return base_color.darkened(0.2).lerp(Color(0.5, 0.45, 0.4), 0.3)
	elif condition < 80:
		return base_color.darkened(0.1)
	else:
		return base_color
