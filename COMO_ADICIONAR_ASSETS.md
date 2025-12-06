# Como Adicionar Assets Visuais ao City Map

## O Problema

O Citybound original não usa sprites/texturas tradicionais - ele gera tudo **proceduralmente com meshes 3D em WebGL**. Para ter um visual similar no Godot 2D, precisamos criar assets visuais.

## O Que Foi Criado

### 1. Sistema de Geração de Texturas (`texture_generator.gd`)
- Gera texturas procedurais para:
  - Grama com variação
  - Asfalto
  - Tijolos
  - Concreto
  - Sprites de árvores
  - Sprites de carros
  - Sprites de pessoas

### 2. Sistema de Vegetação (`vegetation_system.gd`)
- Gerencia árvores e plantas
- Geração procedural de vegetação
- Árvores ao longo de estradas
- Crescimento ao longo do tempo

### 3. Sistema de Tráfego (`traffic_system.gd`)
- Gerencia veículos nas estradas
- Cores variadas (igual ao Citybound)
- Movimento simples
- Tipos diferentes (carro, caminhão, moto)

## Como Melhorar o Visual

### Opção 1: Usar Texturas Procedurais (Já Implementado)
As texturas são geradas em código. Para usar:

```gdscript
var grass_tex = TextureGenerator.generate_grass_texture(64)
var tree_sprite = TextureGenerator.generate_tree_sprite(32)
var car_sprite = TextureGenerator.generate_car_sprite(24, Color.RED)
```

### Opção 2: Criar Sprites Reais

1. **Criar sprites no Aseprite/Piskel/GIMP**:
   - Árvores: 32x32 pixels
   - Carros: 24x16 pixels (vista isométrica)
   - Pessoas: 16x16 pixels
   - Edifícios: tiles de 64x64 pixels

2. **Salvar em** `assets/textures/city/`:
   ```
   assets/textures/city/
   ├── terrain/
   │   ├── grass.png
   │   ├── asphalt.png
   │   └── dirt.png
   ├── buildings/
   │   ├── wall_brick.png
   │   ├── wall_concrete.png
   │   ├── roof_tiles.png
   │   └── roof_flat.png
   ├── vegetation/
   │   ├── tree_oak.png
   │   ├── tree_pine.png
   │   └── bush.png
   └── vehicles/
       ├── car_red.png
       ├── car_blue.png
       └── truck.png
   ```

3. **Carregar no renderer**:
   ```gdscript
   var grass_texture = load("res://assets/textures/city/terrain/grass.png")
   var tree_sprite = load("res://assets/textures/city/vegetation/tree_oak.png")
   ```

### Opção 3: Extrair do Citybound (Difícil)

O Citybound gera meshes 3D em tempo real. Para extrair:

1. Rodar o Citybound
2. Usar ferramentas de captura de tela
3. Extrair sprites frame-by-frame
4. Limpar e organizar

**Não recomendado** - muito trabalhoso.

### Opção 4: Usar Assets de Terceiros

Procurar asset packs isométricos gratuitos:
- **Kenney.nl** - Assets isométricos gratuitos
- **OpenGameArt.org** - Assets open source
- **Itch.io** - Asset packs pagos/gratuitos

Exemplo de busca:
- "isometric city assets"
- "isometric building sprites"
- "isometric tree sprites"

## Próximos Passos

1. **Testar o sistema atual** com texturas procedurais
2. **Decidir** se quer criar sprites próprios ou usar assets de terceiros
3. **Integrar** os assets no renderer

## Exemplo de Uso

```gdscript
# No renderer
var vegetation_system = VegetationSystem.new()
add_child(vegetation_system)
vegetation_system.set_grid_system(grid_system)

# Gerar árvores
vegetation_system.generate_vegetation_in_area(Vector2i(10, 10), Vector2i(50, 50), 0.05)

# Sistema de tráfego
var traffic_system = TrafficSystem.new()
add_child(traffic_system)
traffic_system.set_road_system(road_system)
traffic_system.spawn_random_vehicles(10)
```

## Recursos Úteis

- **Kenney Assets**: https://kenney.nl/assets?q=isometric
- **OpenGameArt**: https://opengameart.org/art-search?keys=isometric
- **Aseprite** (editor de sprites): https://www.aseprite.org/
- **Piskel** (editor online gratuito): https://www.piskelapp.com/

## Conclusão

O visual atual é básico porque usa apenas formas geométricas. Para melhorar:
1. Use as texturas procedurais já criadas
2. Ou crie/baixe sprites reais
3. Integre vegetação e tráfego

O sistema está pronto para receber assets visuais!
