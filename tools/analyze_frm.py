#!/usr/bin/env python3
"""Analisa estrutura de arquivos FRM do Fallout 2"""

import struct
import zlib
from pathlib import Path


class DAT2Reader:
    def __init__(self, path):
        self.path = path
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


def analyze_frm(frm_data, name=""):
    """Analisa estrutura de um arquivo FRM"""
    print(f"\n=== Analisando: {name} ===")
    print(f"Tamanho total: {len(frm_data)} bytes")
    
    # Header (big-endian)
    version = struct.unpack('>I', frm_data[0:4])[0]
    fps = struct.unpack('>H', frm_data[4:6])[0]
    action_frame = struct.unpack('>H', frm_data[6:8])[0]
    frame_count = struct.unpack('>H', frm_data[8:10])[0]
    
    print(f"\nHeader:")
    print(f"  Version: {version}")
    print(f"  FPS: {fps}")
    print(f"  Action frame: {action_frame}")
    print(f"  Frame count (por direcao): {frame_count}")
    
    # Offsets por direção
    x_shifts = [struct.unpack('>h', frm_data[10+i*2:12+i*2])[0] for i in range(6)]
    y_shifts = [struct.unpack('>h', frm_data[22+i*2:24+i*2])[0] for i in range(6)]
    data_offsets = [struct.unpack('>I', frm_data[34+i*4:38+i*4])[0] for i in range(6)]
    
    dirs = ['NE', 'E', 'SE', 'SW', 'W', 'NW']
    
    print(f"\nOffsets por direcao:")
    for i in range(6):
        print(f"  {dirs[i]}: data_offset={data_offsets[i]}, x_shift={x_shifts[i]}, y_shift={y_shifts[i]}")
    
    # Analisar frames de cada direção
    print(f"\nFrames por direcao:")
    base_offset = 62
    
    for direction in range(6):
        # Verificar se direção existe
        if direction > 0 and data_offsets[direction] == data_offsets[direction - 1]:
            print(f"  {dirs[direction]}: (compartilha dados com direcao anterior)")
            continue
        
        offset = base_offset + data_offsets[direction]
        frames_found = 0
        total_size = 0
        
        for frame_idx in range(frame_count):
            if offset + 12 > len(frm_data):
                break
            
            w = struct.unpack('>H', frm_data[offset:offset+2])[0]
            h = struct.unpack('>H', frm_data[offset+2:offset+4])[0]
            size = struct.unpack('>I', frm_data[offset+4:offset+8])[0]
            
            if w <= 0 or h <= 0 or size <= 0 or size > 1000000:
                break
            
            frames_found += 1
            total_size += size
            
            if frame_idx == 0:
                print(f"  {dirs[direction]}: primeiro frame {w}x{h}, size={size}")
            
            # Avançar para próximo frame
            offset += 12 + size
        
        print(f"    -> {frames_found} frames encontrados (esperado: {frame_count})")


def main():
    dat = DAT2Reader(Path('Fallout 2/critter.dat'))
    dat.open()
    print(f"Arquivos no DAT: {len(dat.files)}")
    
    # Analisar animações do player
    animations = {
        'aa': 'idle',
        'ab': 'walk', 
        'at': 'run',
        'an': 'attack_unarmed',
        'ak': 'attack_melee',
        'ch': 'death'
    }
    
    for code, name in animations.items():
        frm_path = f'art/critters/hmjmps{code}.frm'
        frm_data = dat.get(frm_path)
        if frm_data:
            analyze_frm(frm_data, f"{name} ({code})")
        else:
            print(f"\n{name}: arquivo nao encontrado")


if __name__ == '__main__':
    main()
