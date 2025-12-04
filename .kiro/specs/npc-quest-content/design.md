# Design Document: NPCs, Quest System e Conteúdo Jogável

## Análise de Gap: O Que Já Existe vs O Que Falta

### ✅ SISTEMAS JÁ IMPLEMENTADOS (100% Funcionais)

| Sistema | Arquivo | Status | Funcionalidades |
|---------|---------|--------|-----------------|
| **IsometricRenderer** | `isometric_renderer.gd` | ✅ 100% | Conversões tile↔screen, ordenação sprites, elevações |
| **IsometricCamera** | `isometric_camera.gd` | ✅ 100% | Seguimento suave, zoom, limites |
| **Pathfinder** | `pathfinder.gd` | ✅ 100% | A* hexagonal, obstáculos, AP em combate |
| **InputManager** | `input_manager.gd` | ✅ 100% | Clicks, atalhos, conversão coordenadas |
| **CursorManager** | `cursor_manager.gd` | ✅ 100% | 5 modos cursor, tooltips |
| **CombatSystem** | `combat_system.gd` | ✅ 100% | Turnos, hit chance, dano, IA básica |
| **InventorySystem** | `inventory_system.gd` | ✅ 100% | Itens, peso, equipamento, consumíveis |
| **DialogSystem** | `dialog_system.gd` | ✅ 100% | Árvores, requisitos, ações, variáveis |
| **SaveSystem** | `save_system.gd` | ✅ 100% | Save/load, quicksave, slots |
| **MapSystem** | `map_system.gd` | ✅ 100% | Carregamento, elevações, transições |
| **MapLoader** | `map_loader.gd` | ✅ 100% | Parser JSON, instanciação |
| **PrototypeSystem** | `prototype_system.gd` | ✅ 100% | Protótipos de itens/criaturas |
| **ScriptInterpreter** | `script_interpreter.gd` | ✅ 100% | Scripts JSON, variáveis globais |
| **AnimationController** | `animation_controller.gd` | ✅ 100% | Estados, direções, transições |
| **AudioManager** | `audio_manager.gd` | ✅ 100% | Música, SFX, volume |

### ✅ ATORES JÁ IMPLEMENTADOS

| Ator | Arquivo | Status | Funcionalidades |
|------|---------|--------|-----------------|
| **Player** | `player.gd` | ✅ 100% | SPECIAL, HP/AP, movimento, níveis |
| **NPC** | `npc.gd` | ✅ 100% | Stats, IA hostil, mercador, morte/loot |
| **Interactable** | `interactable.gd` | ✅ 100% | Containers, portas, switches |

### ✅ FERRAMENTAS DE EXTRAÇÃO JÁ IMPLEMENTADAS

| Ferramenta | Arquivo | Status | Funcionalidades |
|------------|---------|--------|-----------------|
| **DAT2Reader** | `dat2_reader.py` | ✅ 100% | Leitura de arquivos .dat |
| **FRMDecoder** | `frm_decoder.py` | ✅ 100% | Decodificação de sprites FRM |
| **PaletteLoader** | `palette_loader.py` | ✅ 100% | Carregamento de paletas |
| **CritterExtractor** | `critter_extractor.py` | ⚠️ 60% | Extração básica, falta animações completas |
| **TileExtractor** | `tile_extractor.py` | ✅ 100% | Extração de tiles |
| **MapParser** | `map_parser.py` | ✅ 100% | Parser de mapas .MAP |
| **MsgParser** | `msg_parser.py` | ✅ 100% | Parser de mensagens/diálogos |
| **ACMDecoder** | `acm_decoder.py` | ✅ 100% | Decodificação de áudio |
| **AssetOrganizer** | `asset_organizer.py` | ✅ 100% | Organização de assets |

### ❌ O QUE FALTA IMPLEMENTAR

| Funcionalidade | Prioridade | Dependências |
|----------------|------------|--------------|
| **Quest System** | 🔴 ALTA | DialogSystem, NPCs |
| **Quest Journal UI** | 🔴 ALTA | Quest System |
| **Extração Completa de Animações** | 🔴 ALTA | CritterExtractor |
| **Conversão para SpriteFrames** | 🔴 ALTA | FRMDecoder |
| **Catálogo de Criaturas** | 🟡 MÉDIA | Extração |
| **Indicadores de Quest em NPCs** | 🟡 MÉDIA | Quest System |
| **Área Inicial Jogável** | 🔴 ALTA | Todos os sistemas |
| **Quest Tutorial Completa** | 🔴 ALTA | Quest System |

### 📊 RESUMO DE PROGRESSO

```
Sistemas Core:        ████████████████████ 100% ✅
Atores:               ████████████████████ 100% ✅
Ferramentas Python:   ████████████████░░░░  80% ⚠️
Quest System:         ░░░░░░░░░░░░░░░░░░░░   0% ❌
Conteúdo Jogável:     ██░░░░░░░░░░░░░░░░░░  10% ❌
Animações Completas:  ████████░░░░░░░░░░░░  40% ⚠️
```

### 🔧 DETALHAMENTO DO QUE FALTA

#### 1. Extração de Animações (CritterExtractor)
**Atual**: Extrai apenas sprite idle (aa.frm) de algumas criaturas
**Falta**:
- Extrair TODAS as animações: idle (aa), walk (ab), run (at), attack (an, ao, ap), death (ba-bm), hit (ao)
- Extrair todas as 6 direções por animação
- Gerar spritesheets organizados
- Criar manifesto JSON completo
- Converter para SpriteFrames do Godot (.tres)

#### 2. Quest System
**Atual**: Não existe
**Falta**:
- QuestSystem autoload
- QuestData, QuestObjective, QuestRewards resources
- Máquina de estados de quest
- Integração com DialogSystem (já existe)
- Integração com NPCs (já existe)
- Quest Journal UI

#### 3. Conteúdo Jogável
**Atual**: Sistemas existem mas sem conteúdo
**Falta**:
- Definir área inicial (ex: Vila de Arroyo)
- Criar mapa JSON com tiles, objetos, NPCs
- Criar protótipos de NPCs da área
- Criar diálogos para NPCs
- Criar quest tutorial
- Criar inimigos balanceados
- Testar gameplay loop completo

---

## Overview

Este documento descreve o design técnico para completar três funcionalidades que faltam:

1. **Extração de Animações de NPCs/Criaturas**: Expandir o CritterExtractor existente para extrair TODAS as animações e converter para formato Godot.

2. **Sistema de Quests**: Criar sistema completo de missões que se integra com DialogSystem e NPCs já existentes.

3. **Conteúdo Jogável**: Usar todos os sistemas já implementados para criar a primeira área jogável com quest completa.

O objetivo é ter um jogo demonstrável onde o jogador pode explorar, interagir com NPCs, completar missões e progredir.

## Architecture

### Integração com Sistemas Existentes

O projeto já possui uma arquitetura robusta. Os novos componentes se integram assim:

```
┌─────────────────────────────────────────────────────────────────┐
│                   EXTRACTION PIPELINE (Python)                   │
│                   Expandir ferramentas existentes                │
├─────────────────────────────────────────────────────────────────┤
│  DAT2Reader ✅ → FRMDecoder ✅ → PNGConverter → SpriteFramesGen │
│  (existe)        (existe)        (NOVO)         (NOVO)          │
│                              ↓                                   │
│                      CritterCatalog (JSON) (NOVO)                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    GODOT RUNTIME (GDScript)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ QuestSystem  │←──→│ DialogSystem │←──→│    NPC       │       │
│  │    (NOVO)    │    │     ✅       │    │     ✅       │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         ↓                   ↓                   ↓                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ QuestJournal │    │  DialogUI    │    │AnimController│       │
│  │    (NOVO)    │    │   (existe)   │    │     ✅       │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐
│  │                    GameManager ✅                             │
│  │  Estados: MENU, PLAYING, PAUSED, DIALOG, INVENTORY, COMBAT   │
│  │  Adicionar: QUEST_JOURNAL                                     │
│  └──────────────────────────────────────────────────────────────┘
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐
│  │              SISTEMAS EXISTENTES (Reutilizar)                 │
│  │  CombatSystem ✅  InventorySystem ✅  SaveSystem ✅           │
│  │  MapSystem ✅     PrototypeSystem ✅  Pathfinder ✅           │
│  └──────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘

Legenda: ✅ = Já existe e funciona | (NOVO) = Precisa implementar
```

### Pontos de Integração

| Novo Componente | Integra Com | Como |
|-----------------|-------------|------|
| QuestSystem | DialogSystem | Ações de diálogo chamam `QuestSystem.add_quest()`, `update_objective()` |
| QuestSystem | NPC | NPC verifica `QuestSystem.get_quest_state()` para indicadores |
| QuestSystem | SaveSystem | `SaveSystem.save_game()` inclui `QuestSystem.serialize()` |
| QuestSystem | GameManager | Novo estado `QUEST_JOURNAL` para abrir journal |
| QuestJournal | InputManager | Tecla `J` abre journal (adicionar atalho) |
| AnimationController | NPC | NPC já usa AnimationController, só precisa de mais animações |
| CritterCatalog | PrototypeSystem | Protótipos referenciam animações do catálogo |

## Components and Interfaces

### 1. Extraction Pipeline (Python)

#### 1.1 CritterExtractor
```python
class CritterExtractor:
    """Extrai todas as animações de criaturas do Fallout 2"""
    
    def extract_all(self, dat_path: str, output_dir: str) -> dict:
        """Extrai todas as criaturas e retorna manifesto"""
        
    def extract_critter(self, critter_id: str) -> CritterData:
        """Extrai uma criatura específica com todas as animações"""
        
    def decode_frm(self, data: bytes, palette: list) -> list[Image]:
        """Decodifica FRM em lista de frames por direção"""
```

#### 1.2 GodotConverter
```python
class GodotConverter:
    """Converte sprites extraídos para formato Godot"""
    
    def convert_to_spriteframes(self, frames: list, output_path: str) -> str:
        """Gera arquivo .tres SpriteFrames do Godot"""
        
    def map_6_to_8_directions(self, frames_6dir: list) -> list:
        """Mapeia 6 direções para 8 direções"""
        
    def generate_manifest(self, critters: list) -> dict:
        """Gera manifesto JSON com todas as criaturas"""
```

### 2. Quest System (GDScript)

#### 2.1 QuestSystem (Autoload)
```gdscript
class_name QuestSystem extends Node

signal quest_added(quest_id: String)
signal quest_updated(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

var active_quests: Dictionary = {}  # quest_id -> QuestData
var completed_quests: Array[String] = []
var failed_quests: Array[String] = []

func add_quest(quest_id: String) -> bool
func update_objective(quest_id: String, objective_id: String, progress: int) -> void
func complete_quest(quest_id: String) -> void
func fail_quest(quest_id: String) -> void
func get_quest_state(quest_id: String) -> int  # INACTIVE, ACTIVE, COMPLETED, FAILED
func is_quest_available(quest_id: String) -> bool  # Verifica pré-requisitos
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

#### 2.2 QuestData (Resource)
```gdscript
class_name QuestData extends Resource

@export var quest_id: String
@export var title: String
@export var description: String
@export var objectives: Array[QuestObjective]
@export var rewards: QuestRewards
@export var prerequisites: Array[String]  # IDs de quests que devem estar completas
@export var fail_conditions: Array[Dictionary]
@export var quest_giver_id: String
@export var location_hint: String

enum State { INACTIVE, ACTIVE, READY_TO_COMPLETE, COMPLETED, FAILED }
var state: State = State.INACTIVE
```

#### 2.3 QuestObjective (Resource)
```gdscript
class_name QuestObjective extends Resource

@export var objective_id: String
@export var description: String
@export var type: String  # "kill", "collect", "talk", "reach", "interact"
@export var target_id: String  # ID do alvo (NPC, item, local)
@export var required_count: int = 1
var current_count: int = 0
var is_complete: bool = false
var is_optional: bool = false
```

#### 2.4 QuestRewards (Resource)
```gdscript
class_name QuestRewards extends Resource

@export var experience: int = 0
@export var caps: int = 0
@export var items: Array[Dictionary] = []  # [{item_id, quantity}]
@export var reputation: Dictionary = {}  # {faction_id: amount}
@export var unlocks: Array[String] = []  # IDs de quests/áreas desbloqueadas
```

### 3. Quest Journal UI

#### 3.1 QuestJournal (Control)
```gdscript
class_name QuestJournal extends Control

var selected_quest_id: String = ""
var filter: String = "active"  # "active", "completed", "failed", "all"

func _ready() -> void
func show_journal() -> void
func hide_journal() -> void
func refresh_quest_list() -> void
func select_quest(quest_id: String) -> void
func get_quests_by_filter() -> Array[QuestData]
```

### 4. NPC Integration

#### 4.1 NPCQuestIndicator
```gdscript
# Componente adicionado a NPCs que dão quests
class_name NPCQuestIndicator extends Node2D

enum IndicatorType { NONE, QUEST_AVAILABLE, QUEST_IN_PROGRESS, QUEST_READY }
var current_indicator: IndicatorType = IndicatorType.NONE

func update_indicator() -> void
func _get_indicator_for_npc() -> IndicatorType
```

## Data Models

### Quest Definition (JSON)
```json
{
  "quest_id": "tutorial_01",
  "title": "Primeiros Passos",
  "description": "Aprenda o básico de sobrevivência no wasteland.",
  "quest_giver": "npc_elder",
  "objectives": [
    {
      "id": "obj_talk_elder",
      "description": "Fale com o Ancião",
      "type": "talk",
      "target": "npc_elder",
      "count": 1
    },
    {
      "id": "obj_kill_rats",
      "description": "Elimine os ratos na caverna",
      "type": "kill",
      "target": "creature_rat",
      "count": 3
    },
    {
      "id": "obj_return",
      "description": "Retorne ao Ancião",
      "type": "talk",
      "target": "npc_elder",
      "count": 1
    }
  ],
  "rewards": {
    "experience": 100,
    "caps": 50,
    "items": [{"id": "item_stimpak", "quantity": 2}],
    "unlocks": ["quest_main_01"]
  },
  "prerequisites": [],
  "fail_conditions": []
}
```

### Critter Manifest (JSON)
```json
{
  "critters": [
    {
      "id": "hmwarr",
      "name": "Human Male Warrior",
      "type": "human",
      "animations": {
        "idle": "res://assets/critters/hmwarr/idle.tres",
        "walk": "res://assets/critters/hmwarr/walk.tres",
        "attack": "res://assets/critters/hmwarr/attack.tres",
        "death": "res://assets/critters/hmwarr/death.tres"
      },
      "directions": 6,
      "size": {"width": 32, "height": 48}
    }
  ],
  "types": ["human", "animal", "mutant", "robot", "creature"],
  "total_count": 150
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Extraction Pipeline Properties

**Property 1: FRM Frame Extraction Completeness**
*For any* valid FRM file with N frames and D directions, the extractor should produce exactly N × D individual frame images.
**Validates: Requirements 1.1, 1.2**

**Property 2: PNG Transparency Correctness**
*For any* extracted sprite, pixels with palette index 0 should have alpha value 0 (fully transparent) in the output PNG.
**Validates: Requirements 2.1**

**Property 3: Direction Mapping Consistency**
*For any* critter with 6 directions, the converter should produce output with exactly 8 directions, where directions 1 and 5 are interpolated or duplicated from adjacent directions.
**Validates: Requirements 2.3**

**Property 4: Manifest Completeness**
*For any* extraction run, the manifest should contain an entry for every critter that was successfully extracted, and all paths in the manifest should point to existing files.
**Validates: Requirements 1.4, 3.1, 3.4**

**Property 5: Catalog Filter Correctness**
*For any* filter by type (human, animal, mutant, robot), all returned critters should have that exact type, and no critters of that type should be missing from the results.
**Validates: Requirements 3.3**

### Quest System Properties

**Property 6: Quest State Machine Validity**
*For any* quest, state transitions should only follow valid paths: INACTIVE → ACTIVE → READY_TO_COMPLETE → COMPLETED, or INACTIVE → ACTIVE → FAILED. No other transitions are allowed.
**Validates: Requirements 5.2, 5.4**

**Property 7: Objective Independence**
*For any* quest with multiple objectives, updating one objective should not change the progress of any other objective.
**Validates: Requirements 4.2**

**Property 8: Objective Count Bounds**
*For any* objective with required_count N, current_count should always be in range [0, N], and is_complete should be true if and only if current_count >= required_count.
**Validates: Requirements 4.3**

**Property 9: Quest Prerequisite Enforcement**
*For any* quest with prerequisites, is_quest_available() should return true if and only if all prerequisite quests are in COMPLETED state.
**Validates: Requirements 4.4**

**Property 10: Quest Serialization Round-Trip**
*For any* QuestSystem state, serializing and then deserializing should produce an identical state (same active quests, same progress, same completed/failed lists).
**Validates: Requirements 4.5, 11.5**

**Property 11: Reward Application Correctness**
*For any* completed quest with rewards, completing the quest should increase player XP by exactly rewards.experience, caps by exactly rewards.caps, and add all reward items to inventory.
**Validates: Requirements 5.3, 11.2**

**Property 12: Quest Journal Organization**
*For any* set of quests, the journal should correctly categorize each quest: active quests in "active" filter, completed in "completed", failed in "failed".
**Validates: Requirements 6.1**

**Property 13: Quest-Dialog Integration**
*For any* NPC that is a quest giver, when quest is available the dialog should contain accept/refuse options, and when quest is ready to complete the dialog should contain deliver option.
**Validates: Requirements 7.1, 7.3**

**Property 14: NPC Quest Indicator Correctness**
*For any* NPC that gives quests, the indicator should be QUEST_AVAILABLE when quest is available, QUEST_IN_PROGRESS when active, QUEST_READY when ready to complete, and NONE otherwise.
**Validates: Requirements 7.5**

### Gameplay Properties

**Property 15: NPC Animation State Consistency**
*For any* NPC in the game, if is_moving is true then animation state should be WALK or RUN, and if is_moving is false then animation state should be IDLE (unless in combat or dead).
**Validates: Requirements 10.1, 12.1, 12.2**

**Property 16: Hostile NPC Detection**
*For any* hostile NPC, when player enters detection_range, combat should be initiated within the next frame update.
**Validates: Requirements 10.4, 11.3**

**Property 17: NPC Death Loot Preservation**
*For any* NPC that dies, the corpse should contain all items that were in the NPC's inventory at time of death, and those items should be accessible via loot interaction.
**Validates: Requirements 10.5, 11.5**

**Property 18: Player Spawn Position**
*For any* map load, the player should be positioned at the defined spawn point for that map, within a tolerance of 1 tile.
**Validates: Requirements 8.2**

**Property 19: Level Up Threshold**
*For any* player with XP >= level_threshold[current_level + 1], the level system should allow leveling up, and after level up, player level should increase by exactly 1.
**Validates: Requirements 11.3**

## Conteúdo Jogável: Área Inicial

### Área: Vila de Arroyo (Simplificada)

A primeira área jogável será uma versão simplificada da vila inicial do Fallout 2.

#### Mapa
- **Tamanho**: 50x50 tiles (menor que original para teste)
- **Elevações**: 1 (térreo apenas)
- **Estruturas**: 3-4 cabanas, 1 templo, área de treino

#### NPCs (5 NPCs mínimo)
| NPC | Tipo | Função | Diálogo |
|-----|------|--------|---------|
| Ancião | Quest Giver | Dá quest inicial | Sim |
| Guerreiro | Treinador | Ensina combate | Sim |
| Curandeira | Mercador | Vende stimpaks | Sim |
| Guarda | Hostil (se provocado) | Protege vila | Mínimo |
| Aldeão | Ambiente | Dá dicas | Mínimo |

#### Quest Inicial: "Prova do Guerreiro"
```
Título: Prova do Guerreiro
Descrição: Prove seu valor eliminando as criaturas que ameaçam a vila.

Objetivos:
1. Falar com o Ancião (talk, npc_elder, 1)
2. Eliminar ratos na caverna (kill, creature_rat, 3)
3. Retornar ao Ancião (talk, npc_elder, 1)

Recompensas:
- 100 XP
- 50 caps
- 2x Stimpak
- Desbloqueia: quest_main_01
```

#### Inimigos
| Criatura | HP | Dano | Quantidade |
|----------|----|----- |------------|
| Rato | 10 | 1-3 | 5 |
| Rato Grande | 20 | 2-5 | 2 |

#### Itens no Mapa
- 3x Stimpak (em containers)
- 1x Faca (arma inicial)
- 50 caps (espalhados)
- 1x Armadura de Couro (recompensa oculta)

## Error Handling

### Extraction Errors
- **Corrupted FRM**: Log error with file path, skip file, continue extraction
- **Missing Palette**: Use default grayscale palette, log warning
- **Invalid Direction Count**: Log warning, use available directions

### Quest System Errors
- **Missing Quest Definition**: Return null, log error, don't crash
- **Invalid State Transition**: Ignore transition, log warning
- **Missing Prerequisite Quest**: Quest remains unavailable

### Runtime Errors
- **Missing NPC Prototype**: Use default values, log warning
- **Missing Animation**: Use static sprite fallback
- **Save Corruption**: Detect via checksum, notify player, don't load

## Testing Strategy

### Property-Based Testing Library
- **Python (Extraction)**: Hypothesis
- **GDScript (Runtime)**: Custom PBT implementation with GDUnit4

### Unit Tests
- Quest state transitions
- Objective progress tracking
- Reward calculation
- Dialog option filtering

### Property-Based Tests
Each correctness property will have a corresponding PBT:
- Configure minimum 100 iterations per test
- Tag tests with property reference: `**Feature: npc-quest-content, Property N: description**`

### Integration Tests
- Full quest flow: accept → progress → complete → reward
- NPC interaction: approach → dialog → trade/quest
- Save/Load with active quests

### Test Data Generation
- Random quest definitions with valid structure
- Random objective progress values
- Random NPC configurations
- Synthetic FRM files for extraction testing

