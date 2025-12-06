# Guia de Implementação - Sistema RPG Fallout-like

## Sistemas Implementados

### ✅ 1. Sistema de Stats (SPECIAL)
**Arquivo**: `scripts/data/stat_data.gd`

- 7 stats primários (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- Stats derivados calculados automaticamente (HP, AP, Armor Class, etc)
- Sistema de resistências por tipo de dano
- Damage Threshold e Damage Resistance

### ✅ 2. Sistema de Skills
**Arquivo**: `scripts/data/skill_data.gd`

- 18 skills divididas em categorias (Combat, Stealth, Social, Survival)
- Sistema de "Tagged Skills" (progridem mais rápido)
- Pontos de skill ganhos por nível baseado em Intelligence
- Valores de 0-200

### ✅ 3. Sistema de Itens
**Arquivos**: `scripts/entities/item.gd`, `weapon.gd`, `armor.gd`

#### Item Base
- Sistema de peso e valor
- Stacking para itens consumíveis
- Quest items

#### Weapons
- Tipos de arma (Melee, Ranged, Energy)
- Dano por tipo (Normal, Laser, Fire, etc)
- Sistema de munição
- Modos primário/secundário
- Custo de AP por ação

#### Armor
- Resistências por tipo de dano
- Damage Threshold por tipo
- Sistema de durabilidade
- Penalidades (Agility, Perception)

### ✅ 4. Sistema de Critters (Personagens)
**Arquivo**: `scripts/entities/critter.gd`

- Integração de Stats + Skills + Inventory
- Sistema de equipamento (arma, armadura)
- Progressão (XP, Level Up)
- Dano por localização (Head, Torso, Arms, Legs, etc)
- Gerenciamento de Action Points

### ✅ 5. Sistema de Combate Turn-Based
**Arquivo**: `scripts/systems/combat_system.gd`

- Combate por turnos
- Ordem baseada em Sequence stat
- Cálculo de chance de acerto
- Sistema de críticos
- Targeted shots (localização específica)
- IA básica para inimigos

### ✅ 6. Constantes Globais
**Arquivo**: `scripts/core/constants.gd`

- Enums para todos os sistemas
- Constantes de balanceamento
- Tipos de dano, armas, armaduras
- Estados de combate e IA

## Próximos Passos

### ✅ 7. Sistema de Traits
**Arquivo**: `scripts/data/trait_data.gd`

- 16 traits com vantagens e desvantagens
- Máximo 2 traits por personagem
- Escolhidos na criação do personagem
- Modificam stats, skills e gameplay

### 🔲 8. Sistema de Perks
Criar `scripts/data/perk_data.gd`:
- Definir perks disponíveis (119+ perks)
- Requisitos (nível, stats, skills)
- Efeitos (modificadores de stats, habilidades especiais)
- Sistema de seleção no level up

### 🔲 9. Sistema de Inventário UI
Criar `scenes/ui/inventory_ui.tscn`:
- Grid de itens
- Drag & drop
- Equipar/desequipar
- Informações de item
- Peso total vs carry weight

### 🔲 10. Sistema de Combate UI
Criar `scenes/ui/combat_ui.tscn`:
- Indicador de turno
- HP/AP bars
- Botões de ação (Attack, Item, End Turn)
- Seleção de alvo
- Targeted shot menu
- Log de combate

### 🔲 11. Sistema de IA Avançada
Melhorar `combat_system.gd`:
- Behavior trees
- Avaliação de ameaças
- Uso de itens (stimpaks)
- Táticas (cobertura, fuga)
- Percepção e detecção

### 🔲 12. Sistema de Diálogos
Criar `scripts/systems/dialog_system.gd`:
- Árvore de diálogos
- Skill checks (Speech, Barter)
- Stat checks (Intelligence, Charisma)
- Consequências de escolhas
- Sistema de reputação

### 🔲 13. Sistema de Quests
Criar `scripts/systems/quest_system.gd`:
- Objetivos
- Tracking de progresso
- Recompensas (XP, itens, reputação)
- Quest log

## Como Usar os Sistemas

### Criando um Personagem

```gdscript
# Criar jogador
var player := Critter.new()
player.critter_name = "Vault Dweller"
player.is_player = true

# Configurar stats
player.stats.strength = 6
player.stats.perception = 7
player.stats.endurance = 5
player.stats.charisma = 4
player.stats.intelligence = 8
player.stats.agility = 7
player.stats.luck = 6
player.stats.calculate_derived_stats()

# Tag skills
player.skills.tag_skill(SkillData.Skill.SMALL_GUNS)
player.skills.tag_skill(SkillData.Skill.SPEECH)
player.skills.tag_skill(SkillData.Skill.SCIENCE)
```

### Criando uma Arma

```gdscript
var pistol := Weapon.new()
pistol.item_name = "10mm Pistol"
pistol.weapon_type = GameConstants.WeaponType.SMALL_GUN
pistol.damage_type = GameConstants.DamageType.NORMAL
pistol.min_damage = 5
pistol.max_damage = 12
pistol.ap_cost_primary = 5
pistol.range = 20
pistol.uses_ammo = true
pistol.magazine_size = 12
pistol.current_ammo = 12

player.equip_weapon(pistol)
```

### Criando uma Armadura

```gdscript
var leather_armor := Armor.new()
leather_armor.item_name = "Leather Armor"
leather_armor.armor_type = GameConstants.ArmorType.LIGHT
leather_armor.armor_class_bonus = 5
leather_armor.damage_resistance[GameConstants.DamageType.NORMAL] = 20
leather_armor.damage_threshold[GameConstants.DamageType.NORMAL] = 2

player.equip_armor(leather_armor)
```

### Iniciando Combate

```gdscript
var combat := CombatSystem.new()
add_child(combat)

var enemies: Array[Critter] = [enemy1, enemy2]
var all_combatants: Array[Critter] = [player] + enemies

combat.start_combat(all_combatants)

# Conectar sinais
combat.turn_started.connect(_on_turn_started)
combat.attack_executed.connect(_on_attack_executed)
combat.combat_ended.connect(_on_combat_ended)
```

### Executando Ataque

```gdscript
func _on_player_attack_button_pressed(target: Critter) -> void:
	if combat.is_player_turn():
		var result := combat.execute_attack(
			player,
			target,
			GameConstants.HitLocation.TORSO
		)
		
		if result.hit:
			print("Hit! Damage: %d" % result.damage)
			if result.critical:
				print("CRITICAL HIT!")
```

## Balanceamento

### Stats Recomendados por Arquétipo

**Combatente**
- STR: 7, PER: 6, END: 7, CHA: 3, INT: 5, AGI: 7, LCK: 5
- Skills: Small Guns, Melee, First Aid

**Furtivo**
- STR: 4, PER: 7, END: 5, CHA: 5, INT: 7, AGI: 8, LCK: 4
- Skills: Sneak, Lockpick, Small Guns

**Diplomata**
- STR: 4, PER: 6, END: 5, CHA: 8, INT: 8, AGI: 5, LCK: 4
- Skills: Speech, Barter, Science

### Progressão de Dano

- **Nível 1-5**: 5-15 dano
- **Nível 6-10**: 10-25 dano
- **Nível 11-15**: 20-40 dano
- **Nível 16+**: 30-60 dano

### XP por Nível

```
Level 2: 1000 XP
Level 3: 3000 XP
Level 4: 6000 XP
Level 5: 10000 XP
...
```

## Testes

### Testar Sistema de Combate

```gdscript
func test_combat() -> void:
	var player := _create_test_player()
	var enemy := _create_test_enemy()
	
	var combat := CombatSystem.new()
	add_child(combat)
	
	combat.start_combat([player, enemy])
	
	# Simular alguns turnos
	for i in 5:
		if combat.is_player_turn():
			combat.execute_attack(player, enemy)
		combat.end_turn()
```

## Referências

- **Fallout 2 CE**: `fallout2-ce-main/` (código fonte original)
- **Documentação**: `docs/design/FALLOUT2_ANALYSIS.md`
- **Arquitetura**: `docs/design/ARCHITECTURE.md`
