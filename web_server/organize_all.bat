@echo off
echo ========================================
echo Extrator e Organizador COMPLETO
echo Fallout 2 - Extrai e Organiza TUDO
echo ========================================
echo.
echo Isso vai:
echo   1. Extrair TODOS os arquivos dos .DAT
echo   2. Organizar em estrutura logica
echo   3. Criar indices para facilitar acesso
echo.
echo Pode levar varios minutos!
echo.
pause

cd /d "%~dp0"
python extract_and_organize_all.py

pause

