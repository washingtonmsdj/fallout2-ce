extends Node
## Gerenciador de salvamento e carregamento
## Lida com persistência de dados do jogador

const SAVE_PATH := "user://savegame.dat"

func save_game(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Falha ao criar arquivo de salvamento")
		return false
	
	var json_string := JSON.stringify(data)
	file.store_string(json_string)
	file.close()
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Falha ao abrir arquivo de salvamento")
		return {}
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Falha ao parsear dados de salvamento")
		return {}
	
	return json.data
