@echo off
REM Script para compilar Fallout 2 para WebAssembly (Windows)
REM 
REM PRÉ-REQUISITOS:
REM   1. Emscripten instalado e ativado
REM   2. CMake instalado
REM   3. Assets do Fallout 2 na pasta "Fallout 2\"

echo ==========================================
echo Compilando Fallout 2 para WebAssembly
echo ==========================================
echo.

REM Verificar se Emscripten está instalado
where emcc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Emscripten nao encontrado!
    echo Instale em: https://emscripten.org/docs/getting_started/downloads.html
    pause
    exit /b 1
)

echo Emscripten encontrado!
echo.

REM Diretórios
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%.."
set PROJECT_ROOT=%CD%
set BUILD_DIR=%PROJECT_ROOT%\build-web
set FALLOUT_DIR=%PROJECT_ROOT%\Fallout 2

REM Verificar se os assets existem
if not exist "%FALLOUT_DIR%" (
    echo AVISO: Pasta 'Fallout 2' nao encontrada!
    echo Certifique-se de que os assets do jogo estao em: %FALLOUT_DIR%
    pause
)

REM Criar diretório de build
echo.
echo Criando diretorio de build...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd "%BUILD_DIR%"

REM Configurar CMake
echo.
echo Configurando CMake...
call emcmake cmake "%PROJECT_ROOT%" -DCMAKE_BUILD_TYPE=Release -DFALLOUT_VENDORED=OFF
if %ERRORLEVEL% NEQ 0 (
    echo ERRO na configuracao do CMake!
    pause
    exit /b 1
)

REM Compilar
echo.
echo Compilando (isso pode levar varios minutos)...
call emmake make -j4
if %ERRORLEVEL% NEQ 0 (
    echo ERRO na compilacao!
    pause
    exit /b 1
)

REM Verificar se compilou
if exist "fallout2-ce.html" (
    echo.
    echo ==========================================
    echo Compilacao concluida com sucesso!
    echo ==========================================
    echo.
    echo Arquivos gerados em: %BUILD_DIR%
    echo   - fallout2-ce.html (pagina principal)
    echo   - fallout2-ce.js (JavaScript)
    echo   - fallout2-ce.wasm (WebAssembly)
    echo.
    echo Para testar:
    echo   1. Copie os assets para build-web\
    echo   2. Inicie um servidor HTTP:
    echo      cd %BUILD_DIR%
    echo      python -m http.server 8000
    echo   3. Abra: http://localhost:8000/fallout2-ce.html
    echo.
) else (
    echo.
    echo ERRO: Arquivo fallout2-ce.html nao foi gerado!
    pause
    exit /b 1
)

pause

