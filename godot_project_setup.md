# 🎮 Configuração do Projeto Godot

## 📋 Passo a Passo para Criar o Projeto Base

### 1. Instalar o Godot

1. Baixe o Godot 4.2 ou superior: https://godotengine.org/download
2. Extraia em uma pasta acessível
3. Execute o executável do Godot

### 2. Criar Novo Projeto

1. No Godot, clique em **"New Project"**
2. Nome do projeto: `fallout2-godot`
3. Caminho: escolha uma pasta (pode ser `fallout2-ce/godot_project`)
4. Renderer: **Forward+** (recomendado para 2D moderno)
5. Clique em **"Create & Edit"**

### 3. Configurar Estrutura de Pastas

Crie as seguintes pastas no FileSystem do Godot:

```
res://
├── scenes/
│   ├── maps/
│   ├── ui/
│   └── characters/
├── scripts/
│   ├── core/
│   ├── systems/
│   └── actors/
└── assets/
    ├── sprites/
    ├── audio/
    └── data/
```

### 4. Configurações do Projeto

#### 4.1 Configurar Display

1. Vá em **Project → Project Settings**
2. Na seção **Display → Window**:
   - **Size**: Width `1024`, Height `768`
   - **Mode**: `Windowed` (para começar)
   - **Stretch**: Mode `2d`, Aspect `keep`

#### 4.2 Configurar Input

Na seção **Input Map**, adicione as ações:
- `move_up`
- `move_down`
- `move_left`
- `move_right`
- `interact`
- `inventory`
- `pause`

### 5. Criar Cena Principal

1. Crie uma nova cena: **File → New Scene**
2. Adicione um Node2D como root, nomeie como `Game`
3. Salve como `scenes/main.tscn`

### 6. Scripts Base Necessários

#### `scripts/core/game_manager.gd`
```gdscript
extends Node

var current_map: Node2D = null
var player: Node2D = null

func _ready():
    # Inicializar jogo
    load_main_menu()
    
func load_main_menu():
    # Carregar menu principal
    pass

func start_new_game():
    # Iniciar novo jogo
    pass

func load_map(map_name: String):
    # Carregar um mapa
    pass
```

#### `scripts/core/map_manager.gd`
```gdscript
extends Node2D

@export var map_name: String = ""
@export var map_data_path: String = ""

var map_data: Dictionary = {}

func _ready():
    if map_data_path != "":
        load_map_data(map_data_path)

func load_map_data(path: String):
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        map_data = JSON.parse_string(json_string)
        file.close()
        apply_map_data()
```

#### `scripts/actors/player.gd`
```gdscript
extends CharacterBody2D

@export var speed: float = 200.0
@export var action_points: int = 10

func _physics_process(delta):
    handle_input()
    move_and_slide()

func handle_input():
    var input_vector = Vector2.ZERO
    
    if Input.is_action_pressed("move_up"):
        input_vector.y -= 1
    if Input.is_action_pressed("move_down"):
        input_vector.y += 1
    if Input.is_action_pressed("move_left"):
        input_vector.x -= 1
    if Input.is_action_pressed("move_right"):
        input_vector.x += 1
    
    velocity = input_vector.normalized() * speed
```

### 7. Importar Assets Convertidos

1. Copie os assets convertidos para `assets/sprites/`
2. No Godot, os arquivos serão importados automaticamente
3. Ajuste as configurações de importação se necessário:
   - **Sprites**: Filter: ON, Mipmaps: OFF (para 2D pixel art)
   - **Áudio**: Import como OGG para melhor compatibilidade

### 8. Configurar Câmera Isométrica

Crie um script para câmera isométrica:

#### `scripts/core/isometric_camera.gd`
```gdscript
extends Camera2D

func _ready():
    # Configurar para visão isométrica
    zoom = Vector2(1.5, 1.5)
    # Ajustar offset conforme necessário
```

### 9. Testar Configuração

1. Crie uma cena de teste simples
2. Adicione um sprite
3. Execute o projeto (F5)
4. Verifique se tudo está funcionando

## 📚 Próximos Passos

1. Converter alguns sprites usando `convert_frm_to_godot.py`
2. Importar sprites no Godot
3. Criar primeira cena de jogo
4. Implementar sistema básico de movimento
5. Adicionar sistema de mapas

## 💡 Dicas

- Use **TileMap** do Godot para mapas baseados em tiles
- Use **AnimatedSprite2D** para animações de personagens
- Use **Area2D** para detecção de colisões e interações
- Organize código em módulos reutilizáveis

## 🔗 Links Úteis

- [Godot Documentation](https://docs.godotengine.org/)
- [2D Isometric Game Tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/2d_isometric.html)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

