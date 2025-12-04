#!/usr/bin/env python3
"""
Script para extrair e analisar sprites dos arquivos .DAT
Converte .FRM para PNG para visualização no dashboard
"""

import os
import sys
from pathlib import Path
import struct

# Adicionar path do projeto
BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"

# Estrutura do .FRM (baseado em src/art.h)
class FRMHeader:
    def __init__(self):
        self.field_0 = 0
        self.frames_per_second = 0
        self.action_frame = 0
        self.frame_count = 0
        self.x_offsets = [0] * 6
        self.y_offsets = [0] * 6
        self.data_offsets = [0] * 6
        self.padding = [0] * 6
        self.data_size = 0

class FRMFrame:
    def __init__(self):
        self.width = 0
        self.height = 0
        self.size = 0
        self.x = 0
        self.y = 0
        self.pixels = None

def read_frm_header(file):
    """Lê header do arquivo .FRM"""
    header = FRMHeader()
    
    # Ler campos do header (80 bytes total)
    header.field_0 = struct.unpack('<I', file.read(4))[0]
    header.frames_per_second = struct.unpack('<h', file.read(2))[0]
    header.action_frame = struct.unpack('<h', file.read(2))[0]
    header.frame_count = struct.unpack('<h', file.read(2))[0]
    
    # Ler offsets X (12 bytes)
    for i in range(6):
        header.x_offsets[i] = struct.unpack('<h', file.read(2))[0]
    
    # Ler offsets Y (12 bytes)
    for i in range(6):
        header.y_offsets[i] = struct.unpack('<h', file.read(2))[0]
    
    # Ler data offsets (24 bytes)
    for i in range(6):
        header.data_offsets[i] = struct.unpack('<I', file.read(4))[0]
    
    # Ler padding (24 bytes)
    for i in range(6):
        header.padding[i] = struct.unpack('<I', file.read(4))[0]
    
    # Ler data size (4 bytes)
    header.data_size = struct.unpack('<I', file.read(4))[0]
    
    return header

def read_frm_frame(file):
    """Lê um frame do arquivo .FRM"""
    frame = FRMFrame()
    
    frame.width = struct.unpack('<h', file.read(2))[0]
    frame.height = struct.unpack('<h', file.read(2))[0]
    frame.size = struct.unpack('<I', file.read(4))[0]
    frame.x = struct.unpack('<h', file.read(2))[0]
    frame.y = struct.unpack('<h', file.read(2))[0]
    
    # Ler pixels
    if frame.size > 0:
        frame.pixels = file.read(frame.size)
    
    return frame

def frm_to_png_data(frm_path, output_dir):
    """Converte .FRM para dados que podem ser visualizados"""
    try:
        with open(frm_path, 'rb') as f:
            header = read_frm_header(f)
            
            # Criar estrutura de dados para visualização
            data = {
                'header': {
                    'frames_per_second': header.frames_per_second,
                    'action_frame': header.action_frame,
                    'frame_count': header.frame_count,
                    'x_offsets': header.x_offsets,
                    'y_offsets': header.y_offsets,
                },
                'frames': []
            }
            
            # Ler frames de cada direção
            for direction in range(6):
                if header.data_offsets[direction] == 0:
                    continue
                
                f.seek(header.data_offsets[direction])
                direction_frames = []
                
                for frame_idx in range(header.frame_count):
                    frame = read_frm_frame(f)
                    direction_frames.append({
                        'width': frame.width,
                        'height': frame.height,
                        'x': frame.x,
                        'y': frame.y,
                        'size': frame.size,
                        'has_data': frame.pixels is not None
                    })
                
                data['frames'].append({
                    'direction': direction,
                    'frames': direction_frames
                })
            
            return data
            
    except Exception as e:
        print(f"Erro ao ler {frm_path}: {e}")
        return None

def extract_known_sprites():
    """Extrai sprites conhecidos que estão em pastas"""
    extracted = []
    
    # Procurar .FRM em data/art/
    art_dir = FALLOUT_DIR / "data" / "art"
    if art_dir.exists():
        for frm_file in art_dir.rglob("*.FRM"):
            relative_path = frm_file.relative_to(FALLOUT_DIR)
            extracted.append({
                'name': frm_file.name,
                'path': str(relative_path),
                'full_path': str(frm_file),
                'size': frm_file.stat().st_size
            })
        for frm_file in art_dir.rglob("*.frm"):
            relative_path = frm_file.relative_to(FALLOUT_DIR)
            extracted.append({
                'name': frm_file.name,
                'path': str(relative_path),
                'full_path': str(frm_file),
                'size': frm_file.stat().st_size
            })
    
    return extracted

def main():
    """Função principal"""
    print("=" * 60)
    print("🔍 Extraindo e Analisando Sprites")
    print("=" * 60)
    
    # Criar diretório de extração
    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    
    # Extrair sprites conhecidos
    print("\n📦 Procurando sprites em pastas...")
    sprites = extract_known_sprites()
    
    print(f"✅ Encontrados {len(sprites)} arquivos .FRM")
    
    # Salvar lista de sprites
    import json
    sprites_file = EXTRACTED_DIR / "sprites_list.json"
    with open(sprites_file, 'w', encoding='utf-8') as f:
        json.dump(sprites, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Lista salva em: {sprites_file}")
    
    # Analisar cada sprite
    print("\n🔬 Analisando sprites...")
    analyzed = []
    for sprite in sprites:
        print(f"  Analisando: {sprite['name']}")
        data = frm_to_png_data(sprite['full_path'], EXTRACTED_DIR)
        if data:
            analyzed.append({
                'name': sprite['name'],
                'path': sprite['path'],
                'analysis': data
            })
    
    # Salvar análise
    analysis_file = EXTRACTED_DIR / "sprites_analysis.json"
    with open(analysis_file, 'w', encoding='utf-8') as f:
        json.dump(analyzed, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Análise salva em: {analysis_file}")
    print(f"\n✅ Processo concluído! {len(analyzed)} sprites analisados.")
    print("\n⚠️  Nota: Para ver sprites dos .DAT, você precisa:")
    print("   1. Usar ferramentas como 'dat2' ou 'Fallout Mod Manager'")
    print("   2. Ou implementar extrator baseado em src/xfile.cc")

if __name__ == "__main__":
    main()

