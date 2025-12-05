extends Node
## Gerenciador principal do jogo
## Controla estados globais, inicialização e ciclo de vida

signal game_started
signal game_paused
signal game_resumed

enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_state(new_state: GameState) -> void:
	current_state = new_state
	match new_state:
		GameState.PLAYING:
			game_started.emit()
		GameState.PAUSED:
			game_paused.emit()
			get_tree().paused = true
		GameState.MENU:
			get_tree().paused = false
