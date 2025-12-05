@echo off
echo Iniciando movimentacao de assets Fallout 2...

set "SOURCE_DIR=%~dp0godot_project\assets"
set "BACKUP_DIR=%~dp0_fallout2_assets_backup"

echo Criando diretorio de backup...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Movendo pasta audio...
if exist "%SOURCE_DIR%\audio" (
    move "%SOURCE_DIR%\audio" "%BACKUP_DIR%\audio"
    echo Pasta audio movida com sucesso
) else (
    echo Pasta audio nao encontrada
)

echo Movendo pasta misc...
if exist "%SOURCE_DIR%\misc" (
    move "%SOURCE_DIR%\misc" "%BACKUP_DIR%\misc"
    echo Pasta misc movida com sucesso
) else (
    echo Pasta misc nao encontrada
)

echo Movendo pasta palettes...
if exist "%SOURCE_DIR%\palettes" (
    move "%SOURCE_DIR%\palettes" "%BACKUP_DIR%\palettes"
    echo Pasta palettes movida com sucesso
) else (
    echo Pasta palettes nao encontrada
)

echo Movendo pasta scripts...
if exist "%SOURCE_DIR%\scripts" (
    move "%SOURCE_DIR%\scripts" "%BACKUP_DIR%\scripts"
    echo Pasta scripts movida com sucesso
) else (
    echo Pasta scripts nao encontrada
)

echo Verificando arquivos restantes...
dir "%SOURCE_DIR%" /b | findstr /r ".*\.(acm|ACM|frm|FRM|pal|PAL|int|INT)$"
if %errorlevel% equ 0 (
    echo AVISO: Ainda ha arquivos problematicos na pasta assets!
) else (
    echo Sucesso: Nenhum arquivo problematico restante!
)

echo.
echo Assets Fallout 2 movidos para: %BACKUP_DIR%
echo Para recupera-los, mova as pastas de volta para godot_project\assets\
echo.
pause