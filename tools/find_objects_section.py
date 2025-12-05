#!/usr/bin/env python3
"""Encontra a seção de objetos no arquivo MAP."""

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


def analyze_after_scripts(data, start_offset):
    """Analisa bytes após a seção de scripts."""
    
    print(f"\nAnalisando a partir do offset {start_offset}")
    print(f"Bytes restantes: {len(data) - start_offset}")
    
    # Mostrar primeiros 400 bytes
    print("\nPrimeiros 400 bytes:")
    for i in range(0, min(400, len(data) - start_offset), 4):
        off = start_offset + i
        val = struct.unpack('>I', data[off:off+4])[0]
        val_s = struct.unpack('>i', data[off:off+4])[0]
        
        # Marcar valores interessantes
        marker = ""
        if 1 <= val <= 1000:
            marker = " <-- possível count"
        elif val == 0xFFFFFFFF:
            marker = " <-- -1"
        elif (val >> 24) <= 5 and (val & 0xFFFF) > 0 and (val & 0xFFFF) < 5000:
            marker = f" <-- possível PID (tipo={(val >> 24)}, id={val & 0xFFFF})"
        
        print(f"  +{i:4d} (abs {off:5d}): {data[off:off+4].hex()}  uint={val:10d}  int={val_s:10d}{marker}")
    
    # Procurar padrão de objetos
    # No Fallout 2, objetos têm estrutura específica
    # Vamos procurar por sequências que parecem objetos válidos
    
    print("\n" + "=" * 60)
    print("Procurando padrões de objetos...")
    
    # Um objeto válido tem:
    # - Offset 0: ID interno (qualquer valor)
    # - Offset 4: tile position (0-9999 ou -1)
    # - Offset 32: FRM ID (tipo << 24 | id)
    # - Offset 44: PID (tipo << 24 | id)
    
    candidates = []
    
    for i in range(start_offset, len(data) - 84, 4):
        # Verificar se parece um objeto
        tile = struct.unpack('>i', data[i+4:i+8])[0]
        frm_id = struct.unpack('>I', data[i+32:i+36])[0]
        pid = struct.unpack('>I', data[i+44:i+48])[0]
        
        # Tile válido?
        if not (-1 <= tile < 10000):
            continue
        
        # FRM ID válido? (tipo 0-5)
        frm_type = (frm_id >> 24) & 0xFF
        if frm_type > 5:
            continue
        
        # PID válido? (tipo 0-5)
        pid_type = (pid >> 24) & 0xFF
        if pid_type > 5:
            continue
        
        # Parece válido!
        candidates.append((i, tile, frm_id, pid))
    
    print(f"Encontrados {len(candidates)} candidatos a objetos")
    
    if candidates:
        print("\nPrimeiros 20 candidatos:")
        for i, (off, tile, frm_id, pid) in enumerate(candidates[:20]):
            frm_type = (frm_id >> 24) & 0xFF
            pid_type = (pid >> 24) & 0xFF
            type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
            
            x = tile % 100 if tile >= 0 else -1
            y = tile // 100 if tile >= 0 else -1
            
            print(f"  Offset {off}: tile={tile} ({x},{y}), FRM={frm_id:08X} ({type_names[frm_type]}), PID={pid:08X} ({type_names[pid_type]})")
        
        # Verificar se há um padrão de espaçamento
        if len(candidates) >= 2:
            spacings = []
            for i in range(1, min(20, len(candidates))):
                spacing = candidates[i][0] - candidates[i-1][0]
                spacings.append(spacing)
            
            print(f"\nEspaçamentos entre candidatos: {spacings[:10]}")
            
            # Se o espaçamento é consistente, provavelmente encontramos objetos
            if len(set(spacings[:5])) <= 2:
                print("Espaçamento consistente - provavelmente são objetos!")
                
                # Calcular onde começa a seção de objetos
                first_obj = candidates[0][0]
                
                # Procurar o contador antes do primeiro objeto
                for check_off in range(first_obj - 20, first_obj, 4):
                    if check_off < start_offset:
                        continue
                    val = struct.unpack('>I', data[check_off:check_off+4])[0]
                    if 1 <= val <= 1000:
                        print(f"\nPossível contador em offset {check_off}: {val}")
                        print(f"Primeiro objeto em offset {first_obj}")
                        print(f"Diferença: {first_obj - check_off} bytes")


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    # Artemple
    print("=" * 60)
    print("ARTEMPLE.MAP")
    print("=" * 60)
    
    data = dat.get("maps/artemple.map")
    if data:
        # Offset após scripts (calculado anteriormente)
        # Header: 60 bytes
        # Reserved: 176 bytes
        # Vars: 0 bytes
        # Tiles: 40000 bytes
        # Scripts: 52 bytes (5 counts + 2 scripts de 16 bytes + checksum)
        
        # Vamos calcular manualmente
        offset = 0
        offset += 60  # Header
        offset += 176  # Reserved
        offset += 0  # Global vars
        offset += 0  # Local vars
        offset += 40000  # Tiles (só elevação 0)
        
        print(f"Offset antes dos scripts: {offset}")
        
        # Scripts
        for i in range(5):
            count = struct.unpack('>I', data[offset:offset+4])[0]
            print(f"Script tipo {i}: count={count}")
            offset += 4
            
            if count > 0 and count < 1000:
                # Cada script tem 16 bytes
                # A cada 16 scripts, +4 bytes de checksum
                num_checksums = count // 16
                offset += count * 16 + num_checksums * 4
        
        print(f"Offset após scripts: {offset}")
        
        analyze_after_scripts(data, offset)
    
    dat.close()


if __name__ == "__main__":
    main()
