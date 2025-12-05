#!/usr/bin/env python3
"""Debug da estrutura de scripts no mapa."""

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
    
    # Pular header e tiles
    offset = 236  # Após header
    offset += 40000  # Tiles elevação 0
    
    print(f"\nOffset após tiles: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Seção de scripts
    print("\n=== ANALISANDO SCRIPTS ===")
    
    # Sabemos que há 2 scripts CRITTER (tipo 3)
    # Vamos procurar o padrão
    
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"\nTipo {script_type}: count = {count}")
        offset += 4
        
        if count == 2 and script_type == 3:
            # Encontramos os 2 scripts CRITTER
            print("  Analisando estrutura dos scripts CRITTER:")
            
            for i in range(count):
                print(f"\n  Script {i}:")
                
                # Ler campos
                for j in range(20):
                    if offset + 4 > len(data):
                        break
                    val = struct.unpack('>I', data[offset:offset+4])[0]
                    val_signed = struct.unpack('>i', data[offset:offset+4])[0]
                    print(f"    +{j*4:2d}: {val:10d} (0x{val:08X}) signed={val_signed:10d}")
                    
                    if j == 0:
                        # Primeiro campo - pode ser PID ou next_script
                        pass
                
                # Pular 16 bytes (tamanho típico de script)
                offset += 16
                
                # Ver se há padding
                if offset + 4 <= len(data):
                    next_val = struct.unpack('>I', data[offset:offset+4])[0]
                    print(f"    Próximo valor: {next_val:10d} (0x{next_val:08X})")
        
        elif count > 0 and count < 100:
            # Pular scripts
            offset += count * 16
    
    print(f"\nOffset após scripts: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Procurar início dos objetos
    print("\n=== PROCURANDO OBJETOS ===")
    
    # Objetos começam com um contador
    # Vamos procurar valores razoáveis
    for test_offset in range(offset - 50, min(offset + 100, len(data) - 4)):
        if test_offset < 0:
            continue
        
        val = struct.unpack('>I', data[test_offset:test_offset+4])[0]
        
        if 100 <= val <= 1000:
            print(f"Offset {test_offset}: {val} (possível contador de objetos)")
            
            # Ver próximos valores
            for i in range(1, 5):
                if test_offset + i*4 + 4 <= len(data):
                    next_val = struct.unpack('>I', data[test_offset + i*4:test_offset + i*4 + 4])[0]
                    print(f"  +{i*4}: {next_val:10d} (0x{next_val:08X})")
    
    dat.close()


if __name__ == "__main__":
    main()
