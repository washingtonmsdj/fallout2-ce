# Próximas Tarefas - Pronto para Execução

**Prioridade**: CRÍTICA  
**Impacto**: Alto - Bloqueadores para gameplay  
**Tempo Estimado**: 1-2 semanas

---

## 🎯 Tarefa 11: MapManager - Carregamento de Mapas

### Objetivo
Implementar o sistema de carregamento e gerenciamento de mapas convertidos, permitindo transições entre mapas e renderização correta de elevações.

### Subtarefas

#### 11.1 - Criar Estrutura de Dados para Mapas
**Esforço**: Médio | **Tempo**: 2-3 horas

**O que fazer**:
1. Criar classe `MapData` em `godot_project/scripts/data/map_data.gd`
   - Propriedades: id, name, width, height, elevation_count
   - Tiles: array 3D [elevation][y][x]
   - Objetos: lista de objetos com posição e tipo
   - NPCs: lista de NPCs com posição e ID
   - Conexões: mapa de saídas para outros mapas

2. Criar classe `TileData` em `godot_project/scripts/data/tile_data.gd`
   - Propriedades: tile_id, elevation, flags (walkable, transparent, etc)
   - Métodos: is_walkable(), is_transparent()

3. Criar classe `MapObject` em `godot_project/scripts/data/map_object.gd`
   - Propriedades: id, type, position, rotation, proto_id
   - Métodos: get_sprite(), get_collision_shape()

**Referência**: Requirements 4.1, 9.3

#### 11.2 - Implementar Carregamento de Mapas
**Esforço**: Alto | **Tempo**: 4-5 horas

**O que fazer**:
1. Expandir `MapManager` em `godot_project/scripts/systems/map_system.gd`
   - Método `load_map(map_id: String) -> MapData`
   - Método `unload_current_map()`
   - Método `get_current_map() -> MapData`
   - Método `get_tile(pos: Vector2i, elevation: int) -> TileData`

2. Implementar carregamento de recursos convertidos
   - Carregar TileMap scenes geradas pelo conversor
   - Carregar objetos e NPCs
   - Configurar scripts de mapa

3. Integrar com GameManager
   - Sinal `map_loaded(map_id: String)`
   - Sinal `map_unloaded()`
   - Transição de estado EXPLORATION

**Referência**: Requirements 4.1

#### 11.3 - Implementar Sistema de Elevações
**Esforço**: Médio | **Tempo**: 3-4 horas

**O que fazer**:
1. Expandir renderização de elevações
   - Renderizar 3 níveis de elevação (0, 1, 2)
   - Mostrar/ocultar elevações baseado em posição do player
   - Transições suaves entre elevações

2. Implementar transições de elevação
   - Detectar escadas/rampas
   - Permitir movimento entre elevações
   - Atualizar câmera e renderização

3. Implementar oclusão correta
   - Ocultar objetos acima do player
   - Mostrar objetos abaixo do player
   - Ordenação correta de sprites

**Referência**: Requirements 9.3

#### 11.4 - Implementar Transições de Mapa
**Esforço**: Médio | **Tempo**: 3-4 horas

**O que fazer**:
1. Detectar saídas de mapa
   - Criar zonas de saída em bordas do mapa
   - Detectar quando player entra em zona
   - Sinal `map_exit_detected(exit_id: String, target_map: String)`

2. Implementar transição
   - Fade out do mapa atual
   - Descarregar mapa
   - Carregar novo mapa
   - Posicionar player na entrada correta
   - Fade in do novo mapa

3. Integrar com GameManager
   - Pausar gameplay durante transição
   - Atualizar estado do jogo
   - Salvar progresso

**Referência**: Requirements 4.1

#### 11.5 - Write Property Test for Map Loading
**Esforço**: Médio | **Tempo**: 2-3 horas

**O que fazer**:
1. Criar `tests/property/test_map_loading.gd`
   - **Property**: Para qualquer mapa válido, carregar e descarregar deve restaurar estado
   - **Validação**: Verificar que tiles estão corretos, objetos posicionados, NPCs presentes
   - **Iterações**: 100+

2. Criar `tests/property/test_elevation_transitions.gd`
   - **Property**: Transições entre elevações devem manter posição XY
   - **Validação**: Verificar que player não cai através de pisos
   - **Iterações**: 100+

3. Criar `tests/property/test_map_transitions.gd`
   - **Property**: Transição entre mapas deve posicionar player corretamente
   - **Validação**: Verificar que player aparece na entrada, não em posição aleatória
   - **Iterações**: 100+

**Referência**: Requirements 4.1, 9.3

---

## 🎯 Tarefa 12: SaveSystem - Persistência de Dados

### Objetivo
Implementar sistema completo de save/load com validação, permitindo persistência de progresso do jogo.

### Subtarefas

#### 12.1 - Definir Formato de Save
**Esforço**: Baixo | **Tempo**: 1-2 horas

**O que fazer**:
1. Criar estrutura JSON para save
   ```json
   {
     "version": "1.0",
     "timestamp": "2024-12-04T10:30:00Z",
     "player": {
       "position": {"x": 100, "y": 100, "elevation": 0},
       "stats": {"strength": 5, "perception": 7, ...},
       "skills": {"small_guns": 60, "melee_weapons": 45, ...},
       "inventory": [...],
       "experience": 5000,
       "level": 3
     },
     "world": {
       "current_map": "arroyo",
       "game_time": {"year": 2161, "month": 1, "day": 1, "hour": 12},
       "global_flags": {...},
       "global_vars": {...},
       "map_states": {...}
     },
     "quests": [...],
     "dialogue_history": [...]
   }
   ```

2. Criar classe `SaveData` em `godot_project/scripts/data/save_data.gd`
   - Propriedades: version, timestamp, player_data, world_data, quests, dialogue_history
   - Métodos: to_dict(), from_dict(), validate()

**Referência**: Requirements 5.1

#### 12.2 - Implementar Serialização
**Esforço**: Alto | **Tempo**: 4-5 horas

**O que fazer**:
1. Expandir `SaveSystem` em `godot_project/scripts/systems/save_system.gd`
   - Método `save_game(slot: int) -> bool`
   - Método `get_save_path(slot: int) -> String`
   - Método `create_save_data() -> SaveData`

2. Serializar dados do player
   - Posição, stats, skills
   - Inventário completo
   - Experiência e nível

3. Serializar estado do mundo
   - Mapa atual
   - Tempo do jogo
   - Flags e variáveis globais
   - Estado de cada mapa visitado

4. Serializar quests e diálogos
   - Status de cada quest
   - Histórico de diálogos
   - Consequências aplicadas

**Referência**: Requirements 5.1

#### 12.3 - Implementar Desserialização
**Esforço**: Alto | **Tempo**: 4-5 horas

**O que fazer**:
1. Implementar carregamento de save
   - Método `load_game(slot: int) -> bool`
   - Método `load_save_data(path: String) -> SaveData`
   - Método `restore_game_state(save_data: SaveData) -> bool`

2. Restaurar dados do player
   - Posição, stats, skills
   - Inventário
   - Experiência e nível

3. Restaurar estado do mundo
   - Carregar mapa correto
   - Restaurar tempo do jogo
   - Restaurar flags e variáveis
   - Restaurar estado de mapas

4. Restaurar quests e diálogos
   - Restaurar status de quests
   - Restaurar histórico de diálogos
   - Reaplicar consequências

**Referência**: Requirements 5.1

#### 12.4 - Implementar Validação
**Esforço**: Médio | **Tempo**: 3-4 horas

**O que fazer**:
1. Validar integridade de save
   - Verificar versão
   - Verificar campos obrigatórios
   - Verificar tipos de dados
   - Verificar ranges de valores (stats 1-10, skills 0-100, etc)

2. Detectar saves corrompidos
   - Checksum de arquivo
   - Validação de estrutura JSON
   - Validação de referências (mapas, NPCs, itens)

3. Implementar recuperação
   - Fallback para último save válido
   - Mensagens de erro claras
   - Log de erros

**Referência**: Requirements 5.1

#### 12.5 - Write Property Test for Save/Load Round-Trip
**Esforço**: Médio | **Tempo**: 2-3 horas

**O que fazer**:
1. Criar `tests/property/test_save_load_roundtrip.gd`
   - **Property**: Para qualquer estado de jogo válido, save + load deve restaurar estado idêntico
   - **Validação**: Comparar player data, world state, quests, dialogue history
   - **Iterações**: 100+

2. Criar `tests/property/test_save_validation.gd`
   - **Property**: Saves inválidos devem ser detectados e rejeitados
   - **Validação**: Testar com dados corrompidos, versões antigas, campos faltantes
   - **Iterações**: 100+

3. Criar `tests/property/test_save_compatibility.gd`
   - **Property**: Saves de versões anteriores devem ser migrados corretamente
   - **Validação**: Testar migração de v1.0 para v1.1, etc
   - **Iterações**: 100+

**Referência**: Requirements 5.1, 3.4

---

## 📋 Ordem de Execução Recomendada

### Semana 1
1. **Tarefa 11.1** - Estrutura de dados (2-3h)
2. **Tarefa 11.2** - Carregamento de mapas (4-5h)
3. **Tarefa 11.3** - Sistema de elevações (3-4h)
4. **Tarefa 11.4** - Transições de mapa (3-4h)
5. **Tarefa 11.5** - Property tests (2-3h)

**Total Semana 1**: ~17-19 horas

### Semana 2
1. **Tarefa 12.1** - Formato de save (1-2h)
2. **Tarefa 12.2** - Serialização (4-5h)
3. **Tarefa 12.3** - Desserialização (4-5h)
4. **Tarefa 12.4** - Validação (3-4h)
5. **Tarefa 12.5** - Property tests (2-3h)

**Total Semana 2**: ~14-19 horas

---

## 🧪 Testes Necessários

### Property-Based Tests
- [ ] Map loading round-trip
- [ ] Elevation transitions
- [ ] Map transitions
- [ ] Save/load round-trip
- [ ] Save validation
- [ ] Save compatibility

**Total**: 6 property tests com 100+ iterações cada

### Unit Tests
- [ ] MapData creation and validation
- [ ] TileData properties
- [ ] MapObject positioning
- [ ] SaveData serialization
- [ ] SaveData deserialization
- [ ] Save file I/O

**Total**: 6+ unit tests

---

## 📊 Métricas de Sucesso

### Tarefa 11 - MapManager
- ✅ Todos os mapas carregam sem erros
- ✅ Elevações renderizam corretamente
- ✅ Transições entre mapas funcionam
- ✅ 6 property tests passando (600+ iterações)
- ✅ Sem memory leaks ao carregar/descarregar mapas

### Tarefa 12 - SaveSystem
- ✅ Saves criados com sucesso
- ✅ Saves carregados e restauram estado
- ✅ Saves inválidos detectados
- ✅ 6 property tests passando (600+ iterações)
- ✅ Compatibilidade com versões anteriores

---

## 🚀 Próximos Passos Após Conclusão

Após completar Tarefas 11 e 12:

1. **Tarefa 16** - Expandir InventorySystem
   - Limite de peso
   - Sistema de equipamento
   - Uso de consumíveis

2. **Tarefa 15** - Implementar DialogSystem
   - Árvores de diálogo
   - Condições e consequências
   - Barter

3. **Tarefa 14** - Expandir CombatSystem
   - AI de combate
   - Comportamentos de inimigos
   - Uso de itens

4. **Criar Primeiro Mapa Jogável**
   - Arroyo (mapa inicial)
   - NPCs básicos
   - Quests iniciais

---

## 💡 Notas Importantes

1. **Integração com GameManager**: Ambas as tarefas precisam integrar com GameManager para transições de estado
2. **Performance**: Considerar cache de mapas para transições rápidas
3. **Versioning**: Implementar sistema de versão de saves desde o início
4. **Backup**: Criar backup automático de saves antes de sobrescrever
5. **Testes**: Executar testes após cada subtarefa para detectar problemas cedo

---

## 📞 Suporte

Se encontrar problemas:
1. Verificar logs em `godot_project/logs/`
2. Executar testes com `python godot_project/tests/run_all_tests.py`
3. Revisar documentação em `.kiro/specs/complete-migration-master/design.md`
4. Consultar exemplos em `godot_project/scripts/systems/`

