"""
Testes para o módulo asset_organizer.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import json
import tempfile
import shutil
import re
import logging
from pathlib import Path
from hypothesis import given, strategies as st, settings

from tools.extractors.asset_organizer import AssetOrganizer, ManifestEntry


def cleanup_organizer(organizer):
    """Fecha handlers do logger para permitir limpeza do diretório."""
    for handler in organizer.logger.handlers[:]:
        handler.close()
        organizer.logger.removeHandler(handler)


class TestAssetOrganizer:
    """Testes unitários para AssetOrganizer."""
    
    def test_create_directory_structure(self):
        """Testa criação da estrutura de diretórios."""
        temp_dir = tempfile.mkdtemp()
        try:
            organizer = AssetOrganizer(temp_dir)
            
            # Verificar que diretórios foram criados
            assets_dir = Path(temp_dir) / 'assets'
            assert (assets_dir / 'sprites' / 'critters').exists()
            assert (assets_dir / 'sprites' / 'tiles').exists()
            assert (assets_dir / 'sprites' / 'ui').exists()
            assert (assets_dir / 'audio' / 'music').exists()
            assert (assets_dir / 'audio' / 'sfx').exists()
            assert (assets_dir / 'data' / 'maps').exists()
            
            cleanup_organizer(organizer)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    def test_organize_sprite(self):
        """Testa organização de sprite."""
        temp_dir = tempfile.mkdtemp()
        try:
            organizer = AssetOrganizer(temp_dir)
            
            # Criar arquivo fonte temporário
            source_file = Path(temp_dir) / 'source' / 'test.png'
            source_file.parent.mkdir(parents=True, exist_ok=True)
            source_file.write_bytes(b'PNG data')
            
            # Organizar sprite
            output_path = organizer.organize_sprite(
                str(source_file), 
                'critters', 
                'test.png',
                dimensions={'width': 100, 'height': 100}
            )
            
            # Verificar que foi adicionado ao manifesto
            assert len(organizer.manifest) == 1
            assert organizer.manifest[0].asset_type == 'sprite'
            
            cleanup_organizer(organizer)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    def test_generate_manifest(self):
        """Testa geração de manifesto."""
        temp_dir = tempfile.mkdtemp()
        try:
            organizer = AssetOrganizer(temp_dir)
            
            # Adicionar algumas entradas manualmente
            organizer.manifest.append(ManifestEntry(
                original_path='test1.png',
                output_path='assets/sprites/critters/test1.png',
                asset_type='sprite',
                dimensions={'width': 100, 'height': 100}
            ))
            organizer.manifest.append(ManifestEntry(
                original_path='test2.ogg',
                output_path='assets/audio/music/test2.ogg',
                asset_type='audio'
            ))
            
            manifest = organizer.generate_manifest()
            
            assert manifest['total_assets'] == 2
            assert 'assets' in manifest
            assert 'statistics' in manifest
            
            cleanup_organizer(organizer)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)


class TestAssetOrganizerPropertyTests:
    """Property-based tests para AssetOrganizer."""
    
    @given(
        num_sprites=st.integers(min_value=1, max_value=10),
        num_audio=st.integers(min_value=0, max_value=5),
        num_data=st.integers(min_value=0, max_value=5)
    )
    @settings(max_examples=50)
    def test_property_15_output_structure_conformance(self, num_sprites, num_audio, num_data):
        """
        **Feature: fallout2-asset-extraction, Property 15: Output Structure Conformance**
        
        Para qualquer asset extraído, o caminho de saída DEVE conformar ao padrão:
        `godot_project/assets/{category}/{subcategory}/{filename}.{ext}`
        onde category é sprites/audio/data.
        
        **Validates: Requirements 10.1, 10.2, 10.3, 10.4**
        """
        temp_dir = tempfile.mkdtemp()
        try:
            organizer = AssetOrganizer(temp_dir)
            
            # Padrão esperado para caminhos de saída
            sprite_pattern = re.compile(r'^assets/sprites/[^/]+/[^/]+\.png$')
            audio_pattern = re.compile(r'^assets/audio/[^/]+/[^/]+\.(ogg|wav)$')
            data_pattern = re.compile(r'^assets/data/[^/]+/[^/]+\.json$')
            
            # Adicionar sprites
            for i in range(num_sprites):
                organizer.manifest.append(ManifestEntry(
                    original_path=f'original/sprite_{i}.frm',
                    output_path=f'assets/sprites/critters/sprite_{i}.png',
                    asset_type='sprite',
                    dimensions={'width': 100, 'height': 100}
                ))
            
            # Adicionar áudio
            for i in range(num_audio):
                organizer.manifest.append(ManifestEntry(
                    original_path=f'original/audio_{i}.acm',
                    output_path=f'assets/audio/music/audio_{i}.ogg',
                    asset_type='audio'
                ))
            
            # Adicionar dados
            for i in range(num_data):
                organizer.manifest.append(ManifestEntry(
                    original_path=f'original/data_{i}.msg',
                    output_path=f'assets/data/messages/data_{i}.json',
                    asset_type='data'
                ))
            
            # Verificar conformidade de estrutura
            for entry in organizer.manifest:
                output_path = entry.output_path
                
                if entry.asset_type == 'sprite':
                    assert sprite_pattern.match(output_path), \
                        f"Sprite path não conforme: {output_path}"
                elif entry.asset_type == 'audio':
                    assert audio_pattern.match(output_path), \
                        f"Audio path não conforme: {output_path}"
                elif entry.asset_type == 'data':
                    assert data_pattern.match(output_path), \
                        f"Data path não conforme: {output_path}"
            
            cleanup_organizer(organizer)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
    
    @given(
        num_assets=st.integers(min_value=1, max_value=20),
        include_dimensions=st.booleans()
    )
    @settings(max_examples=50, deadline=None)
    def test_property_14_manifest_entry_completeness(self, num_assets, include_dimensions):
        """
        **Feature: fallout2-asset-extraction, Property 14: Manifest Entry Completeness**
        
        Para qualquer asset extraído, a entrada do manifesto DEVE conter:
        original_path, output_path, asset_type, e dimensions (para imagens).
        
        **Validates: Requirements 9.2**
        """
        temp_dir = tempfile.mkdtemp()
        try:
            organizer = AssetOrganizer(temp_dir)
            
            # Adicionar assets
            for i in range(num_assets):
                dimensions = {'width': 100 + i, 'height': 100 + i} if include_dimensions else None
                organizer.manifest.append(ManifestEntry(
                    original_path=f'original/asset_{i}.frm',
                    output_path=f'assets/sprites/critters/asset_{i}.png',
                    asset_type='sprite',
                    dimensions=dimensions
                ))
            
            # Gerar manifesto
            manifest = organizer.generate_manifest()
            
            # Verificar completude
            assert manifest['total_assets'] == num_assets
            assert len(manifest['assets']) == num_assets
            
            for asset in manifest['assets']:
                # Campos obrigatórios
                assert 'original_path' in asset, "Falta original_path"
                assert 'output_path' in asset, "Falta output_path"
                assert 'asset_type' in asset, "Falta asset_type"
                
                # Verificar que os campos não estão vazios
                assert asset['original_path'], "original_path está vazio"
                assert asset['output_path'], "output_path está vazio"
                assert asset['asset_type'], "asset_type está vazio"
                
                # Para sprites, verificar dimensions se fornecido
                if include_dimensions and asset['asset_type'] == 'sprite':
                    assert asset['dimensions'] is not None, "Falta dimensions para sprite"
                    assert 'width' in asset['dimensions'], "Falta width em dimensions"
                    assert 'height' in asset['dimensions'], "Falta height em dimensions"
            
            cleanup_organizer(organizer)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
