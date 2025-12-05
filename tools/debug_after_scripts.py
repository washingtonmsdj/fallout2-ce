#!/usr/bin/env python3
"""Debug detalhado após seção de scripts."""

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
    
    # Offset após scripts
    offset = 40288
    
    print(f"Analisando offset {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    print()
    
    # Mostrar os primeiros 500 bytes em formato estruturado
    print("Primeiros 500 bytes após scripts:")
    print("-" * 80)
    
    for i in range(0, min(500, len(data) - offset), 4):
        val = struct.unpack('>I', data[offset+i:offset+i+4])[0]
        val_s = struct.unpack('>i', data[offset+i:offset+i+4])[0]
        
        # Tentar identificar o que pode ser
        notes = []
        
        if val == 0:
            notes.append("zero")
        elif val == 0xFFFFFFFF:
            notes.append("-1")
        elif 1 <= val <= 1000:
            notes.append(f"possível count ({val})")
        elif 0 <= val < 10000:
            notes.append(f"possível tile ({val % 100}, {val // 100})")
        
        # Verificar se parece PID
        pid_type = (val >> 24) & 0xFF
        if pid_type <= 5 and (val & 0xFFFFFF) > 0:
            type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
            notes.append(f"PID? ({type_names[pid_type]}:{val & 0xFFFF})")
        
        # Verificar se parece FID
        fid_type = (val >> 24) & 0x0F
        if fid_type <= 6 and (val & 0xFFF) > 0:
            fid_types = ["item", "critter", "scenery", "wall", "tile", "misc", "interface"]
            if fid_type < len(fid_types):
                notes.append(f"FID? ({fid_types[fid_type]}:{val & 0xFFF})")
        
        note_str = " | ".join(notes) if notes else ""
        print(f"+{i:4d}: {data[offset+i:offset+i+4].hex()}  {val:10d}  {val_s:10d}  {note_str}")
    
    # Procurar o valor 511 que vimos antes
    print("\n" + "=" * 80)
    print("Procurando valor 511:")
    for i in range(offset, len(data) - 4, 4):
        val = struct.unpack('>I', data[i:i+4])[0]
        if val == 511:
            print(f"  Encontrado em offset {i} (relativo: {i - offset})")
            # Mostrar contexto
            start = max(0, i - 20)
            print(f"  Contexto ({start} a {i+20}):")
            for j in range(start, min(i + 20, len(data)), 4):
                v = struct.unpack('>I', data[j:j+4])[0]
                marker = " <-- 511" if j == i else ""
                print(f"    {j}: {v:10d}{marker}")
            break
    
    dat.close()


if __name__ == "__main__":
    main()
