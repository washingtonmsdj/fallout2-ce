# Análise do Fallout 2 Community Edition

## Visão Geral

O Fallout 2 CE é uma reimplementação completa do motor do Fallout 2 clássico. Esta análise extrai os conceitos principais para aplicar em projetos modernos.

## Sistemas Principais

### 1. Sistema SPECIAL (Stats)

**SPECIAL** = Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck

#### Stats Primários (7)
- **Strength**: Força física, dano corpo-a-corpo, peso carregável
- **Perception**: Percepção, precisão, detecção
- **Endurance**: Resistência, HP, resistências
- **Charisma**: Carisma, reações de NPCs, companheiros
- **Intelligence**: Inteligência, pontos de skill, diálogos
- **Agility**: Agilidade, Action Points, sequência de combate
- **Luck**: Sorte, críticos, eventos aleatórios

Valores: 1-10 (mínimo-máximo)

#### Stats Derivados (26)
- **HP**: Pontos de vida (derivado de Endurance)
- **AP**: Action Points para combate turn-based
- **Armor Class**: Chance de esquiva
- **Carry Weight**: Peso máximo carregável
- **Melee/Unarmed Damage**: Dano base
- **Sequence**: Ordem de turno no combate
- **Healing Rate**: Taxa de cura natural
- **Critical Chance**: Chance de acerto crítico
- **Damage Threshold/Resistance**: Por tipo de dano (Normal, Laser, Fire, Plasma, Electrical, EMP, Explosion)

#### Stats do Jogador (5)
- Pontos de skill não gastos
- Nível
- Experiência
- Reputação
- Karma

### 2. Sistema de Skills (18)

#### Combate
- Small Guns, Big Guns, Energy Weapons
- Unarmed, Melee Weapons, Throwing

#### Stealth & Theft
- Sneak, Lockpick, Steal, Traps

#### Social
- Speech, Barter

#### Survival
- First Aid, Doctor, Science, Repair, Outdoorsman, Gambling

**Tagged Skills**: 3-4 skills que começam com bônus e progridem mais rápido

### 3. Sistema de Perks (119+)

Habilidades especiais desbloqueadas por nível. Exemplos:

#### Combate
- **Bonus Ranged Damage**: +2 dano com armas de longo alcance
- **Better Criticals**: +20% dano em críticos
- **Sniper**: Críticos sempre acertam olhos
- **Slayer**: Ataques corpo-a-corpo sempre críticos

#### Defesa
- **Toughness**: +10% resistência a dano
- **Dodger**: +5 Armor Class
- **Lifegiver**: +4 HP por nível

#### Utilidade
- **Swift Learner**: +5% XP
- **Strong Back**: +50 lbs carry weight
- **Pack Rat**: Itens pesam 50% menos

### 4. Sistema de Combate Turn-Based

#### Action Points (AP)
- Cada ação consome AP
- Movimento, ataque, reload, usar item
- AP regenera no próximo turno

#### Hit Modes
- **Armas**: Primário, Secundário, Reload
- **Desarmado**: Punch, Kick (7 níveis cada)
  - Punch: Strong → Hammer → Haymaker → Jab → Palm Strike → Piercing Strike
  - Kick: Strong → Snap → Power → Hip → Hook → Piercing

#### Hit Locations (Targeted Shots)
- Head, Eyes (mais difícil, mais dano)
- Torso (padrão)
- Arms (pode desarmar)
- Legs (reduz movimento)
- Groin (crítico especial)

#### Critical Hits
- Baseado em Luck e Perks
- Efeitos especiais por localização
- Massive Criticals (críticos extremos)
- Mensagens descritivas únicas

#### Damage System
- **Damage Threshold (DT)**: Redução fixa de dano
- **Damage Resistance (DR)**: Redução percentual
- Tipos de dano: Normal, Laser, Fire, Plasma, Electrical, EMP, Explosion
- Armaduras têm DT/DR específicos por tipo

### 5. Sistema de Inventário

#### Características
- Peso limitado (baseado em Strength)
- Slots de equipamento (arma, armadura, etc)
- Stacking de itens
- Durabilidade de equipamentos
- Munição por tipo de arma

#### Tipos de Itens
- Armas (corpo-a-corpo, armas de fogo, energia)
- Armaduras (leve, média, pesada, power armor)
- Consumíveis (stimpaks, drogas, comida)
- Munição
- Misc (chaves, quest items)

### 6. Sistema de Progressão

#### Experiência
- Ganho por: combate, quests, diálogos, descobertas
- Curva exponencial de XP por nível
- Nível máximo: 99

#### Level Up
- Pontos de skill para distribuir
- A cada 3 níveis: escolher um Perk
- Possibilidade de aumentar stats (via Perks especiais)

### 7. Sistema de IA

#### Behavior Trees
- Avaliação de ameaças
- Escolha de armas baseada em situação
- Uso de cobertura
- Fuga quando HP baixo
- Uso de itens (stimpaks, drogas)

#### Percepção
- Campo de visão
- Detecção por som
- Stealth vs Perception check

## Arquitetura de Código

### Separação de Concerns
```
stats/skills/perks → Definições (enums, constantes)
critter → Entidade base (jogador, NPCs, inimigos)
combat → Sistema de combate
item/inventory → Sistema de itens
ai → Inteligência artificial
```

### Padrões Observados

1. **Data-Driven Design**: Stats, skills, perks são dados, não código
2. **Component-Based**: Critters têm componentes (stats, inventory, ai)
3. **Event System**: Combate usa eventos para efeitos
4. **State Machines**: IA e combate usam estados
5. **Lookup Tables**: Críticos, dano, XP em tabelas

## Lições para Projetos Modernos

### O que Funciona Bem
- Sistema SPECIAL é balanceado e profundo
- Turn-based permite decisões táticas
- Targeted shots adicionam estratégia
- Perks criam builds únicos
- Sistema de críticos é satisfatório

### O que Modernizar
- UI/UX mais intuitiva
- Feedback visual melhor
- Animações mais fluidas
- Tutorial integrado
- Balanceamento dinâmico

### Aplicação no Godot

1. **Resources** para dados (stats, skills, perks)
2. **Nodes** para entidades (CharacterBody3D com scripts)
3. **Signals** para eventos de combate
4. **State Machines** para IA e combate
5. **Autoloads** para managers globais


## 8. Sistema de Traits

**Traits** são características permanentes escolhidas na criação do personagem. Diferente de Perks, Traits têm vantagens E desvantagens.

### Características (16 Traits)

Máximo: 2 traits por personagem

#### Combate
- **Fast Metabolism**: +2 Healing Rate, mas radiação/veneno duram mais
- **Bruiser**: +2 Strength, -2 Action Points
- **Heavy Handed**: +4 dano corpo-a-corpo, -30% Critical Chance
- **Finesse**: +10% Critical Chance, -30% dano base
- **Fast Shot**: -1 AP em ataques, mas sem targeted shots
- **Kamikaze**: +5 Sequence, mas Armor Class = 0
- **Bloody Mess**: +5% dano, animações violentas

#### Físico
- **Small Frame**: +1 Agility, -10% carry weight
- **One Hander**: +20% acerto uma mão, -40% duas mãos

#### Social
- **Sex Appeal**: Melhor com sexo oposto, pior com mesmo sexo
- **Good Natured**: +15% skills sociais, -10% skills combate

#### Químicos
- **Chem Reliant**: Drogas duram 2x, vício 2x mais rápido
- **Chem Resistant**: 50% resistência vício, drogas duram metade

#### Especiais
- **Jinxed**: Mais critical failures para TODOS
- **Skilled**: +5 skill points/nível, perk a cada 4 níveis
- **Gifted**: +1 todos SPECIAL, -10% skills, -5 skill points/nível

### Design Philosophy

Traits criam **trade-offs interessantes**:
- Gifted é poderoso no início, mas fraco no late game
- Skilled é fraco no início, mas forte no late game
- Fast Shot muda completamente o estilo de combate
- Jinxed afeta TODO o jogo (aliados e inimigos)

## 9. Sistema de Prototypes (Proto)

O Fallout usa um sistema de **prototypes** para definir objetos base:

### Tipos de Proto
- **Item Proto**: Armas, armaduras, consumíveis
- **Critter Proto**: Personagens, NPCs, inimigos
- **Scenery Proto**: Portas, escadas, elevadores
- **Wall Proto**: Paredes
- **Tile Proto**: Tiles de chão
- **Misc Proto**: Objetos diversos

### Item Proto Structure

#### Weapon Data
```cpp
- animationCode: Animação de ataque
- minDamage/maxDamage: Dano
- damageType: Tipo de dano
- maxRange1/maxRange2: Alcance primário/secundário
- minStrength: Força mínima
- actionPointCost1/2: Custo de AP
- criticalFailureType: Tipo de falha crítica
- rounds: Rajadas
- caliber: Calibre da munição
- ammoCapacity: Capacidade de munição
```

#### Armor Data
```cpp
- armorClass: Bônus de AC
- damageResistance[7]: Resistência por tipo
- damageThreshold[7]: Threshold por tipo
- perk: Perk especial da armadura
- maleFid/femaleFid: Sprites por gênero
```

#### Drug Data
```cpp
- stat[3]: Stats afetados
- amount[3]: Quantidade de modificação
- duration1/duration2: Duração dos efeitos
- addictionChance: Chance de vício
- withdrawalEffect: Efeito de abstinência
```

### Critter Proto Structure
```cpp
- baseStats[35]: Stats base
- bonusStats[35]: Bônus de stats
- skills[18]: Valores de skills
- bodyType: Tipo de corpo (Biped, Quadruped, Robotic)
- experience: XP dado ao matar
- killType: Tipo para estatísticas
- damageType: Tipo de dano natural
- aiPacket: Pacote de IA
- team: Time/facção
```

### Material Types
- Glass, Metal, Plastic, Wood
- Dirt, Stone, Cement, Leather
- Afeta sons de impacto e destruição

### Caliber Types (19 tipos)
- Rocket, Flamethrower Fuel
- Energy Cells (C, D)
- Bullets: .223, 5mm, .40, 10mm, .44, 14mm, 12 gauge, 9mm, .45, 7.62
- Especiais: BB, 2mm, 4.7mm Caseless, NH Needler

### Body Types
- **Biped**: Humanos, mutantes
- **Quadruped**: Animais
- **Robotic**: Robôs

### Kill Types (19 tipos)
Para estatísticas de kills:
- Man, Woman, Child
- Super Mutant, Ghoul
- Brahmin, Radscorpion, Rat
- Floater, Centaur, Robot
- Dog, Mantis, Death Claw
- Plant, Gecko, Alien
- Giant Ant, Big Bad Boss

## 10. Sistema de Munição

### Características
- **Caliber**: Tipo de munição
- **Quantity**: Quantidade por stack
- **AC Modifier**: Modificador de Armor Class
- **DR Modifier**: Modificador de Damage Resistance
- **Damage Multiplier/Divisor**: Modificador de dano

### Tipos Especiais
- **AP (Armor Piercing)**: Ignora parte da armadura
- **JHP (Jacketed Hollow Point)**: Mais dano, menos penetração
- **FMJ (Full Metal Jacket)**: Balanceado

## Conclusão da Análise

O Fallout 2 é um exemplo perfeito de **data-driven design**:
- Tudo é definido em dados (proto files)
- Código é genérico e reutilizável
- Fácil de balancear e modificar
- Suporta mods extensivamente

### Principais Takeaways

1. **Separação de Dados e Lógica**: Stats, skills, items são dados
2. **Sistema Modular**: Cada sistema é independente
3. **Trade-offs Interessantes**: Traits, perks, stats criam escolhas difíceis
4. **Profundidade Tática**: Combate turn-based com muitas opções
5. **Progressão Satisfatória**: XP, levels, perks, equipment
6. **Balanceamento por Números**: Tudo é ajustável via dados

Este código é uma masterclass em design de RPG!
