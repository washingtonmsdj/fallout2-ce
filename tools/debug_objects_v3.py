#!/usr/bin/env python3
"""Debug detalhado da leitura de objetos - versão 3."""

import struct
import zlib
from pathlib import Path

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


def load_protos(dat):
    """Carrega protos de scenery para determinar subtipos."""
    protos = {}
    
    # Scenery protos
    files = dat.list_files("proto/scenery")
    for filepath in files:
        if not filepath.endswith('.pro'):
            continue
        
        data = dat.get(filepath)
        if not data or len(data) < 36:
            continue
        
        try:
            pid = struct.unpack('>I', data[0:4])[0]
            # type está no offset 32
            subtype = struct.unpack('>I', data[32:36])[0]
            protos[pid] = subtype
        except:
            continue
    
    # Item protos
    files = dat.list_files("proto/items")
    for filepath in files:
        if not filepath.endswith('.pro'):
            continue
        
        data = dat.get(filepath)
        if not data or len(data) < 36:
            continue
        
        try:
            pid = struct.unpack('>I', data[0:4])[0]
            # type está no offset 32
            subtype = struct.unpack('>I', data[32:36])[0]
            protos[pid] = subtype
        except:
            continue
    
    return protos


def main():
    print("Iniciando...", flush=True)
    
    dat_path = Path("Fallout 2/master.dat")
    dat = DAT2Reader(dat_path)
    dat.open()
    
    print(f"DAT aberto: {len(dat.files)} arquivos", flush=True)
    
    # Carregar protos
    print("Carregando protos...", flush=True)
    protos = load_protos(dat)
    print(f"Protos carregados: {len(protos)}", flush=True)
    
    # Ler mapa
    data = dat.get("maps/artemple.map")
    print(f"Mapa: {len(data)} bytes", flush=True)
    
    # Ir para seção de objetos
    offset = 42448  # Após total_objects e obj_count
    
    print(f"\n=== OBJETOS (offset {offset}) ===", flush=True)
    
    # Ler todos os 567 objetos
    obj_count = 567
    
    for i in range(obj_count):
        if offset + 72 > len(data):
            print(f"\nERRO: fim dos dados no objeto {i}, offset={offset}", flush=True)
            break
        
        start_offset = offset
        
        # Base (72 bytes)
        obj_id = struct.unpack('>I', data[offset+0:offset+4])[0]
        tile = struct.unpack('>i', data[offset+4:offset+8])[0]
        fid = struct.unpack('>I', data[offset+32:offset+36])[0]
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        pid = struct.unpack('>I', data[offset+44:offset+48])[0]
        
        obj_type_id = (pid >> 24) & 0xFF
        obj_type = TYPE_NAMES.get(obj_type_id, f"unknown({obj_type_id})")
        
        offset += 72
        
        # Inventário (12 bytes)
        inv_length = struct.unpack('>I', data[offset:offset+4])[0]
        inv_capacity = struct.unpack('>I', data[offset+4:offset+8])[0]
        offset += 12
        
        # Dados específicos
        extra_bytes = 0
        if obj_type_id == OBJ_TYPE_CRITTER:
            extra_bytes = 44
            offset += 44
        elif obj_type_id == OBJ_TYPE_ITEM:
            extra_bytes = 4
            offset += 4
            
            subtype = protos.get(pid, -1)
            if subtype == 3:  # Weapon
                extra_bytes += 8
                offset += 8
            elif subtype in [4, 5, 6]:  # Ammo, Misc, Key
                extra_bytes += 4
                offset += 4
        elif obj_type_id == OBJ_TYPE_SCENERY:
            extra_bytes = 4
            offset += 4
            
            subtype = protos.get(pid, -1)
            if subtype == 0:  # Door
                extra_bytes += 4
                offset += 4
            elif subtype in [1, 2]:  # Stairs, Elevator
                extra_bytes += 8
                offset += 8
            elif subtype in [3, 4]:  # Ladder
                extra_bytes += 8
                offset += 8
        elif obj_type_id == OBJ_TYPE_WALL:
            extra_bytes = 4
            offset += 4
        elif obj_type_id == OBJ_TYPE_MISC:
            extra_bytes = 4
            offset += 4
            
            pid_index = pid & 0xFFFFFF
            if pid_index <= 0x10:
                extra_bytes += 16
                offset += 16
        
        total_size = offset - start_offset
        
        # Mostrar apenas objetos interessantes ou a cada 50
        if i < 10 or i % 50 == 0 or obj_type_id != OBJ_TYPE_SCENERY or inv_length > 0:
            print(f"Obj {i:3d}: tile={tile:5d}, pid={pid:08X} ({obj_type:8s}), inv={inv_length}, extra={extra_bytes}, size={total_size}, offset={offset}", flush=True)
    
    print(f"\nOffset final: {offset}", flush=True)
    print(f"Bytes restantes: {len(data) - offset}", flush=True)
    
    dat.close()
    print("\nFim!", flush=True)


if __name__ == "__main__":
    main()
