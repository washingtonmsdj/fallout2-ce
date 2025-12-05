#!/usr/bin/env python3
"""Analisa os tamanhos reais dos objetos no mapa."""

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
    
    print(f"Tamanho: {len(data)} bytes")
    
    # Começar na seção de objetos
    offset = 40296  # Após scripts
    
    print(f"\nAnalisando objetos a partir de offset {offset}...")
    print(f"Bytes disponíveis: {len(data) - offset}")
    
    # Se temos 567 objetos e 52484 bytes
    # Tamanho médio = 52484 / 567 ≈ 92.6 bytes
    
    print(f"\nTamanho médio esperado: {(len(data) - offset) / 567:.1f} bytes")
    
    # Vamos procurar padrões
    # Objetos válidos têm PID com tipo 0-5 no byte alto
    
    print("\nProcurando PIDs válidos:")
    
    valid_pids = []
    for test_offset in range(offset, min(offset + 1000, len(data) - 4), 4):
        pid = struct.unpack('>I', data[test_offset:test_offset+4])[0]
        obj_type = (pid >> 24) & 0xFF
        
        if 0 <= obj_type <= 5 and pid != 0:
            # Verificar se o tile também é válido
            if test_offset + 8 <= len(data):
                tile = struct.unpack('>I', data[test_offset+4:test_offset+8])[0]
                
                if 0 <= tile < 10000:
                    valid_pids.append((test_offset, pid, obj_type, tile))
    
    print(f"\nEncontrados {len(valid_pids)} possíveis PIDs válidos nos primeiros 1000 bytes")
    
    # Calcular distâncias entre PIDs
    if len(valid_pids) > 1:
        print("\nDistâncias entre PIDs consecutivos:")
        for i in range(min(20, len(valid_pids) - 1)):
            off1, pid1, type1, tile1 = valid_pids[i]
            off2, pid2, type2, tile2 = valid_pids[i+1]
            dist = off2 - off1
            
            type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
            print(f"  {off1:5d} -> {off2:5d}: {dist:3d} bytes ({type_names[type1]})")
    
    # Analisar estrutura do primeiro objeto
    print("\n=== PRIMEIRO OBJETO (hex dump) ===")
    first_offset = offset
    
    for i in range(30):  # 30 linhas de 4 bytes = 120 bytes
        if first_offset + i*4 + 4 > len(data):
            break
        
        val = struct.unpack('>I', data[first_offset + i*4:first_offset + i*4 + 4])[0]
        val_signed = struct.unpack('>i', data[first_offset + i*4:first_offset + i*4 + 4])[0]
        
        # Tentar interpretar
        comment = ""
        if i == 0:
            obj_type = (val >> 24) & 0xFF
            type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
            if obj_type < len(type_names):
                comment = f"PID ({type_names[obj_type]})"
        elif i == 1:
            if 0 <= val < 10000:
                x = val % 100
                y = val // 100
                comment = f"tile ({x},{y})"
        elif i == 8:
            comment = "FRM ID?"
        elif i == 9:
            comment = "flags?"
        elif i == 10:
            comment = "elevation?"
        
        print(f"  +{i*4:3d}: {val:10d} (0x{val:08X}) {val_signed:10d}  {comment}")
    
    dat.close()


if __name__ == "__main__":
    main()
