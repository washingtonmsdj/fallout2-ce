#!/usr/bin/env python3
"""Extrai tiles do Fallout 2"""

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

def decode_frm(data, pal):
    if len(data) < 62: return None
    offs = [struct.unpack('>I', data[34+i*4:38+i*4])[0] for i in range(6)]
    o = 62 + offs[0]
    if o + 12 > len(data): return None
    w = struct.unpack('>H', data[o:o+2])[0]
    h = struct.unpack('>H', data[o+2:o+4])[0]
    sz = struct.unpack('>I', data[o+4:o+8])[0]
    if w <= 0 or h <= 0: return None
    o += 12
    if o + sz > len(data): return None
    px = data[o:o+sz]
    img = Image.new('RGBA', (w, h), (0,0,0,0))
    pix = img.load()
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if i < len(px):
                p = px[i]
                if p == 0: pix[x,y] = (0,0,0,0)
                else: pix[x,y] = (*pal[p], 255)
    return img

def main():
    print("Extraindo tiles do Fallout 2...")
    dat = DAT2("Fallout 2/master.dat")
    dat.open()
    pal = load_pal(dat)
    
    out = Path("godot_project/assets/sprites/tiles")
    out.mkdir(parents=True, exist_ok=True)
    
    # Extrair tiles
    tiles = [f for f in dat.files.keys() if 'art/tiles' in f and f.endswith('.frm')]
    print(f"Encontrados {len(tiles)} tiles")
    
    count = 0
    for tile in tiles[:100]:  # Primeiros 100
        d = dat.get(tile)
        if not d: continue
        img = decode_frm(d, pal)
        if not img: continue
        name = Path(tile).stem.lower()
        img.save(out / f"{name}.png", 'PNG')
        count += 1
    
    print(f"Extraidos: {count} tiles")
    dat.close()

if __name__ == "__main__":
    main()
