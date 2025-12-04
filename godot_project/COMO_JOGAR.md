# Como Jogar - Fallout 2 Godot Edition

## Requisitos

- **Godot Engine 4.2** ou superior
- **Arquivos originais do Fallout 2** (opcional, para assets completos)

## Início Rápido

### 1. Abrir o Projeto

1. Abra o Godot Engine
2. Clique em "Import"
3. Navegue até a pasta `godot_project`
4. Selecione `project.godot`
5. Clique em "Import & Edit"

### 2. Executar o Jogo

- Pressione **F5** para executar
- Ou clique no botão ▶️ no canto superior direito

### 3. Menu Principal

O menu aparecerá com as opções:

- **INTRO** (I) - Reproduz intro (não implementado)
- **NEW GAME** (N) - Inicia novo jogo
- **LOAD GAME** (L) - Carrega jogo salvo
- **OPTIONS** (O) - Opções (não implementado)
- **CREDITS** (C) - Créditos (não implementado)
- **EXIT** (E) - Sair do jogo

## Controles do Jogo

### Movimento
- **W / ↑** - Mover para cima
- **S / ↓** - Mover para baixo
- **A / ←** - Mover para esquerda
- **D / →** - Mover para direita
- **Shift** - Correr (segurar)
- **Click Esquerdo** - Mover para posição / Interagir
- **Click Direito** - Parar movimento

### Interface
- **I** - Abrir/Fechar Inventário
- **C** - Tela de Personagem
- **P** - PipBoy
- **ESC** - Pausar

### Save/Load
- **F6** - Quicksave
- **F9** - Quickload

## Gameplay Atual

### O que funciona:
- Menu principal com navegação
- Movimento do personagem
- HUD com HP e AP
- Sistema de combate básico
- NPCs interagíveis
- Sistema de save/load

### O que está em desenvolvimento:
- Conversão de sprites originais
- Mapas do jogo original
- Diálogos completos
- Sistema de quests

## Convertendo Assets Originais

Se você tem os arquivos originais do Fallout 2:

```bash
cd tools
python extract_and_convert.py "C:/Jogos/Fallout 2" ../godot_project/assets
```

Isso irá:
1. Extrair arquivos dos .DAT
2. Converter sprites .FRM para PNG
3. Organizar na estrutura do Godot

## Estrutura do Jogo

```
Cena Principal (main.tscn)
├── UI (CanvasLayer)
│   └── MainMenuOriginal
└── Camera2D

Cena de Jogo (game_scene.tscn)
├── World
│   ├── Ground (tiles)
│   ├── Objects (construções, etc)
│   └── NPCs
├── Player
│   └── Camera2D
└── HUD
    └── FalloutHUD
```

## Dicas

1. **Sem sprites?** O jogo funciona com placeholders coloridos
2. **Erro ao carregar?** Verifique se está usando Godot 4.2+
3. **Performance lenta?** Reduza a resolução em Project Settings

## Problemas Conhecidos

- Sprites originais precisam ser convertidos manualmente
- Alguns sistemas ainda não estão completos
- Mapas são placeholders por enquanto

## Próximos Passos

1. Converter assets do jogo original
2. Importar mapas
3. Adicionar NPCs e diálogos
4. Implementar quests

---

*Divirta-se explorando o wasteland!*
