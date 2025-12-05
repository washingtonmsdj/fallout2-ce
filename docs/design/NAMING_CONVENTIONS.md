# Convenções de Nomenclatura

## Arquivos e Pastas

### Cenas (.tscn)
- **PascalCase**: `PlayerCharacter.tscn`, `MainMenu.tscn`
- Descritivo e específico

### Scripts (.gd)
- **snake_case**: `player_controller.gd`, `enemy_ai.gd`
- Sufixos comuns: `_manager`, `_controller`, `_system`

### Assets
- **snake_case**: `hero_diffuse.png`, `sword_mesh.glb`
- Formato: `[nome]_[tipo]_[variação].[ext]`
- Exemplos:
  - `player_texture_diffuse.png`
  - `enemy_orc_model.glb`
  - `footstep_grass_01.wav`

## Código

### Variáveis
- **snake_case**: `player_health`, `max_speed`
- Booleanos: prefixo `is_`, `has_`, `can_`
  - `is_alive`, `has_weapon`, `can_jump`

### Constantes
- **UPPER_SNAKE_CASE**: `MAX_HEALTH`, `GRAVITY_FORCE`

### Funções
- **snake_case**: `calculate_damage()`, `spawn_enemy()`
- Verbos descritivos

### Classes
- **PascalCase**: `PlayerController`, `EnemyAI`

### Sinais
- **snake_case**: `health_changed`, `item_collected`
- Tempo passado ou presente

### Enums
- **PascalCase** para o tipo: `WeaponType`
- **UPPER_SNAKE_CASE** para valores: `SWORD`, `BOW`, `STAFF`

## Organização de Pastas

```
nome_categoria/
  ├── subcategoria/
  │   ├── NomeCena.tscn
  │   └── nome_script.gd
```

## Prefixos Úteis

- `temp_`: Arquivos temporários
- `test_`: Arquivos de teste
- `old_`: Versões antigas (para remover depois)
- `wip_`: Work in progress
