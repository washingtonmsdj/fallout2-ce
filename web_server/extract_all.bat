@echo off
echo ========================================
echo Extrator Completo de Arquivos .DAT
echo Fallout 2 - Extrai TODOS os arquivos
echo ========================================
echo.
echo Isso vai extrair TODOS os arquivos dos .DAT
echo Pode levar varios minutos e ocupar bastante espaco!
echo.
pause

cd /d "%~dp0"
python extract_all_dat.py

pause

