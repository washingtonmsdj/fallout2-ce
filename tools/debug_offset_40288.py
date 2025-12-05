#!/usr/bin/env python3
"""Debug específico do offset 40288."""

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
    
    # Vamos analisar a seção de scripts mais detalhadamente
    offset = 40236  # Após tiles
    
    print("=== SEÇÃO DE SCRIPTS ===")
    print(f"Offset inicial: {offset}")
    
    for script_type in range(5):
        count = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"\nTipo {script_type}: count = {count}")
        print(f"  Offset do count: {offset}")
        print(f"  Bytes: {data[offset:offset+4].hex()}")
        offset += 4
        
        if count > 0 and count < 1000:
            print(f"  Lendo {count} scripts...")
            for i in range(count):
                script_offset = offset
                
                # Ler 16 bytes do script
                script_data = data[offset:offset+16]
                print(f"    Script {i}: {script_data.hex()}")
                
                # Interpretar
                pid = struct.unpack('>I', script_data[0:4])[0]
                tile = struct.unpack('>i', script_data[4:8])[0]
                val1 = struct.unpack('>I', script_data[8:12])[0]
                val2 = struct.unpack('>I', script_data[12:16])[0]
                
                print(f"      PID={pid:08X}, tile={tile}, val1={val1}, val2={val2}")
                
                offset += 16
                
                # Checksum a cada 16 scripts
                if (i + 1) % 16 == 0:
                    checksum = struct.unpack('>I', data[offset:offset+4])[0]
                    print(f"    Checksum: {checksum:08X}")
                    offset += 4
    
    print(f"\n=== APÓS SCRIPTS ===")
    print(f"Offset: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Mostrar próximos 100 bytes
    print("\nPróximos 100 bytes:")
    for i in range(0, min(100, len(data) - offset), 4):
        val = struct.unpack('>I', data[offset+i:offset+i+4])[0]
        print(f"  +{i:3d}: {data[offset+i:offset+i+4].hex()} = {val}")
    
    # O valor 511 está em algum lugar?
    print("\n=== PROCURANDO 511 ===")
    for i in range(offset, min(offset + 200, len(data) - 4), 4):
        val = struct.unpack('>I', data[i:i+4])[0]
        if val == 511:
            print(f"Encontrado 511 em offset {i}")
            # Mostrar contexto
            print(f"  Contexto: {data[i-8:i+12].hex()}")
    
    dat.close()


if __name__ == "__main__":
    main()
