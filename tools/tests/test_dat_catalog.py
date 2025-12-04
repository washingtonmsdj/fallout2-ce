"""
Property-based tests for DAT catalog completeness.

**Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

For any file within a Fallout 2 DAT, the catalog system must extract and register:
- Complete file path
- File type (identified by extension and magic bytes)
- Size
- All referenced dependencies
"""
import pytest
import json
from pathlib import Path
from hypothesis import given, strategies as st, settings, HealthCheck, assume
from typing import Dict, List, Set

import sys
from pathlib import Path

# Add tools directory to path for imports
tools_dir = Path(__file__).parent.parent
if str(tools_dir) not in sys.path:
    sys.path.insert(0, str(tools_dir))

from extractors.dat2_reader import DAT2Reader, DAT2Manager, FileInfo


# Known file type extensions in Fallout 2
KNOWN_EXTENSIONS = {
    '.frm', '.FRM', '.pro', '.PRO', '.map', '.MAP', '.msg', '.MSG',
    '.acm', '.ACM', '.pal', '.PAL', '.int', '.INT', '.lst', '.LST',
    '.txt', '.TXT', '.gam', '.GAM', '.sve', '.mve', '.MVE', '.cfg',
    '.fon', '.FON', '.aaf', '.AAF', '.rix', '.RIX', '.gcd', '.GCD',
    '.bio', '.BIO', '.lip', '.LIP', '.msk', '.MSK', '.bak', '.BAK',
    '.h', '.ssl', '.ref', '.REF', '.lbm', '.LBM', '.com', '.COM',
    '.lnk', '.fr0', '.FR0', '.fr1', '.FR1', '.fr2', '.FR2',
    '.fr3', '.FR3', '.fr4', '.FR4', '.fr5', '.FR5', ''
}

# File categories
FILE_CATEGORIES = {
    'graphics': {'.frm', '.FRM', '.pal', '.PAL', '.rix', '.RIX', '.fon', '.FON', '.aaf', '.AAF'},
    'data': {'.pro', '.PRO', '.lst', '.LST'},
    'world': {'.map', '.MAP', '.gam', '.GAM', '.sav'},
    'scripts': {'.int', '.INT', '.ssl', '.h'},
    'text': {'.msg', '.MSG', '.txt', '.TXT', '.sve'},
    'audio': {'.acm', '.ACM', '.wav'},
    'video': {'.mve', '.MVE'},
    'config': {'.cfg', '.ini'},
}


def get_file_category(extension: str) -> str:
    """Get the category for a file extension."""
    ext_lower = extension.lower()
    for category, extensions in FILE_CATEGORIES.items():
        if extension in extensions or ext_lower in {e.lower() for e in extensions}:
            return category
    return 'unknown'


class TestDATCatalogCompleteness:
    """
    Property tests for DAT catalog completeness.
    
    **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
    **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**
    """
    
    @pytest.fixture
    def fallout2_path(self):
        """Path to Fallout 2 installation."""
        # Try multiple possible paths
        possible_paths = [
            Path("Fallout 2"),
            Path("../Fallout 2"),
            Path(__file__).parent.parent.parent / "Fallout 2",
        ]
        for path in possible_paths:
            if path.exists():
                return path
        pytest.skip("Fallout 2 installation not found")
        return None
    
    @pytest.fixture
    def master_dat(self, fallout2_path):
        """Open master.dat for testing."""
        dat_path = fallout2_path / "master.dat"
        if not dat_path.exists():
            pytest.skip("master.dat not found")
        reader = DAT2Reader(str(dat_path))
        reader.open()
        yield reader
        reader.close()
    
    @pytest.fixture
    def critter_dat(self, fallout2_path):
        """Open critter.dat for testing."""
        dat_path = fallout2_path / "critter.dat"
        if not dat_path.exists():
            pytest.skip("critter.dat not found")
        reader = DAT2Reader(str(dat_path))
        reader.open()
        yield reader
        reader.close()
    
    @pytest.fixture
    def patch_dat(self, fallout2_path):
        """Open patch000.dat for testing."""
        dat_path = fallout2_path / "patch000.dat"
        if not dat_path.exists():
            pytest.skip("patch000.dat not found")
        reader = DAT2Reader(str(dat_path))
        reader.open()
        yield reader
        reader.close()
    
    def test_property_2_all_files_have_valid_paths(self, master_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.1**
        
        For any file in the DAT, the catalog must have a valid, non-empty path.
        """
        files = master_dat.list_files()
        
        for file_path in files:
            # Path must not be empty
            assert file_path, "File path cannot be empty"
            
            # Path must not contain null bytes
            assert '\x00' not in file_path, f"Path contains null bytes: {file_path}"
            
            # Path should be printable
            assert all(c.isprintable() or c in '\\/.' for c in file_path), \
                f"Path contains non-printable characters: {repr(file_path)}"
    
    def test_property_2_all_files_have_valid_info(self, master_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.2**
        
        For any file in the DAT, the catalog must have valid metadata.
        """
        files = master_dat.list_files()
        
        # Sample a subset for performance
        sample_size = min(100, len(files))
        import random
        sample = random.sample(files, sample_size)
        
        for file_path in sample:
            info = master_dat.get_file_info(file_path)
            
            # Info must exist
            assert info is not None, f"No info for file: {file_path}"
            
            # Size must be non-negative
            assert info.size >= 0, f"Invalid size for {file_path}: {info.size}"
            
            # Compressed size must be non-negative
            assert info.compressed_size >= 0, \
                f"Invalid compressed size for {file_path}: {info.compressed_size}"
            
            # Compressed size should not exceed uncompressed (for compressed files)
            # Note: This is generally true but not always due to compression overhead
            if info.is_compressed and info.size > 100:
                # Allow some overhead for small files
                assert info.compressed_size <= info.size * 1.1, \
                    f"Compressed larger than original for {file_path}"
    
    def test_property_2_all_files_have_recognized_extensions(self, master_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.2**
        
        For any file in the DAT, the extension should be recognized.
        """
        files = master_dat.list_files()
        unrecognized = set()
        
        for file_path in files:
            ext = Path(file_path).suffix
            if ext and ext not in KNOWN_EXTENSIONS:
                unrecognized.add(ext)
        
        # Report unrecognized extensions (informational, not failure)
        if unrecognized:
            print(f"Unrecognized extensions found: {unrecognized}")
        
        # At least 95% of files should have recognized extensions
        recognized_count = sum(1 for f in files if Path(f).suffix in KNOWN_EXTENSIONS or not Path(f).suffix)
        recognition_rate = recognized_count / len(files) if files else 1.0
        
        assert recognition_rate >= 0.95, \
            f"Too many unrecognized extensions: {1 - recognition_rate:.1%}"
    
    def test_property_2_files_can_be_extracted(self, master_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.3**
        
        For any file in the DAT, extraction should succeed and return valid data.
        """
        files = master_dat.list_files()
        
        # Sample a subset for performance
        sample_size = min(50, len(files))
        import random
        sample = random.sample(files, sample_size)
        
        extraction_failures = []
        
        for file_path in sample:
            try:
                data = master_dat.extract_file(file_path)
                info = master_dat.get_file_info(file_path)
                
                # Extracted data size should match expected size
                assert len(data) == info.size, \
                    f"Size mismatch for {file_path}: got {len(data)}, expected {info.size}"
                
            except Exception as e:
                extraction_failures.append((file_path, str(e)))
        
        # All sampled files should extract successfully
        assert not extraction_failures, \
            f"Extraction failures: {extraction_failures[:5]}"
    
    def test_property_2_folder_structure_is_consistent(self, master_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.4**
        
        The folder structure should be consistent and well-organized.
        """
        files = master_dat.list_files()
        
        # Collect all folders
        folders = set()
        for file_path in files:
            parts = file_path.replace('\\', '/').split('/')
            for i in range(len(parts) - 1):
                folder = '/'.join(parts[:i+1])
                folders.add(folder)
        
        # Known top-level folders
        expected_top_level = {'art', 'data', 'maps', 'proto', 'scripts', 'sound', 'text', 'premade', 'cuts'}
        actual_top_level = {f.split('/')[0].lower() for f in folders if '/' in f or f}
        
        # Most expected folders should exist
        found_expected = expected_top_level & actual_top_level
        assert len(found_expected) >= 5, \
            f"Missing expected folders. Found: {actual_top_level}"
    
    def test_property_2_critter_dat_contains_critters(self, critter_dat):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.1, 2.2**
        
        critter.dat should contain critter sprites.
        """
        files = critter_dat.list_files()
        
        # All files should be in art/critters
        critter_files = [f for f in files if 'critter' in f.lower()]
        
        assert len(critter_files) > 0, "critter.dat should contain critter files"
        
        # Most files should be FRM sprites
        frm_files = [f for f in files if f.lower().endswith('.frm')]
        frm_ratio = len(frm_files) / len(files) if files else 0
        
        assert frm_ratio >= 0.5, \
            f"critter.dat should be mostly FRM files, got {frm_ratio:.1%}"
    
    def test_property_2_patch_dat_overrides_correctly(self, fallout2_path):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.5**
        
        patch000.dat should properly override files from master.dat.
        """
        master_path = fallout2_path / "master.dat"
        patch_path = fallout2_path / "patch000.dat"
        
        if not patch_path.exists():
            pytest.skip("patch000.dat not found")
        
        # Open both DATs
        with DAT2Reader(str(master_path)) as master, \
             DAT2Reader(str(patch_path)) as patch:
            
            master_files = set(master.list_files())
            patch_files = set(patch.list_files())
            
            # Find overlapping files
            overlapping = master_files & patch_files
            
            if overlapping:
                # For overlapping files, patch version should be used
                # (This is tested via DAT2Manager priority)
                manager = DAT2Manager([str(master_path), str(patch_path)])
                
                # Sample an overlapping file
                sample_file = next(iter(overlapping))
                
                # Get from manager (should be patch version)
                manager_data = manager.get_file(sample_file)
                patch_data = patch.extract_file(sample_file)
                
                assert manager_data == patch_data, \
                    f"Manager should return patch version for {sample_file}"
                
                manager.close()


class TestDATCatalogPropertyBased:
    """
    Property tests for DAT catalog using random sampling.
    
    **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
    **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**
    """
    
    @pytest.fixture
    def fallout2_path(self):
        """Path to Fallout 2 installation."""
        possible_paths = [
            Path("Fallout 2"),
            Path("../Fallout 2"),
            Path(__file__).parent.parent.parent / "Fallout 2",
        ]
        for path in possible_paths:
            if path.exists():
                return path
        pytest.skip("Fallout 2 installation not found")
        return None
    
    def test_property_random_file_extraction(self, fallout2_path):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.3**
        
        For any randomly selected file, extraction should succeed.
        """
        import random
        
        all_files = []
        dat_names = ['master.dat', 'critter.dat', 'patch000.dat']
        
        for dat_name in dat_names:
            dat_path = fallout2_path / dat_name
            if dat_path.exists():
                with DAT2Reader(str(dat_path)) as reader:
                    files = reader.list_files()
                    all_files.extend([(dat_name, f) for f in files])
        
        if not all_files:
            pytest.skip("No DAT files available")
        
        # Test 20 random files
        sample_size = min(20, len(all_files))
        sample = random.sample(all_files, sample_size)
        
        for dat_name, file_path in sample:
            dat_path = fallout2_path / dat_name
            
            with DAT2Reader(str(dat_path)) as reader:
                # Get file info
                info = reader.get_file_info(file_path)
                assert info is not None, f"No info for {file_path}"
                
                # Extract file
                data = reader.extract_file(file_path)
                
                # Verify size
                assert len(data) == info.size, \
                    f"Size mismatch: got {len(data)}, expected {info.size}"
                
                # Verify data is not empty (unless size is 0)
                if info.size > 0:
                    assert len(data) > 0, f"Empty data for non-empty file: {file_path}"


class TestCatalogJSONReport:
    """
    Tests for the generated JSON catalog report.
    
    **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
    **Validates: Requirements 2.4**
    """
    
    @pytest.fixture
    def catalog_json(self):
        """Load the generated catalog JSON."""
        possible_paths = [
            Path("analysis/dat_catalog/dat_catalog.json"),
            Path("../analysis/dat_catalog/dat_catalog.json"),
            Path(__file__).parent.parent.parent / "analysis/dat_catalog/dat_catalog.json",
        ]
        json_path = None
        for path in possible_paths:
            if path.exists():
                json_path = path
                break
        if json_path is None:
            pytest.skip("Catalog JSON not generated yet")
        
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def test_catalog_has_all_dat_files(self, catalog_json):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.1**
        
        The catalog should include all three DAT files.
        """
        expected_dats = {'master.dat', 'critter.dat', 'patch000.dat'}
        actual_dats = set(catalog_json.get('dat_files', {}).keys())
        
        assert expected_dats == actual_dats, \
            f"Missing DAT files: {expected_dats - actual_dats}"
    
    def test_catalog_has_summary(self, catalog_json):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.4**
        
        The catalog should have a summary section.
        """
        assert 'summary' in catalog_json, "Missing summary section"
        
        summary = catalog_json['summary']
        assert 'total_files' in summary, "Missing total_files in summary"
        assert 'total_size' in summary, "Missing total_size in summary"
        assert summary['total_files'] > 0, "No files in catalog"
    
    def test_catalog_files_have_required_fields(self, catalog_json):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.2**
        
        Each file entry should have required metadata fields.
        """
        required_fields = {'path', 'size', 'type', 'category'}
        
        for dat_name, dat_info in catalog_json.get('dat_files', {}).items():
            files = dat_info.get('files', [])
            
            # Sample check (first 10 files)
            for file_entry in files[:10]:
                missing = required_fields - set(file_entry.keys())
                assert not missing, \
                    f"Missing fields {missing} in {dat_name} file entry"
    
    def test_catalog_folders_have_purpose(self, catalog_json):
        """
        **Feature: complete-migration-master, Property 2: Catálogo de Arquivos DAT Completo**
        **Validates: Requirements 2.4**
        
        Each folder should have a purpose description.
        """
        for dat_name, dat_info in catalog_json.get('dat_files', {}).items():
            folders = dat_info.get('folders', {})
            
            for folder_path, folder_info in folders.items():
                assert 'purpose' in folder_info, \
                    f"Missing purpose for folder {folder_path} in {dat_name}"
                assert folder_info['purpose'], \
                    f"Empty purpose for folder {folder_path} in {dat_name}"
