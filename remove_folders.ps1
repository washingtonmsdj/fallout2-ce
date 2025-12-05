$folders = @('audio', 'misc', 'palettes', 'scripts')
$basePath = "C:\Users\Casa\Documents\Novo github\fallout2-ce\godot_project\assets"

foreach ($folder in $folders) {
    $fullPath = Join-Path $basePath $folder
    Write-Host "Removing $folder..."

    if (Test-Path $fullPath) {
        # Try normal removal first
        try {
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
            Write-Host "✓ $folder removed successfully"
        }
        catch {
            Write-Host "Normal removal failed for $folder, trying alternative method..."

            # Alternative: Use cmd to force delete
            $cmdPath = $fullPath -replace '/', '\'
            cmd /c "rd /s /q `"$cmdPath`"" 2>$null
            Start-Sleep -Milliseconds 500

            if (!(Test-Path $fullPath)) {
                Write-Host "✓ $folder removed with alternative method"
            } else {
                Write-Host "✗ Failed to remove $folder"
            }
        }
    } else {
        Write-Host "$folder not found"
    }
}

Write-Host "Cleanup completed!"