# Requirements Document

## Introduction

Este documento especifica os requisitos para a migração completa do Fallout 2 Community Edition para o Godot Engine 4.5. O objetivo é recriar todos os sistemas de gameplay do jogo original, incluindo combate turn-based, sistema SPECIAL, skills, perks, traits, inventário, diálogos, worldmap, e todas as interfaces de usuário.

O projeto utiliza o código fonte do Fallout 2 CE (C++) como referência para garantir fidelidade às mecânicas originais.

## Glossary

- **SPECIAL**: Sistema de atributos primários (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- **Critter**: Entidade de personagem (jogador, NPC, inimigo)
- **AP (Action Points)**: Pontos de ação gastos em combate
- **DT (Damage Threshold)**: Redução fixa de dano por tipo
- **DR (Damage Resistance)**: Redução percentual de dano por tipo
- **Perk**: Habilidade especial desbloqueada por nível
- **Trait**: Característica escolhida na criação com vantagens/desvantagens
- **Tagged Skill**: Skill que progride mais rápido
- **Hit Location**: Parte do corpo alvo de ataque (Head, Torso, Arms, Legs, Eyes, Groin)
- **Worldmap**: Mapa de viagem entre localizações
- **Pipboy**: Interface principal do jogador para status, inventário, mapa e quests

## Requirements

### Requirement 1: Sistema de Perks Completo

**User Story:** As a player, I want to unlock special abilities as I level up, so that I can customize my character build and gain unique combat and non-combat advantages.

#### Acceptance Criteria

1. WHEN the Perk system initializes THEN the system SHALL define all 119 perks from Fallout 2 with their names, descriptions, and effects
2. WHEN a player reaches a perk-eligible level THEN the system SHALL present available perks filtered by requirements (level, stats, skills)
3. WHEN a player selects a perk THEN the system SHALL apply the perk's effects to the character's stats, skills, or abilities
4. WHEN a perk has multiple ranks THEN the system SHALL track the current rank and allow selection up to the maximum
5. WHEN a perk modifies combat THEN the system SHALL apply damage bonuses, accuracy modifiers, or special effects during attacks
6. WHEN a perk modifies non-combat abilities THEN the system SHALL apply skill bonuses, carry weight increases, or other passive effects

### Requirement 2: Sistema de IA de Combate Avançada

**User Story:** As a player, I want enemies to behave intelligently in combat, so that battles are challenging and tactical.

#### Acceptance Criteria

1. WHEN an AI-controlled critter starts its turn THEN the system SHALL evaluate all possible actions and select the optimal one
2. WHEN an AI critter has low HP THEN the system SHALL consider using healing items or fleeing based on AI personality
3. WHEN an AI critter has multiple weapons THEN the system SHALL select the most effective weapon for the current situation
4. WHEN cover is available THEN the system SHALL position the AI critter to minimize exposure while maintaining attack capability
5. WHEN an AI critter detects a threat THEN the system SHALL alert nearby allies and coordinate group tactics
6. WHEN an AI critter runs out of ammo THEN the system SHALL switch to melee weapons or reload based on tactical assessment

### Requirement 3: Sistema de Mapas e Tiles

**User Story:** As a player, I want to explore detailed maps with interactive objects, so that I can navigate the game world and interact with the environment.

#### Acceptance Criteria

1. WHEN a map loads THEN the system SHALL render all tiles, objects, and critters in their correct positions
2. WHEN a player clicks on a walkable tile THEN the system SHALL calculate and execute pathfinding to that location
3. WHEN a player interacts with a door THEN the system SHALL open, close, or indicate locked status based on door state
4. WHEN a player interacts with a container THEN the system SHALL display the container's inventory for looting
5. WHEN a player enters a trigger zone THEN the system SHALL execute the associated script or event
6. WHEN a map has multiple elevations THEN the system SHALL handle transitions between levels via stairs or elevators

### Requirement 4: Sistema de Worldmap e Viagem

**User Story:** As a player, I want to travel between locations on a world map, so that I can explore the wasteland and discover new areas.

#### Acceptance Criteria

1. WHEN the player opens the worldmap THEN the system SHALL display all discovered locations and the player's current position
2. WHEN the player selects a destination THEN the system SHALL calculate travel time based on distance and Outdoorsman skill
3. WHILE traveling THEN the system SHALL check for random encounters based on location danger level
4. WHEN a random encounter triggers THEN the system SHALL generate appropriate enemies and terrain for combat
5. WHEN the player discovers a new location THEN the system SHALL add it to the worldmap permanently
6. WHEN the player has a vehicle THEN the system SHALL reduce travel time and modify encounter rates

### Requirement 5: Sistema de Diálogos Completo

**User Story:** As a player, I want to engage in meaningful conversations with NPCs, so that I can gather information, complete quests, and influence the game world.

#### Acceptance Criteria

1. WHEN the player initiates dialogue THEN the system SHALL display the NPC's greeting based on reputation and previous interactions
2. WHEN dialogue options are presented THEN the system SHALL show available responses including skill-check options
3. WHEN a dialogue option requires a skill check THEN the system SHALL roll against the relevant skill and show success/failure
4. WHEN a dialogue option requires a stat check THEN the system SHALL compare the player's stat to the threshold
5. WHEN the player selects a barter option THEN the system SHALL open the trading interface with appropriate prices
6. WHEN dialogue affects reputation THEN the system SHALL update karma and faction standings accordingly

### Requirement 6: Sistema de Quests

**User Story:** As a player, I want to track and complete quests, so that I can progress through the game's story and earn rewards.

#### Acceptance Criteria

1. WHEN the player receives a quest THEN the system SHALL add it to the quest log with objectives and description
2. WHEN a quest objective is completed THEN the system SHALL update the quest status and notify the player
3. WHEN all objectives are complete THEN the system SHALL mark the quest as ready for turn-in
4. WHEN the player turns in a quest THEN the system SHALL grant XP, items, and reputation rewards
5. WHEN a quest has multiple paths THEN the system SHALL track which path the player chose and adjust outcomes
6. WHEN a quest fails THEN the system SHALL update the quest log and apply any failure consequences

### Requirement 7: Interface Pipboy Completa

**User Story:** As a player, I want a comprehensive interface to view my character status, inventory, map, and quests, so that I can manage my character effectively.

#### Acceptance Criteria

1. WHEN the player opens the Pipboy THEN the system SHALL display the main menu with Status, Inventory, Map, and Data tabs
2. WHEN viewing Status THEN the system SHALL show all SPECIAL stats, derived stats, skills, perks, and current effects
3. WHEN viewing Inventory THEN the system SHALL display all items organized by category with weight and value
4. WHEN viewing Map THEN the system SHALL show the local area map with markers for important locations
5. WHEN viewing Data THEN the system SHALL display active quests, completed quests, and game statistics
6. WHEN the player uses an item from Pipboy THEN the system SHALL apply the item's effect and update inventory

### Requirement 8: Editor de Personagem

**User Story:** As a player, I want to create and customize my character at the start of the game, so that I can define my playstyle and role-playing experience.

#### Acceptance Criteria

1. WHEN character creation starts THEN the system SHALL present the SPECIAL stat allocation interface with 40 points to distribute
2. WHEN allocating SPECIAL points THEN the system SHALL enforce minimum (1) and maximum (10) values per stat
3. WHEN selecting traits THEN the system SHALL allow up to 2 traits and display their benefits and drawbacks
4. WHEN tagging skills THEN the system SHALL allow 3 skills to be tagged with +20 bonus and faster progression
5. WHEN naming the character THEN the system SHALL validate the name and store it for use throughout the game
6. WHEN character creation completes THEN the system SHALL calculate all derived stats and initialize the character

### Requirement 9: Sistema de Party e Companheiros

**User Story:** As a player, I want to recruit and manage companions, so that I can have allies in combat and access their unique abilities.

#### Acceptance Criteria

1. WHEN the player recruits a companion THEN the system SHALL add them to the party with their stats, skills, and inventory
2. WHEN in combat THEN the system SHALL include party members in the turn order based on their Sequence stat
3. WHEN a party member's HP reaches zero THEN the system SHALL mark them as unconscious or dead based on damage
4. WHEN the player opens party management THEN the system SHALL allow equipment changes and behavior settings
5. WHEN a party member has dialogue THEN the system SHALL trigger their comments based on location and events
6. WHEN the party limit is reached THEN the system SHALL prevent recruiting additional companions until one leaves

### Requirement 10: Sistema de Efeitos Temporários

**User Story:** As a player, I want temporary effects from items, perks, and combat to affect my character, so that tactical decisions have meaningful consequences.

#### Acceptance Criteria

1. WHEN a timed effect is applied THEN the system SHALL add it to the effect queue with duration and magnitude
2. WHEN time passes THEN the system SHALL decrement effect durations and remove expired effects
3. WHEN a drug is consumed THEN the system SHALL apply immediate effects and schedule withdrawal effects
4. WHEN addiction occurs THEN the system SHALL apply permanent penalties until cured
5. WHEN a crippled limb effect is applied THEN the system SHALL reduce relevant stats until healed
6. WHEN multiple effects stack THEN the system SHALL calculate the combined effect correctly

### Requirement 11: Sistema de Combate Avançado

**User Story:** As a player, I want deep combat mechanics including critical hits, knockback, and special attacks, so that combat is varied and exciting.

#### Acceptance Criteria

1. WHEN a critical hit occurs THEN the system SHALL apply the critical effect based on hit location and roll on the critical table
2. WHEN a massive critical occurs THEN the system SHALL apply additional effects like instant death or limb crippling
3. WHEN knockback is triggered THEN the system SHALL move the target away from the attacker based on damage
4. WHEN using burst fire THEN the system SHALL calculate hits on multiple targets in the cone of fire
5. WHEN using aimed shots THEN the system SHALL apply accuracy penalties and damage/effect bonuses by location
6. WHEN a weapon jams or breaks THEN the system SHALL prevent further use until repaired

### Requirement 12: Sistema de Economia e Comércio

**User Story:** As a player, I want to buy, sell, and trade items with merchants, so that I can acquire equipment and manage my resources.

#### Acceptance Criteria

1. WHEN opening a trade interface THEN the system SHALL display both inventories with prices adjusted by Barter skill
2. WHEN selecting items to trade THEN the system SHALL calculate the total value and show the balance
3. WHEN confirming a trade THEN the system SHALL transfer items and currency between parties
4. WHEN a merchant has limited caps THEN the system SHALL prevent trades exceeding their available currency
5. WHEN reputation affects prices THEN the system SHALL apply discounts or markups based on faction standing
6. WHEN stealing from a merchant THEN the system SHALL use Steal skill and apply consequences if caught

### Requirement 13: Sistema de Reputação e Karma

**User Story:** As a player, I want my actions to affect how the world perceives me, so that my choices have lasting consequences.

#### Acceptance Criteria

1. WHEN the player performs a good action THEN the system SHALL increase karma by the appropriate amount
2. WHEN the player performs an evil action THEN the system SHALL decrease karma by the appropriate amount
3. WHEN karma reaches certain thresholds THEN the system SHALL assign titles (Childkiller, Champion, etc.)
4. WHEN interacting with factions THEN the system SHALL track reputation separately for each faction
5. WHEN reputation is very low THEN the system SHALL trigger hostile reactions from that faction
6. WHEN reputation is very high THEN the system SHALL unlock special dialogue options and rewards

### Requirement 14: Sistema de Salvamento Completo

**User Story:** As a player, I want to save and load my game progress, so that I can continue playing across sessions and recover from mistakes.

#### Acceptance Criteria

1. WHEN the player saves the game THEN the system SHALL serialize all game state including character, world, and quest data
2. WHEN the player loads a save THEN the system SHALL deserialize and restore the exact game state
3. WHEN multiple save slots exist THEN the system SHALL display them with timestamps and character info
4. WHEN auto-save triggers THEN the system SHALL save to a dedicated slot without interrupting gameplay
5. WHEN a save file is corrupted THEN the system SHALL detect the error and notify the player
6. WHEN quicksave is used THEN the system SHALL save immediately to a dedicated quicksave slot

### Requirement 15: Sistema de Som e Música Completo

**User Story:** As a player, I want immersive audio including music, sound effects, and ambient sounds, so that the game atmosphere is enhanced.

#### Acceptance Criteria

1. WHEN entering a new area THEN the system SHALL crossfade to the appropriate ambient music
2. WHEN combat starts THEN the system SHALL transition to combat music
3. WHEN an action occurs THEN the system SHALL play the appropriate sound effect
4. WHEN dialogue plays THEN the system SHALL play voice lines if available
5. WHEN in the wasteland THEN the system SHALL play ambient environmental sounds
6. WHEN audio settings change THEN the system SHALL apply volume adjustments immediately

### Requirement 16: Sistema de Animações de Combate

**User Story:** As a player, I want to see visual feedback for combat actions, so that battles feel impactful and clear.

#### Acceptance Criteria

1. WHEN an attack is executed THEN the system SHALL play the appropriate attack animation
2. WHEN damage is dealt THEN the system SHALL play hit reaction animations on the target
3. WHEN a critical hit occurs THEN the system SHALL play enhanced death or injury animations
4. WHEN a critter dies THEN the system SHALL play death animation appropriate to the damage type
5. WHEN reloading THEN the system SHALL play the weapon reload animation
6. WHEN using items THEN the system SHALL play the item use animation

### Requirement 17: Sistema de Habilidades Ativas

**User Story:** As a player, I want to use skills actively in the world, so that my character build affects exploration and problem-solving.

#### Acceptance Criteria

1. WHEN using Lockpick on a locked container THEN the system SHALL roll against skill and unlock on success
2. WHEN using Repair on a broken item THEN the system SHALL restore durability based on skill level
3. WHEN using Science on a computer THEN the system SHALL allow hacking attempts based on skill
4. WHEN using Doctor on an injured character THEN the system SHALL heal HP and cure conditions based on skill
5. WHEN using Steal on an NPC THEN the system SHALL attempt to take items based on skill vs perception
6. WHEN using Sneak THEN the system SHALL reduce detection chance based on skill level

### Requirement 18: Sistema de Containers e Loot

**User Story:** As a player, I want to find and loot containers throughout the world, so that I can acquire items and resources.

#### Acceptance Criteria

1. WHEN interacting with a container THEN the system SHALL display its contents in a loot interface
2. WHEN taking items THEN the system SHALL transfer them to player inventory respecting weight limits
3. WHEN a container is locked THEN the system SHALL require lockpicking or a key to access
4. WHEN a container is trapped THEN the system SHALL trigger the trap unless disarmed
5. WHEN looting a corpse THEN the system SHALL display all items the critter was carrying
6. WHEN a container respawns THEN the system SHALL regenerate contents after the specified time

### Requirement 19: Sistema de Iluminação e Visão

**User Story:** As a player, I want lighting to affect visibility and combat, so that time of day and environment matter tactically.

#### Acceptance Criteria

1. WHEN it is nighttime THEN the system SHALL reduce visibility range for all critters
2. WHEN a light source is present THEN the system SHALL increase visibility in its radius
3. WHEN attacking in darkness THEN the system SHALL apply accuracy penalties
4. WHEN the Night Vision perk is active THEN the system SHALL reduce darkness penalties
5. WHEN using a flare THEN the system SHALL create a temporary light source
6. WHEN entering a dark area THEN the system SHALL adjust the visual presentation accordingly

### Requirement 20: Sistema de Veículos

**User Story:** As a player, I want to acquire and use vehicles, so that I can travel faster and carry more items.

#### Acceptance Criteria

1. WHEN the player acquires a vehicle THEN the system SHALL add it to the player's assets with its stats
2. WHEN traveling with a vehicle THEN the system SHALL reduce worldmap travel time significantly
3. WHEN the vehicle needs fuel THEN the system SHALL consume fuel items from inventory during travel
4. WHEN the vehicle is damaged THEN the system SHALL require repair before further use
5. WHEN the vehicle has trunk space THEN the system SHALL provide additional inventory storage
6. WHEN entering a location THEN the system SHALL park the vehicle at the entrance
