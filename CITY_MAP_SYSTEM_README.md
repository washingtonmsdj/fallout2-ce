# City Map System - Fallout 2: Godot Edition

## 🎮 Visão Geral

O City Map System é um sistema completo de simulação de cidade inspirado em Citybound, adaptado para o universo pós-apocalíptico do Fallout. O sistema gerencia todos os aspectos de uma cidade: terreno, estradas, edifícios, cidadãos, economia e facções.

## 📋 Componentes Implementados

### ✅ Fase 1: Core Infrastructure
- **EventBus**: Sistema de comunicação entre componentes via sinais
- **CityConfig**: Configurações globais e constantes
- **CityManager**: Coordenador central de todos os sistemas

### ✅ Fase 2: Grid and Terrain System
- **GridSystem**: Grid de até 500x500 tiles
- **TileData**: Dados de cada tile (terreno, elevação, walkability, radiação)
- **Serialização**: Salvar/carregar estado do grid

### ✅ Fase 3: Road System and Pathfinding
- **RoadSystem**: Criação de estradas retas e curvas (Bezier)
- **Conectividade**: Conexão automática de estradas adjacentes
- **Pathfinding**: A* com otimizações e landmarks

### ✅ Fase 4: Zone and Building Systems
- **ZoneSystem**: 6 tipos de zonas (Residencial, Comercial, Industrial, Agrícola, Militar, Restrita)
- **BuildingSystem**: 25 tipos de edifícios com capacidades únicas
- **Construção**: Sistema completo de construção, upgrade, reparo e destruição

### ✅ Fase 5: Citizen System
- **CitizenData**: Cidadãos com necessidades, skills e relacionamentos
- **Necessidades**: 6 tipos (fome, sede, descanso, felicidade, saúde, segurança)
- **Decisões Autônomas**: Cidadãos buscam satisfazer necessidades críticas
- **Atributos**: Skills, traits, experiência, level, facção

### ✅ Fase 6: Economy System
- **Recursos**: 9 tipos (comida, água, caps, materiais, energia, medicina, armas, combustível, componentes)
- **Produção/Consumo**: Rastreamento de taxas por edifício
- **Preços Dinâmicos**: Variam com oferta/demanda
- **Comércio**: Sistema de troca de recursos

### ✅ Fase 7: Faction System
- **Facções**: Criação e gerenciamento de facções
- **Território**: Controle exclusivo de tiles
- **Relações**: 5 níveis (Hostil, Desfavorável, Neutro, Amigável, Aliado)
- **Reputação**: Rastreamento com jogador e cidadãos

## 🚀 Como Usar

### Iniciar a Cena de Teste

```gdscript
# Abrir a cena de teste integrada
scenes/test/TestCityIntegrated.tscn
```

### Criar uma Cidade Programaticamente

```gdscript
# Criar sistemas
var grid = GridSystem.new()
var building_system = BuildingSystem.new()
var citizen_system = CitizenSystem.new()
var economy_system = EconomySystem.new()
var faction_system = FactionSystem.new()

# Inicializar
grid._ready()
grid.set_grid_size(100, 100)

# Criar edifício
var building_id = building_system.construct_building(
    BuildingSystem.BuildingType.SMALL_HOUSE,
    Vector2i(25, 25),
    Vector2i(3, 3)
)

# Criar cidadão
var citizen_id = citizen_system.spawn_citizen("John", Vector2i(50, 50))
citizen_system.assign_home(citizen_id, building_id)

# Adicionar recursos
economy_system.add_resource(EconomySystem.ResourceType.FOOD, 100.0)
```

## 📊 Estrutura de Dados

### Grid System
```gdscript
class TileData:
    var terrain_type: int      # Tipo de terreno
    var elevation: float       # Elevação
    var walkable: bool         # Pode caminhar?
    var radiation_level: float # Nível de radiação
```

### Building System
```gdscript
class BuildingData:
    var id: int
    var building_type: int
    var position: Vector2i
    var size: Vector2i
    var level: int             # 1-5
    var condition: float       # 0-100
    var is_operational: bool
```

### Citizen System
```gdscript
class CitizenData:
    var id: int
    var name: String
    var position: Vector2i
    var needs: Dictionary      # 6 tipos de necessidades
    var skills: Dictionary     # Habilidades (0-100)
    var relationships: Dictionary
    var home_building_id: int
    var job_building_id: int
    var faction_id: int
```

### Economy System
```gdscript
class ResourceData:
    var resource_type: int
    var amount: float
    var production_rate: float
    var consumption_rate: float
    var price: float
```

### Faction System
```gdscript
class FactionData:
    var id: int
    var name: String
    var color: Color
    var territory: Array        # Vector2i positions
    var reputation: Dictionary  # citizen_id -> value
    var relations: Dictionary   # faction_id -> RelationType
    var members: Array
```

## 🎯 Tipos de Edifícios

### Residencial
- SMALL_HOUSE (2 moradores)
- MEDIUM_HOUSE (4 moradores)
- LARGE_HOUSE (6 moradores)
- APARTMENT (8 moradores)

### Comercial
- SHOP (2 funcionários)
- MARKET (4 funcionários)
- RESTAURANT (3 funcionários)
- BANK (3 funcionários)

### Industrial
- FACTORY (8 funcionários)
- WORKSHOP (4 funcionários)
- WAREHOUSE (3 funcionários)
- POWER_PLANT (5 funcionários)

### Agrícola
- FARM (4 funcionários)
- GREENHOUSE (3 funcionários)
- GRAIN_MILL (3 funcionários)

### Militar
- GUARD_POST (4 funcionários)
- BARRACKS (6 funcionários)
- WATCHTOWER (2 funcionários)
- ARMORY (2 funcionários)

### Utilidade
- WATER_PUMP (2 funcionários)
- MEDICAL_CLINIC (3 funcionários)
- SCHOOL (4 funcionários)
- LIBRARY (2 funcionários)

### Especial
- VAULT (capacidade variável)
- SETTLEMENT_CENTER (5 funcionários)

## 💰 Tipos de Recursos

1. **FOOD** - Comida
2. **WATER** - Água
3. **CAPS** - Moeda
4. **MATERIALS** - Materiais de construção
5. **POWER** - Energia
6. **MEDICINE** - Medicina
7. **WEAPONS** - Armas
8. **FUEL** - Combustível
9. **COMPONENTS** - Componentes eletrônicos

## 👥 Necessidades de Cidadãos

1. **HUNGER** - Fome (satisfeita em restaurantes/shops)
2. **THIRST** - Sede (satisfeita em fontes de água)
3. **REST** - Descanso (satisfeito em casa)
4. **HAPPINESS** - Felicidade (satisfeita em lazer)
5. **HEALTH** - Saúde (satisfeita em clínicas)
6. **SAFETY** - Segurança (satisfeita em zonas seguras)

## ⚔️ Relações de Facção

- **HOSTILE (-2)**: Inimigos, podem atacar
- **UNFRIENDLY (-1)**: Desfavorável, evitam
- **NEUTRAL (0)**: Neutro, sem interação
- **FRIENDLY (1)**: Amigável, cooperam
- **ALLIED (2)**: Aliados, trabalham juntos

## 🧪 Testes

Todos os sistemas têm testes de propriedade:

```bash
# Teste de consistência de grid
scripts/test/test_grid_consistency.gd

# Teste de conectividade de estradas
scripts/test/test_road_connectivity.gd

# Teste de integridade de colocação de edifícios
scripts/test/test_building_placement.gd

# Teste de limites de necessidades
scripts/test/test_citizen_needs.gd

# Teste de conservação de recursos
scripts/test/test_resource_conservation.gd

# Teste de exclusividade territorial
scripts/test/test_faction_territory.gd
```

## 📈 Próximas Fases

- **Fase 8**: PowerSystem e WaterSystem
- **Fase 9**: WeatherSystem e EventSystem
- **Fase 10**: DefenseSystem
- **Fase 11**: VehicleSystem, CraftingSystem, QuestSystem
- **Fase 12**: Rendering System (isométrico)
- **Fase 13**: Integração com Player
- **Fase 14**: Save/Load e Performance
- **Fase 15**: Cenas e UI finais

## 🔧 Configuração

Todas as configurações estão em `CityConfig`:

```gdscript
# Tamanhos de grid
GRID_SIZE_DEFAULT = Vector2i(100, 100)
GRID_SIZE_MIN = Vector2i(50, 50)
GRID_SIZE_MAX = Vector2i(500, 500)

# Taxas de decay de necessidades
NEED_DECAY_RATES = {
    HUNGER: 5.0,
    THIRST: 4.0,
    REST: 3.0,
    HAPPINESS: 2.0,
    HEALTH: 1.0,
    SAFETY: 2.0
}

# Preços iniciais de recursos
RESOURCE_PRICES = {
    FOOD: 1.0,
    WATER: 0.8,
    CAPS: 1.0,
    ...
}
```

## 📝 Notas Técnicas

- Todos os sistemas usam **EventBus** para comunicação
- Sem acoplamento direto entre sistemas
- Capacidades de edifícios são definidas por tipo
- Preços são dinâmicos baseados em oferta/demanda
- Território é exclusivo por facção
- Cidadãos tomam decisões autônomas baseadas em necessidades

## 🐛 Debug

Para imprimir informações de debug:

```gdscript
var test_scene = get_node("TestCityIntegrated")
test_scene.print_debug_info()
```

## 📄 Licença

Parte do projeto Fallout 2: Godot Edition

## 👨‍💻 Desenvolvedor

Desenvolvido com Kiro IDE
