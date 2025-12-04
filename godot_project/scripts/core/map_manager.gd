extends Node2D

## Gerenciador de mapas
## Carrega e renderiza mapas do Fallout 2

@export var map_name: String = ""
@export var map_data_path: String = ""

var map_data: Dictionary = {}
var tiles: Array = []
var objects: Array = []

func _ready():
	if map_data_path != "":
		load_map_data(map_data_path)
	elif map_name != "":
		load_map_by_name(map_name)

func load_map_data(path: String):
	"""Carrega dados do mapa de um arquivo JSON"""
	print("MapManager: Carregando mapa de: ", path)
	
	if not ResourceLoader.exists(path):
		print("MapManager: Arquivo não encontrado: ", path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		
		if error == OK:
			map_data = json.data
			apply_map_data()
		else:
			print("MapManager: Erro ao parsear JSON: ", error)
	else:
		print("MapManager: Erro ao abrir arquivo")

func load_map_by_name(name: String):
	"""Carrega mapa pelo nome"""
	map_name = name
	var path = "res://assets/data/maps/" + name + ".json"
	load_map_data(path)

func apply_map_data():
	"""Aplica dados do mapa à cena"""
	print("MapManager: Aplicando dados do mapa: ", map_name)
	
	if map_data.has("tiles"):
		create_tiles(map_data.tiles)
	
	if map_data.has("objects"):
		create_objects(map_data.objects)
	
	print("MapManager: Mapa carregado com sucesso")

func create_tiles(tile_data: Array):
	"""Cria tiles no mapa"""
	# TODO: Implementar criação de tiles
	print("MapManager: Criando ", tile_data.size(), " tiles")

func create_objects(object_data: Array):
	"""Cria objetos no mapa"""
	# TODO: Implementar criação de objetos
	print("MapManager: Criando ", object_data.size(), " objetos")

