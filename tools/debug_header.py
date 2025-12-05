#!/usr/bin/env python3
"""Debug do header do mapa."""

import struct
import zlib
from pathlib import Path

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
        
        # Header detalhado
        print("\n=== HEADER DETALHADO ===", flush=True)
        
        offset = 0
        
        # version (4 bytes)
        version = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] version: {version}", flush=True)
        offset += 4
        
        # name (16 bytes)
        name = data[offset:offset+16]
        name_str = name.split(b'\x00')[0].decode('latin-1', errors='ignore')
        print(f"[{offset:4d}] name: {name_str} (raw: {name.hex()})", flush=True)
        offset += 16
        
        # entering_tile (4 bytes)
        entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] entering_tile: {entering_tile}", flush=True)
        offset += 4
        
        # entering_elevation (4 bytes)
        entering_elev = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] entering_elevation: {entering_elev}", flush=True)
        offset += 4
        
        # entering_rotation (4 bytes)
        entering_rot = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] entering_rotation: {entering_rot}", flush=True)
        offset += 4
        
        # local_vars_count (4 bytes)
        local_vars = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] local_vars_count: {local_vars}", flush=True)
        offset += 4
        
        # script_index (4 bytes)
        script_idx = struct.unpack('>i', data[offset:offset+4])[0]
        print(f"[{offset:4d}] script_index: {script_idx}", flush=True)
        offset += 4
        
        # flags (4 bytes)
        flags = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] flags: {flags:08X} (decimal: {flags})", flush=True)
        print(f"        Elevação 0 presente: {(flags & 2) == 0}", flush=True)
        print(f"        Elevação 1 presente: {(flags & 4) == 0}", flush=True)
        print(f"        Elevação 2 presente: {(flags & 8) == 0}", flush=True)
        offset += 4
        
        # darkness (4 bytes)
        darkness = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] darkness: {darkness}", flush=True)
        offset += 4
        
        # global_vars_count (4 bytes)
        global_vars = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] global_vars_count: {global_vars}", flush=True)
        offset += 4
        
        # map_id (4 bytes)
        map_id = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] map_id: {map_id}", flush=True)
        offset += 4
        
        # timestamp (4 bytes)
        timestamp = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"[{offset:4d}] timestamp: {timestamp}", flush=True)
        offset += 4
        
        # reserved (176 bytes)
        print(f"[{offset:4d}] reserved: 176 bytes", flush=True)
        offset += 176
        
        print(f"\nOffset após header: {offset}", flush=True)
        
        # Vars
        print(f"\nGlobal vars: {global_vars} * 4 = {global_vars * 4} bytes", flush=True)
        print(f"Local vars: {local_vars} * 4 = {local_vars * 4} bytes", flush=True)
        
        offset += global_vars * 4 + local_vars * 4
        print(f"Offset após vars: {offset}", flush=True)
        
        # Tiles
        print("\n=== TILES ===", flush=True)
        elev_flags = [2, 4, 8]
        for elev in range(3):
            present = (flags & elev_flags[elev]) == 0
            print(f"Elevação {elev}: {'presente' if present else 'ausente'}", flush=True)
            if present:
                # Verificar primeiro tile
                first_tile = struct.unpack('>I', data[offset:offset+4])[0]
                print(f"  Primeiro tile: {first_tile:08X}", flush=True)
                offset += 10000 * 4
        
        print(f"\nOffset após tiles: {offset}", flush=True)
        print(f"Bytes restantes: {len(data) - offset}", flush=True)
        
        # Verificar próximos bytes
        print("\n=== PRÓXIMOS 40 BYTES ===", flush=True)
        for i in range(10):
            if offset + 4 <= len(data):
                val = struct.unpack('>I', data[offset:offset+4])[0]
                val_signed = struct.unpack('>i', data[offset:offset+4])[0]
                print(f"[{offset:5d}] {val:10d} ({val:08X}) signed: {val_signed}", flush=True)
                offset += 4


if __name__ == "__main__":
    main()
