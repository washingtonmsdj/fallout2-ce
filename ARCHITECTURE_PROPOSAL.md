# 🏗️ Arquitetura Proposta: Fallout 2 CE - Refatoração Completa

## 🎯 Análise da Situação Atual

### Problemas Identificados
- **Caminhos hardcoded incorretos**: MapLoader procurando arquivos nos lugares errados
- **Estrutura fragmentada**: Código espalhado sem organização clara
- **Dependências acopladas**: Sistemas muito interdependentes
- **Falta de testes**: Código sem cobertura adequada de testes
- **Documentação insuficiente**: Falta documentação arquitetural
- **Performance não otimizada**: Sistema de renderização básico

### Pontos Positivos
- ✅ Extração de assets funcionando
- ✅ Parser de mapas básico operacional
- ✅ Base de renderização isométrica
- ✅ Estrutura inicial do Godot project

## 🏛️ Arquitetura Modular Proposta

### **1. Princípios Arquiteturais**

#### **SOLID Principles**
- **Single Responsibility**: Cada classe/módulo tem uma responsabilidade única
- **Open/Closed**: Código aberto para extensão, fechado para modificação
- **Liskov Substitution**: Subclasses substituíveis pelas classes base
- **Interface Segregation**: Interfaces específicas para cada cliente
- **Dependency Inversion**: Dependência de abstrações, não implementações

#### **Design Patterns**
- **Factory Pattern**: Para criação de objetos complexos (maps, entities)
- **Observer Pattern**: Para comunicação entre sistemas
- **Command Pattern**: Para ações do jogador e NPCs
- **State Pattern**: Para máquinas de estado de entidades
- **Strategy Pattern**: Para algoritmos intercambiáveis

### **2. Estrutura de Diretórios Otimizada**

```
fallout2-ce/
├── docs/                          # 📚 Documentação completa
│   ├── architecture.md           # Arquitetura do sistema
│   ├── api_reference.md          # Referência da API
│   ├── development_guide.md      # Guia de desenvolvimento
│   └── deployment_guide.md       # Guia de deployment
│
├── tools/                         # 🛠️  Ferramentas de desenvolvimento
│   ├── extractors/               # Extração de assets
│   │   ├── base_extractor.py     # Interface base
│   │   ├── frm_extractor.py      # Sprites/animations
│   │   ├── map_extractor.py      # Mapas
│   │   ├── audio_extractor.py    # Áudio
│   │   └── proto_extractor.py    # Protótipos
│   ├── builders/                 # Construção de dados
│   │   ├── base_builder.py       # Interface base
│   │   ├── sprite_builder.py     # Otimização de sprites
│   │   ├── tile_builder.py       # Tilesets
│   │   └── map_builder.py        # Dados de mapa
│   ├── validators/               # Validações
│   │   ├── base_validator.py     # Interface base
│   │   ├── asset_validator.py    # Validação de assets
│   │   └── data_validator.py     # Validação de dados
│   └── cli/                      # Interface de linha de comando
│       ├── extract_command.py    # Comando de extração
│       ├── build_command.py      # Comando de build
│       └── validate_command.py   # Comando de validação
│
├── godot_project/
│   ├── project.godot             # Configuração do Godot
│   ├── assets/                   # 📦 Assets processados
│   │   ├── sprites/              # Sprites organizados por categoria
│   │   │   ├── characters/       # Personagens
│   │   │   ├── creatures/        # Criaturas
│   │   │   ├── items/           # Itens
│   │   │   ├── scenery/         # Cenário
│   │   │   └── ui/              # Interface
│   │   ├── tiles/               # Tiles organizados
│   │   │   ├── ground/          # Tiles de chão
│   │   │   ├── walls/           # Paredes
│   │   │   └── roofs/           # Tetos
│   │   ├── audio/               # Áudio processado
│   │   │   ├── music/           # Música de fundo
│   │   │   ├── sfx/             # Efeitos sonoros
│   │   │   └── voice/           # Vozes/dialógos
│   │   ├── data/                # 📋 Dados estruturados
│   │   │   ├── maps/            # Dados de mapas
│   │   │   ├── prototypes/      # Protótipos de objetos
│   │   │   ├── dialogs/         # Dados de diálogos
│   │   │   ├── quests/          # Dados de quests
│   │   │   └── localization/    # Textos localizados
│   │   └── fonts/               # Fontes processadas
│   │
│   ├── scripts/
│   │   ├── core/                # 🎮 Núcleo do jogo
│   │   │   ├── game_manager.gd              # Gerenciador principal
│   │   │   ├── scene_manager.gd             # Gerenciamento de cenas
│   │   │   ├── save_load_system.gd          # Sistema de save/load
│   │   │   ├── settings_manager.gd          # Configurações
│   │   │   └── event_system.gd              # Sistema de eventos
│   │   │
│   │   ├── systems/             # 🔧 Sistemas principais
│   │   │   ├── map_system.gd                # Sistema de mapas
│   │   │   ├── tile_system.gd               # Sistema de tiles
│   │   │   ├── object_system.gd             # Sistema de objetos
│   │   │   ├── isometric_renderer.gd        # Renderização isométrica
│   │   │   ├── lighting_system.gd           # Sistema de iluminação
│   │   │   ├── audio_system.gd              # Sistema de áudio
│   │   │   └── physics_system.gd            # Sistema de física
│   │   │
│   │   ├── managers/            # 👥 Gerenciadores especializados
│   │   │   ├── player_manager.gd            # Controle do jogador
│   │   │   ├── inventory_manager.gd         # Inventário
│   │   │   ├── combat_manager.gd            # Combate
│   │   │   ├── dialog_manager.gd            # Diálogos
│   │   │   ├── quest_manager.gd             # Quests
│   │   │   ├── faction_manager.gd           # Facções/reputação
│   │   │   ├── time_manager.gd              # Sistema de tempo
│   │   │   └── ai_manager.gd                # IA de NPCs
│   │   │
│   │   ├── components/          # 🧩 Componentes reutilizáveis
│   │   │   ├── base_component.gd            # Componente base
│   │   │   ├── interactable.gd               # Objetos interativos
│   │   │   ├── animated_sprite_2d.gd        # Sprite animado otimizado
│   │   │   ├── collision_component.gd        # Componente de colisão
│   │   │   ├── state_machine.gd              # Máquina de estados
│   │   │   └── health_component.gd           # Componente de vida
│   │   │
│   │   ├── entities/            # 🏃 Entidades do jogo
│   │   │   ├── base_entity.gd               # Entidade base
│   │   │   ├── player_entity.gd             # Entidade do jogador
│   │   │   ├── npc_entity.gd                # Entidade de NPC
│   │   │   ├── creature_entity.gd           # Entidade de criatura
│   │   │   ├── item_entity.gd               # Entidade de item
│   │   │   └── scenery_entity.gd            # Entidade de cenário
│   │   │
│   │   ├── ui/                  # 🖥️ Interface do usuário
│   │   │   ├── base_ui.gd                  # UI base
│   │   │   ├── main_menu.gd                # Menu principal
│   │   │   ├── hud.gd                      # HUD do jogo
│   │   │   ├── inventory_ui.gd             # Interface de inventário
│   │   │   ├── dialog_ui.gd                # Interface de diálogo
│   │   │   ├── character_screen.gd         # Tela do personagem
│   │   │   └── options_menu.gd             # Menu de opções
│   │   │
│   │   ├── utils/               # 🔨 Utilitários
│   │   │   ├── math_utils.gd                # Funções matemáticas
│   │   │   ├── string_utils.gd              # Manipulação de strings
│   │   │   ├── file_utils.gd                # Operações de arquivo
│   │   │   ├── debug_utils.gd               # Utilitários de debug
│   │   │   └── constants.gd                 # Constantes globais
│   │   │
│   │   └── autoload/            # 🔄 Scripts autoload
│   │       ├── AssetDatabase.gd             # Banco de dados de assets
│   │       ├── EventBus.gd                  # Barramento de eventos
│   │       ├── GameState.gd                 # Estado global do jogo
│   │       └── Logger.gd                    # Sistema de logging
│   │
│   ├── scenes/                  # 🎬 Cenas do Godot
│   │   ├── main.tscn                       # Cena principal
│   │   ├── game_world.tscn                 # Mundo do jogo
│   │   ├── main_menu.tscn                  # Menu principal
│   │   ├── character_creation.tscn         # Criação de personagem
│   │   ├── loading_screen.tscn             # Tela de carregamento
│   │   └── ui_components/                  # Componentes de UI
│   │       ├── dialog_box.tscn             # Caixa de diálogo
│   │       ├── inventory_panel.tscn        # Painel de inventário
│   │       └── character_sheet.tscn        # Ficha do personagem
│   │
│   ├── tests/                  # 🧪 Sistema de testes
│   │   ├── unit/                          # Testes unitários
│   │   ├── integration/                   # Testes de integração
│   │   ├── performance/                   # Testes de performance
│   │   ├── visual/                        # Testes visuais
│   │   └── test_runner.gd                 # Executor de testes
│   │
│   └── resources/              # 📄 Recursos do Godot
│       ├── themes/                        # Temas de UI
│       ├── shaders/                       # Shaders customizados
│       ├── materials/                     # Materiais
│       └── animations/                    # Animações
│
├── config/                      # ⚙️ Configurações
│   ├── build_config.json        # Configuração de build
│   ├── asset_config.json        # Configuração de assets
│   └── game_config.json         # Configuração do jogo
│
├── build/                       # 📦 Build system
│   ├── windows/                 # Scripts de build Windows
│   ├── linux/                   # Scripts de build Linux
│   └── macos/                   # Scripts de build macOS
│
└── .github/                     # 🔄 CI/CD
    ├── workflows/               # GitHub Actions
    └── issue_templates/         # Templates de issues
```

### **3. Sistema de Assets Inteligente**

#### **AssetDatabase (Autoload)**
```gdscript
class_name AssetDatabase
extends Node

# ===== PROPERTIES =====
var _sprite_cache: Dictionary = {}
var _tile_cache: Dictionary = {}
var _audio_cache: Dictionary = {}
var _map_cache: Dictionary = {}
var _prototype_cache: Dictionary = {}

# Cache statistics
var _cache_hits: int = 0
var _cache_misses: int = 0
var _memory_usage: int = 0

# ===== PUBLIC API =====

# Sprite management
func get_sprite(sprite_id: String) -> Texture2D:
    return _get_cached_asset(_sprite_cache, sprite_id, "sprite")

func preload_sprite(sprite_id: String) -> void:
    _preload_asset(_sprite_cache, sprite_id, "sprite")

# Tile management
func get_tile(tile_id: String) -> Texture2D:
    return _get_cached_asset(_tile_cache, tile_id, "tile")

func get_tileset(tileset_id: String) -> TileSet:
    return _get_cached_asset(_tile_cache, tileset_id, "tileset")

# Audio management
func get_audio_clip(audio_id: String) -> AudioStream:
    return _get_cached_asset(_audio_cache, audio_id, "audio")

# Map data management
func get_map_data(map_id: String) -> MapData:
    return _get_cached_asset(_map_cache, map_id, "map")

# Prototype management
func get_prototype(proto_id: String) -> PrototypeData:
    return _get_cached_asset(_prototype_cache, proto_id, "prototype")

# ===== PRIVATE METHODS =====

func _get_cached_asset(cache: Dictionary, asset_id: String, asset_type: String) -> Resource:
    if cache.has(asset_id):
        _cache_hits += 1
        return cache[asset_id]

    _cache_misses += 1
    var asset = _load_asset(asset_id, asset_type)

    if asset:
        cache[asset_id] = asset
        _update_memory_usage(asset)

    return asset

func _load_asset(asset_id: String, asset_type: String) -> Resource:
    var path = _get_asset_path(asset_id, asset_type)

    if not ResourceLoader.exists(path):
        Logger.warning("Asset not found: %s (%s)" % [asset_id, asset_type])
        return null

    var asset = load(path)

    if not asset:
        Logger.error("Failed to load asset: %s" % path)
        return null

    return asset

func _get_asset_path(asset_id: String, asset_type: String) -> String:
    match asset_type:
        "sprite":
            return "res://assets/sprites/%s.png" % asset_id
        "tile":
            return "res://assets/tiles/%s.png" % asset_id
        "audio":
            return "res://assets/audio/%s.wav" % asset_id
        "map":
            return "res://assets/data/maps/%s.json" % asset_id
        "prototype":
            return "res://assets/data/prototypes/%s.json" % asset_id
        _:
            Logger.error("Unknown asset type: %s" % asset_type)
            return ""

func _preload_asset(cache: Dictionary, asset_id: String, asset_type: String) -> void:
    if not cache.has(asset_id):
        var asset = _load_asset(asset_id, asset_type)
        if asset:
            cache[asset_id] = asset
            _update_memory_usage(asset)

func _update_memory_usage(asset: Resource) -> void:
    # Estimate memory usage (rough approximation)
    if asset is Texture2D:
        var texture = asset as Texture2D
        var size = texture.get_size()
        _memory_usage += size.x * size.y * 4  # RGBA
    elif asset is AudioStream:
        # Estimate based on length and sample rate
        pass

# ===== DEBUG METHODS =====

func get_cache_stats() -> Dictionary:
    return {
        "hits": _cache_hits,
        "misses": _cache_misses,
        "hit_rate": float(_cache_hits) / (_cache_hits + _cache_misses) * 100,
        "memory_usage_mb": _memory_usage / (1024 * 1024),
        "cached_sprites": _sprite_cache.size(),
        "cached_tiles": _tile_cache.size(),
        "cached_audio": _audio_cache.size(),
        "cached_maps": _map_cache.size(),
        "cached_prototypes": _prototype_cache.size()
    }

func clear_cache() -> void:
    _sprite_cache.clear()
    _tile_cache.clear()
    _audio_cache.clear()
    _map_cache.clear()
    _prototype_cache.clear()
    _memory_usage = 0
    _cache_hits = 0
    _cache_misses = 0
```

### **4. Sistema de Eventos (EventBus)**

#### **EventBus (Autoload)**
```gdscript
class_name EventBus
extends Node

# ===== SIGNALS =====

# Game lifecycle events
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended()

# Player events
signal player_moved(position: Vector2i)
signal player_interacted(target: Node)
signal player_inventory_changed()
signal player_health_changed(old_health: int, new_health: int)
signal player_level_up(new_level: int)

# Combat events
signal combat_started(attacker: Node, defender: Node)
signal combat_ended(winner: Node, loser: Node)
signal damage_dealt(target: Node, damage: int, damage_type: String)
signal entity_died(entity: Node)

# Dialog events
signal dialog_started(npc: Node, dialog_id: String)
signal dialog_ended()
signal dialog_option_selected(option_id: String)

# Quest events
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)

# Map events
signal map_changed(map_id: String)
signal tile_interacted(tile_pos: Vector2i, tile_type: String)

# UI events
signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)
signal ui_button_pressed(button_name: String)

# ===== PUBLIC API =====

func emit_event(event_name: String, data: Dictionary = {}) -> void:
    if has_signal(event_name):
        emit_signal(event_name, data)
        Logger.debug("Event emitted: %s with data: %s" % [event_name, data])
    else:
        Logger.warning("Unknown event: %s" % event_name)

# ===== CONVENIENCE METHODS =====

# Player events
func player_moved_to(position: Vector2i) -> void:
    emit_signal("player_moved", position)

func player_interacted_with(target: Node) -> void:
    emit_signal("player_interacted", target)

# Combat events
func combat_started_between(attacker: Node, defender: Node) -> void:
    emit_signal("combat_started", attacker, defender)

func damage_dealt_to(target: Node, damage: int, damage_type: String = "normal") -> void:
    emit_signal("damage_dealt", target, damage, damage_type)

# Dialog events
func dialog_started_with(npc: Node, dialog_id: String) -> void:
    emit_signal("dialog_started", npc, dialog_id)

# Quest events
func quest_started_with_id(quest_id: String) -> void:
    emit_signal("quest_started", quest_id)

func quest_completed_with_id(quest_id: String) -> void:
    emit_signal("quest_completed", quest_id)
```

### **5. Sistema de Mapas Robusto**

#### **MapSystem**
```gdscript
class_name MapSystem
extends Node

# ===== PROPERTIES =====
var current_map: MapData = null
var map_container: Node2D = null
var tile_system: TileSystem = null
var object_system: ObjectSystem = null

# ===== PUBLIC API =====

func load_map(map_id: String) -> bool:
    Logger.info("Loading map: %s" % map_id)

    # Load map data
    var map_data = AssetDatabase.get_map_data(map_id)
    if not map_data:
        Logger.error("Failed to load map data: %s" % map_id)
        return false

    # Validate map data
    if not _validate_map_data(map_data):
        Logger.error("Invalid map data: %s" % map_id)
        return false

    # Unload current map
    if current_map:
        _unload_current_map()

    # Load new map
    current_map = map_data

    # Initialize systems
    tile_system.initialize_for_map(map_data)
    object_system.initialize_for_map(map_data)

    # Create map container
    map_container = Node2D.new()
    map_container.name = "Map_%s" % map_id
    add_child(map_container)

    # Load tiles
    var tiles_loaded = tile_system.load_tiles(map_container)
    Logger.info("Loaded %d tiles" % tiles_loaded)

    # Load objects
    var objects_loaded = object_system.load_objects(map_container)
    Logger.info("Loaded %d objects" % objects_loaded)

    # Emit event
    EventBus.emit_signal("map_changed", map_id)

    Logger.info("Map loaded successfully: %s" % map_id)
    return true

func unload_map() -> void:
    if current_map:
        _unload_current_map()
        current_map = null

func get_tile_at(position: Vector2i) -> TileData:
    return tile_system.get_tile_at(position)

func get_objects_at(position: Vector2i) -> Array:
    return object_system.get_objects_at(position)

func is_position_walkable(position: Vector2i) -> bool:
    # Check if tile is walkable
    var tile = get_tile_at(position)
    if not tile or not tile.walkable:
        return false

    # Check for blocking objects
    var objects = get_objects_at(position)
    for obj in objects:
        if obj.blocks_movement:
            return false

    return true

# ===== PRIVATE METHODS =====

func _unload_current_map() -> void:
    if map_container:
        map_container.queue_free()
        map_container = null

    tile_system.unload_tiles()
    object_system.unload_objects()

func _validate_map_data(map_data: MapData) -> bool:
    if not map_data:
        return false

    # Validate required fields
    if map_data.name.is_empty():
        return false

    if map_data.width <= 0 or map_data.height <= 0:
        return false

    if map_data.tiles.is_empty():
        return false

    return true
```

### **6. Sistema de Renderização Otimizado**

#### **IsometricRenderer**
```gdscript
class_name IsometricRenderer
extends Node2D

# ===== CONSTANTS =====
const TILE_WIDTH = 80
const TILE_HEIGHT = 36
const HEX_OFFSETS = [
    Vector2i(1, -1),   # NE
    Vector2i(1, 0),    # E
    Vector2i(0, 1),    # SE
    Vector2i(-1, 1),   # SW
    Vector2i(-1, 0),   # W
    Vector2i(0, -1)    # NW
]

# ===== PROPERTIES =====
var map_width: int = 100
var map_height: int = 100
var viewport_rect: Rect2 = Rect2()
var visible_tiles: Array = []

# ===== PUBLIC API =====

func initialize(width: int, height: int) -> void:
    map_width = width
    map_height = height
    _update_viewport_rect()

func tile_to_screen(tile_pos: Vector2i, elevation: int = 0) -> Vector2:
    """
    Convert tile coordinates to screen coordinates
    Using the original Fallout isometric formula
    """
    var x = tile_pos.x
    var y = tile_pos.y

    # Base isometric transformation
    var screen_x = (x - y) * (TILE_WIDTH / 2.0)
    var screen_y = (x + y) * (TILE_HEIGHT / 2.0)

    # Add elevation offset
    screen_y -= elevation * ELEVATION_OFFSET

    return Vector2(screen_x, screen_y)

func screen_to_tile(screen_pos: Vector2) -> Vector2i:
    """
    Convert screen coordinates to tile coordinates
    """
    var x = screen_pos.x / (TILE_WIDTH / 2.0)
    var y = screen_pos.y / (TILE_HEIGHT / 2.0)

    # Reverse the transformation
    var tile_x = (x + y) / 2.0
    var tile_y = (y - x) / 2.0

    return Vector2i(round(tile_x), round(tile_y))

func get_visible_tiles(camera_pos: Vector2, viewport_size: Vector2) -> Array:
    """
    Get all tiles that should be visible in the current viewport
    Uses frustum culling for performance
    """
    var half_width = viewport_size.x / 2.0
    var half_height = viewport_size.y / 2.0

    var top_left = screen_to_tile(camera_pos - Vector2(half_width, half_height))
    var bottom_right = screen_to_tile(camera_pos + Vector2(half_width, half_height))

    # Add some padding for safety
    top_left -= Vector2i(2, 2)
    bottom_right += Vector2i(2, 2)

    # Clamp to map bounds
    top_left.x = max(0, top_left.x)
    top_left.y = max(0, top_left.y)
    bottom_right.x = min(map_width - 1, bottom_right.x)
    bottom_right.y = min(map_height - 1, bottom_right.y)

    var visible = []
    for y in range(top_left.y, bottom_right.y + 1):
        for x in range(top_left.x, bottom_right.x + 1):
            visible.append(Vector2i(x, y))

    return visible

func sort_by_render_order(nodes: Array) -> Array:
    """
    Sort nodes by isometric render order (Y-sort)
    """
    return nodes.sort_custom(func(a, b):
        var a_pos = a.global_position
        var b_pos = b.global_position
        return a_pos.y < b_pos.y
    )

# ===== PRIVATE METHODS =====

func _update_viewport_rect() -> void:
    viewport_rect = Rect2(Vector2.ZERO, Vector2(map_width * TILE_WIDTH, map_height * TILE_HEIGHT))

func _ready() -> void:
    # Connect to viewport changes
    get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
    _update_viewport_rect()

func _process(_delta: float) -> void:
    # Update visible tiles based on camera position
    var camera = get_viewport().get_camera_2d()
    if camera:
        var camera_pos = camera.global_position
        var viewport_size = get_viewport_rect().size
        visible_tiles = get_visible_tiles(camera_pos, viewport_size)
```

## 🚀 Plano de Implementação Gradual

### **Fase 1: Foundation (1-2 semanas)**
1. **Reestruturar diretórios** seguindo a arquitetura proposta
2. **Implementar AssetDatabase** como sistema central de assets
3. **Criar EventBus** para comunicação entre sistemas
4. **Migrar scripts existentes** para a nova estrutura
5. **Implementar sistema básico de logging**

### **Fase 2: Core Systems (2-3 semanas)**
1. **Refatorar MapSystem** com carregamento robusto
2. **Implementar TileSystem** otimizado
3. **Melhorar IsometricRenderer** com culling
4. **Implementar ObjectSystem** para objetos do mapa
5. **Criar sistema de testes básico**

### **Fase 3: Game Mechanics (3-4 semanas)**
1. **Implementar PlayerManager** completo
2. **Sistema de inventário** com drag & drop
3. **CombatManager** com turnos e cálculos
4. **DialogManager** com ramificações
5. **QuestManager** com pré-requisitos

### **Fase 4: Performance & Polish (2-3 semanas)**
1. **Otimização de renderização** com LOD e instancing
2. **Sistema de cache inteligente** para assets
3. **Melhorias de performance** no carregamento
4. **Interface polida** e responsiva
5. **Sistema de áudio** completo

### **Fase 5: Content & Testing (3-4 semanas)**
1. **Implementar mapas principais** do jogo
2. **Sistema de quests completo** com todas as quests
3. **Balanceamento** de combate e dificuldade
4. **Testes extensivos** de integração
5. **Documentação final** e guias

## 🎯 Benefícios da Nova Arquitetura

### **Para Desenvolvedores**
- **👥 Colaboração**: Estrutura clara facilita trabalho em equipe
- **🔧 Manutenibilidade**: Código modular e bem documentado
- **🧪 Testabilidade**: Cobertura completa de testes automatizados
- **📈 Escalabilidade**: Fácil adição de novos recursos

### **Para o Projeto**
- **⚡ Performance**: Sistema otimizado desde o início
- **🔒 Robustez**: Tratamento adequado de erros e edge cases
- **🎮 Jogabilidade**: Melhor experiência de jogo
- **🔄 Manutenibilidade**: Fácil de atualizar e estender

### **Para Usuários**
- **🚀 Performance**: Jogo mais rápido e estável
- **🎨 Visual**: Gráficos mais polidos e consistentes
- **🎵 Áudio**: Sistema de som aprimorado
- **💾 Save/Load**: Sistema de salvamento confiável

## 🤔 Conclusão

Refazer o projeto do zero com esta arquitetura seria **altamente recomendável** pelos seguintes motivos:

1. **Problemas Estruturais**: A arquitetura atual tem problemas fundamentais que seriam difíceis de corrigir incrementalmente
2. **Benefícios a Longo Prazo**: Uma base sólida permitirá desenvolvimento mais rápido e confiável no futuro
3. **Experiência Aprendida**: Já identificamos os problemas, podemos evitá-los na nova implementação
4. **Tecnologia Madura**: Godot 4.x oferece recursos que não estavam disponíveis quando o projeto começou

**Recomendação**: Implementar a arquitetura proposta, começando pelos sistemas fundamentais (AssetDatabase, EventBus, MapSystem) e construindo incrementalmente a partir daí.