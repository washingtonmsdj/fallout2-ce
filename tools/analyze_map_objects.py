#!/usr/bin/env python3
"""Analisa a estrutura de objetos do arquivo MAP do Fallout 2."""

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


def read_script_section(data, offset):
    """Lê uma seção de scripts corretamente."""
    # Cada seção de script tem:
    # - 4 bytes: count
    # - Para cada script:
    #   - 4 bytes: PID
    #   - 4 bytes: next_script (ou -1)
    #   - Mais dados dependendo do tipo
    
    if offset + 4 > len(data):
        return offset, 0
    
    count = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Cada script tem pelo menos 16 bytes de dados
    # Mas o tamanho real varia - vamos tentar encontrar o padrão
    
    return offset, count


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    data = dat.get("maps/artemple.map")
    if not data:
        print("Mapa não encontrado!")
        return
    
    print(f"Tamanho do arquivo: {len(data)} bytes")
    print("=" * 60)
    
    offset = 0
    
    # Header
    version = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Nome (16 bytes)
    offset += 16
    
    # Entering (12 bytes)
    offset += 12
    
    # Local vars (4 bytes)
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Script index (4 bytes)
    offset += 4
    
    # Flags (4 bytes)
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Darkness, global_vars, map_id, timestamp (16 bytes)
    global_vars = struct.unpack('>I', data[offset+4:offset+8])[0]
    offset += 16
    
    # Reserved (176 bytes)
    offset += 176
    
    # Global vars data
    offset += global_vars * 4
    
    # Local vars data
    offset += local_vars * 4
    
    print(f"Offset antes dos tiles: {offset}")
    
    # Tiles - só elevação 0 está presente (flags = 12 = 0b1100)
    elev_flags = [2, 4, 8]
    for i in range(3):
        if (flags & elev_flags[i]) == 0:
            offset += 100 * 100 * 4  # 40000 bytes por elevação
    
    print(f"Offset após tiles: {offset}")
    
    # Agora vem a seção de scripts
    # Formato: 5 tipos de scripts, cada um com count + dados
    print("\n=== SEÇÃO DE SCRIPTS ===")
    
    script_types = ["Spatial", "Timed", "Item", "Critter", "Scenery"]
    
    for script_type in range(5):
        if offset + 4 > len(data):
            print(f"Fim dos dados em offset {offset}")
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        print(f"\nTipo {script_type} ({script_types[script_type]}): {count} scripts")
        offset += 4
        
        if count > 0 and count < 1000:
            # Cada script tem estrutura variável
            # Vamos ler os primeiros bytes para entender
            for i in range(min(count, 3)):
                if offset + 24 > len(data):
                    break
                
                # Estrutura básica de script:
                # 4 bytes: PID
                # 4 bytes: tile
                # 4 bytes: elevation + orientation
                # 4 bytes: script_id
                # 4 bytes: flags
                # 4 bytes: next_script
                
                pid = struct.unpack('>I', data[offset:offset+4])[0]
                tile = struct.unpack('>I', data[offset+4:offset+8])[0]
                elev_ori = struct.unpack('>I', data[offset+8:offset+12])[0]
                script_id = struct.unpack('>i', data[offset+12:offset+16])[0]
                
                print(f"  Script {i}: PID={pid:08X}, tile={tile}, script_id={script_id}")
            
            # Pular todos os scripts (cada um tem ~24 bytes mínimo)
            # Mas o tamanho real pode variar
            offset += count * 24
    
    print(f"\nOffset após scripts: {offset}")
    print(f"Bytes restantes: {len(data) - offset}")
    
    # Agora vem a seção de objetos
    print("\n=== SEÇÃO DE OBJETOS ===")
    
    # Procurar pelo padrão de objetos
    # Objetos começam com um contador de 4 bytes
    
    # Vamos procurar em diferentes offsets
    for test_offset in range(offset - 100, min(offset + 200, len(data) - 4)):
        if test_offset < 0:
            continue
        
        count = struct.unpack('>I', data[test_offset:test_offset+4])[0]
        
        # Um contador válido de objetos seria entre 1 e 1000
        if 1 <= count <= 1000:
            # Verificar se os próximos bytes parecem objetos válidos
            if test_offset + 8 <= len(data):
                next_val = struct.unpack('>I', data[test_offset+4:test_offset+8])[0]
                # PID de objeto tem formato específico (tipo no byte alto)
                obj_type = (next_val >> 24) & 0xF
                if obj_type <= 5:  # Tipos válidos: 0-5
                    print(f"Possível início de objetos em offset {test_offset}: count={count}")
                    print(f"  Primeiro PID: {next_val:08X} (tipo={obj_type})")
                    
                    # Tentar ler alguns objetos
                    obj_offset = test_offset + 4
                    for i in range(min(count, 5)):
                        if obj_offset + 80 > len(data):
                            break
                        
                        pid = struct.unpack('>I', data[obj_offset:obj_offset+4])[0]
                        tile = struct.unpack('>I', data[obj_offset+4:obj_offset+8])[0]
                        
                        obj_type = (pid >> 24) & 0xF
                        obj_id = pid & 0xFFFF
                        
                        x = tile % 100
                        y = tile // 100
                        
                        type_names = ["item", "critter", "scenery", "wall", "tile", "misc"]
                        type_name = type_names[obj_type] if obj_type < len(type_names) else "unknown"
                        
                        print(f"  Obj {i}: PID={pid:08X} ({type_name}:{obj_id}), tile={tile} ({x},{y})")
                        
                        obj_offset += 80
                    
                    break
    
    dat.close()


if __name__ == "__main__":
    main()
