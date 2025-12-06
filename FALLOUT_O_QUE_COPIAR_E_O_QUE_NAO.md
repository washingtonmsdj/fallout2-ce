# Fallout 2 CE: O Que Copiar vs O Que NÃO Copiar

## 🎯 Regra de Ouro

**COPIE:** Lógica de gameplay, fórmulas, valores, mecânicas
**NÃO COPIE:** Infraestrutura, renderização, input, audio, janelas

---

## ❌ NÃO COPIAR - Infraestrutura (Godot já tem)

### 1. Sistema de Renderização

```cpp
// ❌ NÃO COPIE ISSO - tile.cc, svga.cc, draw.cc
void tile_render(int x, int y, unsigned char* data, int width, int height) {
    // Código de renderização low-level
    unsigned char* screen = getScreenBuffer();
    for (int i = 0; i < height; i++) {
        memcpy(screen + (y + i) * SCREEN_WIDTH + x, 
               data + i * width, width);
    }
}

void svga_blit(unsigned char* src, int srcWidth, int srcHeight,
               int srcPitch, unsigned char* dest, int destPitch) {
    // Blitting manual de pixels
}
```

**Por quê não copiar?**
- Godot tem Sprite2D, AnimatedSprite2D
- Batching automático
- GPU acceleration
- Z-ordering automático

**Use no Godot:**
```gdscript
# ✅ Use isso
var sprite = Sprite2D.new()
sprite.texture = load("res://assets/hero.png")
sprite.position = Vector2(x, y)
add_child(sprite)
```

---

### 2. Sistema de Janelas e Display

```cpp
// ❌ NÃO COPIE ISSO - window_manager.cc, svga.cc
int window_create(int x, int y, int width, int height, int color, int flags) {
    Window* window = (Window*)malloc(sizeof(Window));
    window->buffer = (unsigned char*)malloc(width * height);
    window->rect.x = x;
    window->rect.y = y;
    // ... gerenciamento manual de janelas
}

void window_draw(Window* window) {
    // Desenha janela pixel por pixel
}
```

**Por quê não copiar?**
- Godot tem Control nodes (Panel, Window, etc)
- Layout automático
- Theme system
- Responsive design

**Use no Godot:**
```gdscript
# ✅ Use isso
var panel = Panel.new()
panel.position = Vector2(x, y)
panel.size = Vector2(width, height)
add_child(panel)
```

---

### 3. Sistema de Input

```cpp
// ❌ NÃO COPIE ISSO - input.cc, kb.cc, mouse.cc
int input_get_key() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_KEYDOWN) {
            return event.key.keysym.sym;
        }
    }
    return -1;
}

void mouse_get_position(int* x, int* y) {
    SDL_GetMouseState(x, y);
}
```

**Por quê não copiar?**
- Godot tem Input singleton
- Action mapping
- Gamepad support automático

**Use no Godot:**
```gdscript
# ✅ Use isso
func _input(event):
    if event.is_action_pressed("attack"):
        attack()
```

---

### 4. Sistema de Audio

```cpp
// ❌ NÃO COPIE ISSO - sound.cc, audio.cc
void sound_play(Sound* sound, int volume) {
    Mix_Volume(-1, volume);
    Mix_PlayChannel(-1, sound->chunk, 0);
}

void music_play(const char* filename) {
    Mix_Music* music = Mix_LoadMUS(filename);
    Mix_PlayMusic(music, -1);
}
```

**Por quê não copiar?**
- Godot tem AudioStreamPlayer
- Audio buses
- Effects (reverb, etc)
- 3D spatial audio

**Use no Godot:**
```gdscript
# ✅ Use isso
var audio = AudioStreamPlayer.new()
audio.stream = load("res://sounds/gunshot.ogg")
audio.play()
```

---

### 5. Sistema de Arquivos e Carregamento

```cpp
// ❌ NÃO COPIE ISSO - db.cc, loadsave.cc
File* file_open(const char* path, const char* mode) {
    FILE* f = fopen(path, mode);
    // Gerenciamento manual de arquivos
}

void* file_read_all(const char* path, size_t* size) {
    FILE* f = fopen(path, "rb");
    fseek(f, 0, SEEK_END);
    *size = ftell(f);
    void* data = malloc(*size);
    fread(data, 1, *size, f);
    fclose(f);
    return data;
}
```

**Por quê não copiar?**
- Godot tem FileAccess
- Resource system
- Automatic loading
- Compression built-in

**Use no Godot:**
```gdscript
# ✅ Use isso
var file = FileAccess.open("user://save.dat", FileAccess.READ)
var data = file.get_var()
```

---

### 6. Sistema de Memória

```cpp
// ❌ NÃO COPIE ISSO - memory.cc
void* mem_malloc(size_t size) {
    void* ptr = malloc(size);
    // Tracking manual de memória
    memory_tracker_add(ptr, size);
    return ptr;
}

void mem_free(void* ptr) {
    memory_tracker_remove(ptr);
    free(ptr);
}
```

**Por quê não copiar?**
- GDScript tem garbage collection
- Sem memory leaks
- Sem manual management

**Use no Godot:**
```gdscript
# ✅ Use isso
var data = []  # Automático
# Sem free(), sem malloc()
```

---

### 7. Game Loop e Timing

```cpp
// ❌ NÃO COPIE ISSO - game.cc
void game_loop() {
    unsigned int lastTime = SDL_GetTicks();
    
    while (running) {
        unsigned int currentTime = SDL_GetTicks();
        float deltaTime = (currentTime - lastTime) / 1000.0f;
        lastTime = currentTime;
        
        handle_input();
        update(deltaTime);
        render();
        
        SDL_Delay(16); // ~60 FPS
    }
}
```

**Por quê não copiar?**
- Godot tem game loop built-in
- _process() e _physics_process()
- Delta time automático
- VSync handling

**Use no Godot:**
```gdscript
# ✅ Use isso
func _process(delta):
    update_game(delta)
```

---

## ✅ COPIAR - Lógica de Gameplay (O Coração do Fallout)

### 1. Fórmulas de Combate

```cpp
// ✅ COPIE ISSO - combat.cc
int combat_to_hit(Object* attacker, Object* target, int hitMode) {
    // ESTA É A ESSÊNCIA DO FALLOUT!
    int chance = skill_level(attacker, weapon_skill(weapon));
    chance += stat_level(attacker, STAT_PERCEPTION) * 5;
    chance -= stat_level(target, STAT_AGILITY);
    
    // Hit location penalties
    switch (hitMode) {
        case HIT_LOCATION_HEAD: chance -= 40; break;
        case HIT_LOCATION_EYES: chance -= 60; break;
        case HIT_LOCATION_GROIN: chance -= 30; break;
    }
    
    return clamp(chance, 5, 95);
}
```

**Por quê copiar?**
- Esta é a MECÂNICA do Fallout
- Balanceamento testado
- Feel autêntico

**Porte para Godot:**
```gdscript
# ✅ Porte assim
func calculate_to_hit(attacker: Critter, target: Critter, hit_mode: HitLocation) -> int:
    var chance = attacker.get_skill(weapon.skill_type)
    chance += attacker.stats.perception * 5  # FÓRMULA EXATA
    chance -= target.stats.agility
    
    match hit_mode:
        HitLocation.HEAD: chance -= 40
        HitLocation.EYES: chance -= 60
        HitLocation.GROIN: chance -= 30
    
    return clamp(chance, 5, 95)
```

---

### 2. Sistema SPECIAL (Stats)

```cpp
// ✅ COPIE ISSO - stat.cc
void stat_calculate_derived(Object* obj) {
    // FÓRMULAS SAGRADAS DO FALLOUT
    int strength = stat_level(obj, STAT_STRENGTH);
    int endurance = stat_level(obj, STAT_ENDURANCE);
    int agility = stat_level(obj, STAT_AGILITY);
    int perception = stat_level(obj, STAT_PERCEPTION);
    int luck = stat_level(obj, STAT_LUCK);
    
    // Hit Points
    obj->max_hp = 15 + strength + (2 * endurance);
    
    // Action Points
    obj->action_points = 5 + (agility / 2);
    
    // Armor Class
    obj->armor_class = agility;
    
    // Carry Weight
    obj->carry_weight = 25 + (strength * 25);
    
    // Melee Damage
    obj->melee_damage = max(1, strength - 5);
    
    // Sequence
    obj->sequence = 2 * perception;
    
    // Healing Rate
    obj->healing_rate = max(1, endurance / 3);
    
    // Critical Chance
    obj->critical_chance = luck;
}
```

**Por quê copiar?**
- ESTAS SÃO AS FÓRMULAS DEFINIDORAS
- Balanceamento perfeito
- Identidade do Fallout

**Porte para Godot:**
```gdscript
# ✅ Porte EXATAMENTE assim
func calculate_derived_stats():
    # FÓRMULAS EXATAS DO FALLOUT 2
    max_hp = 15 + strength + (2 * endurance)
    action_points = 5 + int(agility / 2.0)
    armor_class = agility
    carry_weight = 25 + (strength * 25)
    melee_damage = max(1, strength - 5)
    sequence = 2 * perception
    healing_rate = max(1, int(endurance / 3.0))
    critical_chance = luck
```

---

### 3. Sistema de Dano

```cpp
// ✅ COPIE ISSO - combat.cc
int calculate_damage(Object* attacker, Object* target, Object* weapon, 
                     int hitLocation, int damageType) {
    // Base damage
    int damage = random_between(weapon->min_damage, weapon->max_damage);
    
    // Melee bonus
    if (is_melee_weapon(weapon)) {
        damage += max(1, stat_level(attacker, STAT_STRENGTH) - 5);
    }
    
    // Location multiplier
    float multiplier = 1.0f;
    switch (hitLocation) {
        case HIT_LOCATION_HEAD: multiplier = 2.0f; break;
        case HIT_LOCATION_EYES: multiplier = 3.0f; break;
        case HIT_LOCATION_GROIN: multiplier = 1.5f; break;
    }
    damage = (int)(damage * multiplier);
    
    // Damage Resistance
    int dr = get_damage_resistance(target, damageType);
    damage = damage * (100 - dr) / 100;
    
    // Damage Threshold
    int dt = get_damage_threshold(target, damageType);
    damage -= dt;
    
    return max(0, damage);
}
```

**Por quê copiar?**
- Sistema DR/DT é único do Fallout
- Multiplicadores de localização
- Balanceamento de armas

**Porte para Godot:**
```gdscript
# ✅ Porte EXATAMENTE
func calculate_damage(attacker, target, weapon, hit_location, damage_type):
    var damage = randi_range(weapon.min_damage, weapon.max_damage)
    
    if weapon.is_melee():
        damage += max(1, attacker.stats.strength - 5)
    
    var multiplier = 1.0
    match hit_location:
        HitLocation.HEAD: multiplier = 2.0
        HitLocation.EYES: multiplier = 3.0
        HitLocation.GROIN: multiplier = 1.5
    
    damage = int(damage * multiplier)
    
    var dr = target.get_damage_resistance(damage_type)
    damage = damage * (100 - dr) / 100
    
    var dt = target.get_damage_threshold(damage_type)
    damage -= dt
    
    return max(0, damage)
```

---

### 4. Sistema de Skills

```cpp
// ✅ COPIE ISSO - skill.cc
int skill_get_base_value(int skill, int* stats) {
    // FÓRMULAS BASE DE CADA SKILL
    switch (skill) {
        case SKILL_SMALL_GUNS:
            return 5 + (4 * stats[STAT_AGILITY]);
        
        case SKILL_BIG_GUNS:
            return 2 * stats[STAT_AGILITY];
        
        case SKILL_ENERGY_WEAPONS:
            return 2 * stats[STAT_AGILITY];
        
        case SKILL_UNARMED:
            return 30 + (2 * (stats[STAT_AGILITY] + stats[STAT_STRENGTH]));
        
        case SKILL_MELEE_WEAPONS:
            return 20 + (2 * (stats[STAT_AGILITY] + stats[STAT_STRENGTH]));
        
        case SKILL_LOCKPICK:
            return 10 + (stats[STAT_PERCEPTION] + stats[STAT_AGILITY]);
        
        case SKILL_SCIENCE:
            return 4 * stats[STAT_INTELLIGENCE];
        
        case SKILL_REPAIR:
            return 3 * stats[STAT_INTELLIGENCE];
        
        // ... etc
    }
}
```

**Por quê copiar?**
- Fórmulas de progressão
- Balanceamento de builds
- Identidade de cada skill

**Porte para Godot:**
```gdscript
# ✅ Porte EXATAMENTE
func get_base_skill_value(skill: Skill) -> int:
    match skill:
        Skill.SMALL_GUNS:
            return 5 + (4 * stats.agility)
        Skill.BIG_GUNS:
            return 2 * stats.agility
        Skill.ENERGY_WEAPONS:
            return 2 * stats.agility
        Skill.UNARMED:
            return 30 + (2 * (stats.agility + stats.strength))
        Skill.MELEE_WEAPONS:
            return 20 + (2 * (stats.agility + stats.strength))
        Skill.LOCKPICK:
            return 10 + (stats.perception + stats.agility)
        Skill.SCIENCE:
            return 4 * stats.intelligence
        Skill.REPAIR:
            return 3 * stats.intelligence
```

---

### 5. Sistema de Perks

```cpp
// ✅ COPIE ISSO - perk.cc
typedef struct PerkRequirement {
    int level;
    int stats[STAT_COUNT];
    int skills[SKILL_COUNT];
} PerkRequirement;

// Bonus Ranged Damage
PerkRequirement PERK_BONUS_RANGED_DAMAGE = {
    .level = 6,
    .stats = {0, 0, 0, 0, 0, 6, 6},  // Agility 6, Luck 6
    .skills = {0}
};

// Better Criticals
PerkRequirement PERK_BETTER_CRITICALS = {
    .level = 9,
    .stats = {0, 6, 0, 0, 0, 0, 0},  // Perception 6
    .skills = {0}
};
```

**Por quê copiar?**
- Requisitos de perks
- Efeitos de perks
- Progressão de personagem

**Porte para Godot:**
```gdscript
# ✅ Porte EXATAMENTE
const PERK_REQUIREMENTS = {
    Perk.BONUS_RANGED_DAMAGE: {
        "level": 6,
        "agility": 6,
        "luck": 6
    },
    Perk.BETTER_CRITICALS: {
        "level": 9,
        "perception": 6
    }
}
```

---

### 6. Critical Hit Table

```cpp
// ✅ COPIE ISSO - combat.cc
typedef struct CriticalEffect {
    int damageMultiplier;
    int effectFlags;
    const char* message;
} CriticalEffect;

// Critical effects por localização
CriticalEffect CRITICAL_HEAD_EFFECTS[] = {
    {2, 0, "Critical hit to the head!"},
    {2, CRIPPLED, "Critical hit! Head crippled!"},
    {3, KNOCKED_DOWN, "Devastating hit! Knocked down!"},
    {3, KNOCKED_OUT, "Massive critical! Knocked out!"},
    {4, BLINDED, "Brutal hit! Blinded!"},
    {6, INSTANT_DEATH, "Fatal critical! Instant death!"}
};
```

**Por quê copiar?**
- Sistema de críticos é ICÔNICO
- Mensagens e efeitos
- Balanceamento

**Porte para Godot:**
```gdscript
# ✅ Porte EXATAMENTE
const CRITICAL_HEAD_EFFECTS = [
    {"multiplier": 2, "effect": Effect.NONE, "msg": "Critical hit to the head!"},
    {"multiplier": 2, "effect": Effect.CRIPPLED, "msg": "Critical hit! Head crippled!"},
    {"multiplier": 3, "effect": Effect.KNOCKED_DOWN, "msg": "Devastating hit! Knocked down!"},
    {"multiplier": 3, "effect": Effect.KNOCKED_OUT, "msg": "Massive critical! Knocked out!"},
    {"multiplier": 4, "effect": Effect.BLINDED, "msg": "Brutal hit! Blinded!"},
    {"multiplier": 6, "effect": Effect.INSTANT_DEATH, "msg": "Fatal critical! Instant death!"}
]
```

---

### 7. Sistema de IA

```cpp
// ✅ COPIE ISSO - combat_ai.cc
int ai_pick_target(Object* attacker) {
    Object* bestTarget = NULL;
    int bestScore = -999;
    
    for (Object* target : visibleEnemies) {
        int score = 0;
        
        // Prefer low HP targets
        score += (100 - target->hp_percent) / 10;
        
        // Prefer close targets
        int distance = tile_dist(attacker->tile, target->tile);
        score -= distance / 5;
        
        // Prefer targets we can hit
        int hitChance = combat_to_hit(attacker, target);
        score += hitChance / 10;
        
        if (score > bestScore) {
            bestScore = score;
            bestTarget = target;
        }
    }
    
    return bestTarget;
}
```

**Por quê copiar?**
- Comportamento de IA
- Decisões táticas
- Feel do combate

**Porte para Godot:**
```gdscript
# ✅ Porte a LÓGICA
func ai_pick_target(attacker: Critter) -> Critter:
    var best_target = null
    var best_score = -999
    
    for target in visible_enemies:
        var score = 0
        
        score += (100 - target.hp_percent()) / 10
        
        var distance = attacker.distance_to(target)
        score -= distance / 5
        
        var hit_chance = calculate_to_hit(attacker, target)
        score += hit_chance / 10
        
        if score > best_score:
            best_score = score
            best_target = target
    
    return best_target
```

---

## 📊 Resumo Visual

### ❌ NÃO COPIAR (Infraestrutura)
```
fallout2-ce/src/
├── tile.cc          ❌ Renderização
├── svga.cc          ❌ Display
├── draw.cc          ❌ Drawing
├── window_manager.cc ❌ Janelas
├── input.cc         ❌ Input
├── kb.cc            ❌ Teclado
├── mouse.cc         ❌ Mouse
├── sound.cc         ❌ Audio
├── db.cc            ❌ File I/O
├── memory.cc        ❌ Memória
└── game.cc          ❌ Game loop
```

### ✅ COPIAR (Gameplay)
```
fallout2-ce/src/
├── combat.cc        ✅ Fórmulas de combate
├── stat.cc          ✅ Sistema SPECIAL
├── skill.cc         ✅ Sistema de skills
├── perk.cc          ✅ Sistema de perks
├── trait.cc         ✅ Sistema de traits
├── combat_ai.cc     ✅ IA de combate
├── critter.cc       ✅ Lógica de personagens
├── item.cc          ✅ Sistema de itens
├── proto.cc         ✅ Definições de objetos
└── scripts.cc       ✅ Sistema de scripts
```

---

## 🎯 Checklist Prático

Ao olhar um arquivo do Fallout 2 CE, pergunte:

### ❌ NÃO COPIAR se:
- [ ] Lida com pixels, buffers, texturas
- [ ] Usa SDL, OpenGL, DirectX
- [ ] Gerencia janelas ou display
- [ ] Processa input de hardware
- [ ] Toca sons diretamente
- [ ] Gerencia memória (malloc/free)
- [ ] Lê/escreve arquivos diretamente
- [ ] Implementa game loop

### ✅ COPIAR se:
- [ ] Calcula dano, hit chance, stats
- [ ] Define fórmulas de progressão
- [ ] Implementa regras de combate
- [ ] Define requisitos de perks/skills
- [ ] Implementa lógica de IA
- [ ] Define balanceamento
- [ ] Implementa mecânicas de jogo
- [ ] Define tabelas de dados

---

## 💡 Exemplo Prático Final

### Arquivo: combat.cc

```cpp
// ❌ NÃO COPIE (linha 1-50)
#include <SDL2/SDL.h>
void render_combat_ui() {
    SDL_Rect rect = {x, y, w, h};
    SDL_RenderFillRect(renderer, &rect);
}

// ✅ COPIE (linha 100-200)
int calculate_to_hit(Object* attacker, Object* target) {
    int chance = skill_level(attacker, SKILL_SMALL_GUNS);
    chance += stat_level(attacker, STAT_PERCEPTION) * 5;
    return clamp(chance, 5, 95);
}

// ❌ NÃO COPIE (linha 300-350)
void play_gunshot_sound() {
    Mix_PlayChannel(-1, gunshot_sound, 0);
}

// ✅ COPIE (linha 400-500)
int calculate_damage(Object* attacker, Object* weapon) {
    int damage = random_between(weapon->min_dmg, weapon->max_dmg);
    damage += max(1, stat_level(attacker, STAT_STRENGTH) - 5);
    return damage;
}
```

---

## 🏆 Conclusão

**Infraestrutura = Godot já tem (melhor)**
**Gameplay = Copie do Fallout 2 CE (autêntico)**

Você quer o **cérebro** do Fallout, não o **corpo**.

O Godot é o corpo moderno. O Fallout 2 CE é o cérebro clássico.

Junte os dois = Jogo perfeito! 🎮
