# Fallout 2 Godot Edition

Reimplementação do Fallout 2 em Godot Engine, mantendo todas as características visuais e mecânicas do jogo original.

## Status do Projeto

### ✅ Implementado
- Sistema de menu principal (fiel ao original)
- Sistema de gerenciamento de jogo (GameManager)
- Sistema de player com stats SPECIAL
- Sistema de combate por turnos com Action Points
- Sistema de inventário
- Sistema de diálogos
- Sistema de save/load
- Sistema de mapas
- Sistema de renderização isométrica
- HUD do jogo
- NPCs básicos

### 🔄 Em Progresso
- Conversão de assets (.FRM para PNG)
- Importação de mapas originais
- Sistema de scripts (interpretador)

### ⏳ Pendente
- Worldmap
- Sistema de quests completo
- Todos os NPCs e diálogos
- Efeitos sonoros e música
- Animações completas

## Como Usar

### Requisitos
- Godot Engine 4.2 ou superior
- Arquivos originais do Fallout 2 (master.dat, critter.dat)

### Instalação

1. Clone ou baixe este repositório
2. Abra o projeto `godot_project` no Godot Engine
3. Execute o jogo (F5)

### Conversão de Assets

Para converter os assets originais do Fallout 2:

```bash
cd tools
python extract_and_convert.py "caminho/para/Fallout 2" ../godot_project/assets
```

## Estrutura do Projeto

```
godot_project/
├── assets/
│   ├── sprites/          # Sprites convertidos
│   │   ├── ui/           # Interface
│   │   ├── critters/     # Personagens
│   │   ├── items/        # Itens
│   │   └── tiles/        # Tiles do mapa
│   ├── audio/            # Sons e músicas
│   └── data/             # Dados JSON
├── scenes/
│   ├── main.tscn         # Cena principal
│   ├── characters/       # Cenas de personagens
│   ├── game/             # Cena de jogo
│   ├── maps/             # Mapas
│   └── ui/               # Interface
├── scripts/
│   ├── core/             # Scripts principais
│   │   ├── game_manager.gd
│   │   └── game_scene.gd
│   ├── actors/           # Personagens
│   │   ├── player.gd
│   │   └── npc.gd
│   ├── systems/          # Sistemas do jogo
│   │   ├── combat_system.gd
│   │   ├── inventory_system.gd
│   │   ├── dialog_system.gd
│   │   ├── save_system.gd
│   │   ├── map_system.gd
│   │   └── isometric_renderer.gd
│   └── ui/               # Interface
│       ├── main_menu_fallout2.gd
│       └── fallout_hud.gd
└── project.godot
```

## Controles

### Menu
- **I** - Intro
- **N** - Novo Jogo
- **L** - Carregar Jogo
- **O** - Opções
- **C** - Créditos
- **E** - Sair

### Jogo
- **WASD / Setas** - Movimento
- **E** - Interagir
- **I** - Inventário
- **C** - Personagem
- **P** - PipBoy
- **ESC** - Pausar
- **F6** - Quicksave
- **F9** - Quickload
- **Click Esquerdo** - Mover/Interagir
- **Click Direito** - Parar

## Sistemas Implementados

### GameManager
Controla o estado geral do jogo:
- Estados: MENU, PLAYING, PAUSED, DIALOG, INVENTORY, COMBAT
- Carregamento de mapas
- Transições de cena

### Player
Sistema de personagem com:
- Stats SPECIAL (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- HP e Action Points
- Sistema de níveis e experiência
- Movimento isométrico

### Combat System
Combate por turnos:
- Ordem de turno baseada em Sequence
- Action Points para ações
- Cálculo de hit chance e dano
- IA básica de inimigos

### Inventory System
Gerenciamento de itens:
- Adicionar/remover itens
- Equipar armas e armaduras
- Sistema de peso
- Uso de itens consumíveis

### Dialog System
Sistema de diálogos:
- Diálogos em árvore
- Opções condicionais
- Ações (dar item, XP, etc.)

### Save System
Sistema de save/load:
- 10 slots de save
- Quicksave/Quickload
- Salva estado completo do jogo

## Fidelidade ao Original

Este projeto busca manter total fidelidade ao Fallout 2 original:

- **Visual**: Mesmas cores, posições e proporções
- **Mecânicas**: Sistema SPECIAL, combate por turnos, Action Points
- **Interface**: Menu e HUD idênticos ao original
- **Gameplay**: Mesmo comportamento e sensação do jogo original

## Licença

Este projeto é uma reimplementação para fins educacionais. Os assets originais do Fallout 2 são propriedade da Interplay/Bethesda.

## Créditos

- Jogo Original: Interplay Entertainment / Black Isle Studios
- Reimplementação: Baseada no Fallout 2 Community Edition
- Engine: Godot Engine
