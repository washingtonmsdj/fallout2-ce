# Script para verificar se o Rust nightly foi instalado
Write-Host "Verificando instalação do Rust nightly..." -ForegroundColor Cyan

$env:Path += ";$env:USERPROFILE\.cargo\bin"

try {
    $rustVersion = rustc --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Rust instalado com sucesso!" -ForegroundColor Green
        Write-Host "Versão: $rustVersion" -ForegroundColor Green
        
        Write-Host "`nPróximos passos:" -ForegroundColor Yellow
        Write-Host "1. Abra um novo terminal na pasta: citybound-master\citybound-master"
        Write-Host "2. Execute: npm install"
        Write-Host "3. Execute: npm run ensure-tooling"
        Write-Host "4. Em dois terminais separados, execute:"
        Write-Host "   Terminal 1: npm run watch-browser"
        Write-Host "   Terminal 2: npm start"
    } else {
        Write-Host "✗ Rust ainda não está disponível" -ForegroundColor Red
        Write-Host "Aguarde mais alguns minutos e execute este script novamente" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Rust ainda não está disponível" -ForegroundColor Red
    Write-Host "Aguarde mais alguns minutos e execute este script novamente" -ForegroundColor Yellow
}

Write-Host "`nPressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
