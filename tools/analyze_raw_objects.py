#!/usr/bin/env python3
"""Analisa bytes brutos após seção de scripts para encontrar objetos."""

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
    
    # Ir direto para após os tiles
    # Header: 60 bytes
    # Reserved: 176 bytes
    # Tiles: 40000 bytes (só elevação 0)
    # Total: 40236 bytes
    
    offset = 40236
    
    print(f"Analisando a partir do offset {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    print("=" * 60)
    
    # Mostrar os primeiros 200 bytes como hex e valores
    print("\nPrimeiros 200 bytes após tiles:")
    for i in range(0, min(200, len(data) - offset), 4):
        val = struct.unpack('>I', data[offset+i:offset+i+4])[0]
        val_signed = struct.unpack('>i', data[offset+i:offset+i+4])[0]
        hex_bytes = data[offset+i:offset+i+4].hex()
        print(f"  +{i:4d}: {hex_bytes}  uint={val:10d}  int={val_signed:10d}")
    
    # Procurar padrões de objetos
    # Objetos do Fallout 2 têm PIDs com formato específico:
    # - Byte alto indica tipo (0=item, 1=critter, 2=scenery, 3=wall, etc)
    # - Bytes baixos indicam ID
    
    print("\n" + "=" * 60)
    print("Procurando PIDs válidos (formato 0x0TNNNNNN onde T=tipo):")
    
    found_pids = []
    for i in range(offset, len(data) - 4, 4):
        val = struct.unpack('>I', data[i:i+4])[0]
        
        # PID válido: byte mais alto é 0, segundo byte é tipo (0-5)
        high_byte = (val >> 24) & 0xFF
        type_byte = (val >> 16) & 0xFF
        
        if high_byte == 0 and type_byte <= 5 and (val & 0xFFFF) > 0 and (val & 0xFFFF) < 10000:
            # Verificar se o próximo valor parece um tile válido
            if i + 4 < len(data):
                next_val = struct.unpack('>i', data[i+4:i+8])[0]
                if 0 <= next_val < 10000:  # Tile válido
                    found_pids.append((i, val, next_val))
    
    print(f"Encontrados {len(found_pids)} possíveis PIDs")
    for i, (off, pid, tile) in enumerate(found_pids[:20]):
        obj_type = (pid >> 16) & 0xFF
        obj_id = pid & 0xFFFF
        type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
        type_name = type_names[obj_type] if obj_type < len(type_names) else "?"
        x = tile % 100
        y = tile // 100
        print(f"  Offset {off}: PID={pid:08X} ({type_name}:{obj_id}), tile={tile} ({x},{y})")
    
    # Tentar encontrar o contador de objetos
    print("\n" + "=" * 60)
    print("Procurando contador de objetos (valor entre 1-500):")
    
    for i in range(offset, min(offset + 500, len(data) - 4), 4):
        val = struct.unpack('>I', data[i:i+4])[0]
        if 1 <= val <= 500:
            # Verificar se após este valor há PIDs válidos
            if i + 8 < len(data):
                next_val = struct.unpack('>I', data[i+4:i+8])[0]
                high = (next_val >> 24) & 0xFF
                type_b = (next_val >> 16) & 0xFF
                if high == 0 and type_b <= 5:
                    print(f"  Offset {i}: count={val}, próximo valor={next_val:08X}")
    
    dat.close()


if __name__ == "__main__":
    main()
