# Análise do Formato de Objetos do Fallout 2

## Descobertas da Análise

### Estrutura do ARTEMPLE.MAP
- Tamanho total: 92780 bytes
- Header: 236 bytes
- Tiles (elevação 0): 40000 bytes
- Scripts (2 CRITTER): ~60 bytes
- **Objetos: começam em offset 40328**
- **Bytes disponíveis para objetos: 52452**

### Cálculo de Objetos
Se temos 567 objetos declarados:
- Tamanho médio: 52452 / 567 ≈ **92.5 bytes por objeto**

### Estrutura de Objeto (baseada no código fonte)

```
Object {
    // Campos base (72 bytes)
    id: u32,              // +0
    tile: i32,            // +4
    x: i32,               // +8
    y: i32,               // +12
    sx: i32,              // +16
    sy: i32,              // +20
    frame: u32,           // +24
    rotation: u32,        // +28
    fid: u32,             // +32
    flags: u32,           // +36
    elevation: u32,       // +40
    pid: u32,             // +44
    cid: u32,             // +48
    lightDistance: u32,   // +52
    lightIntensity: u32,  // +56
    field_74: u32,        // +60
    sid: i32,             // +64
    scriptIndex: u32,     // +68
    
    // Inventário (12 bytes)
    inv_length: u32,      // +72
    inv_capacity: u32,    // +76
    inv_ptr: u32,         // +80 (ignorado em arquivo)
    
    // Dados específicos do tipo (variável)
    type_data: [...]
}
```

### Tamanhos por Tipo

1. **ITEM** (tipo 0): 72 + 12 + 4 = **88 bytes** (sem inventário)
2. **CRITTER** (tipo 1): 72 + 12 + 48 = **132 bytes**
3. **SCENERY** (tipo 2): 72 + 12 + 4-12 = **88-96 bytes**
4. **WALL** (tipo 3): 72 + 12 + 4 = **88 bytes**
5. **MISC** (tipo 5): 72 + 12 + 20 = **104 bytes** (exit grid)

### Problema Identificado

O parser atual está:
1. ✓ Lendo os 72 bytes base corretamente
2. ✓ Lendo os 12 bytes de inventário
3. ✗ **Pulando muitos bytes para items no inventário**
4. ✗ **Não alinhando corretamente após cada objeto**

### Solução

O inventário NÃO contém objetos completos recursivos. Os items no inventário são referências (4 bytes cada) ou estruturas menores.

**Tamanho correto do inventário**: `inv_length * 4` (não 84!)

### Novo Cálculo

```
Objeto base = 72 + 12 = 84 bytes
+ inventário = inv_length * 4
+ dados tipo = 4-48 bytes

Total médio ≈ 92 bytes ✓
```

## Próximo Passo

Corrigir o parser para:
1. Ler inventário como `inv_length * 4` bytes
2. Ler dados específicos do tipo corretamente
3. Validar que chegamos aos 567 objetos
