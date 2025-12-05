#!/usr/bin/env python3
"""Debug da seção de scripts do mapa - versão 2."""

import struct
import zlib
from pathlib import Path

# Tipos de script
SCRIPT_TYPE_SYSTEM = 0
SCRIPT_TYPE_SPATIAL = 1
SCRIPT_TYPE_TIMED = 2
SCRIPT_TYPE_ITEM = 3
SCRIPT_TYPE_CRITTER = 4

SCRIPT_LIST_EXTENT_SIZE = 16

def main():
    print("Iniciando...", flush=True)
    
    dat_path = Path("Fallout 2/master.dat")
    
    with open(dat_path, 'rb') as f:
        f.seek(-8, 2)
        tree_size = struct.unpack('<I', f.read(4))[0]
        data_size = struct.unpack('<I', f.read(4))[0]
        
        f.seek(data_size - tree_size - 8)
        count = struct.unpack('<I', f.read(4))[0]
        
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
        
        # Ler mapa
        map_key = 'maps/artemple.map'
        comp, rsize, psize, off = files[map_key]
        
        f.seek(off)
        data = f.read(psize)
        
        if comp:
            data = zlib.decompress(data)
        
        print(f"Mapa: {len(data)} bytes", flush=True)
        
        # Ir para seção de scripts
        offset = 40236  # Após tiles
        
        print(f"\n=== SEÇÃO DE SCRIPTS (offset {offset}) ===", flush=True)
        
        script_type_names = ['SYSTEM', 'SPATIAL', 'TIMED', 'ITEM', 'CRITTER']
        
        for script_type in range(5):
            if offset + 4 > len(data):
                print(f"ERRO: fim dos dados!", flush=True)
                break
            
            scripts_count = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            print(f"\nTipo {script_type} ({script_type_names[script_type]}): {scripts_count} scripts", flush=True)
            
            if scripts_count == 0:
                continue
            
            if scripts_count > 10000:
                print(f"  ERRO: count muito alto!", flush=True)
                break
            
            # Calcular número de extents
            num_extents = (scripts_count + SCRIPT_LIST_EXTENT_SIZE - 1) // SCRIPT_LIST_EXTENT_SIZE
            print(f"  Extents necessários: {num_extents}", flush=True)
            
            for ext_idx in range(num_extents):
                print(f"\n  Extent {ext_idx}:", flush=True)
                
                # Ler 16 scripts
                for i in range(SCRIPT_LIST_EXTENT_SIZE):
                    if offset + 8 > len(data):
                        print(f"    ERRO: fim dos dados no script {i}!", flush=True)
                        break
                    
                    # sid (4 bytes)
                    sid = struct.unpack('>i', data[offset:offset+4])[0]
                    sid_type = (sid >> 24) & 0xFF
                    
                    # field_4 (4 bytes)
                    field_4 = struct.unpack('>i', data[offset+4:offset+8])[0]
                    
                    script_offset_start = offset
                    offset += 8
                    
                    # Dados específicos do tipo (baseado no SID)
                    extra_data = ""
                    if sid_type == SCRIPT_TYPE_SPATIAL:
                        built_tile = struct.unpack('>i', data[offset:offset+4])[0]
                        radius = struct.unpack('>i', data[offset+4:offset+8])[0]
                        extra_data = f", built_tile={built_tile}, radius={radius}"
                        offset += 8
                    elif sid_type == SCRIPT_TYPE_TIMED:
                        time = struct.unpack('>i', data[offset:offset+4])[0]
                        extra_data = f", time={time}"
                        offset += 4
                    
                    # Campos comuns (14 * 4 = 56 bytes)
                    flags = struct.unpack('>i', data[offset:offset+4])[0]
                    index = struct.unpack('>i', data[offset+4:offset+8])[0]
                    offset += 56
                    
                    script_size = offset - script_offset_start
                    
                    if i < 5 or (ext_idx == num_extents - 1 and i >= SCRIPT_LIST_EXTENT_SIZE - 3):
                        print(f"    Script {i}: sid={sid:08X} (type={sid_type}), field_4={field_4}, flags={flags:08X}, index={index}, size={script_size}{extra_data}", flush=True)
                    elif i == 5:
                        print(f"    ... (scripts 5-{SCRIPT_LIST_EXTENT_SIZE-4} omitidos)", flush=True)
                
                # length (4 bytes)
                if offset + 4 > len(data):
                    print(f"    ERRO: fim dos dados no length!", flush=True)
                    break
                
                ext_length = struct.unpack('>I', data[offset:offset+4])[0]
                offset += 4
                
                # next (4 bytes)
                if offset + 4 > len(data):
                    print(f"    ERRO: fim dos dados no next!", flush=True)
                    break
                
                ext_next = struct.unpack('>I', data[offset:offset+4])[0]
                offset += 4
                
                print(f"    [Extent footer] length={ext_length}, next={ext_next}", flush=True)
        
        print(f"\n=== APÓS SCRIPTS ===", flush=True)
        print(f"Offset: {offset}", flush=True)
        print(f"Bytes restantes: {len(data) - offset}", flush=True)
        
        # Próximos bytes
        print(f"\nPróximos 60 bytes:", flush=True)
        for i in range(15):
            if offset + 4 <= len(data):
                val = struct.unpack('>I', data[offset:offset+4])[0]
                val_signed = struct.unpack('>i', data[offset:offset+4])[0]
                print(f"[{offset:5d}] {val:10d} ({val:08X}) signed: {val_signed}", flush=True)
                offset += 4


if __name__ == "__main__":
    main()
