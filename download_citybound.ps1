# Script para baixar e rodar Citybound

Write-Host "Baixando Citybound build pronto..." -ForegroundColor Cyan

$downloadUrl = "http://aeplay.org/citybound-livebuilds"
$outputPath = "$env:TEMP\citybound_builds.html"

try {
    # Baixar página
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -TimeoutSec 30
    
    # Ler conteúdo
    $content = Get-Content $outputPath -Raw
    
    # Procurar por links de download Windows
    if ($content -match 'href="([^"]*windows[^"]*\.exe)"') {
        $exeUrl = $matches[1]
        Write-Host "✓ Encontrado: $exeUrl" -ForegroundColor Green
        
        $exePath = "$env:TEMP\citybound.exe"
        Write-Host "Baixando executável..." -ForegroundColor Yellow
        
        Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -TimeoutSec 300
        
        Write-Host "✓ Download completo!" -ForegroundColor Green
        Write-Host "Iniciando Citybound..." -ForegroundColor Cyan
        
        & $exePath
        
        Write-Host "`nAbra seu navegador em: http://localhost:1234" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Não consegui encontrar o link de download" -ForegroundColor Red
        Write-Host "Acesse manualmente: $downloadUrl" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Erro: $_" -ForegroundColor Red
    Write-Host "Acesse manualmente: $downloadUrl" -ForegroundColor Yellow
}
