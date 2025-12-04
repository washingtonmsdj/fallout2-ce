"""
Configuração de testes e fixtures base para o sistema de extração de assets.

Este arquivo contém fixtures compartilhadas e configurações do pytest/hypothesis.
"""
import pytest
from pathlib import Path
import tempfile
import shutil


@pytest.fixture
def temp_dir():
    """Cria um diretório temporário para testes e limpa após o teste."""
    temp_path = Path(tempfile.mkdtemp())
    yield temp_path
    shutil.rmtree(temp_path, ignore_errors=True)


@pytest.fixture
def sample_dat2_path():
    """Retorna o caminho para um arquivo DAT2 de exemplo (se disponível)."""
    # Por enquanto retorna None, será implementado quando tivermos arquivos de teste
    return None


@pytest.fixture
def sample_frm_path():
    """Retorna o caminho para um arquivo FRM de exemplo (se disponível)."""
    # Por enquanto retorna None, será implementado quando tivermos arquivos de teste
    return None


@pytest.fixture
def sample_pal_path():
    """Retorna o caminho para um arquivo PAL de exemplo (se disponível)."""
    # Por enquanto retorna None, será implementado quando tivermos arquivos de teste
    return None

