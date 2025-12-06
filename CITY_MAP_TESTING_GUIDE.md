# Guia de Teste - City Map System

## 🎮 Como Testar no Jogo

### Passo 1: Abrir a Cena de Teste

1. Abra o Godot
2. Navegue até `scenes/test/TestCityIntegrated.tscn`
3. Clique em "Play" (F5) ou use o botão de play

### Passo 2: Observar a Inicialização

Quando a cena iniciar, você verá no console:

```
🏙️ Initializing City Map System...
✅ City Map System initialized!
📊 Grid: 100x100
🛣️ Roads: 2
🏢 Buildings: 4
👥 Citizens: 5
💰 Resources: 9 types
⚔️ Factions: 2

🛣️ Creating roads...
✅ Created 2 roads

🏘️ Creating zones...
✅ Created 2 zones

🏢 Creating buildings...
✅ Created 4 buildings

👥 Creating citizens...
✅ Created 5 citizens

⚔️ Creating factions...
✅ Created 2 factions

💰 Initializing economy...
✅ Economy initialized
```

### Passo 3: Interagir com o Sistema

#### Controles
- **Scroll do Mouse**: Zoom in/out
- **Espaço**: Ativar modo de construção
- **ESC**: Cancelar modo de construção

#### Painel de Informações (Canto Superior Esquerdo)

O painel mostra em tempo real:
- 👥 **Pop**: População de cidadãos vivos
- 🏗️ **Build**: Número de edifícios
- 🍖 **Food**: Quantidade de comida
- 💧 **Water**: Quantidade de água
- 💰 **Caps**: Moeda
- 🧱 **Materials**: Materiais
- 😊 **Happiness**: Felicidade média
- ⏱️ **Speed**: Velocidade do jogo

### Passo 4: Testar Funcionalidades

#### Teste de Grid System
```gdscript
# O grid 100x100 foi criado com sucesso
# Todos os 10.000 tiles estão acessíveis
```

#### Teste de Road System
```gdscript
# 2 estradas foram criadas:
# - Estrada horizontal (10,50) até (90,50)
# - Estrada vertical (50,10) até (50,90)
```

#### Teste de Zone System
```gdscript
# 2 zonas foram criadas:
# - Zona Residencial (20-40, 20-40)
# - Zona Comercial (60-80, 20-40)
```

#### Teste de Building System
```gdscript
# 4 edifícios foram construídos:
# - 2 casas (SMALL_HOUSE, MEDIUM_HOUSE)
# - 1 loja (SHOP)
# - 1 fazenda (FARM)

# Capacidades:
# - SMALL_HOUSE: 2 moradores
# - MEDIUM_HOUSE: 4 moradores
# - SHOP: 2 funcionários
# - FARM: 4 funcionários
```

#### Teste de Citizen System
```gdscript
# 5 cidadãos foram criados:
# - Citizen_0: Casa em SMALL_HOUSE, Trabalho em SHOP
# - Citizen_1: Casa em SMALL_HOUSE, Trabalho em FARM
# - Citizen_2: Casa em MEDIUM_HOUSE, Trabalho em FARM
# - Citizen_3: Casa em MEDIUM_HOUSE, Trabalho em FARM
# - Citizen_4: Casa em MEDIUM_HOUSE, Trabalho em FARM

# Cada cidadão tem:
# - 6 necessidades (0-100)
# - Skills (0-100)
# - Traits
# - Relacionamentos
```

#### Teste de Economy System
```gdscript
# 9 tipos de recursos foram inicializados:
# - Food: 100
# - Water: 100
# - Caps: 500
# - Materials: 200
# - Power: 0
# - Medicine: 0
# - Weapons: 0
# - Fuel: 0
# - Components: 0

# Preços dinâmicos variam com oferta/demanda
```

#### Teste de Faction System
```gdscript
# 2 facções foram criadas:
# - Player Settlement (Verde, Jogador)
# - Rival Faction (Vermelha, IA)

# Player Settlement controla:
# - Território de 40x40 tiles (1600 tiles)
# - Relação com Rival: Neutro
```

## 📊 Verificar Dados em Tempo Real

### No Console do Godot

Você pode chamar funções de debug:

```gdscript
# Imprimir informações de debug
test_scene.print_debug_info()

# Resultado:
# === CITY MAP SYSTEM DEBUG ===
# Grid: 100x100
# Roads: 2
# Zones: 2
# Buildings: 4
# Citizens: 5
# Factions: 2
# Game Speed: 1.0x
```

### Acessar Dados Diretamente

```gdscript
# Obter estatísticas de cidadãos
var citizen_stats = citizen_system.get_citizen_statistics()
print("Cidadãos vivos: %d" % citizen_stats["alive_citizens"])
print("Felicidade média: %.1f" % citizen_stats["average_happiness"])

# Obter estatísticas de edifícios
var building_stats = building_system.get_building_statistics()
print("Edifícios operacionais: %d" % building_stats["operational"])

# Obter estatísticas de economia
var economy_stats = economy_system.get_resource_statistics()
print("Recursos: %s" % economy_stats["resources"])

# Obter estatísticas de facções
var faction_stats = faction_system.get_faction_statistics()
print("Facções: %d" % faction_stats["total_factions"])
```

## 🧪 Executar Testes Unitários

### Teste de Grid Consistency
```bash
# Valida que o grid mantém consistência
# - Todos os tiles são acessíveis
# - Dados são preservados
# - Serialização funciona
```

### Teste de Road Connectivity
```bash
# Valida que estradas se conectam corretamente
# - Estradas adjacentes são conectadas
# - Estradas distantes não são conectadas
# - Conexões são bidirecionais
```

### Teste de Building Placement
```bash
# Valida que edifícios são colocados corretamente
# - Tiles são ocupados
# - Sobreposição é prevenida
# - Destruição libera tiles
```

### Teste de Citizen Needs
```bash
# Valida que necessidades funcionam
# - Necessidades começam em [0, 100]
# - Decay funciona
# - Limites são respeitados
```

### Teste de Resource Conservation
```bash
# Valida que recursos são conservados
# - Produção aumenta quantidade
# - Consumo diminui quantidade
# - Preços variam com oferta/demanda
```

### Teste de Faction Territory
```bash
# Valida que território é exclusivo
# - Tiles pertencem a uma facção
# - Sobreposição é prevenida
# - Disputas são detectadas
```

## 🔍 Observar Eventos

O sistema emite eventos via EventBus:

```gdscript
# Conectar a eventos
event_bus.building_constructed.connect(func(id, pos):
    print("Edifício construído em %s" % pos)
)

event_bus.citizen_spawned.connect(func(id):
    print("Cidadão criado: %d" % id)
)

event_bus.resource_changed.connect(func(type, old, new):
    print("Recurso %d: %.1f -> %.1f" % [type, old, new])
)

event_bus.faction_territory_changed.connect(func(faction_id, tiles):
    print("Facção %d reivindicou %d tiles" % [faction_id, tiles.size()])
)
```

## 📈 Monitorar Performance

### FPS
- Observar FPS no canto superior esquerdo do Godot
- Esperado: 60 FPS com 100x100 grid

### Memória
- Abrir Monitor (Debug > Monitor)
- Observar uso de memória
- Esperado: < 50MB para cidade pequena

### Tempo de Atualização
- Adicionar timers para medir tempo de atualização
- Esperado: < 16ms por frame (60 FPS)

## 🐛 Troubleshooting

### Erro: "CityEventBus not found"
- Verificar se `scripts/city/core/event_bus.gd` existe
- Verificar se o nome da classe está correto

### Erro: "GridSystem not initialized"
- Verificar se `grid_system._ready()` foi chamado
- Verificar se `set_grid_size()` foi chamado

### Erro: "Building construction failed"
- Verificar se há espaço disponível
- Verificar se o tile é caminhável
- Verificar se não há outro edifício no local

### Erro: "Citizen assignment failed"
- Verificar se o edifício tem capacidade
- Verificar se o cidadão existe
- Verificar se o edifício é do tipo correto

## ✅ Checklist de Teste

- [ ] Grid System inicializa corretamente
- [ ] Roads são criadas e conectadas
- [ ] Zones são criadas com restrições
- [ ] Buildings são construídos com capacidade
- [ ] Citizens são criados com necessidades
- [ ] Economy rastreia recursos
- [ ] Factions controlam território
- [ ] UI atualiza em tempo real
- [ ] Eventos são emitidos corretamente
- [ ] Testes unitários passam

## 📝 Relatório de Teste

Após testar, crie um relatório:

```markdown
# Relatório de Teste - City Map System

## Data: [DATA]
## Testador: [NOME]

### Sistemas Testados
- [x] Grid System
- [x] Road System
- [x] Zone System
- [x] Building System
- [x] Citizen System
- [x] Economy System
- [x] Faction System

### Resultados
- Grid: ✅ Funcionando
- Roads: ✅ Funcionando
- Zones: ✅ Funcionando
- Buildings: ✅ Funcionando
- Citizens: ✅ Funcionando
- Economy: ✅ Funcionando
- Factions: ✅ Funcionando

### Problemas Encontrados
- Nenhum

### Observações
- Sistema está estável
- Performance é boa
- UI é responsiva
```

## 🎯 Próximos Passos

1. Testar Fase 8 (PowerSystem, WaterSystem)
2. Testar Fase 9 (WeatherSystem, EventSystem)
3. Testar Fase 10 (DefenseSystem)
4. Integrar com rendering
5. Integrar com player

---

**Última atualização**: Dezembro 2025
**Status**: ✅ Pronto para teste
