#!/usr/bin/env python3
"""Extrai TODOS os tiles do Fallout 2 para o projeto Godot."""

import struct
import zlib
from pathlib import Path
from PIL import Image


class DAT2Reader:
    """Leitor de arquivos DAT2."""
    
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


def load_palette(dat):
    """Carrega a paleta de cores."""
    data = dat.get('color.pal')
    if not data:
        return [(i, i, i) for i in range(256)]
    
    palette = []
    for i in range(256):
        r = min(255, data[i * 3] * 4)
        g = min(255, data[i * 3 + 1] * 4)
        b = min(255, data[i * 3 + 2] * 4)
        palette.append((r, g, b))
    return palette


def decode_frm(data, palette):
    """Decodifica um arquivo FRM para imagem."""
    if len(data) < 62:
        return None
    
    # Ler offsets dos frames
    offsets = []
    for i in range(6):
        offset = struct.unpack('>I', data[34 + i * 4:38 + i * 4])[0]
        offsets.append(offset)
    
    # Usar primeiro frame
    frame_offset = 62 + offsets[0]
    if frame_offset + 12 > len(data):
        return None
    
    width = struct.unpack('>H', data[frame_offset:frame_offset + 2])[0]
    height = struct.unpack('>H', data[frame_offset + 2:frame_offset + 4])[0]
    size = struct.unpack('>I', data[frame_offset + 4:frame_offset + 8])[0]
    
    if width <= 0 or height <= 0:
        return None
    
    pixel_offset = frame_offset + 12
    if pixel_offset + size > len(data):
        return None
    
    pixels = data[pixel_offset:pixel_offset + size]
    
    # Criar imagem
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    pix = img.load()
    
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if idx < len(pixels):
                p = pixels[idx]
                if p == 0:
                    pix[x, y] = (0, 0, 0, 0)  # Transparente
                else:
                    pix[x, y] = (*palette[p], 255)
    
    return img


def main():
    print("=" * 60)
    print("EXTRATOR DE TILES DO FALLOUT 2")
    print("=" * 60)
    
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    output_dir = project_root / "godot_project" / "assets" / "sprites" / "tiles"
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if not dat_path.exists():
        print(f"DAT não encontrado: {dat_path}")
        return
    
    print(f"Lendo: {dat_path}")
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    palette = load_palette(dat)
    
    # Encontrar todos os tiles
    tile_files = sorted([f for f in dat.files.keys() if 'art/tiles' in f and f.endswith('.frm')])
    
    print(f"Encontrados {len(tile_files)} tiles")
    
    extracted = 0
    errors = 0
    
    for i, tile_path in enumerate(tile_files):
        tile_name = Path(tile_path).stem.lower()
        output_path = output_dir / f"{tile_name}.png"
        
        # Pular se já existe
        if output_path.exists():
            extracted += 1
            continue
        
        data = dat.get(tile_path)
        if not data:
            errors += 1
            continue
        
        img = decode_frm(data, palette)
        if not img:
            errors += 1
            continue
        
        img.save(output_path, 'PNG')
        extracted += 1
        
        if (i + 1) % 100 == 0:
            print(f"  Processados: {i + 1}/{len(tile_files)}")
    
    dat.close()
    
    print("\n" + "=" * 60)
    print(f"EXTRAÇÃO COMPLETA!")
    print(f"  Tiles extraídos: {extracted}")
    print(f"  Erros: {errors}")
    print(f"  Diretório: {output_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
