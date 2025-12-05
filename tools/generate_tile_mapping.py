#!/usr/bin/env python3
"""
Gera mapeamento de floor_id para nomes de tiles do Fallout 2.
Extrai a lista de tiles do master.dat e cria um JSON de mapeamento.
"""

import struct
import zlib
import json
from pathlib import Path


class DAT2Reader:
    """Leitor simples de arquivos DAT2."""
    
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
    print("GERADOR DE MAPEAMENTO DE TILES")
    print("=" * 60)
    
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    output_path = project_root / "godot_project" / "assets" / "data" / "tile_mapping.json"
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if not dat_path.exists():
        print(f"DAT não encontrado: {dat_path}")
        # Criar mapeamento baseado nos tiles existentes
        tiles_dir = project_root / "godot_project" / "assets" / "sprites" / "tiles"
        if tiles_dir.exists():
            tiles = sorted([f.stem for f in tiles_dir.glob("*.png")])
            mapping = {str(i): tile for i, tile in enumerate(tiles)}
            with open(output_path, 'w') as f:
                json.dump(mapping, f, indent=2)
            print(f"Mapeamento criado com {len(mapping)} tiles existentes")
        return
    
    print(f"Lendo: {dat_path}")
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    # Encontrar todos os tiles
    tile_files = sorted([f for f in dat.files.keys() if 'art/tiles' in f and f.endswith('.frm')])
    
    print(f"Encontrados {len(tile_files)} tiles no DAT")
    
    # Criar mapeamento: índice -> nome do tile (sem extensão)
    mapping = {}
    for i, tile_path in enumerate(tile_files):
        tile_name = Path(tile_path).stem.lower()
        mapping[str(i)] = tile_name
    
    # Salvar mapeamento
    with open(output_path, 'w') as f:
        json.dump(mapping, f, indent=2)
    
    print(f"Mapeamento salvo em: {output_path}")
    print(f"Total de tiles mapeados: {len(mapping)}")
    
    # Mostrar primeiros 20
    print("\nPrimeiros 20 tiles:")
    for i in range(min(20, len(mapping))):
        print(f"  {i}: {mapping[str(i)]}")
    
    dat.close()


if __name__ == "__main__":
    main()
