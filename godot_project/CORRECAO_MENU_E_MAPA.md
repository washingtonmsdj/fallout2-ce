# Correção do Menu e Mapa

## Problemas Identificados

1. **Botão New Game não funcionava corretamente**
   - Carregava diretamente o jogo sem tela de criação de personagem
   - Não havia fluxo de criação de personagem

2. **Mapa aparecia quebrado**
   - Tiles estavam em posições cartesianas ao invés de isométricas
   - Sistema de renderização isométrica não estava sendo usado

## Correções Implementadas

### 1. Tela de Criação de Personagem

Criados novos arquivos:
- `godot_project/scenes/ui/character_creation.tscn` - Cena da tela
- `godot_project/scripts/ui/character_creation.gd` - Script da tela

Funcionalidades:
- Campo para nome do personagem
- Botão "Start Game" para iniciar
- Botão "Cancel" para voltar ao menu
- Validação de nome (usa "Chosen One" se vazio)

### 2. Fluxo do Menu Corrigido

Modificado `game_manager.gd`:
- `start_new_game()` agora carrega a tela de criação de personagem
- Adicionado campo `player_name` para armazenar nome do personagem
- Criado método `_load_character_creation()` para carregar a tela
- Mantido fallback `_start_game_directly()` caso a tela não exista

### 3. Renderização Isométrica Corrigida

Modificado `game_scene.gd`:
- Adicionado método `_convert_tiles_to_isometric()`
- Converte posições dos tiles de cartesianas para isométricas
- Usa o `IsometricRenderer` para calcular posições corretas
- Player agora é posicionado corretamente no grid isométrico

## Fluxo Atual

```
Menu Principal
    ↓ (Click em New Game)
Tela de Criação de Personagem
    ↓ (Digita nome e clica Start Game)
Cena de Jogo (com mapa isométrico correto)
```

## Como Testar

1. Abra o projeto no Godot
2. Execute a cena principal
3. Clique em "New Game"
4. Digite um nome (ou deixe vazio para usar "Chosen One")
5. Clique em "Start Game"
6. O jogo deve carregar com o mapa em perspectiva isométrica correta

## Próximas Melhorias

- Adicionar mais opções na criação de personagem (atributos, traits, etc)
- Melhorar visual da tela de criação
- Adicionar preview do personagem
- Implementar sistema de templates de personagem
