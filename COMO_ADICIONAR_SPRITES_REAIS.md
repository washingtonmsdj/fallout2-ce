# 🎨 Como Adicionar Sprites Reais aos Objetos

## Situação Atual

✅ **Sistema funcionando**: 407 objetos instanciados  
⚠️ **Visual**: Placeholders coloridos temporários  
🎯 **Objetivo**: Substituir placeholders por sprites reais do Fallout 2

## Opção 1: Solução Rápida (Recomendada)

### Usar Sprites Genéricos

Crie sprites simples para cada tipo e o sistema usará automaticamente:

```bash
# Criar sprites genéricos
godot_project/assets/sprites/
├─ items/item_generic.png       ← Sprite padrão para items
├─ characters/critter_generic.png  ← Sprite padrão para critters
├─ scenery/scenery_generic.png  ← Sprite padrão para scenery
├─ walls/wall_generic.png       ← Sprite padrão para walls
└─ misc/misc_generic.png        ← Sprite padrão para misc
```

### Atualizar MapLoader

Modificar `_get_object_texture()` em `map_loader.gd`:

```gdscript
func _get_object_texture(pid: int, frm_id: int, obj_type_str: String) -> Texture2D:
    # Tentar sprite específico do PID
    var sprite_path = f"res://assets/sprites/{folder}/pid_{pid:08x}.png"
    if ResourceLoader.exists(sprite_path):
        return load(sprite_path)
    
    # Fallback: sprite genérico do tipo
    var generic_paths = {
        "item": "res://assets/sprites/items/item_generic.png",
        "critter": "res://assets/sprites/characters/critter_generic.png",
        "scenery": "res://assets/sprites/scenery/scenery_generic.png",
        "wall": "res://assets/sprites/walls/wall_generic.png",
        "misc": "res://assets/sprites/misc/misc_generic.png",
    }
    
    var generic_path = generic_paths.get(obj_type_str, "")
    if generic_path != "" and ResourceLoader.exists(generic_path):
        return load(generic_path)
    
    return null  # Usar placeholder colorido
```

**Vantagens**:
- Rápido (30 minutos)
- Visual melhor que placeholders
- Não requer extração complexa

**Desvantagens**:
- Todos os objetos do mesmo tipo parecem iguais
- Não é fiel ao Fallout 2 original

## Opção 2: Mapeamento Manual (Médio Esforço)

### Mapear Objetos Importantes

Identifique os objetos mais visíveis e mapeie manualmente:

1. **Criar arquivo de mapeamento**:

```json
// godot_project/assets/data/pid_sprite_mapping.json
{
  "0x019611D8": "characters/tribal_male.png",
  "0x0196EDB0": "characters/tribal_female.png",
  "0x00000170": "items/spear.png",
  "0x000002B0": "items/knife.png",
  "0x02000015": "scenery/door.png"
}
```

2. **Atualizar MapLoader para usar mapeamento**:

```gdscript
var pid_sprite_mapping: Dictionary = {}

func _ready():
    _load_pid_sprite_mapping()

func _load_pid_sprite_mapping():
    var mapping_path = "res://assets/data/pid_sprite_mapping.json"
    if FileAccess.file_exists(mapping_path):
        var file = FileAccess.open(mapping_path, FileAccess.READ)
        var json = JSON.new()
        if json.parse(file.get_as_text()) == OK:
            pid_sprite_mapping = json.data
        file.close()

func _get_object_texture(pid: int, frm_id: int, obj_type_str: String) -> Texture2D:
    # Verificar mapeamento manual
    var pid_hex = "0x%08X" % pid
    if pid_sprite_mapping.has(pid_hex):
        var sprite_path = "res://assets/sprites/" + pid_sprite_mapping[pid_hex]
        if ResourceLoader.exists(sprite_path):
            return load(sprite_path)
    
    # Fallback para genérico ou placeholder
    ...
```

3. **Extrair sprites específicos**:

```bash
# Usar ferramenta de extração para PIDs específicos
python tools/extract_specific_pids.py 0x019611D8 0x0196EDB0 0x00000170
```

**Vantagens**:
- Objetos importantes têm sprites corretos
- Controle total sobre quais sprites usar
- Pode ser feito gradualmente

**Desvantagens**:
- Trabalho manual
- Não escalável para muitos objetos

## Opção 3: Sistema Automático Completo (Alto Esforço)

### Implementar Leitor de PRO Files

Sistema completo que lê arquivos .PRO para obter FRM IDs corretos:

1. **Criar leitor de PRO**:

```python
# tools/pro_reader.py
def read_pro_file(dat_reader, pid):
    """Lê arquivo PRO e retorna FID."""
    obj_type = (pid >> 24) & 0xFF
    proto_id = pid & 0xFFFF
    
    type_dirs = {
        0: 'proto/items',
        1: 'proto/critters',
        2: 'proto/scenery',
        3: 'proto/walls',
        5: 'proto/misc',
    }
    
    pro_path = f"{type_dirs[obj_type]}/{proto_id:08d}.pro"
    pro_data = dat_reader.get(pro_path)
    
    if not pro_data or len(pro_data) < 8:
        return None
    
    # FID está no offset 4 (little-endian)
    fid = struct.unpack('<I', pro_data[4:8])[0]
    return fid
```

2. **Gerar mapeamento completo**:

```python
# tools/generate_complete_pid_mapping.py
def generate_mapping():
    """Gera mapeamento PID → Sprite para todos os objetos."""
    # Abrir DAT files
    dat = DAT2Reader("Fallout 2/master.dat")
    dat.open()
    
    # Carregar JSON do mapa
    with open('godot_project/assets/data/maps/artemple.json') as f:
        map_data = json.load(f)
    
    mapping = {}
    
    for obj in map_data['objects']:
        pid = obj['pid']
        
        # Ler PRO para obter FID
        fid = read_pro_file(dat, pid)
        if not fid:
            continue
        
        # Converter FID para caminho FRM
        frm_path = fid_to_frm_path(fid)
        
        # Extrair e salvar sprite
        sprite_path = extract_and_save_sprite(dat, frm_path, pid)
        
        if sprite_path:
            mapping[f"0x{pid:08X}"] = sprite_path
    
    # Salvar mapeamento
    with open('godot_project/assets/data/pid_sprite_mapping.json', 'w') as f:
        json.dump(mapping, f, indent=2)
```

3. **Executar**:

```bash
python tools/generate_complete_pid_mapping.py
```

**Vantagens**:
- Sprites corretos para todos os objetos
- Automático e escalável
- Reutilizável para outros mapas

**Desvantagens**:
- Complexo de implementar
- Requer entendimento profundo dos formatos
- Tempo de desenvolvimento: 4-8 horas

## Comparação das Opções

| Aspecto | Opção 1 | Opção 2 | Opção 3 |
|---------|---------|---------|---------|
| **Tempo** | 30 min | 2-3h | 4-8h |
| **Complexidade** | Baixa | Média | Alta |
| **Fidelidade** | Baixa | Média | Alta |
| **Escalabilidade** | Baixa | Média | Alta |
| **Manutenção** | Fácil | Média | Fácil |
| **Visual** | Genérico | Parcial | Perfeito |

## Recomendação

### Para Desenvolvimento Rápido
**Opção 1** - Sprites genéricos

### Para Protótipo Apresentável
**Opção 2** - Mapeamento manual dos 20-30 objetos principais

### Para Versão Final
**Opção 3** - Sistema automático completo

## Implementação Passo a Passo (Opção 1)

### 1. Criar Sprites Genéricos

Use qualquer editor de imagem para criar sprites simples 32x32:

```
Item:    🟡 Caixa amarela
Critter: 🔴 Boneco vermelho
Scenery: 🟢 Objeto verde
Wall:    ⚪ Parede cinza
Misc:    🔵 Marcador azul
```

### 2. Salvar nos Locais Corretos

```
godot_project/assets/sprites/
├─ items/item_generic.png
├─ characters/critter_generic.png
├─ scenery/scenery_generic.png
├─ walls/wall_generic.png
└─ misc/misc_generic.png
```

### 3. Atualizar MapLoader

Adicionar função helper em `map_loader.gd`:

```gdscript
func _get_generic_sprite_path(obj_type_str: String) -> String:
    match obj_type_str:
        "item":
            return "res://assets/sprites/items/item_generic.png"
        "critter":
            return "res://assets/sprites/characters/critter_generic.png"
        "scenery":
            return "res://assets/sprites/scenery/scenery_generic.png"
        "wall":
            return "res://assets/sprites/walls/wall_generic.png"
        "misc":
            return "res://assets/sprites/misc/misc_generic.png"
        _:
            return ""
```

Modificar `_create_object_node_from_json()`:

```gdscript
# Tentar carregar sprite
if obj_node is Sprite2D:
    var texture = _get_object_texture(pid, frm_id)
    if texture:
        obj_node.texture = texture
    else:
        # Tentar sprite genérico
        var generic_path = _get_generic_sprite_path(object_type_str)
        if generic_path != "" and ResourceLoader.exists(generic_path):
            obj_node.texture = load(generic_path)
        else:
            # Último recurso: placeholder colorido
            obj_node.texture = _create_placeholder_texture(obj_type)
```

### 4. Testar

```
1. Criar os 5 sprites genéricos
2. Reabrir Godot
3. Executar temple_of_trials.tscn
4. Ver sprites genéricos ao invés de placeholders!
```

## Conclusão

O sistema está pronto para receber sprites reais. Escolha a opção que melhor se adequa ao seu cronograma:

- **Agora**: Opção 1 (sprites genéricos)
- **Depois**: Opção 2 (mapeamento manual)
- **Versão final**: Opção 3 (sistema completo)

O importante é que **o sistema de carregamento está 100% funcional** e aceita sprites assim que você adicioná-los!

---

**Próximo passo recomendado**: Criar 5 sprites genéricos simples (30 minutos)
