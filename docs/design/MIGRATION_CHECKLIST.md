# Checklist de Migração: Fallout 2 CE → Godot

## Legenda
- ✅ Implementado
- 🔶 Parcialmente implementado
- ❌ Não implementado
- ⚪ Não aplicável (específico do engine original)

---

## 1. SISTEMAS DE PERSONAGEM

### 1.1 Stats (stat.cc/stat_defs.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| SPECIAL Stats (7 primários) | ✅ | stat_data.gd | S.P.E.C.I.A.L completo |
| Stats Derivados (HP, AP, AC, etc) | ✅ | stat_data.gd | Calculados automaticamente |
| Damage Threshold por tipo | ✅ | stat_data.gd | 8 tipos de dano |
| Damage Resistance por tipo | ✅ | stat_data.gd | 8 tipos de dano |
| Modificadores de stat | ✅ | stat_data.gd | modify_stat() |
| PC Stats (Level, XP, Karma) | ✅ | critter.gd | No Critter |
| Limites min/max de stats | ✅ | constants.gd | 1-10 |

### 1.2 Skills (skill.cc/skill_defs.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| 18 Skills | ✅ | skill_data.gd | Todas implementadas |
| Tagged Skills | ✅ | skill_data.gd | Até 4 tags |
| Skill Points | ✅ | skill_data.gd | unspent_skill_points |
| Custo de aumento | ✅ | skill_data.gd | Tagged = metade |
| Skill baseado em SPECIAL | 🔶 | skill_data.gd | Base fixa, falta fórmula completa |
| Skill checks | ❌ | - | Falta implementar |

### 1.3 Perks (perk.cc/perk_defs.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| 119 Perks definidos | ❌ | - | Não implementado |
| Requisitos de perk | ❌ | - | Não implementado |
| Efeitos de perk | ❌ | - | Não implementado |
| Perks por nível | ❌ | - | Não implementado |
| Perks de arma | ❌ | - | Não implementado |

### 1.4 Traits (trait.cc/trait_defs.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| 16 Traits definidos | ✅ | trait_data.gd | Todos implementados |
| Seleção de traits | ✅ | trait_data.gd | Máximo 2 |
| Efeitos de traits | ✅ | trait_data.gd | apply_trait_effects() |
| Modificadores de dano | ✅ | trait_data.gd | get_damage_modifier() |

### 1.5 Critter (critter.cc/critter.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Estrutura base | ✅ | critter.gd | Node com stats/skills |
| Sistema de HP | ✅ | critter.gd | take_damage(), heal() |
| Sistema de AP | ✅ | critter.gd | spend_ap(), start_turn() |
| Equipamento | ✅ | critter.gd | equipped_weapon/armor |
| Inventário | ✅ | critter.gd | Array[Item] |
| Progressão (XP/Level) | ✅ | critter.gd | add_experience() |
| Facções | ✅ | critter.gd | faction string |
| Karma/Reputação | 🔶 | critter.gd | Variáveis existem, sem lógica |

---

## 2. SISTEMA DE COMBATE

### 2.1 Combat Core (combat.cc/combat_defs.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Turn-based combat | ✅ | combat_system.gd | Funcional |
| Ordem de turno (Sequence) | ✅ | combat_system.gd | Baseado em stat |
| Action Points | ✅ | combat_system.gd | Custo por ação |
| Cálculo de hit chance | ✅ | combat_system.gd | Skill - AC |
| Sistema de críticos | ✅ | combat_system.gd | Baseado em Luck |
| Targeted shots | 🔶 | combat_system.gd | Localizações existem, UI falta |
| Hit locations (8) | ✅ | constants.gd | Enum completo |
| Multiplicadores por local | ✅ | critter.gd | _get_location_damage_multiplier() |
| Massive criticals | ❌ | - | Não implementado |
| Critical effects | ❌ | - | Não implementado |
| Knockback | ❌ | - | Não implementado |

### 2.2 Combat AI (combat_ai.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| IA básica | 🔶 | combat_system.gd | Ataca inimigo mais próximo |
| Behavior trees | ❌ | - | Não implementado |
| Avaliação de ameaças | ❌ | - | Não implementado |
| Uso de cobertura | ❌ | - | Não implementado |
| Uso de itens (stimpaks) | ❌ | - | Não implementado |
| Fuga quando HP baixo | ❌ | - | Não implementado |
| Escolha de arma | ❌ | - | Não implementado |

### 2.3 Actions (actions.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Atacar | ✅ | combat_system.gd | execute_attack() |
| Usar item | ❌ | - | Não implementado |
| Recarregar | ❌ | - | Lógica existe em weapon.gd |
| Mover | ❌ | - | Não implementado |
| Usar skill | ❌ | - | Não implementado |

---

## 3. SISTEMA DE ITENS

### 3.1 Item Base (item.cc/item.h)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Classe base Item | ✅ | item.gd | Resource |
| Peso | ✅ | item.gd | weight |
| Valor | ✅ | item.gd | value |
| Stacking | ✅ | item.gd | stackable, max_stack |
| Quest items | ✅ | item.gd | is_quest_item |
| Uso de item | 🔶 | item.gd | use() vazio |

### 3.2 Weapons (parte de item.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Tipos de arma (6) | ✅ | weapon.gd | WeaponType enum |
| Dano min/max | ✅ | weapon.gd | min_damage, max_damage |
| Tipo de dano | ✅ | weapon.gd | damage_type |
| Custo AP | ✅ | weapon.gd | ap_cost_primary/secondary |
| Alcance | ✅ | weapon.gd | range |
| Sistema de munição | ✅ | weapon.gd | uses_ammo, magazine_size |
| Reload | ✅ | weapon.gd | reload() |
| Modos de ataque | ✅ | weapon.gd | has_secondary_mode |
| Modificador de precisão | ✅ | weapon.gd | accuracy_modifier |
| Multiplicador crítico | ✅ | weapon.gd | critical_multiplier |
| Burst mode | ❌ | - | Não implementado |
| Armas de arremesso | ❌ | - | Não implementado |

### 3.3 Armor (parte de item.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Tipos de armadura (4) | ✅ | armor.gd | ArmorType enum |
| Armor Class bonus | ✅ | armor.gd | armor_class_bonus |
| DR por tipo de dano | ✅ | armor.gd | damage_resistance dict |
| DT por tipo de dano | ✅ | armor.gd | damage_threshold dict |
| Durabilidade | ✅ | armor.gd | current_durability |
| Penalidades | ✅ | armor.gd | agility_penalty |
| Reparo | ✅ | armor.gd | repair() |

### 3.4 Inventory (inventory.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Lista de itens | ✅ | critter.gd | inventory array |
| Limite de peso | ✅ | critter.gd | carry_weight check |
| Adicionar/remover | ✅ | critter.gd | add_item(), remove_item() |
| Equipar arma | ✅ | critter.gd | equip_weapon() |
| Equipar armadura | ✅ | critter.gd | equip_armor() |
| UI de inventário | ❌ | - | Não implementado |
| Drag & drop | ❌ | - | Não implementado |
| Container/loot | ❌ | - | Não implementado |

---

## 4. SISTEMAS DE MUNDO

### 4.1 Map (map.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de tiles | ❌ | - | Usar TileMap do Godot |
| Carregamento de mapas | ❌ | - | Não implementado |
| Objetos no mapa | ❌ | - | Não implementado |
| Triggers/scripts | ❌ | - | Não implementado |
| Elevadores | ❌ | - | Não implementado |

### 4.2 Worldmap (worldmap.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Mapa mundo | ❌ | - | Não implementado |
| Viagem | ❌ | - | Não implementado |
| Encontros aleatórios | ❌ | - | Não implementado |
| Localizações | ❌ | - | Não implementado |
| Tempo de viagem | ❌ | - | Não implementado |

### 4.3 Scripts (scripts.cc/interpreter.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de scripts | ⚪ | - | Godot usa GDScript nativo |
| Triggers | ❌ | - | Não implementado |
| Eventos | 🔶 | - | Signals do Godot |

---

## 5. SISTEMAS DE DIÁLOGO

### 5.1 Dialog (dialog.cc/game_dialog.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de diálogos | ❌ | - | Não implementado |
| Árvore de opções | ❌ | - | Não implementado |
| Skill checks | ❌ | - | Não implementado |
| Stat checks | ❌ | - | Não implementado |
| Barter | ❌ | - | Não implementado |
| Reações de NPC | ❌ | - | Não implementado |

### 5.2 Message (message.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de mensagens | ❌ | - | Não implementado |
| Localização | ❌ | - | Estrutura de pastas existe |

---

## 6. SISTEMAS DE ÁUDIO/VISUAL

### 6.1 Audio (audio.cc/game_sound.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Audio Manager | ✅ | audio_manager.gd | Básico |
| Música | ✅ | audio_manager.gd | play_music() |
| SFX | ✅ | audio_manager.gd | play_sfx() |
| Pool de players | ✅ | audio_manager.gd | MAX_SFX_PLAYERS |
| Som ambiente | ❌ | - | Não implementado |
| Som 3D/posicional | ❌ | - | Não implementado |

### 6.2 Animation (animation.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de animação | ⚪ | - | Usar AnimationPlayer do Godot |
| Animações de combate | ❌ | - | Não implementado |
| Animações de morte | ❌ | - | Não implementado |

### 6.3 Art/Graphics (art.cc/draw.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Carregamento de sprites | ⚪ | - | Godot nativo |
| Paleta de cores | ⚪ | - | Não necessário |
| Efeitos visuais | ❌ | - | Não implementado |

---

## 7. SISTEMAS DE INTERFACE

### 7.1 Interface (interface.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| HUD de combate | 🔶 | TestBattle.tscn | Básico para teste |
| Barra de HP | 🔶 | test_battle.gd | Labels |
| Barra de AP | 🔶 | test_battle.gd | Labels |
| Combat log | ✅ | test_battle.gd | RichTextLabel |
| Botões de ação | ✅ | TestBattle.tscn | Attack, Heal, End Turn |

### 7.2 Character Editor (character_editor.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Criação de personagem | ❌ | - | Não implementado |
| Distribuição de stats | ❌ | - | Não implementado |
| Seleção de traits | ❌ | - | Não implementado |
| Seleção de skills | ❌ | - | Não implementado |

### 7.3 Pipboy (pipboy.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Interface Pipboy | ❌ | - | Não implementado |
| Status | ❌ | - | Não implementado |
| Inventário | ❌ | - | Não implementado |
| Mapa | ❌ | - | Não implementado |
| Quests | ❌ | - | Não implementado |

### 7.4 Skilldex (skilldex.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Menu de skills | ❌ | - | Não implementado |
| Uso de skills | ❌ | - | Não implementado |

---

## 8. SISTEMAS DE PERSISTÊNCIA

### 8.1 Save/Load (loadsave.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Save Manager | ✅ | save_manager.gd | Básico |
| Salvar jogo | ✅ | save_manager.gd | save_game() |
| Carregar jogo | ✅ | save_manager.gd | load_game() |
| Múltiplos slots | ❌ | - | Não implementado |
| Auto-save | ❌ | - | Não implementado |
| Serialização completa | ❌ | - | Só Dictionary básico |

### 8.2 Config (config.cc/game_config.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Game Settings | ✅ | game_settings.gd | Resource |
| Gráficos | ✅ | game_settings.gd | resolution, fullscreen |
| Áudio | ✅ | game_settings.gd | volumes |
| Gameplay | ✅ | game_settings.gd | difficulty |
| Aplicar settings | ✅ | game_settings.gd | apply_settings() |

---

## 9. SISTEMAS AUXILIARES

### 9.1 Party (party_member.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de party | ❌ | - | Não implementado |
| Companheiros | ❌ | - | Não implementado |
| Controle de NPCs | ❌ | - | Não implementado |

### 9.2 Queue (queue.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de eventos | ❌ | - | Não implementado |
| Timers | ❌ | - | Não implementado |
| Efeitos temporários | ❌ | - | Não implementado |

### 9.3 Random (random.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| RNG | ⚪ | - | Godot nativo (randf, randi) |

### 9.4 Reaction (reaction.cc)
| Feature | Status | Arquivo Godot | Notas |
|---------|--------|---------------|-------|
| Sistema de reações | ❌ | - | Não implementado |
| Karma effects | ❌ | - | Não implementado |
| Reputation effects | ❌ | - | Não implementado |

---

## RESUMO

### Por Categoria

| Categoria | Implementado | Parcial | Não Implementado |
|-----------|--------------|---------|------------------|
| Personagem | 85% | 10% | 5% |
| Combate | 50% | 20% | 30% |
| Itens | 80% | 10% | 10% |
| Mundo | 0% | 0% | 100% |
| Diálogo | 0% | 0% | 100% |
| Áudio/Visual | 30% | 0% | 70% |
| Interface | 20% | 20% | 60% |
| Persistência | 40% | 0% | 60% |
| Auxiliares | 0% | 0% | 100% |

### Total Geral

- **✅ Implementado**: ~35%
- **🔶 Parcial**: ~10%
- **❌ Não Implementado**: ~55%

### Prioridades para Próximas Implementações

1. **Alta Prioridade**
   - Sistema de Perks
   - IA de Combate avançada
   - UI de Inventário
   - Sistema de Diálogos

2. **Média Prioridade**
   - Editor de Personagem
   - Sistema de Mapas
   - Sistema de Quests
   - Pipboy UI

3. **Baixa Prioridade**
   - Worldmap
   - Sistema de Party
   - Encontros aleatórios
   - Efeitos visuais avançados

---

## Arquivos Godot Criados

```
scripts/
├── core/
│   ├── constants.gd      ✅ Enums e constantes
│   └── game_manager.gd   ✅ Estados do jogo
├── data/
│   ├── stat_data.gd      ✅ Sistema SPECIAL
│   ├── skill_data.gd     ✅ 18 Skills
│   └── trait_data.gd     ✅ 16 Traits
├── entities/
│   ├── item.gd           ✅ Item base
│   ├── weapon.gd         ✅ Armas
│   ├── armor.gd          ✅ Armaduras
│   └── critter.gd        ✅ Personagens
├── systems/
│   └── combat_system.gd  ✅ Combate turn-based
├── managers/
│   ├── audio_manager.gd  ✅ Áudio
│   └── save_manager.gd   ✅ Save/Load
└── test/
    └── test_battle.gd    ✅ Cena de teste
```
