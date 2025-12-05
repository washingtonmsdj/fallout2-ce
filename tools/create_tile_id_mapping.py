#!/usr/bin/env python3
"""
Cria mapeamento correto de tile IDs para nomes de arquivos.
No Fallout 2, os tiles são listados em art/tiles/tiles.lst
O índice na lista corresponde ao ID do tile.
"""

import struct
import zlib
import json
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
    print("=" * 60)
    print("CRIANDO MAPEAMENTO DE TILE IDs")
    print("=" * 60)
    
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    output_path = project_root / "godot_project" / "assets" / "data" / "tile_mapping.json"
    
    if not dat_path.exists():
        print(f"DAT não encontrado: {dat_path}")
        return
    
    print(f"Lendo: {dat_path}")
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    # Tentar ler tiles.lst
    lst_data = dat.get('art/tiles/tiles.lst')
    
    mapping = {}
    
    if lst_data:
        print("Encontrado tiles.lst!")
        lines = lst_data.decode('latin-1').split('\n')
        for i, line in enumerate(lines):
            line = line.strip()
            if line and not line.startswith(';'):
                # Remover extensão .frm
                tile_name = line.replace('.frm', '').replace('.FRM', '').lower()
                mapping[str(i)] = tile_name
        print(f"Tiles no LST: {len(mapping)}")
    else:
        print("tiles.lst não encontrado, usando lista de arquivos...")
        # Fallback: usar lista de arquivos ordenada
        tile_files = sorted([f for f in dat.files.keys() if 'art/tiles' in f and f.endswith('.frm')])
        for i, tile_path in enumerate(tile_files):
            tile_name = Path(tile_path).stem.lower()
            mapping[str(i)] = tile_name
        print(f"Tiles encontrados: {len(mapping)}")
    
    # Salvar mapeamento
    with open(output_path, 'w') as f:
        json.dump(mapping, f, indent=2)
    
    print(f"\nMapeamento salvo em: {output_path}")
    print(f"Total de tiles: {len(mapping)}")
    
    # Mostrar alguns exemplos
    print("\nExemplos:")
    for i in [0, 1, 100, 500, 1000, 2000, 3000]:
        if str(i) in mapping:
            print(f"  {i}: {mapping[str(i)]}")
    
    dat.close()


if __name__ == "__main__":
    main()
