#!/usr/bin/env python3
"""
Parser de mapas do Fallout 2 com suporte a protos.
Carrega os protos para determinar os subtipos de items e scenery.
"""

import struct
import zlib
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Tuple
import json

# Tipos de objeto
OBJ_TYPE_ITEM = 0
OBJ_TYPE_CRITTER = 1
OBJ_TYPE_SCENERY = 2
OBJ_TYPE_WALL = 3
OBJ_TYPE_TILE = 4
OBJ_TYPE_MISC = 5

TYPE_NAMES = {
    OBJ_TYPE_ITEM: "item",
    OBJ_TYPE_CRITTER: "critter",
    OBJ_TYPE_SCENERY: "scenery",
    OBJ_TYPE_WALL: "wall",
    OBJ_TYPE_TILE: "tile",
    OBJ_TYPE_MISC: "misc"
}

# Subtipos de item
ITEM_TYPE_ARMOR = 0
ITEM_TYPE_CONTAINER = 1
ITEM_TYPE_DRUG = 2
ITEM_TYPE_WEAPON = 3
ITEM_TYPE_AMMO = 4
ITEM_TYPE_MISC = 5
ITEM_TYPE_KEY = 6

# Subtipos de scenery
SCENERY_TYPE_DOOR = 0
SCENERY_TYPE_STAIRS = 1
SCENERY_TYPE_ELEVATOR = 2
SCENERY_TYPE_LADDER_UP = 3
SCENERY_TYPE_LADDER_DOWN = 4
SCENERY_TYPE_GENERIC = 5


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
    
    def list_files(self, prefix=""):
        return [f for f in self.files.keys() if f.startswith(prefix.lower())]


@dataclass
class Proto:
    pid: int
    obj_type: int
    subtype: int  # Para items e scenery


@dataclass
class MapObject:
    pid: int
    x: int
    y: int
    tile: int
    elevation: int
    orientation: int
    script_id: int
    object_type: str
    frm_id: int = 0
    flags: int = 0


def load_protos(dat: DAT2Reader) -> Dict[int, Proto]:
    """Carrega todos os protos do DAT."""
    protos = {}
    
    # Tipos de proto e seus diretórios
    proto_dirs = {
        OBJ_TYPE_ITEM: "proto/items",
        OBJ_TYPE_CRITTER: "proto/critters",
        OBJ_TYPE_SCENERY: "proto/scenery",
        OBJ_TYPE_WALL: "proto/walls",
        OBJ_TYPE_TILE: "proto/tiles",
        OBJ_TYPE_MISC: "proto/misc"
    }
    
    for obj_type, proto_dir in proto_dirs.items():
        files = dat.list_files(proto_dir)
        
        for filepath in files:
            if not filepath.endswith('.pro'):
                continue
            
            data = dat.get(filepath)
            if not data or len(data) < 12:
                continue
            
            try:
                pid = struct.unpack('>I', data[0:4])[0]
                
                subtype = 0
                if obj_type == OBJ_TYPE_ITEM:
                    # type está no offset 32 (após pid, messageId, fid, lightDistance, lightIntensity, flags, extendedFlags, sid)
                    if len(data) >= 36:
                        subtype = struct.unpack('>I', data[32:36])[0]
                elif obj_type == OBJ_TYPE_SCENERY:
                    # type está no offset 32
                    if len(data) >= 36:
                        subtype = struct.unpack('>I', data[32:36])[0]
                
                protos[pid] = Proto(pid=pid, obj_type=obj_type, subtype=subtype)
            except:
                continue
    
    return protos


def read_object(data: bytes, offset: int, protos: Dict[int, Proto], verbose: bool = False) -> Tuple[Optional[MapObject], int]:
    """Lê um objeto do mapa."""
    
    if offset + 72 > len(data):
        return None, offset
    
    start_offset = offset
    
    try:
        # Campos base (72 bytes)
        obj_id = struct.unpack('>I', data[offset+0:offset+4])[0]
        tile = struct.unpack('>i', data[offset+4:offset+8])[0]
        x_off = struct.unpack('>i', data[offset+8:offset+12])[0]
        y_off = struct.unpack('>i', data[offset+12:offset+16])[0]
        sx = struct.unpack('>i', data[offset+16:offset+20])[0]
        sy = struct.unpack('>i', data[offset+20:offset+24])[0]
        frame = struct.unpack('>I', data[offset+24:offset+28])[0]
        rotation = struct.unpack('>I', data[offset+28:offset+32])[0]
        fid = struct.unpack('>I', data[offset+32:offset+36])[0]
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        elevation = struct.unpack('>I', data[offset+40:offset+44])[0]
        pid = struct.unpack('>I', data[offset+44:offset+48])[0]
        cid = struct.unpack('>I', data[offset+48:offset+52])[0]
        light_dist = struct.unpack('>I', data[offset+52:offset+56])[0]
        light_int = struct.unpack('>I', data[offset+56:offset+60])[0]
        field_74 = struct.unpack('>I', data[offset+60:offset+64])[0]
        sid = struct.unpack('>i', data[offset+64:offset+68])[0]
        script_idx = struct.unpack('>I', data[offset+68:offset+72])[0]
        
        offset += 72
        
        obj_type_id = (pid >> 24) & 0xFF
        obj_type = TYPE_NAMES.get(obj_type_id, f"unknown({obj_type_id})")
        
        # Inventário (12 bytes)
        if offset + 12 > len(data):
            return None, start_offset + 72
        
        inv_length = struct.unpack('>I', data[offset:offset+4])[0]
        inv_capacity = struct.unpack('>I', data[offset+4:offset+8])[0]
        inv_ptr = struct.unpack('>I', data[offset+8:offset+12])[0]
        offset += 12
        
        # Ler itens do inventário recursivamente
        for _ in range(inv_length):
            if offset + 4 > len(data):
                break
            # quantity (4 bytes)
            offset += 4
            # objeto recursivo
            _, offset = read_object(data, offset, protos, verbose=False)
        
        # Dados específicos do tipo
        if obj_type_id == OBJ_TYPE_CRITTER:
            # Critter: field_0 (4) + combat data (28) + hp (4) + radiation (4) + poison (4) = 44 bytes
            # combat data: damageLastTurn, maneuver, ap, results, aiPacket, team, whoHitMeCid = 7 * 4 = 28
            offset += 44
        elif obj_type_id == OBJ_TYPE_ITEM:
            # flags (4 bytes)
            offset += 4
            
            # Dados específicos do subtipo
            proto = protos.get(pid)
            if proto:
                subtype = proto.subtype
                if subtype == ITEM_TYPE_WEAPON:
                    offset += 8  # ammoQuantity + ammoTypePid
                elif subtype in [ITEM_TYPE_AMMO, ITEM_TYPE_MISC, ITEM_TYPE_KEY]:
                    offset += 4
        elif obj_type_id == OBJ_TYPE_SCENERY:
            # flags (4 bytes)
            offset += 4
            
            # Dados específicos do subtipo
            proto = protos.get(pid)
            if proto:
                subtype = proto.subtype
                if subtype == SCENERY_TYPE_DOOR:
                    offset += 4  # openFlags
                elif subtype in [SCENERY_TYPE_STAIRS, SCENERY_TYPE_ELEVATOR]:
                    offset += 8
                elif subtype in [SCENERY_TYPE_LADDER_UP, SCENERY_TYPE_LADDER_DOWN]:
                    offset += 8  # Para versão 20
                # SCENERY_TYPE_GENERIC (5) não tem dados extras
        elif obj_type_id == OBJ_TYPE_WALL:
            # flags (4 bytes)
            offset += 4
        elif obj_type_id == OBJ_TYPE_MISC:
            # flags (4 bytes)
            offset += 4
            
            # Exit grid tem 16 bytes extras
            # PID de exit grid: 0x05000000 a 0x05000010
            pid_index = pid & 0xFFFFFF
            if pid_index <= 0x10:  # Exit grid
                offset += 16
        
        # Calcular posição
        if 0 <= tile < 40000:
            x = tile % 200
            y = tile // 200
        else:
            x = 0
            y = 0
        
        obj = MapObject(
            pid=pid,
            x=x,
            y=y,
            tile=tile,
            elevation=elevation & 0x3,
            orientation=rotation & 0x7,
            script_id=sid,
            object_type=obj_type,
            frm_id=fid,
            flags=flags
        )
        
        return obj, offset
        
    except Exception as e:
        if verbose:
            print(f"ERRO lendo objeto: {e}", flush=True)
        return None, start_offset + 72


def parse_map(data: bytes, filename: str, protos: Dict[int, Proto], verbose: bool = False) -> dict:
    """Parser de mapa com suporte a protos."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    TILES_PER_LEVEL = MAP_WIDTH * MAP_HEIGHT
    
    offset = 0
    
    # === HEADER ===
    version = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16
    
    entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
    entering_elev = struct.unpack('>I', data[offset+4:offset+8])[0]
    entering_rot = struct.unpack('>I', data[offset+8:offset+12])[0]
    offset += 12
    
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    script_idx = struct.unpack('>i', data[offset:offset+4])[0]
    offset += 4
    
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    darkness = struct.unpack('>I', data[offset:offset+4])[0]
    global_vars = struct.unpack('>I', data[offset+4:offset+8])[0]
    offset += 16
    
    # Reserved
    offset += 176
    
    # Vars
    offset += global_vars * 4
    offset += local_vars * 4
    
    if verbose:
        print(f"Header: version={version}, name={name}, flags={flags:08X}", flush=True)
        print(f"Offset após header+vars: {offset}", flush=True)
    
    # === TILES ===
    tiles = []
    elev_flags = [2, 4, 8]
    elevations_present = []
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue
        elevations_present.append(elevation)
        
        for i in range(TILES_PER_LEVEL):
            if offset + 4 > len(data):
                break
            
            tile_value = struct.unpack('>I', data[offset:offset+4])[0]
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
        print(f"Offset após tiles: {offset}", flush=True)
        print(f"Elevações presentes: {elevations_present}", flush=True)
    
    # === SCRIPTS ===
    SCRIPT_LIST_EXTENT_SIZE = 16
    
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        scripts_count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type}: {scripts_count}", flush=True)
        
        if scripts_count == 0:
            continue
        
        if scripts_count > 10000:
            if verbose:
                print(f"  ERRO: count muito alto!", flush=True)
            break
        
        num_extents = (scripts_count + SCRIPT_LIST_EXTENT_SIZE - 1) // SCRIPT_LIST_EXTENT_SIZE
        
        for ext_idx in range(num_extents):
            # Ler 16 scripts
            for i in range(SCRIPT_LIST_EXTENT_SIZE):
                if offset + 8 > len(data):
                    break
                
                sid = struct.unpack('>i', data[offset:offset+4])[0]
                sid_type = (sid >> 24) & 0xFF
                offset += 8  # sid + field_4
                
                # Dados específicos do tipo
                if sid_type == 1:  # SPATIAL
                    offset += 8
                elif sid_type == 2:  # TIMED
                    offset += 4
                
                offset += 56  # campos comuns
            
            # length + next
            offset += 8
    
    if verbose:
        print(f"Offset após scripts: {offset}", flush=True)
        print(f"Bytes restantes: {len(data) - offset}", flush=True)
    
    # === OBJETOS ===
    objects = []
    
    if offset + 4 <= len(data):
        total_objects = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"\nTotal objetos: {total_objects}", flush=True)
        
        if total_objects > 0 and total_objects < 50000:
            for elevation in range(3):
                if offset + 4 > len(data):
                    break
                
                obj_count = struct.unpack('>I', data[offset:offset+4])[0]
                offset += 4
                
                if verbose:
                    print(f"Elevação {elevation}: {obj_count} objetos", flush=True)
                
                if obj_count > 10000:
                    if verbose:
                        print(f"  ERRO: count muito alto!", flush=True)
                    break
                
                for i in range(obj_count):
                    if offset + 72 > len(data):
                        if verbose:
                            print(f"  ERRO: fim dos dados no objeto {i}, offset={offset}", flush=True)
                        break
                    
                    obj, offset = read_object(data, offset, protos, verbose=(verbose and i < 3))
                    if obj and obj.pid != 0 and obj.pid != 0xFFFFFFFF:
                        obj.elevation = elevation
                        objects.append(obj)
                    elif verbose and i < 10:
                        print(f"  Objeto {i} ignorado: obj={obj is not None}, pid={obj.pid if obj else 'None'}", flush=True)
    
    if verbose:
        print(f"\nTotal objetos lidos: {len(objects)}", flush=True)
        print(f"Offset final: {offset}", flush=True)
    
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
    print("Iniciando...", flush=True)
    
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    print(f"DAT aberto: {len(dat.files)} arquivos", flush=True)
    
    # Carregar protos
    print("Carregando protos...", flush=True)
    protos = load_protos(dat)
    print(f"Protos carregados: {len(protos)}", flush=True)
    
    # Testar com artemple
    print("\n" + "=" * 70, flush=True)
    print("ARTEMPLE.MAP", flush=True)
    print("=" * 70, flush=True)
    
    data = dat.get("maps/artemple.map")
    if data:
        map_data = parse_map(data, "artemple.map", protos, verbose=True)
        
        print("\n" + "=" * 70, flush=True)
        print("RESULTADO FINAL", flush=True)
        print("=" * 70, flush=True)
        print(f"Tiles: {map_data['stats']['total_tiles']}", flush=True)
        print(f"Objetos: {map_data['stats']['total_objects']}", flush=True)
        print(f"  - Critters: {map_data['stats']['critters']}", flush=True)
        print(f"  - Items: {map_data['stats']['items']}", flush=True)
        print(f"  - Scenery: {map_data['stats']['scenery']}", flush=True)
        print(f"  - Walls: {map_data['stats']['walls']}", flush=True)
        print(f"  - Misc: {map_data['stats']['misc']}", flush=True)
        
        if map_data['objects']:
            print("\nPrimeiros 20 objetos:", flush=True)
            for obj in map_data['objects'][:20]:
                print(f"  {obj['object_type']:8s}: tile={obj['tile']:5d} ({obj['x']:3d},{obj['y']:3d}) PID={obj['pid']:08X} FRM={obj['frm_id']:08X}", flush=True)
        
        # Salvar
        output_path = project_root / "godot_project" / "assets" / "data" / "maps" / "artemple.json"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSalvo em: {output_path}", flush=True)
    
    dat.close()
    print("\nFim!", flush=True)


if __name__ == "__main__":
    main()
