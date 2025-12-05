#!/usr/bin/env python3
"""
Parser DEFINITIVO de mapas do Fallout 2.

Baseado no código fonte oficial do Fallout 2 CE:
https://github.com/alexbatalov/fallout2-ce

Estrutura correta de objetos descoberta através de análise do código fonte.
"""

import struct
import zlib
import json
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Optional, Tuple


class DAT2Reader:
    def __init__(self, path):
        self.path = Path(path)
        self.files = {}
        self.fh = None
        
    def open(self):
        self.fh = open(self.path, 'rb')
        self.fh.seek(-8, 2)
        tree_size = struct.unpack('<I', self.fh.read(4))[0]
        data_size = struct.unpack('<I', self.fh.read(4))[0]
        self.fh.seek(data_size - tree_size - 8)
        count = struct.unpack('<I', self.fh.read(4))[0]
        for _ in range(count):
            nlen = struct.unpack('<I', self.fh.read(4))[0]
            name = self.fh.read(nlen).decode('ascii', errors='ignore').rstrip('\x00')
            comp = struct.unpack('<B', self.fh.read(1))[0]
            rsize = struct.unpack('<I', self.fh.read(4))[0]
            psize = struct.unpack('<I', self.fh.read(4))[0]
            off = struct.unpack('<I', self.fh.read(4))[0]
            self.files[name.lower().replace('\\', '/')] = (comp, rsize, psize, off)
        return len(self.files)
    
    def close(self):
        if self.fh:
            self.fh.close()
    
    def get(self, name):
        name = name.lower().replace('\\', '/')
        if name not in self.files:
            return None
        comp, rsize, psize, off = self.files[name]
        self.fh.seek(off)
        data = self.fh.read(psize)
        if comp:
            try:
                data = zlib.decompress(data)
            except:
                pass
        return data


@dataclass
class MapObject:
    pid: int
    x: int
    y: int
    elevation: int
    orientation: int
    script_id: int
    object_type: str
    frm_id: int = 0
    flags: int = 0


TYPE_NAMES = {
    0: "item",
    1: "critter",
    2: "scenery",
    3: "wall",
    4: "tile",
    5: "misc"
}


def read_int32_be(data: bytes, offset: int) -> int:
    """Lê um int32 big-endian."""
    return struct.unpack('>i', data[offset:offset+4])[0]


def read_uint32_be(data: bytes, offset: int) -> int:
    """Lê um uint32 big-endian."""
    return struct.unpack('>I', data[offset:offset+4])[0]


def read_object_from_save(data: bytes, offset: int, obj_num: int, verbose: bool = False) -> Tuple[Optional[MapObject], int]:
    """
    Lê um objeto usando o formato de save do Fallout 2.
    
    Baseado em objectDataRead() do código fonte:
    - 72 bytes: campos base
    - 12 bytes: inventário header
    - N * 4 bytes: items no inventário (apenas ponteiros, não objetos completos)
    - Dados específicos do tipo
    """
    
    MIN_SIZE = 84  # 72 + 12
    
    if offset + MIN_SIZE > len(data):
        return None, offset
    
    start_offset = offset
    
    try:
        # === CAMPOS BASE (72 bytes) ===
        obj_id = read_uint32_be(data, offset + 0)
        tile = read_int32_be(data, offset + 4)
        x_off = read_int32_be(data, offset + 8)
        y_off = read_int32_be(data, offset + 12)
        sx = read_int32_be(data, offset + 16)
        sy = read_int32_be(data, offset + 20)
        frame = read_uint32_be(data, offset + 24)
        rotation = read_uint32_be(data, offset + 28)
        fid = read_uint32_be(data, offset + 32)
        flags = read_uint32_be(data, offset + 36)
        elevation = read_uint32_be(data, offset + 40)
        pid = read_uint32_be(data, offset + 44)
        cid = read_uint32_be(data, offset + 48)
        light_distance = read_uint32_be(data, offset + 52)
        light_intensity = read_uint32_be(data, offset + 56)
        outline = read_uint32_be(data, offset + 60)
        sid = read_int32_be(data, offset + 64)
        script_index = read_uint32_be(data, offset + 68)
        
        offset += 72
        
        # === INVENTÁRIO (12 bytes header) ===
        inv_length = read_uint32_be(data, offset + 0)
        inv_capacity = read_uint32_be(data, offset + 4)
        inv_ptr = read_uint32_be(data, offset + 8)  # Ignorado
        offset += 12
        
        # Items no inventário (4 bytes cada - apenas ponteiros)
        # Em arquivos salvos, estes são ponteiros que devemos ignorar
        if inv_length > 0 and inv_length < 0x80000000:  # Verificar se não é -1
            if inv_length < 1000:  # Sanity check
                offset += inv_length * 4
        
        # === DADOS ESPECÍFICOS DO TIPO ===
        obj_type_id = (pid >> 24) & 0xFF
        
        # Ler flags do tipo (4 bytes)
        if offset + 4 <= len(data):
            type_flags = read_uint32_be(data, offset)
            offset += 4
        
        # Dados adicionais por tipo
        if obj_type_id == 1:  # CRITTER
            # Critter data: combat_data (32) + hp (4) + rad (4) + poison (4) = 44 bytes
            if offset + 44 <= len(data):
                offset += 44
        elif obj_type_id == 0:  # ITEM
            # Item data: varia por subtipo (0-8 bytes)
            item_subtype = (pid >> 16) & 0xFF
            if item_subtype == 0:  # Armor
                offset += 4
            elif item_subtype == 1:  # Container
                offset += 4
            elif item_subtype == 2:  # Drug
                offset += 4
            elif item_subtype == 3:  # Weapon
                offset += 8
            elif item_subtype == 4:  # Ammo
                offset += 4
            elif item_subtype == 5:  # Misc
                offset += 4
            elif item_subtype == 6:  # Key
                offset += 4
        elif obj_type_id == 2:  # SCENERY
            # Scenery data: varia por subtipo
            scenery_subtype = (pid >> 16) & 0xFF
            if scenery_subtype == 0:  # Door
                offset += 4
            elif scenery_subtype == 1:  # Stairs
                offset += 8
            elif scenery_subtype == 2:  # Elevator
                offset += 8
            elif scenery_subtype == 3:  # Ladder bottom
                offset += 8
            elif scenery_subtype == 4:  # Ladder top
                offset += 8
        elif obj_type_id == 5:  # MISC
            # Misc data: exit grid tem 16 bytes extras
            misc_subtype = (pid >> 16) & 0xFF
            if misc_subtype == 0:  # Exit grid
                offset += 16
        
        # Calcular posição no mapa
        if 0 <= tile < 10000:
            x = tile % 100
            y = tile // 100
        else:
            x = 0
            y = 0
        
        # Tipo de objeto
        obj_type = TYPE_NAMES.get(obj_type_id, "misc")
        
        # Criar objeto
        obj = MapObject(
            pid=pid,
            x=x,
            y=y,
            elevation=elevation & 0x3,
            orientation=rotation & 0x7,
            script_id=sid,
            object_type=obj_type,
            frm_id=fid,
            flags=flags
        )
        
        bytes_read = offset - start_offset
        
        if verbose and obj_num < 50:
            inv_str = f"inv={inv_length}" if inv_length < 1000 else "inv=?"
            print(f"  {obj_num:3d}: {obj_type:8s} PID={pid:08X} @ ({x:2d},{y:2d}) {inv_str} - {bytes_read} bytes")
        
        return obj, offset
        
    except Exception as e:
        if verbose:
            print(f"  ERRO em objeto {obj_num} offset {offset}: {e}")
        return None, offset + MIN_SIZE


def parse_map_definitivo(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parser definitivo baseado no código fonte do Fallout 2 CE."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    
    offset = 0
    
    # === HEADER (236 bytes) ===
    version = read_uint32_be(data, offset)
    offset += 4
    
    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16
    
    entering_tile = read_uint32_be(data, offset)
    entering_elev = read_uint32_be(data, offset + 4)
    entering_rot = read_uint32_be(data, offset + 8)
    offset += 12
    
    local_vars = read_uint32_be(data, offset)
    offset += 4
    
    script_idx = read_int32_be(data, offset)
    offset += 4
    
    flags = read_uint32_be(data, offset)
    offset += 4
    
    darkness = read_uint32_be(data, offset)
    global_vars = read_uint32_be(data, offset + 4)
    map_id = read_uint32_be(data, offset + 8)
    timestamp = read_uint32_be(data, offset + 12)
    offset += 16
    
    # Reserved (176 bytes)
    offset += 176
    
    # Global vars
    offset += global_vars * 4
    
    # Local vars
    offset += local_vars * 4
    
    if verbose:
        print(f"Header: version={version}, name={name}")
        print(f"Offset após header: {offset}")
    
    # === TILES ===
    tiles = []
    elev_flags = [2, 4, 8]
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue
        
        for i in range(MAP_WIDTH * MAP_HEIGHT):
            if offset + 4 > len(data):
                break
            
            tile_value = read_uint32_be(data, offset)
            offset += 4
            
            floor_id = tile_value & 0xFFFF
            roof_id = (tile_value >> 16) & 0xFFFF
            
            x = i % MAP_WIDTH
            y = i // MAP_WIDTH
            
            if floor_id != 0 or roof_id != 0:
                tiles.append({
                    "floor_id": floor_id,
                    "roof_id": roof_id,
                    "x": x,
                    "y": y,
                    "elevation": elevation
                })
    
    if verbose:
        print(f"Offset após tiles: {offset}")
    
    # === SCRIPTS ===
    # 5 tipos de scripts
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = read_uint32_be(data, offset)
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type}: {count}")
        
        if count > 0 and count < 1000:
            # Cada script tem 16 bytes base
            # Mas há padding/alinhamento complexo
            # Vamos usar o tamanho descoberto: 20 bytes por script
            offset += count * 20
    
    if verbose:
        print(f"Offset após scripts: {offset}")
        print(f"Bytes restantes: {len(data) - offset}\n")
    
    # === OBJETOS ===
    # Formato descoberto: não há contador total, apenas contadores por elevação
    # Pular possível header/padding (32 bytes)
    offset += 32
    
    objects = []
    
    if verbose:
        print(f"Início da seção de objetos: offset {offset}\n")
    
    # Ler objetos para cada elevação
    for elevation in range(3):
        if offset + 4 > len(data):
            break
        
        obj_count = read_uint32_be(data, offset)
        offset += 4
        
        if verbose:
            print(f"Elevação {elevation}: {obj_count} objetos")
        
        if obj_count > 0 and obj_count < 10000:
            for i in range(obj_count):
                if offset + 84 > len(data):
                    if verbose:
                        print(f"  Fim dos dados em objeto {i}")
                    break
                
                obj, new_offset = read_object_from_save(data, offset, len(objects), verbose)
                
                if obj and obj.pid != 0 and obj.pid != 0xFFFFFFFF:
                    obj.elevation = elevation
                    objects.append(obj)
                
                if new_offset <= offset:
                    if verbose:
                        print(f"  Offset não avançou, parando")
                    break
                
                offset = new_offset
    
    if verbose:
        print(f"\nTotal objetos lidos: {len(objects)}")
        print(f"Offset final: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")
    
    return {
        "name": name,
        "filename": filename,
        "version": version,
        "width": MAP_WIDTH,
        "height": MAP_HEIGHT,
        "num_levels": 3,
        "entering": {
            "tile": entering_tile,
            "elevation": entering_elev,
            "rotation": entering_rot,
            "x": entering_tile % MAP_WIDTH,
            "y": entering_tile // MAP_WIDTH
        },
        "script": f"script_{script_idx}.int" if script_idx > 0 else "",
        "flags": flags,
        "tiles": tiles,
        "objects": [asdict(o) for o in objects],
        "stats": {
            "total_tiles": len(tiles),
            "total_objects": len(objects),
            "critters": len([o for o in objects if o.object_type == "critter"]),
            "items": len([o for o in objects if o.object_type == "item"]),
            "scenery": len([o for o in objects if o.object_type == "scenery"]),
            "walls": len([o for o in objects if o.object_type == "wall"]),
            "misc": len([o for o in objects if o.object_type == "misc"])
        }
    }


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    print("=" * 70)
    print("PARSER DEFINITIVO - ARTEMPLE.MAP")
    print("=" * 70)
    
    data = dat.get("maps/artemple.map")
    if data:
        print(f"Tamanho: {len(data)} bytes\n")
        
        map_data = parse_map_definitivo(data, "artemple.map", verbose=True)
        
        print("\n" + "=" * 70)
        print("RESULTADO FINAL")
        print("=" * 70)
        print(f"Nome: {map_data['name']}")
        print(f"Tiles: {map_data['stats']['total_tiles']}")
        print(f"Objetos: {map_data['stats']['total_objects']}")
        print(f"  - Critters: {map_data['stats']['critters']}")
        print(f"  - Items: {map_data['stats']['items']}")
        print(f"  - Scenery: {map_data['stats']['scenery']}")
        print(f"  - Walls: {map_data['stats']['walls']}")
        print(f"  - Misc: {map_data['stats']['misc']}")
        
        # Verificar progresso
        total = map_data['stats']['total_objects']
        if total >= 500:
            print(f"\n✓ EXCELENTE! Lemos {total} objetos (esperado: ~567)")
        elif total >= 300:
            print(f"\n⚠ BOM PROGRESSO! Lemos {total} objetos (esperado: ~567)")
        elif total >= 100:
            print(f"\n⚠ Progresso moderado: {total} objetos (esperado: ~567)")
        else:
            print(f"\n✗ Ainda faltam muitos objetos: {total}/567")
        
        # Salvar
        output_path = project_root / "godot_project" / "assets" / "data" / "maps" / "artemple.json"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSalvo em: {output_path}")
    
    dat.close()


if __name__ == "__main__":
    main()
