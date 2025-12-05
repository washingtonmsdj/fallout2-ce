#!/usr/bin/env python3
"""Debug da estrutura do arquivo MAP."""

import struct
import zlib
from pathlib import Path


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


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    data = dat.get("maps/artemple.map")
    if not data:
        print("Mapa não encontrado!")
        return
    
    print(f"Tamanho do arquivo: {len(data)} bytes")
    
    offset = 0
    
    # Header
    version = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: version = {version}")
    offset += 4
    
    # Nome
    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1')
    print(f"Offset {offset}: name = '{name}'")
    offset += 16
    
    # Entering
    entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
    entering_elev = struct.unpack('>I', data[offset+4:offset+8])[0]
    entering_rot = struct.unpack('>I', data[offset+8:offset+12])[0]
    print(f"Offset {offset}: entering = tile:{entering_tile}, elev:{entering_elev}, rot:{entering_rot}")
    offset += 12
    
    # Local vars
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: local_vars = {local_vars}")
    offset += 4
    
    # Script index
    script_idx = struct.unpack('>i', data[offset:offset+4])[0]
    print(f"Offset {offset}: script_index = {script_idx}")
    offset += 4
    
    # Flags
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: flags = {flags} (bin: {bin(flags)})")
    offset += 4
    
    # Darkness
    darkness = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: darkness = {darkness}")
    offset += 4
    
    # Global vars
    global_vars = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: global_vars = {global_vars}")
    offset += 4
    
    # Map ID
    map_id = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: map_id = {map_id}")
    offset += 4
    
    # Timestamp
    timestamp = struct.unpack('>I', data[offset:offset+4])[0]
    print(f"Offset {offset}: timestamp = {timestamp}")
    offset += 4
    
    # Reserved (44 * 4 = 176 bytes)
    print(f"Offset {offset}: reserved (176 bytes)")
    offset += 176
    
    # Global vars data
    print(f"Offset {offset}: global_vars data ({global_vars * 4} bytes)")
    offset += global_vars * 4
    
    # Local vars data
    print(f"Offset {offset}: local_vars data ({local_vars * 4} bytes)")
    offset += local_vars * 4
    
    # Tiles - depende dos flags
    elev_flags = [2, 4, 8]
    tiles_per_level = 100 * 100 * 4
    total_tiles_size = 0
    print(f"\nTiles:")
    for i, ef in enumerate(elev_flags):
        if (flags & ef) == 0:
            print(f"  Elevação {i}: presente ({tiles_per_level} bytes)")
            total_tiles_size += tiles_per_level
        else:
            print(f"  Elevação {i}: NÃO presente")
    
    print(f"Offset {offset}: tiles ({total_tiles_size} bytes)")
    offset += total_tiles_size
    
    print(f"\nOffset após tiles: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Scripts section (5 tipos)
    print(f"\nScripts:")
    for script_type in range(5):
        if offset + 4 <= len(data):
            count = struct.unpack('>I', data[offset:offset+4])[0]
            print(f"  Tipo {script_type}: {count} scripts")
            offset += 4
            
            # Cada script tem dados variáveis
            for _ in range(min(count, 100)):
                if offset + 16 > len(data):
                    break
                # Pular dados do script (tamanho variável, mas pelo menos 16 bytes)
                offset += 16
    
    print(f"\nOffset após scripts: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Objetos
    if offset + 4 <= len(data):
        obj_count = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"\nObjetos: {obj_count}")
        
        if obj_count > 0 and obj_count < 10000:
            offset += 4
            print(f"Primeiros 100 bytes de objetos:")
            print(data[offset:offset+100].hex())
    
    dat.close()


if __name__ == "__main__":
    main()
