# Fallout 2 File Format Specifications

This document provides byte-level specifications for all major file formats used in Fallout 2.

**Requirements: 3.1, 3.2** - Documentação de Formatos de Arquivo

---

## Table of Contents

1. [DAT2 Container Format](#dat2-container-format)
2. [FRM Sprite Format](#frm-sprite-format)
3. [MAP Map Format](#map-map-format)
4. [PRO Prototype Format](#pro-prototype-format)
5. [MSG Message Format](#msg-message-format)
6. [ACM Audio Format](#acm-audio-format)
7. [PAL Palette Format](#pal-palette-format)

---

## DAT2 Container Format

The DAT2 format is a compressed archive container used for master.dat, critter.dat, and patch000.dat.

### File Structure Overview

```
┌─────────────────────────────────────┐
│         File Data Section           │  ← Compressed/uncompressed file contents
├─────────────────────────────────────┤
│         Entry Table                 │  ← File metadata entries
├─────────────────────────────────────┤
│         Footer (8 bytes)            │  ← Size information
└─────────────────────────────────────┘
```

### Footer Structure (8 bytes, at end of file)

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| -8     | 4    | uint32 | entries_data_size (entry table size) |
| -4     | 4    | uint32 | dbase_data_size (total data + table + footer) |

### Entry Table Structure

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 0      | 4    | uint32 | Number of entries              |
| 4+     | var  | Entry[]| Array of file entries          |

### File Entry Structure (variable size)

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 0      | 4    | uint32 | Path length (N)                |
| 4      | N    | char[] | File path (latin-1 encoded)    |
| 4+N    | 1    | uint8  | Compression flag (0=raw, 1=zlib) |
| 5+N    | 4    | uint32 | Uncompressed size              |
| 9+N    | 4    | uint32 | Compressed/stored size         |
| 13+N   | 4    | uint32 | Data offset (relative to data section start) |

### Compression

- **Algorithm**: zlib (DEFLATE)
- **Flag**: 0 = uncompressed, 1 = zlib compressed
- **Decompression**: Standard zlib.decompress()

### Reading Algorithm

```python
# 1. Read footer
file.seek(-8, SEEK_END)
entries_data_size = read_uint32()
dbase_data_size = read_uint32()

# 2. Calculate positions
file_size = file.tell() + 8
entries_table_start = file_size - entries_data_size - 8
data_section_start = file_size - dbase_data_size

# 3. Read entry table
file.seek(entries_table_start)
num_entries = read_uint32()
for i in range(num_entries):
    entry = read_entry()
    
# 4. Extract file
actual_offset = data_section_start + entry.data_offset
file.seek(actual_offset)
data = file.read(entry.compressed_size)
if entry.is_compressed:
    data = zlib.decompress(data)
```

---

## FRM Sprite Format

The FRM (Frame Resource Manager) format stores sprites and animations with up to 6 isometric directions.

### Byte Order: Big-Endian

### Header Structure (62 bytes)

| Offset | Size | Type    | Description                    |
|--------|------|---------|--------------------------------|
| 0      | 4    | int32   | Version                        |
| 4      | 2    | int16   | Frames per second (FPS)        |
| 6      | 2    | int16   | Action frame index             |
| 8      | 2    | int16   | Number of frames per direction |
| 10     | 12   | int16[6]| X offsets for each direction   |
| 22     | 12   | int16[6]| Y offsets for each direction   |
| 34     | 24   | int32[6]| Data offsets for each direction|
| 58     | 4    | int32   | Total data size                |

### Direction Indices

| Index | Direction | Description      |
|-------|-----------|------------------|
| 0     | NE        | North-East       |
| 1     | E         | East             |
| 2     | SE        | South-East       |
| 3     | SW        | South-West       |
| 4     | W         | West             |
| 5     | NW        | North-West       |

### Frame Header Structure (12 bytes per frame)

| Offset | Size | Type  | Description                    |
|--------|------|-------|--------------------------------|
| 0      | 2    | int16 | Width in pixels                |
| 2      | 2    | int16 | Height in pixels               |
| 4      | 4    | int32 | Pixel data size                |
| 8      | 2    | int16 | X offset (hotspot)             |
| 10     | 2    | int16 | Y offset (hotspot)             |

### Pixel Data

- **Format**: 8-bit indexed color
- **Size**: width × height bytes
- **Palette**: External .PAL file (256 colors)
- **Transparency**: Index 0 is typically transparent
- **Alignment**: 4-byte aligned between frames

### Data Layout

```
[Header - 62 bytes]
[Padding to 4-byte alignment]
[Direction 0 Data]
  [Frame 0 Header - 12 bytes]
  [Frame 0 Pixels - width*height bytes]
  [Padding]
  [Frame 1 Header]
  [Frame 1 Pixels]
  ...
[Direction 1 Data]
  ...
```

### Direction Sharing

If `data_offsets[n] == data_offsets[n-1]`, direction n shares data with direction n-1.

---

## MAP Map Format

The MAP format stores game maps including tiles, objects, and scripts.

### Byte Order: Little-Endian

### Header Structure (60+ bytes)

| Offset | Size | Type    | Description                    |
|--------|------|---------|--------------------------------|
| 0      | 4    | uint32  | Version                        |
| 4      | 16   | char[16]| Map name (null-terminated)     |
| 20     | 4    | uint32  | Entering tile position         |
| 24     | 4    | uint32  | Entering elevation (0-2)       |
| 28     | 4    | uint32  | Entering rotation (0-5)        |
| 32     | 4    | uint32  | Local variables count          |
| 36     | 4    | uint32  | Script index                   |
| 40     | 4    | uint32  | Flags                          |
| 44     | 4    | uint32  | Darkness level                 |
| 48     | 4    | uint32  | Global variables count         |
| 52     | 4    | uint32  | Map index                      |
| 56     | 4    | uint32  | Last visit time                |
| 60     | 176  | reserved| Reserved fields (44 × 4 bytes) |

### Map Dimensions

- **Standard Size**: 200 × 200 tiles
- **Elevations**: 3 levels (ground, middle, roof)
- **Tile Grid**: Hexagonal

### Tile Data Section

Each elevation contains:
- Floor tiles array
- Roof tiles array

### Object Section

Objects are stored after tile data with:
- Object count
- Object entries (variable size per object)

### Object Entry Structure

| Field        | Size | Description                    |
|--------------|------|--------------------------------|
| PID          | 4    | Prototype ID                   |
| Position     | 4    | Tile position                  |
| Elevation    | 4    | Level (0-2)                    |
| Orientation  | 4    | Facing direction (0-5)         |
| Script ID    | 4    | Associated script              |
| Inventory    | var  | Inventory items (if container) |

---

## PRO Prototype Format

The PRO format defines properties for items, critters, tiles, scenery, and walls.

### Byte Order: Little-Endian

### Common Header (all types)

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 0      | 4    | uint32 | Object type                    |
| 4      | 4    | uint32 | PID (Prototype ID)             |
| 8      | 4    | uint32 | Text ID (for MSG lookup)       |
| 12     | 4    | uint32 | FID (Frame ID for sprite)      |
| 16     | 4    | uint32 | Light radius                   |
| 20     | 4    | uint32 | Light intensity                |
| 24     | 4    | uint32 | Flags                          |

### Object Types

| Value | Type     | Description              |
|-------|----------|--------------------------|
| 0     | ITEM     | Items (weapons, armor)   |
| 1     | CRITTER  | Creatures and NPCs       |
| 2     | SCENERY  | Scenery objects          |
| 3     | WALL     | Walls                    |
| 4     | TILE     | Floor/roof tiles         |
| 5     | MISC     | Miscellaneous            |

### Item Prototype Extended Fields

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 28     | 4    | uint32 | Item type (weapon/armor/etc)   |
| 32     | 4    | uint32 | Material                       |
| 36     | 4    | uint32 | Size                           |
| 40     | 4    | uint32 | Weight                         |
| 44     | 4    | uint32 | Cost                           |
| 48     | 4    | uint32 | Inventory FID                  |
| 52     | 1    | uint8  | Sound ID                       |

### Weapon-Specific Fields (Item type = 3)

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 53     | 4    | uint32 | Animation code                 |
| 57     | 4    | uint32 | Min damage                     |
| 61     | 4    | uint32 | Max damage                     |
| 65     | 4    | uint32 | Damage type                    |
| 69     | 4    | uint32 | Max range (primary)            |
| 73     | 4    | uint32 | Max range (secondary)          |
| 77     | 4    | uint32 | Projectile PID                 |
| 81     | 4    | uint32 | Min strength                   |
| 85     | 4    | uint32 | AP cost (primary)              |
| 89     | 4    | uint32 | AP cost (secondary)            |
| 93     | 4    | uint32 | Crit fail table                |
| 97     | 4    | uint32 | Perk                           |
| 101    | 4    | uint32 | Rounds                         |
| 105    | 4    | uint32 | Caliber                        |
| 109    | 4    | uint32 | Ammo PID                       |
| 113    | 4    | uint32 | Max ammo                       |
| 117    | 1    | uint8  | Sound ID                       |

### Critter Prototype Extended Fields

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 28     | 4    | uint32 | Flags                          |
| 32     | 4    | uint32 | Script ID                      |
| 36     | 4    | uint32 | Head FID                       |
| 40     | 4    | uint32 | AI packet                      |
| 44     | 4    | uint32 | Team number                    |
| 48     | 28   | int32[7]| SPECIAL stats (S,P,E,C,I,A,L) |
| 76     | 4    | uint32 | Hit points                     |
| 80     | 4    | uint32 | Action points                  |
| 84     | 4    | uint32 | Armor class                    |
| 88     | 4    | uint32 | Unarmed damage                 |
| 92     | 4    | uint32 | Melee damage                   |
| 96     | 4    | uint32 | Carry weight                   |
| 100    | 4    | uint32 | Sequence                       |
| 104    | 4    | uint32 | Healing rate                   |
| 108    | 4    | uint32 | Critical chance                |
| 112    | 4    | uint32 | Better criticals               |


---

## MSG Message Format

The MSG format stores localized text messages and dialog strings.

### Format Type: Text-based

### Structure

MSG files are text files with entries in the format:
```
{id}{}{text}
```

### Entry Format

| Component | Description                              |
|-----------|------------------------------------------|
| `{id}`    | Numeric message ID (integer)             |
| `{}`      | Empty field (reserved)                   |
| `{text}`  | Message text (may contain newlines)      |

### Example

```
{100}{}{Welcome to Vault City.}
{101}{}{What brings you here, stranger?}
{102}{}{I'm looking for information about the GECK.}
```

### Encoding

- **Primary**: Latin-1 (ISO-8859-1)
- **Fallback**: CP1252 (Windows)
- **Modern**: UTF-8 (for translations)

### Special Characters

| Sequence | Meaning                    |
|----------|----------------------------|
| `\n`     | Newline                    |
| `%s`     | String placeholder         |
| `%d`     | Integer placeholder        |
| `@`      | Color code prefix          |

### Dialog Files

Dialog MSG files (in `text/english/dialog/`) contain:
- NPC responses (IDs 100-199)
- Player options (IDs 200-299)
- Skill checks (IDs 300-399)
- Barter text (IDs 400-499)

### Parsing Algorithm

```python
import re

MSG_PATTERN = re.compile(r'\{(\d+)\}\{\}(.*?)(?=\{\d+\}\{\}|$)', re.DOTALL)

def parse_msg(data: bytes) -> dict:
    text = data.decode('latin-1')
    messages = {}
    
    for match in MSG_PATTERN.findall(text):
        msg_id = int(match[0])
        msg_text = match[1].strip()
        messages[msg_id] = msg_text
    
    return messages
```

---

## ACM Audio Format

The ACM format is a proprietary compressed audio format used for music and sound effects.

### Header Structure (14 bytes)

| Offset | Size | Type   | Description                    |
|--------|------|--------|--------------------------------|
| 0      | 4    | char[4]| Magic number (varies)          |
| 4      | 4    | uint32 | Sample count                   |
| 8      | 2    | uint16 | Channels (1=mono, 2=stereo)    |
| 10     | 2    | uint16 | Sample rate (usually 22050)    |
| 12     | 2    | uint16 | Compression level              |

### Audio Properties

| Property    | Typical Value    |
|-------------|------------------|
| Sample Rate | 22050 Hz         |
| Channels    | 1 (mono)         |
| Bit Depth   | 16-bit           |
| Compression | Proprietary      |

### Conversion

ACM files require specialized decoders. Options:
1. **acm2wav**: Dedicated ACM decoder
2. **ffmpeg**: With ACM codec support
3. **libacm**: Library implementation

### Output Formats for Godot

| Format | Use Case           | Quality    |
|--------|--------------------|------------|
| OGG    | Music, long audio  | Good       |
| WAV    | Sound effects      | Lossless   |
| MP3    | Alternative        | Good       |

### Conversion Example

```bash
# Using ffmpeg (if ACM codec available)
ffmpeg -i input.acm -c:a libvorbis output.ogg

# Using acm2wav
acm2wav input.acm output.wav
```

---

## PAL Palette Format

The PAL format stores 256-color palettes used for indexed color sprites.

### Structure (768 bytes)

| Offset | Size | Type      | Description                    |
|--------|------|-----------|--------------------------------|
| 0      | 768  | RGB[256]  | 256 RGB triplets               |

### RGB Entry (3 bytes each)

| Offset | Size | Type  | Description                    |
|--------|------|-------|--------------------------------|
| 0      | 1    | uint8 | Red (0-63, multiply by 4)      |
| 1      | 1    | uint8 | Green (0-63, multiply by 4)    |
| 2      | 1    | uint8 | Blue (0-63, multiply by 4)     |

### Color Conversion

Fallout 2 uses 6-bit color values (0-63). Convert to 8-bit:
```python
def convert_color(value_6bit):
    return (value_6bit * 255) // 63
    # Or simply: value_6bit * 4
```

### Standard Palette

The default palette is `color.pal` in the `art/` directory.

### Special Indices

| Index | Purpose              |
|-------|----------------------|
| 0     | Transparent          |
| 1-15  | System colors        |
| 16-31 | Animated colors      |
| 32-255| Standard colors      |

### Loading Example

```python
def load_palette(data: bytes) -> list:
    colors = []
    for i in range(256):
        r = data[i * 3] * 4
        g = data[i * 3 + 1] * 4
        b = data[i * 3 + 2] * 4
        colors.append((r, g, b))
    return colors
```

---

## File Type Summary

| Extension | Format    | Byte Order    | Compression |
|-----------|-----------|---------------|-------------|
| .dat      | DAT2      | Little-Endian | zlib        |
| .frm      | FRM       | Big-Endian    | None        |
| .map      | MAP       | Little-Endian | None        |
| .pro      | PRO       | Little-Endian | None        |
| .msg      | MSG       | N/A (text)    | None        |
| .acm      | ACM       | Little-Endian | Proprietary |
| .pal      | PAL       | N/A           | None        |

---

## Implementation Status

| Format | Parser      | Encoder     | Tests       |
|--------|-------------|-------------|-------------|
| DAT2   | ✅ Complete | ✅ Complete | ✅ Complete |
| FRM    | ✅ Complete | ⚠️ Partial  | ✅ Complete |
| MAP    | ⚠️ Partial  | ❌ None     | ⚠️ Partial  |
| PRO    | ⚠️ Partial  | ❌ None     | ❌ None     |
| MSG    | ✅ Complete | ✅ Complete | ✅ Complete |
| ACM    | ⚠️ External | N/A         | ⚠️ Partial  |
| PAL    | ✅ Complete | ✅ Complete | ✅ Complete |

---

## References

- **Source Code**: `src/art.cc`, `src/map.cc`, `src/proto.cc`, `src/message.cc`
- **Existing Documentation**: `analysis/FORMATO_FRM.md`
- **Python Extractors**: `tools/extractors/`

---

*Last Updated: 2025-12-04*
*Requirements: 3.1, 3.2 - Documentação de Formatos de Arquivo*
