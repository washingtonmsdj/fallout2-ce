#!/usr/bin/env python3
"""
Extrator e Conversor de Assets do Fallout 2 para Godot
Extrai arquivos dos .DAT e converte para formatos do Godot

Uso:
    python extract_and_convert.py "Fallout 2" godot_project/assets
"""

import os
import sys
import struct
import json
import zlib
from pathlib import Path
from PIL import Image
import argparse

class DATExtractor:
    """Extrai arquivos dos arquivos .DAT do Fallout 2"""
    
    def __init__(self, dat_path):
        self.dat_path = Path(dat_path)
        self.files = {}
        
    def read_dat(self):
        """Le o arquivo DAT e extrai lista de arquivos"""
        with open(self.dat_path, 'rb') as f:
            # Ler tamanho do arquivo
            f.seek(-8, 2)
            tree_size = struct.unpack('<I', f.read(4))[0]
            data_size = struct.unpack('<I', f.read(4))[0]
            
            # Ler arvore de arquivos
            f.seek(data_size - tree_size - 8)
            file_count = struct.unpack('<I', f.read(4))[0]
            
            for _ in range(file_count):
                name_len = struct.unpack('<I', f.read(4))[0]
                name = f.read(name_len).decode('ascii', errors='ignore').rstrip('\x00')
                compressed = struct.unpack('<B', f.read(1))[0]
                real_size = struct.unpack('<I', f.read(4))[0]
                packed_size = struct.unpack('<I', f.read(4))[0]
                offset = struct.unpack('<I', f.read(4))[0]
                
                self.files[name.lower()] = {
                    'name': name,
                    'compressed': compressed,
                    'real_size': real_size,
                    'packed_size': packed_size,
                    'offset': offset
                }
        
        return len(self.files)
    
    def extract_file(self, filename):
        """Extrai um arquivo especifico do DAT"""
        filename = filename.lower()
        if filename not in self.files:
            return None
        
        info = self.files[filename]
        
        with open(self.dat_path, 'rb') as f:
            f.seek(info['offset'])
            data = f.read(info['packed_size'])
            
            if info['compressed']:
                try:
                    data = zlib.decompress(data)
                except:
                    pass
        
        return data
    
    def list_files(self, extension=None):
        """Lista arquivos no DAT"""
        files = list(self.files.keys())
        if extension:
            files = [f for f in files if f.endswith(extension.lower())]
        return files


class FRMConverter:
    """Converte arquivos .FRM para PNG"""
    
    def __init__(self, palette):
        self.palette = palette
    
    def convert(self, frm_data, output_path):
        """Converte dados FRM para PNG"""
        if len(frm_data) < 62:
            return False
        
        # Ler header (BIG-ENDIAN)
        version = struct.unpack('>I', frm_data[0:4])[0]
        fps = struct.unpack('>H', frm_data[4:6])[0]
        action_frame = struct.unpack('>H', frm_data[6:8])[0]
        frame_count = struct.unpack('>H', frm_data[8:10])[0]
        
        # Offsets X e Y para cada direcao
        x_offsets = [struct.unpack('>h', frm_data[10+i*2:12+i*2])[0] for i in range(6)]
        y_offsets = [struct.unpack('>h', frm_data[22+i*2:24+i*2])[0] for i in range(6)]
        
        # Offsets de dados
        data_offsets = [struct.unpack('>I', frm_data[34+i*4:38+i*4])[0] for i in range(6)]
        
        # Data size
        data_size = struct.unpack('>I', frm_data[58:62])[0]
        
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        frames_saved = 0
        base_offset = 62
        
        for direction in range(6):
            if data_offsets[direction] == 0 and direction > 0:
                continue
            
            offset = base_offset + data_offsets[direction]
            
            for frame_idx in range(frame_count):
                if offset + 12 > len(frm_data):
                    break
                
                # Ler header do frame
                width = struct.unpack('>H', frm_data[offset:offset+2])[0]
                height = struct.unpack('>H', frm_data[offset+2:offset+4])[0]
                size = struct.unpack('>I', frm_data[offset+4:offset+8])[0]
                frame_x = struct.unpack('>h', frm_data[offset+8:offset+10])[0]
                frame_y = struct.unpack('>h', frm_data[offset+10:offset+12])[0]
                
                if width <= 0 or height <= 0 or size <= 0:
                    break
                
                offset += 12
                
                if offset + size > len(frm_data):
                    break
                
                # Criar imagem
                img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
                pixels = img.load()
                
                pixel_data = frm_data[offset:offset+size]
                for y in range(height):
                    for x in range(width):
                        idx = y * width + x
                        if idx < len(pixel_data):
                            pal_idx = pixel_data[idx]
                            if pal_idx == 0:
                                pixels[x, y] = (0, 0, 0, 0)
                            elif pal_idx < len(self.palette):
                                r, g, b = self.palette[pal_idx]
                                pixels[x, y] = (r, g, b, 255)
                
                # Salvar
                if frame_count == 1 and direction == 0:
                    frame_path = output_path.with_suffix('.png')
                else:
                    frame_path = output_path.parent / f"{output_path.stem}_d{direction}_f{frame_idx}.png"
                
                img.save(frame_path, 'PNG')
                frames_saved += 1
                
                offset += size
                # Padding
                offset += (4 - size % 4) % 4
        
        return frames_saved > 0


def load_palette(palette_path):
    """Carrega paleta de cores"""
    palette = [(0, 0, 0)]  # Index 0 = transparente
    
    if palette_path and Path(palette_path).exists():
        with open(palette_path, 'rb') as f:
            data = f.read(768)
        
        for i in range(256):
            r = min(255, data[i * 3] * 4)
            g = min(255, data[i * 3 + 1] * 4)
            b = min(255, data[i * 3 + 2] * 4)
            palette.append((r, g, b))
        
        palette = palette[1:]  # Remover o primeiro que adicionamos
    else:
        # Paleta padrao
        for i in range(1, 256):
            palette.append((i, i, i))
    
    return palette


def main():
    parser = argparse.ArgumentParser(description='Extrai e converte assets do Fallout 2 para Godot')
    parser.add_argument('fallout_dir', help='Diretorio do Fallout 2')
    parser.add_argument('output_dir', help='Diretorio de saida')
    parser.add_argument('--limit', type=int, default=0, help='Limite de arquivos (0=todos)')
    args = parser.parse_args()
    
    fallout_dir = Path(args.fallout_dir)
    output_dir = Path(args.output_dir)
    
    print("=" * 60)
    print("EXTRATOR E CONVERSOR DE ASSETS DO FALLOUT 2")
    print("=" * 60)
    
    # Carregar paleta
    palette_path = fallout_dir / "color.pal"
    if not palette_path.exists():
        # Tentar extrair do master.dat
        master_dat = fallout_dir / "master.dat"
        if master_dat.exists():
            print("Extraindo paleta do master.dat...")
            extractor = DATExtractor(master_dat)
            extractor.read_dat()
            pal_data = extractor.extract_file("color.pal")
            if pal_data:
                with open(palette_path, 'wb') as f:
                    f.write(pal_data)
    
    palette = load_palette(palette_path)
    print(f"Paleta carregada: {len(palette)} cores")
    
    # Criar conversor
    converter = FRMConverter(palette)
    
    # Processar master.dat
    master_dat = fallout_dir / "master.dat"
    if master_dat.exists():
        print(f"\nProcessando {master_dat}...")
        extractor = DATExtractor(master_dat)
        file_count = extractor.read_dat()
        print(f"  {file_count} arquivos encontrados")
        
        # Listar FRMs
        frm_files = extractor.list_files('.frm')
        print(f"  {len(frm_files)} arquivos .FRM")
        
        if args.limit > 0:
            frm_files = frm_files[:args.limit]
        
        converted = 0
        for frm_file in frm_files:
            frm_data = extractor.extract_file(frm_file)
            if frm_data:
                # Determinar pasta de saida
                if 'intrface' in frm_file or 'interface' in frm_file:
                    out_subdir = 'sprites/ui'
                elif 'critter' in frm_file:
                    out_subdir = 'sprites/critters'
                elif 'item' in frm_file:
                    out_subdir = 'sprites/items'
                elif 'tile' in frm_file:
                    out_subdir = 'sprites/tiles'
                else:
                    out_subdir = 'sprites/misc'
                
                out_path = output_dir / out_subdir / Path(frm_file).stem
                
                if converter.convert(frm_data, out_path):
                    converted += 1
                    if converted % 100 == 0:
                        print(f"  Convertidos: {converted}")
        
        print(f"  Total convertido: {converted}")
    
    # Processar critter.dat
    critter_dat = fallout_dir / "critter.dat"
    if critter_dat.exists():
        print(f"\nProcessando {critter_dat}...")
        extractor = DATExtractor(critter_dat)
        file_count = extractor.read_dat()
        print(f"  {file_count} arquivos encontrados")
        
        frm_files = extractor.list_files('.frm')
        print(f"  {len(frm_files)} arquivos .FRM")
        
        if args.limit > 0:
            frm_files = frm_files[:args.limit]
        
        converted = 0
        for frm_file in frm_files:
            frm_data = extractor.extract_file(frm_file)
            if frm_data:
                out_path = output_dir / 'sprites/critters' / Path(frm_file).stem
                if converter.convert(frm_data, out_path):
                    converted += 1
        
        print(f"  Total convertido: {converted}")
    
    print("\n" + "=" * 60)
    print("CONVERSAO CONCLUIDA!")
    print(f"Assets salvos em: {output_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
