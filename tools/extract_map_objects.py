#!/usr/bin/env python3
"""
Extrai objetos dos mapas do Fallout 2 e atualiza os JSONs.
Baseado no código original (src/object.cc - objectRead)
"""

import struct
import zlib
import json
from pathlib import Path
from typing import Dict, List, Optional


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


# Tipos de objeto baseados no PID
OBJ_TYPES = {
    0: "item",
    1: "critter",
    2: "scenery",
    3: "wall",
    4: "tile",
    5: "misc"
}


def parse_map_objects(data: bytes, map_name: str) -> List[Dict]:
    """Parseia objetos de um arquivo MAP."""
    objects = []
    
    try:
        offset = 0
        
        # Pular header (versão)
        offset += 4
        
        # Pular nome (16 bytes)
        offset += 16
        
        # Pular entering info (12 bytes)
        offset += 12
        
        # Ler variáveis locais
        local_vars = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        # Pular script index, flags, darkness, global vars, map id, timestamp
        offset += 24
        
        # Pular campos reservados (44 * 4 = 176 bytes)
        offset += 176
        
        # Ler global vars count
        global_vars = struct.unpack('>I', data[offset-176-24+20:offset-176-24+24])[0]
        
        # Pular variáveis globais e locais
        offset += global_vars * 4
        offset += local_vars * 4
        
        # Pular tiles (3 níveis * 100 * 100 * 4 bytes = 120000 bytes)
        offset += 3 * 100 * 100 * 4
        
        # Agora estamos na seção de objetos
        if offset + 4 > len(data):
            return objects
        
        total_objects = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        print(f"  {map_name}: {total_objects} objetos encontrados")
        
        for i in range(min(total_objects, 5000)):  # Limite de segurança
            if offset + 72 > len(data):  # Tamanho mínimo de um objeto
                break
            
            try:
                # Estrutura do objeto (baseado em objectRead):
                # id, tile, x, y, sx, sy, frame, rotation, fid, flags,
                # elevation, pid, cid, lightDistance, lightIntensity, field_74, sid, scriptIndex
                
                obj_id = struct.unpack('>i', data[offset:offset+4])[0]
                tile = struct.unpack('>i', data[offset+4:offset+8])[0]
                x = struct.unpack('>i', data[offset+8:offset+12])[0]
                y = struct.unpack('>i', data[offset+12:offset+16])[0]
                sx = struct.unpack('>i', data[offset+16:offset+20])[0]
                sy = struct.unpack('>i', data[offset+20:offset+24])[0]
                frame = struct.unpack('>i', data[offset+24:offset+28])[0]
                rotation = struct.unpack('>i', data[offset+28:offset+32])[0]
                fid = struct.unpack('>I', data[offset+32:offset+36])[0]
                flags = struct.unpack('>I', data[offset+36:offset+40])[0]
                elevation = struct.unpack('>i', data[offset+40:offset+44])[0]
                pid = struct.unpack('>I', data[offset+44:offset+48])[0]
                
                offset += 72  # 18 campos * 4 bytes
                
                # Extrair tipo do objeto do PID
                obj_type_id = (pid >> 24) & 0xF
                obj_type = OBJ_TYPES.get(obj_type_id, "misc")
                
                # Extrair índice do FID
                fid_index = fid & 0xFFF
                
                # Calcular posição no grid
                tile_x = tile % 100 if tile >= 0 else 0
                tile_y = (tile // 100) % 100 if tile >= 0 else 0
                
                obj = {
                    "pid": pid,
                    "fid": fid,
                    "fid_index": fid_index,
                    "x": tile_x,
                    "y": tile_y,
                    "tile": tile,
                    "elevation": elevation & 0x3,
                    "rotation": rotation & 0x7,
                    "object_type": obj_type,
                    "flags": flags
                }
                
                objects.append(obj)
                
                # Pular dados extras baseado no tipo
                # Items, critters, etc. têm dados adicionais
                if obj_type == "critter":
                    offset += 40  # Dados de critter
                elif obj_type == "item":
                    offset += 12  # Dados de item
                    
            except Exception as e:
                break
        
    except Exception as e:
        print(f"  Erro ao parsear {map_name}: {e}")
    
    return objects


def main():
    print("=" * 60)
    print("EXTRATOR DE OBJETOS DOS MAPAS")
    print("=" * 60)
    
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    json_dir = project_root / "godot_project" / "assets" / "data" / "maps"
    
    if not dat_path.exists():
        print(f"DAT não encontrado: {dat_path}")
        return
    
    print(f"Lendo: {dat_path}")
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    # Processar apenas artemple por enquanto
    map_file = "maps/artemple.map"
    data = dat.get(map_file)
    
    if data:
        objects = parse_map_objects(data, "artemple")
        
        # Atualizar JSON
        json_path = json_dir / "artemple.json"
        if json_path.exists():
            with open(json_path, 'r') as f:
                map_data = json.load(f)
            
            map_data['objects'] = objects
            map_data['stats']['total_objects'] = len(objects)
            map_data['stats']['critters'] = len([o for o in objects if o['object_type'] == 'critter'])
            map_data['stats']['items'] = len([o for o in objects if o['object_type'] == 'item'])
            map_data['stats']['scenery'] = len([o for o in objects if o['object_type'] == 'scenery'])
            map_data['stats']['walls'] = len([o for o in objects if o['object_type'] == 'wall'])
            
            with open(json_path, 'w') as f:
                json.dump(map_data, f, indent=2)
            
            print(f"\nAtualizado: {json_path}")
            print(f"  Objetos: {len(objects)}")
            print(f"  Por tipo: critters={map_data['stats']['critters']}, "
                  f"items={map_data['stats']['items']}, "
                  f"scenery={map_data['stats']['scenery']}, "
                  f"walls={map_data['stats']['walls']}")
    
    dat.close()


if __name__ == "__main__":
    main()
