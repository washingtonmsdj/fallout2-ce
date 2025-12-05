#!/usr/bin/env python3
"""Debug da seção de scripts do mapa."""

import struct
import zlib
from pathlib import Path

def main():
    print("Iniciando...", flush=True)
    
    dat_path = Path("Fallout 2/master.dat")
    
    # Ler índice do DAT
    print(f"Abrindo {dat_path}...", flush=True)
    
    with open(dat_path, 'rb') as f:
        f.seek(-8, 2)
        tree_size = struct.unpack('<I', f.read(4))[0]
        data_size = struct.unpack('<I', f.read(4))[0]
        
        print(f"Tree: {tree_size}, Data: {data_size}", flush=True)
        
        f.seek(data_size - tree_size - 8)
        count = struct.unpack('<I', f.read(4))[0]
        
        print(f"Arquivos: {count}", flush=True)
        
        # Ler índice
        files = {}
        for i in range(count):
            nlen = struct.unpack('<I', f.read(4))[0]
            name = f.read(nlen).decode('ascii', errors='ignore').rstrip('\x00')
            comp = struct.unpack('<B', f.read(1))[0]
            rsize = struct.unpack('<I', f.read(4))[0]
            psize = struct.unpack('<I', f.read(4))[0]
            off = struct.unpack('<I', f.read(4))[0]
            files[name.lower().replace('\\', '/')] = (comp, rsize, psize, off)
        
        print(f"Índice carregado: {len(files)} arquivos", flush=True)
        
        # Procurar artemple
        map_key = None
        for key in files:
            if 'artemple' in key:
                map_key = key
                print(f"Encontrado: {key}", flush=True)
                break
        
        if not map_key:
            print("ERRO: artemple não encontrado!", flush=True)
            return
        
        # Ler mapa
        comp, rsize, psize, off = files[map_key]
        print(f"Lendo mapa: comp={comp}, rsize={rsize}, psize={psize}, off={off}", flush=True)
        
        f.seek(off)
        data = f.read(psize)
        
        if comp:
            data = zlib.decompress(data)
        
        print(f"Mapa: {len(data)} bytes", flush=True)
        
        # Analisar header
        offset = 0
        version = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore')
        offset += 16
        
        print(f"Version: {version}, Name: {name}", flush=True)
        
        # Pular para vars
        offset = 36
        local_vars = struct.unpack('>I', data[offset:offset+4])[0]
        offset = 44
        flags = struct.unpack('>I', data[offset:offset+4])[0]
        offset = 56
        global_vars = struct.unpack('>I', data[offset:offset+4])[0]
        
        print(f"local_vars={local_vars}, global_vars={global_vars}, flags={flags:08X}", flush=True)
        
        # Calcular offset após header
        offset = 236 + global_vars * 4 + local_vars * 4
        print(f"Offset após header+vars: {offset}", flush=True)
        
        # Tiles
        elev_flags = [2, 4, 8]
        for elev in range(3):
            if (flags & elev_flags[elev]) == 0:
                offset += 10000 * 4
                print(f"Elevação {elev}: presente, offset agora: {offset}", flush=True)
        
        print(f"Offset após tiles: {offset}", flush=True)
        
        # Scripts
        print("\n=== SCRIPTS ===", flush=True)
        
        for script_type in range(5):
            count = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            print(f"Tipo {script_type}: count={count}", flush=True)
            
            if count == 0:
                continue
            
            if count > 10000:
                print(f"  ERRO: count muito alto!", flush=True)
                break
            
            num_extents = (count + 15) // 16
            print(f"  Extents: {num_extents}", flush=True)
            
            for ext_idx in range(num_extents):
                print(f"  Extent {ext_idx}:", flush=True)
                
                for i in range(16):
                    # Ler SID para determinar tipo
                    sid = struct.unpack('>i', data[offset:offset+4])[0]
                    sid_type = (sid >> 24) & 0xFF
                    
                    # Calcular tamanho do script
                    script_size = 8 + 56  # sid + field_4 + campos comuns
                    if sid_type == 1:  # SPATIAL
                        script_size += 8
                    elif sid_type == 2:  # TIMED
                        script_size += 4
                    
                    if i < 3:
                        print(f"    Script {i}: sid={sid:08X}, type={sid_type}, size={script_size}", flush=True)
                    
                    offset += script_size
                
                # length + next
                ext_length = struct.unpack('>I', data[offset:offset+4])[0]
                offset += 4
                ext_next = struct.unpack('>I', data[offset:offset+4])[0]
                offset += 4
                
                print(f"    length={ext_length}, next={ext_next}", flush=True)
        
        print(f"\nOffset após scripts: {offset}", flush=True)
        print(f"Bytes restantes: {len(data) - offset}", flush=True)
        
        # Objetos
        print("\n=== OBJETOS ===", flush=True)
        
        if offset + 4 <= len(data):
            total_obj = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            print(f"Total objetos: {total_obj}", flush=True)
            
            if total_obj > 0 and total_obj < 50000:
                for elev in range(3):
                    if offset + 4 > len(data):
                        break
                    
                    obj_count = struct.unpack('>I', data[offset:offset+4])[0]
                    offset += 4
                    print(f"Elevação {elev}: {obj_count} objetos", flush=True)
        
        print("\nFim!", flush=True)


if __name__ == "__main__":
    main()
