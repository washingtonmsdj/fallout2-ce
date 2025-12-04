# Fallout 2 DAT File Structure Documentation

Generated: 2025-12-04 18:32:33

## Overview

This document provides a comprehensive mapping of all files contained in the Fallout 2 DAT archives.

### Summary

| DAT File | Files | Size | Compressed | Ratio |
|----------|-------|------|------------|-------|
| critter.dat | 7,120 | 619.1 MB | 158.9 MB | 25.7% |
| master.dat | 23,140 | 517.7 MB | 316.8 MB | 61.2% |
| patch000.dat | 489 | 12.9 MB | 2.2 MB | 17.3% |
| **Total** | **30,749** | **1.1 GB** | **478.0 MB** | **41.6%** |

### File Types

| Extension | Type | Category | Description | Count |
|-----------|------|----------|-------------|-------|
| .FRM | sprite | graphics | Frame Resource Manager - sprite/animation | 10,747 |
| .pro | prototype | data | Prototype definition (items/critters/tiles) | 4,308 |
| .PRO | prototype | data | Prototype definition (items/critters/tiles) | 3,345 |
| .ACM | audio | audio | ACM compressed audio | 2,344 |
| .int | script_compiled | scripts | Compiled SSL script | 1,887 |
| .frm | sprite | graphics | Frame Resource Manager - sprite/animation | 1,474 |
| .TXT | text | text | Plain text file | 1,189 |
| .LIP | unknown | unknown | Unknown file type (.LIP) | 1,029 |
| .msg | message | text | Message/dialog text file | 541 |
| .FR0 | unknown | unknown | Unknown file type (.FR0) | 495 |
| .FR1 | unknown | unknown | Unknown file type (.FR1) | 495 |
| .FR2 | unknown | unknown | Unknown file type (.FR2) | 495 |
| .FR3 | unknown | unknown | Unknown file type (.FR3) | 495 |
| .FR4 | unknown | unknown | Unknown file type (.FR4) | 495 |
| .FR5 | unknown | unknown | Unknown file type (.FR5) | 495 |
| .MSG | message | text | Message/dialog text file | 309 |
| .acm | audio | audio | ACM compressed audio | 129 |
| .map | map | world | Map file with tiles, objects, scripts | 117 |
| .MAP | map | world | Map file with tiles, objects, scripts | 53 |
| .gam | savegame | world | Save game file | 48 |
| .GAM | savegame | world | Save game file | 41 |
| .pal | palette | graphics | Color palette (256 indexed colors) | 36 |
| .cfg | config | config | Configuration file | 30 |
|  | unknown | unknown | Unknown file type () | 27 |
| .LST | list | data | List file (indexes) | 20 |
| .txt | text | text | Plain text file | 20 |
| .PAL | palette | graphics | Color palette (256 indexed colors) | 13 |
| .sve | text | text | Save game text | 11 |
| .mve | video | video | MVE video file | 10 |
| .MSK | unknown | unknown | Unknown file type (.MSK) | 7 |
| .rix | image | graphics | RIX image format | 6 |
| .FON | font | graphics | Font file | 5 |
| .lst | list | data | List file (indexes) | 5 |
| .AAF | font | graphics | AAF font file | 4 |
| .GCD | unknown | unknown | Unknown file type (.GCD) | 4 |
| .MVE | video | video | MVE video file | 3 |
| .BAK | unknown | unknown | Unknown file type (.BAK) | 3 |
| .gcd | unknown | unknown | Unknown file type (.gcd) | 2 |
| .BIO | unknown | unknown | Unknown file type (.BIO) | 2 |
| .lnk | unknown | unknown | Unknown file type (.lnk) | 2 |
| .REF | unknown | unknown | Unknown file type (.REF) | 1 |
| .RIX | image | graphics | RIX image format | 1 |
| .Txt | text | text | Plain text file | 1 |
| .LBM | unknown | unknown | Unknown file type (.LBM) | 1 |
| .aaf | font | graphics | AAF font file | 1 |
| .bio | unknown | unknown | Unknown file type (.bio) | 1 |
| .COM | unknown | unknown | Unknown file type (.COM) | 1 |
| .INT | script_compiled | scripts | Compiled SSL script | 1 |

## critter.dat

- **Total Files**: 7,120
- **Total Size**: 619.1 MB
- **Compressed Size**: 158.9 MB

### Folder Structure

#### art/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `art/critters` | Creature and NPC sprites/animations | 7,120 | 619.1 MB |

### Categories Breakdown

| Category | File Count |
|----------|------------|
| graphics | 4,149 |
| unknown | 2,970 |
| data | 1 |

## master.dat

- **Total Files**: 23,140
- **Total Size**: 517.7 MB
- **Compressed Size**: 316.8 MB

### Folder Structure

#### ./

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `.` | Unknown purpose | 11 | 139.2 KB |

#### art/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `art/backgrnd` | Background images | 22 | 1.4 MB |
| `art/cuts` | Graphics and visual assets | 31 | 206.8 MB |
| `art/heads` | NPC talking head animations | 187 | 78.2 MB |
| `art/intrface` | Interface/UI graphics | 502 | 30.1 MB |
| `art/inven` | Inventory item graphics | 368 | 1.5 MB |
| `art/items` | Item sprites (weapons, armor, misc) | 194 | 908.8 KB |
| `art/misc` | Miscellaneous graphics | 57 | 484.1 KB |
| `art/scenery` | Scenery objects (trees, rocks, etc) | 1,867 | 19.3 MB |
| `art/skilldex` | Skilldex interface graphics | 174 | 2.7 MB |
| `art/splash` | Graphics and visual assets | 7 | 2.1 MB |
| `art/tiles` | Terrain and floor tiles | 3,083 | 8.5 MB |
| `art/walls` | Wall tiles and structures | 1,675 | 5.0 MB |

#### data/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `data` | Game data files | 25 | 817.6 KB |

#### maps/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `maps` | Map files | 260 | 35.0 MB |

#### premade/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `premade` | Unknown purpose | 9 | 3.7 KB |

#### proto/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `proto/CRITTERS` | Creature prototypes | 484 | 202.8 KB |
| `proto/ITEMS` | Item prototypes | 532 | 51.0 KB |
| `proto/MISC` | Miscellaneous prototypes | 51 | 2.1 KB |
| `proto/SCENERY` | Scenery prototypes | 1,852 | 107.1 KB |
| `proto/TILES` | Tile prototypes | 3,103 | 127.2 KB |
| `proto/TILES/PATTERNS` | Tile prototypes | 27 | 146.8 KB |
| `proto/WALLS` | Wall prototypes | 1,634 | 79.7 KB |

#### scripts/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `scripts` | Compiled game scripts | 1,448 | 15.0 MB |

#### sound/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `sound/SFX` | Sound effects | 1,362 | 16.7 MB |
| `sound/Speech/BOSSS` | Audio files | 15 | 903.1 KB |
| `sound/Speech/ELDER` | Audio files | 108 | 4.6 MB |
| `sound/Speech/HAKU2` | Audio files | 60 | 1.6 MB |
| `sound/Speech/HAKUN` | Audio files | 163 | 3.4 MB |
| `sound/Speech/HRLD2` | Audio files | 198 | 6.2 MB |
| `sound/Speech/LYNET` | Audio files | 541 | 11.7 MB |
| `sound/Speech/MRCUS` | Audio files | 210 | 3.8 MB |
| `sound/Speech/MYRON` | Audio files | 495 | 10.3 MB |
| `sound/Speech/POWER` | Audio files | 183 | 4.6 MB |
| `sound/Speech/PRESI` | Audio files | 234 | 7.3 MB |
| `sound/Speech/SULIK` | Audio files | 723 | 10.8 MB |
| `sound/Speech/TNDI2` | Audio files | 156 | 4.1 MB |
| `sound/Speech/narrator` | Audio files | 114 | 18.8 MB |

#### text/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `text/english` | English language files | 2 | 16.5 KB |
| `text/english/cuts` | Cutscene text | 138 | 34.9 KB |
| `text/english/dialog` | NPC dialog files | 802 | 3.2 MB |
| `text/english/game` | Game text messages | 33 | 1.1 MB |

### Categories Breakdown

| Category | File Count |
|----------|------------|
| graphics | 8,136 |
| data | 7,673 |
| audio | 2,473 |
| text | 2,049 |
| scripts | 1,443 |
| unknown | 1,080 |
| world | 243 |
| config | 30 |
| video | 13 |

## patch000.dat

- **Total Files**: 489
- **Total Size**: 12.9 MB
- **Compressed Size**: 2.2 MB

### Folder Structure

#### ./

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `.` | Unknown purpose | 2 | 45.4 KB |

#### Art/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Art/intrface` | Interface/UI graphics | 2 | 332.8 KB |

#### Data/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Data` | Game data files | 4 | 103.1 KB |

#### Maps/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Maps` | Map files | 15 | 4.9 MB |

#### Proto/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Proto/Critters` | Creature prototypes | 2 | 832.0 B |
| `Proto/Items` | Item prototypes | 1 | 81.0 B |

#### Scripts/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Scripts` | Compiled game scripts | 446 | 7.1 MB |

#### Text/

| Folder | Purpose | Files | Size |
|--------|---------|-------|------|
| `Text/English/Dialog` | NPC dialog files | 14 | 123.1 KB |
| `Text/English/Game` | Game text messages | 3 | 189.1 KB |

### Categories Breakdown

| Category | File Count |
|----------|------------|
| scripts | 445 |
| text | 22 |
| world | 16 |
| data | 4 |
| graphics | 2 |