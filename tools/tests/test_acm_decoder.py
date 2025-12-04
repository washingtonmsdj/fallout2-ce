"""
Testes para o módulo acm_decoder.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import tempfile
import os
from pathlib import Path
from hypothesis import given, strategies as st, settings

from tools.extractors.acm_decoder import ACMDecoder


class TestACMDecoder:
    """Testes unitários para ACMDecoder."""
    
    def test_detect_audio_type_music(self):
        """Testa detecção de tipo música."""
        decoder = ACMDecoder(use_ffmpeg=False)
        
        assert decoder._detect_audio_type('sound/music/track01.acm') == 'music'
        assert decoder._detect_audio_type('MUSIC/ambient.acm') == 'music'
    
    def test_detect_audio_type_voice(self):
        """Testa detecção de tipo voz."""
        decoder = ACMDecoder(use_ffmpeg=False)
        
        assert decoder._detect_audio_type('sound/voice/dialog.acm') == 'voice'
        assert decoder._detect_audio_type('VOICE/npc01.acm') == 'voice'
    
    def test_detect_audio_type_sfx(self):
        """Testa detecção de tipo efeito sonoro."""
        decoder = ACMDecoder(use_ffmpeg=False)
        
        assert decoder._detect_audio_type('sound/sfx/explosion.acm') == 'sfx'
        assert decoder._detect_audio_type('sound/gunshot.acm') == 'sfx'
    
    def test_organize_audio_creates_path(self):
        """Testa que organize_audio cria caminho correto."""
        decoder = ACMDecoder(use_ffmpeg=False)
        
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = decoder.organize_audio(
                'sound/music/track01.acm',
                temp_dir,
                audio_type='music'
            )
            
            assert 'audio' in output_path
            assert 'music' in output_path
            assert output_path.endswith('.ogg')


class TestACMPropertyTests:
    """Property-based tests para ACMDecoder."""
    
    @given(
        path=st.sampled_from([
            'sound/music/track01.acm',
            'sound/music/ambient.acm',
            'MUSIC/battle.acm',
            'sound/voice/dialog01.acm',
            'sound/voice/npc.acm',
            'VOICE/player.acm',
            'sound/sfx/explosion.acm',
            'sound/gunshot.acm',
            'sound/footstep.acm'
        ])
    )
    @settings(max_examples=50)
    def test_property_11_audio_type_detection(self, path):
        """
        **Feature: fallout2-asset-extraction, Property 11: Audio Format Conversion**
        
        Para qualquer arquivo de áudio ACM, o conversor DEVE detectar corretamente
        o tipo de áudio (music, sfx, voice) baseado no caminho.
        
        **Validates: Requirements 6.1**
        
        Nota: Este teste verifica a detecção de tipo. A conversão real depende
        de ferramentas externas (ffmpeg).
        """
        decoder = ACMDecoder(use_ffmpeg=False)
        
        audio_type = decoder._detect_audio_type(path)
        
        # Verificar que o tipo é válido
        assert audio_type in ['music', 'sfx', 'voice'], \
            f"Tipo de áudio inválido: {audio_type}"
        
        # Verificar consistência com o caminho
        path_lower = path.lower()
        if 'music' in path_lower:
            assert audio_type == 'music', \
                f"Caminho com 'music' deveria ser tipo 'music', não '{audio_type}'"
        elif 'voice' in path_lower:
            assert audio_type == 'voice', \
                f"Caminho com 'voice' deveria ser tipo 'voice', não '{audio_type}'"
    
    @given(
        filename=st.text(min_size=1, max_size=20, alphabet=st.characters(min_codepoint=97, max_codepoint=122)),
        audio_type=st.sampled_from(['music', 'sfx', 'voice'])
    )
    @settings(max_examples=50)
    def test_property_11_audio_organization(self, filename, audio_type):
        """
        **Feature: fallout2-asset-extraction, Property 11: Audio Organization**
        
        Para qualquer arquivo de áudio, o organizador DEVE criar um caminho de saída
        que segue a estrutura: audio/{tipo}/{arquivo}.ogg
        
        **Validates: Requirements 6.1, 6.2**
        """
        decoder = ACMDecoder(use_ffmpeg=False)
        
        with tempfile.TemporaryDirectory() as temp_dir:
            acm_path = f'sound/{audio_type}/{filename}.acm'
            output_path = decoder.organize_audio(acm_path, temp_dir, audio_type=audio_type)
            
            # Verificar estrutura do caminho
            assert 'audio' in output_path, "Caminho deve conter 'audio'"
            assert audio_type in output_path, f"Caminho deve conter '{audio_type}'"
            assert output_path.endswith('.ogg'), "Arquivo deve ter extensão .ogg"
            
            # Verificar que o diretório foi criado
            output_dir = Path(output_path).parent
            assert output_dir.exists(), f"Diretório {output_dir} não foi criado"
    
    @given(
        num_files=st.integers(min_value=1, max_value=10)
    )
    @settings(max_examples=30)
    def test_property_11_multiple_audio_organization(self, num_files):
        """
        **Feature: fallout2-asset-extraction, Property 11: Multiple Audio Files**
        
        Para múltiplos arquivos de áudio, cada um DEVE ser organizado em seu
        diretório correto baseado no tipo.
        
        **Validates: Requirements 6.1, 6.2**
        """
        decoder = ACMDecoder(use_ffmpeg=False)
        
        audio_types = ['music', 'sfx', 'voice']
        
        with tempfile.TemporaryDirectory() as temp_dir:
            organized_paths = []
            
            for i in range(num_files):
                audio_type = audio_types[i % len(audio_types)]
                acm_path = f'sound/{audio_type}/file_{i}.acm'
                output_path = decoder.organize_audio(acm_path, temp_dir, audio_type=audio_type)
                organized_paths.append((output_path, audio_type))
            
            # Verificar que todos os caminhos são únicos
            paths_only = [p[0] for p in organized_paths]
            assert len(paths_only) == len(set(paths_only)), \
                "Caminhos de saída devem ser únicos"
            
            # Verificar que cada caminho está no diretório correto
            for output_path, expected_type in organized_paths:
                assert expected_type in output_path, \
                    f"Arquivo deveria estar em diretório '{expected_type}': {output_path}"
