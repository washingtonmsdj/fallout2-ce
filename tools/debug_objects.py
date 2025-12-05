#!/usr/bin/env python3
"""Debug da seção de objetos do mapa."""

import struct
import zlib
from pathlib import Path

# Tipos de objeto
OBJ_TYPE_ITEM = 0
OBJ_TYPE_CRITTER = 1
OBJ_TYPE_SCENERY = 2
OBJ_TYPE_WALL = 3
OBJ_TYPE_TILE = 4
OBJ_TYPE_MISC = 5

TYPE_NAMES = {
    OBJ_TYPE_ITEM: "item",
    OBJ_TYPE_CRITTER: "critter",
    OBJ_TYPE_SCENERY: "scenery",
    OBJ_TYPE_WALL: "wall",
    OBJ_TYPE_TILE: "tile",
    OBJ_TYPE_MISC: "misc"
}

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
        
        # Ir para seção de objetos (após scripts)
        offset = 42440  # Calculado anteriormente
        
        print(f"\n=== SEÇÃO DE OBJETOS (offset {offset}) ===", flush=True)
        
        # Total de objetos
        total_objects = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        print(f"Total de objetos: {total_objects}", flush=True)
        
        if total_objects > 10000:
            print("ERRO: total muito alto, verificando bytes anteriores...", flush=True)
            # Voltar e verificar
            offset = 42440 - 20
            print(f"\nBytes ao redor de 42440:", flush=True)
            for i in range(15):
                val = struct.unpack('>I', data[offset:offset+4])[0]
                val_signed = struct.unpack('>i', data[offset:offset+4])[0]
                marker = " <-- 42440" if offset == 42440 else ""
                print(f"[{offset:5d}] {val:10d} ({val:08X}) signed: {val_signed}{marker}", flush=True)
                offset += 4
            return
        
        objects_read = 0
        
        for elevation in range(3):
            if offset + 4 > len(data):
                print(f"ERRO: fim dos dados!", flush=True)
                break
            
            obj_count = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            print(f"\nElevação {elevation}: {obj_count} objetos", flush=True)
            
            if obj_count > 10000:
                print(f"  ERRO: count muito alto!", flush=True)
                break
            
            for i in range(obj_count):
                if offset + 72 > len(data):
                    print(f"  ERRO: fim dos dados no objeto {i}!", flush=True)
                    break
                
                # Ler objeto base (72 bytes)
                obj_id = struct.unpack('>I', data[offset+0:offset+4])[0]
                tile = struct.unpack('>i', data[offset+4:offset+8])[0]
                x_off = struct.unpack('>i', data[offset+8:offset+12])[0]
                y_off = struct.unpack('>i', data[offset+12:offset+16])[0]
                sx = struct.unpack('>i', data[offset+16:offset+20])[0]
                sy = struct.unpack('>i', data[offset+20:offset+24])[0]
                frame = struct.unpack('>I', data[offset+24:offset+28])[0]
                rotation = struct.unpack('>I', data[offset+28:offset+32])[0]
                fid = struct.unpack('>I', data[offset+32:offset+36])[0]
                flags = struct.unpack('>I', data[offset+36:offset+40])[0]
                elev = struct.unpack('>I', data[offset+40:offset+44])[0]
                pid = struct.unpack('>I', data[offset+44:offset+48])[0]
                cid = struct.unpack('>I', data[offset+48:offset+52])[0]
                light_dist = struct.unpack('>I', data[offset+52:offset+56])[0]
                light_int = struct.unpack('>I', data[offset+56:offset+60])[0]
                field_74 = struct.unpack('>I', data[offset+60:offset+64])[0]
                sid = struct.unpack('>i', data[offset+64:offset+68])[0]
                script_idx = struct.unpack('>I', data[offset+68:offset+72])[0]
                
                obj_type_id = (pid >> 24) & 0xFF
                obj_type = TYPE_NAMES.get(obj_type_id, f"unknown({obj_type_id})")
                
                offset += 72
                
                if i < 5:
                    print(f"  Objeto {i}: tile={tile}, pid={pid:08X} ({obj_type}), fid={fid:08X}, flags={flags:08X}", flush=True)
                elif i == 5:
                    print(f"  ... (objetos 5-{obj_count-1} omitidos)", flush=True)
                
                # Ler dados adicionais (inventário + tipo específico)
                # Inventário (12 bytes)
                if offset + 12 > len(data):
                    print(f"  ERRO: fim dos dados no inventário!", flush=True)
                    break
                
                inv_length = struct.unpack('>I', data[offset:offset+4])[0]
                inv_capacity = struct.unpack('>I', data[offset+4:offset+8])[0]
                inv_ptr = struct.unpack('>I', data[offset+8:offset+12])[0]
                offset += 12
                
                if i < 5 and inv_length > 0:
                    print(f"    Inventário: {inv_length} itens", flush=True)
                
                # Pular itens do inventário (recursivo - simplificado)
                # Por enquanto, vou assumir que não há inventário aninhado
                
                # Dados específicos do tipo
                if obj_type_id == OBJ_TYPE_CRITTER:
                    # Critter: 52 bytes
                    offset += 52
                elif obj_type_id == OBJ_TYPE_ITEM:
                    # Item: 4 bytes + extras dependendo do subtipo
                    offset += 4
                    item_subtype = (pid >> 16) & 0xFF
                    if item_subtype in [3]:  # Weapon
                        offset += 8
                    elif item_subtype in [4, 5, 6]:  # Ammo, Misc, Key
                        offset += 4
                elif obj_type_id == OBJ_TYPE_SCENERY:
                    # Scenery: 4 bytes + extras
                    offset += 4
                    scenery_subtype = (pid >> 16) & 0xFF
                    if scenery_subtype in [0]:  # Door
                        offset += 4
                    elif scenery_subtype in [1, 2, 3, 4]:  # Stairs, Elevator, Ladder
                        offset += 8
                elif obj_type_id == OBJ_TYPE_WALL:
                    # Wall: 4 bytes
                    offset += 4
                elif obj_type_id == OBJ_TYPE_MISC:
                    # Misc: 4 bytes + extras para exit grid
                    offset += 4
                    misc_subtype = (pid >> 16) & 0xFF
                    if misc_subtype == 0:  # Exit grid
                        offset += 16
                
                objects_read += 1
        
        print(f"\n=== RESULTADO ===", flush=True)
        print(f"Objetos lidos: {objects_read}", flush=True)
        print(f"Offset final: {offset}", flush=True)
        print(f"Bytes restantes: {len(data) - offset}", flush=True)


if __name__ == "__main__":
    main()
