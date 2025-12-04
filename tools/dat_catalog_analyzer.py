"""
DAT Catalog Analyzer - Analyzes and documents Fallout 2 DAT file structure.

This script creates a comprehensive catalog of all files in the Fallout 2 DAT archives,
documenting the hierarchy, file types, and generating JSON/Markdown reports.

Requirements: 2.1, 2.2 - Mapeamento de Arquivos de Dados
"""
import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict, field
from collections import defaultdict
from datetime import datetime

from extractors.dat2_reader import DAT2Reader, DAT2Manager, FileInfo


# File type definitions based on extension
FILE_TYPE_DEFINITIONS = {
    # Graphics
    '.frm': {'type': 'sprite', 'category': 'graphics', 'description': 'Frame Resource Manager - sprite/animation'},
    '.pal': {'type': 'palette', 'category': 'graphics', 'description': 'Color palette (256 indexed colors)'},
    '.rix': {'type': 'image', 'category': 'graphics', 'description': 'RIX image format'},
    
    # Maps and World
    '.map': {'type': 'map', 'category': 'world', 'description': 'Map file with tiles, objects, scripts'},
    '.gam': {'type': 'savegame', 'category': 'world', 'description': 'Save game file'},
    '.sav': {'type': 'mapsave', 'category': 'world', 'description': 'Individual map save state'},
    
    # Prototypes
    '.pro': {'type': 'prototype', 'category': 'data', 'description': 'Prototype definition (items/critters/tiles)'},
    '.lst': {'type': 'list', 'category': 'data', 'description': 'List file (indexes)'},
    
    # Scripts
    '.int': {'type': 'script_compiled', 'category': 'scripts', 'description': 'Compiled SSL script'},
    '.ssl': {'type': 'script_source', 'category': 'scripts', 'description': 'SSL script source'},
    '.h': {'type': 'header', 'category': 'scripts', 'description': 'Script header file'},
    
    # Text and Dialogs
    '.msg': {'type': 'message', 'category': 'text', 'description': 'Message/dialog text file'},
    '.txt': {'type': 'text', 'category': 'text', 'description': 'Plain text file'},
    '.sve': {'type': 'text', 'category': 'text', 'description': 'Save game text'},
    
    # Audio
    '.acm': {'type': 'audio', 'category': 'audio', 'description': 'ACM compressed audio'},
    '.wav': {'type': 'audio', 'category': 'audio', 'description': 'WAV audio file'},
    
    # Video
    '.mve': {'type': 'video', 'category': 'video', 'description': 'MVE video file'},
    
    # Configuration
    '.cfg': {'type': 'config', 'category': 'config', 'description': 'Configuration file'},
    '.ini': {'type': 'config', 'category': 'config', 'description': 'INI configuration file'},
    
    # Other
    '.fon': {'type': 'font', 'category': 'graphics', 'description': 'Font file'},
    '.aaf': {'type': 'font', 'category': 'graphics', 'description': 'AAF font file'},
}

# Folder purpose definitions
FOLDER_PURPOSES = {
    'art': 'Graphics and visual assets',
    'art/critters': 'Creature and NPC sprites/animations',
    'art/items': 'Item sprites (weapons, armor, misc)',
    'art/tiles': 'Terrain and floor tiles',
    'art/scenery': 'Scenery objects (trees, rocks, etc)',
    'art/walls': 'Wall tiles and structures',
    'art/intrface': 'Interface/UI graphics',
    'art/inven': 'Inventory item graphics',
    'art/misc': 'Miscellaneous graphics',
    'art/heads': 'NPC talking head animations',
    'art/backgrnd': 'Background images',
    'art/skilldex': 'Skilldex interface graphics',
    'data': 'Game data files',
    'maps': 'Map files',
    'proto': 'Prototype definitions',
    'proto/items': 'Item prototypes',
    'proto/critters': 'Creature prototypes',
    'proto/tiles': 'Tile prototypes',
    'proto/scenery': 'Scenery prototypes',
    'proto/walls': 'Wall prototypes',
    'proto/misc': 'Miscellaneous prototypes',
    'scripts': 'Compiled game scripts',
    'text': 'Text and localization files',
    'text/english': 'English language files',
    'text/english/game': 'Game text messages',
    'text/english/dialog': 'NPC dialog files',
    'text/english/cuts': 'Cutscene text',
    'sound': 'Audio files',
    'sound/music': 'Music tracks',
    'sound/sfx': 'Sound effects',
    'cuts': 'Cutscene videos',
}


@dataclass
class FileEntry:
    """Represents a file entry in the catalog."""
    path: str
    name: str
    extension: str
    size: int
    compressed_size: int
    is_compressed: bool
    file_type: str
    category: str
    description: str
    source_dat: str
    folder: str


@dataclass
class FolderStats:
    """Statistics for a folder."""
    path: str
    purpose: str
    file_count: int
    total_size: int
    compressed_size: int
    file_types: Dict[str, int] = field(default_factory=dict)
    extensions: Dict[str, int] = field(default_factory=dict)


@dataclass
class DATCatalog:
    """Complete catalog of a DAT file."""
    dat_name: str
    dat_path: str
    total_files: int
    total_size: int
    total_compressed_size: int
    files: List[FileEntry] = field(default_factory=list)
    folders: Dict[str, FolderStats] = field(default_factory=dict)
    file_types: Dict[str, int] = field(default_factory=dict)
    extensions: Dict[str, int] = field(default_factory=dict)
    categories: Dict[str, int] = field(default_factory=dict)


class DATCatalogAnalyzer:
    """Analyzes DAT files and generates comprehensive catalogs."""
    
    def __init__(self, fallout2_path: str):
        """
        Initialize the analyzer.
        
        Args:
            fallout2_path: Path to Fallout 2 installation directory
        """
        self.fallout2_path = Path(fallout2_path)
        self.dat_files = {
            'master.dat': self.fallout2_path / 'master.dat',
            'critter.dat': self.fallout2_path / 'critter.dat',
            'patch000.dat': self.fallout2_path / 'patch000.dat',
        }
        self.catalogs: Dict[str, DATCatalog] = {}
        
    def _get_file_type_info(self, extension: str) -> Dict[str, str]:
        """Get file type information based on extension."""
        ext_lower = extension.lower()
        if ext_lower in FILE_TYPE_DEFINITIONS:
            return FILE_TYPE_DEFINITIONS[ext_lower]
        return {
            'type': 'unknown',
            'category': 'unknown',
            'description': f'Unknown file type ({extension})'
        }
        
    def _get_folder_purpose(self, folder_path: str) -> str:
        """Get the purpose description for a folder."""
        # Normalize path
        normalized = folder_path.lower().replace('\\', '/')
        
        # Try exact match first
        if normalized in FOLDER_PURPOSES:
            return FOLDER_PURPOSES[normalized]
            
        # Try parent folders
        parts = normalized.split('/')
        for i in range(len(parts), 0, -1):
            partial = '/'.join(parts[:i])
            if partial in FOLDER_PURPOSES:
                return FOLDER_PURPOSES[partial]
                
        return 'Unknown purpose'
        
    def analyze_dat(self, dat_name: str) -> Optional[DATCatalog]:
        """
        Analyze a single DAT file and create its catalog.
        
        Args:
            dat_name: Name of the DAT file (e.g., 'master.dat')
            
        Returns:
            DATCatalog object or None if file doesn't exist
        """
        dat_path = self.dat_files.get(dat_name)
        if not dat_path or not dat_path.exists():
            print(f"DAT file not found: {dat_name}")
            return None
            
        print(f"Analyzing {dat_name}...")
        
        catalog = DATCatalog(
            dat_name=dat_name,
            dat_path=str(dat_path),
            total_files=0,
            total_size=0,
            total_compressed_size=0
        )
        
        folder_files: Dict[str, List[FileEntry]] = defaultdict(list)
        
        with DAT2Reader(str(dat_path)) as reader:
            files = reader.list_files()
            
            for file_path in files:
                info = reader.get_file_info(file_path)
                if not info:
                    continue
                    
                # Get file details
                path_obj = Path(file_path)
                extension = path_obj.suffix
                folder = str(path_obj.parent).replace('\\', '/')
                type_info = self._get_file_type_info(extension)
                
                # Create file entry
                entry = FileEntry(
                    path=file_path,
                    name=info.name,
                    extension=extension,
                    size=info.size,
                    compressed_size=info.compressed_size,
                    is_compressed=info.is_compressed,
                    file_type=type_info['type'],
                    category=type_info['category'],
                    description=type_info['description'],
                    source_dat=dat_name,
                    folder=folder
                )
                
                catalog.files.append(entry)
                folder_files[folder].append(entry)
                
                # Update statistics
                catalog.total_files += 1
                catalog.total_size += info.size
                catalog.total_compressed_size += info.compressed_size
                
                # Count by type
                catalog.file_types[type_info['type']] = catalog.file_types.get(type_info['type'], 0) + 1
                catalog.extensions[extension] = catalog.extensions.get(extension, 0) + 1
                catalog.categories[type_info['category']] = catalog.categories.get(type_info['category'], 0) + 1
        
        # Build folder statistics
        for folder_path, files in folder_files.items():
            folder_stats = FolderStats(
                path=folder_path,
                purpose=self._get_folder_purpose(folder_path),
                file_count=len(files),
                total_size=sum(f.size for f in files),
                compressed_size=sum(f.compressed_size for f in files)
            )
            
            for f in files:
                folder_stats.file_types[f.file_type] = folder_stats.file_types.get(f.file_type, 0) + 1
                folder_stats.extensions[f.extension] = folder_stats.extensions.get(f.extension, 0) + 1
                
            catalog.folders[folder_path] = folder_stats
            
        self.catalogs[dat_name] = catalog
        print(f"  Found {catalog.total_files} files in {len(catalog.folders)} folders")
        return catalog
        
    def analyze_all(self) -> Dict[str, DATCatalog]:
        """Analyze all DAT files."""
        for dat_name in self.dat_files.keys():
            self.analyze_dat(dat_name)
        return self.catalogs
        
    def generate_json_report(self, output_path: str) -> str:
        """
        Generate a JSON report of all catalogs.
        
        Args:
            output_path: Path to save the JSON report
            
        Returns:
            Path to the generated report
        """
        report = {
            'generated_at': datetime.now().isoformat(),
            'fallout2_path': str(self.fallout2_path),
            'summary': {
                'total_dat_files': len(self.catalogs),
                'total_files': sum(c.total_files for c in self.catalogs.values()),
                'total_size': sum(c.total_size for c in self.catalogs.values()),
                'total_compressed_size': sum(c.total_compressed_size for c in self.catalogs.values()),
            },
            'dat_files': {}
        }
        
        for dat_name, catalog in self.catalogs.items():
            report['dat_files'][dat_name] = {
                'path': catalog.dat_path,
                'total_files': catalog.total_files,
                'total_size': catalog.total_size,
                'total_compressed_size': catalog.total_compressed_size,
                'compression_ratio': round(catalog.total_compressed_size / catalog.total_size, 3) if catalog.total_size > 0 else 0,
                'file_types': catalog.file_types,
                'extensions': catalog.extensions,
                'categories': catalog.categories,
                'folders': {
                    path: {
                        'purpose': stats.purpose,
                        'file_count': stats.file_count,
                        'total_size': stats.total_size,
                        'file_types': stats.file_types,
                    }
                    for path, stats in catalog.folders.items()
                },
                'files': [
                    {
                        'path': f.path,
                        'size': f.size,
                        'compressed_size': f.compressed_size,
                        'is_compressed': f.is_compressed,
                        'type': f.file_type,
                        'category': f.category,
                    }
                    for f in catalog.files
                ]
            }
            
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
            
        print(f"JSON report saved to: {output_file}")
        return str(output_file)

    def generate_markdown_report(self, output_path: str) -> str:
        """
        Generate a Markdown documentation of the DAT structure.
        
        Args:
            output_path: Path to save the Markdown report
            
        Returns:
            Path to the generated report
        """
        lines = [
            "# Fallout 2 DAT File Structure Documentation",
            "",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "## Overview",
            "",
            "This document provides a comprehensive mapping of all files contained in the Fallout 2 DAT archives.",
            "",
            "### Summary",
            "",
            f"| DAT File | Files | Size | Compressed | Ratio |",
            f"|----------|-------|------|------------|-------|",
        ]
        
        total_files = 0
        total_size = 0
        total_compressed = 0
        
        for dat_name, catalog in sorted(self.catalogs.items()):
            ratio = catalog.total_compressed_size / catalog.total_size if catalog.total_size > 0 else 0
            lines.append(
                f"| {dat_name} | {catalog.total_files:,} | {self._format_size(catalog.total_size)} | "
                f"{self._format_size(catalog.total_compressed_size)} | {ratio:.1%} |"
            )
            total_files += catalog.total_files
            total_size += catalog.total_size
            total_compressed += catalog.total_compressed_size
            
        total_ratio = total_compressed / total_size if total_size > 0 else 0
        lines.append(
            f"| **Total** | **{total_files:,}** | **{self._format_size(total_size)}** | "
            f"**{self._format_size(total_compressed)}** | **{total_ratio:.1%}** |"
        )
        
        # File types summary
        lines.extend([
            "",
            "### File Types",
            "",
            "| Extension | Type | Category | Description | Count |",
            "|-----------|------|----------|-------------|-------|",
        ])
        
        all_extensions = defaultdict(int)
        for catalog in self.catalogs.values():
            for ext, count in catalog.extensions.items():
                all_extensions[ext] += count
                
        for ext, count in sorted(all_extensions.items(), key=lambda x: -x[1]):
            type_info = self._get_file_type_info(ext)
            lines.append(
                f"| {ext} | {type_info['type']} | {type_info['category']} | "
                f"{type_info['description']} | {count:,} |"
            )
            
        # Detailed DAT documentation
        for dat_name, catalog in sorted(self.catalogs.items()):
            lines.extend([
                "",
                f"## {dat_name}",
                "",
                f"- **Total Files**: {catalog.total_files:,}",
                f"- **Total Size**: {self._format_size(catalog.total_size)}",
                f"- **Compressed Size**: {self._format_size(catalog.total_compressed_size)}",
                "",
                "### Folder Structure",
                "",
            ])
            
            # Group folders by top-level
            top_level_folders = defaultdict(list)
            for folder_path, stats in sorted(catalog.folders.items()):
                parts = folder_path.split('/')
                top_level = parts[0] if parts else 'root'
                top_level_folders[top_level].append((folder_path, stats))
                
            for top_level, folders in sorted(top_level_folders.items()):
                lines.append(f"#### {top_level}/")
                lines.append("")
                lines.append("| Folder | Purpose | Files | Size |")
                lines.append("|--------|---------|-------|------|")
                
                for folder_path, stats in folders:
                    lines.append(
                        f"| `{folder_path}` | {stats.purpose} | {stats.file_count:,} | "
                        f"{self._format_size(stats.total_size)} |"
                    )
                lines.append("")
                
            # Categories breakdown
            lines.extend([
                "### Categories Breakdown",
                "",
                "| Category | File Count |",
                "|----------|------------|",
            ])
            
            for category, count in sorted(catalog.categories.items(), key=lambda x: -x[1]):
                lines.append(f"| {category} | {count:,} |")
                
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
            
        print(f"Markdown report saved to: {output_file}")
        return str(output_file)
        
    def _format_size(self, size_bytes: int) -> str:
        """Format size in human-readable format."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.1f} TB"
        
    def get_all_files_by_type(self, file_type: str) -> List[FileEntry]:
        """Get all files of a specific type across all DATs."""
        files = []
        for catalog in self.catalogs.values():
            files.extend([f for f in catalog.files if f.file_type == file_type])
        return files
        
    def get_all_files_by_category(self, category: str) -> List[FileEntry]:
        """Get all files of a specific category across all DATs."""
        files = []
        for catalog in self.catalogs.values():
            files.extend([f for f in catalog.files if f.category == category])
        return files
        
    def get_all_files_in_folder(self, folder_pattern: str) -> List[FileEntry]:
        """Get all files matching a folder pattern across all DATs."""
        files = []
        for catalog in self.catalogs.values():
            files.extend([f for f in catalog.files if folder_pattern.lower() in f.folder.lower()])
        return files


def main():
    """Main entry point for DAT catalog analysis."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Analyze Fallout 2 DAT files')
    parser.add_argument('--fallout2-path', default='Fallout 2',
                        help='Path to Fallout 2 installation')
    parser.add_argument('--output-dir', default='analysis/dat_catalog',
                        help='Output directory for reports')
    parser.add_argument('--json', action='store_true', default=True,
                        help='Generate JSON report')
    parser.add_argument('--markdown', action='store_true', default=True,
                        help='Generate Markdown report')
    
    args = parser.parse_args()
    
    analyzer = DATCatalogAnalyzer(args.fallout2_path)
    analyzer.analyze_all()
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if args.json:
        analyzer.generate_json_report(str(output_dir / 'dat_catalog.json'))
        
    if args.markdown:
        analyzer.generate_markdown_report(str(output_dir / 'DAT_STRUCTURE.md'))
        
    print("\nAnalysis complete!")
    print(f"Reports saved to: {output_dir}")


if __name__ == '__main__':
    main()
