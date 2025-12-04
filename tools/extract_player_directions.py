#!/usr/bin/env python3
"""Extrai todas as 6 direções do sprite do player"""

import struct, zlib
from pathlib import Path
from PIL import Image

class DAT2:
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
        if self.fh: self.fh.close()
    
    def get(self, name):
        name = name.lower().replace('\\', '/')
        if name not in self.files: return None
        comp, rsize, psize, off = self.files[name]
        self.fh.seek(off)
        data = self.fh.read(psize)
        if comp:
            try: data = zlib.decompress(data)
            except: pass
        return data

def load_pal(dat):
    d = dat.get('color.pal')
    if not d: return [(i,i,i) for i in range(256)]
    return [(min(255,d[i*3]*4), min(255,d[i*3+1]*4), min(255,d[i*3+2]*4)) for i in range(256)]

def decode_frm_all_directions(data, pal):
    """Decodifica FRM e retorna todas as 6 direções"""
    if len(data) < 62: return []
    
    # Header
    frame_count = struct.unpack('>H', data[8:10])[0]
    x_shifts = [struct.unpack('>h', data[10+i*2:12+i*2])[0] for i in range(6)]
    y_shifts = [struct.unpack('>h', data[22+i*2:24+i*2])[0] for i in range(6)]
    data_offsets = [struct.unpack('>I', data[34+i*4:38+i*4])[0] for i in range(6)]
    
    images = []
    
    for direction in range(6):
        offset = 62 + data_offsets[direction]
        
        if offset + 12 > len(data):
            continue
        
        # Frame header
        w = struct.unpack('>H', data[offset:offset+2])[0]
        h = struct.unpack('>H', data[offset+2:offset+4])[0]
        sz = struct.unpack('>I', data[offset+4:offset+8])[0]
        
        if w <= 0 or h <= 0 or sz <= 0:
            continue
        
        offset += 12
        if offset + sz > len(data):
            continue
        
        # Decodificar pixels
        px = data[offset:offset+sz]
        img = Image.new('RGBA', (w, h), (0,0,0,0))
        pix = img.load()
        
        for y in range(h):
            for x in range(w):
                i = y * w + x
                if i < len(px):
                    p = px[i]
                    if p == 0:
                        pix[x,y] = (0,0,0,0)
                    else:
                        pix[x,y] = (*pal[p], 255)
        
        images.append((direction, img))
    
    return images

def main():
    print("Extraindo sprite do player com todas as direções...")
    
    # Critter.dat
    dat = DAT2("Fallout 2/critter.dat")
    dat.open()
    
    # Paleta
    master = DAT2("Fallout 2/master.dat")
    master.open()
    pal = load_pal(master)
    master.close()
    
    out = Path("godot_project/assets/sprites/player")
    out.mkdir(parents=True, exist_ok=True)
    
    # Sprite do player (jumpsuit masculino - idle)
    player_file = None
    for f in dat.files.keys():
        if 'hmjmps' in f and 'aa.frm' in f:
            player_file = f
            break
    
    if not player_file:
        print("Sprite do player não encontrado!")
        dat.close()
        return
    
    print(f"Extraindo: {player_file}")
    data = dat.get(player_file)
    
    if data:
        images = decode_frm_all_directions(data, pal)
        print(f"Direções encontradas: {len(images)}")
        
        for direction, img in images:
            # Direções: 0=NE, 1=E, 2=SE, 3=SW, 4=W, 5=NW
            dir_names = ['ne', 'e', 'se', 'sw', 'w', 'nw']
            name = f"player_{dir_names[direction]}.png"
            img.save(out / name, 'PNG')
            print(f"  Salvo: {name} ({img.width}x{img.height})")
    
    dat.close()
    print("\nConcluído!")

if __name__ == "__main__":
    main()
