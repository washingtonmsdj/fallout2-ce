@echo off
setlocal enabledelayedexpansion

cd "C:\Users\Casa\Documents\Novo github\fallout2-ce\godot_project\assets"

set "folders=audio misc palettes scripts"

for %%f in (%folders%) do (
    echo Removing folder: %%f
    if exist "%%f" (
        echo Deleting files in %%f...
        del /f /s /q "%%f\*.*" >nul 2>&1
        echo Removing folder %%f...
        rd /s /q "%%f" 2>nul
        if exist "%%f" (
            echo WARNING: Failed to remove %%f
        ) else (
            echo SUCCESS: %%f removed
        )
    ) else (
        echo Folder %%f not found
    )
)

echo.
echo Checking for remaining problematic files...
dir /b /s | findstr /r "\.(acm|ACM|frm|FRM|pal|PAL|int|INT)$" >nul 2>&1
if %errorlevel% equ 0 (
    echo WARNING: Problematic files still exist!
    dir /b /s | findstr /r "\.(acm|ACM|frm|FRM|pal|PAL|int|INT)$" | find /c "."
) else (
    echo SUCCESS: No problematic files found!
)

echo.
echo Operation completed.
pause