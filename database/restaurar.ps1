# Restaura la base de datos y las imagenes desde una carpeta de respaldo.
# Uso:  .\database\restaurar.ps1 -Carpeta respaldos\2026-09-27_23-10
param(
  [Parameter(Mandatory = $true)][string]$Carpeta,
  [string]$RutaImagenes = "C:\perritos-imagenes"
)

$sql = (Resolve-Path "$Carpeta\perritos_db.sql").Path

# 1. Restaurar la base
cmd /c "mysql -u root -p < ""$sql"""
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: no se pudo restaurar la base de datos. Revisa la contrasena de MySQL." -ForegroundColor Red
  exit 1
}

# 2. Restaurar las imagenes
New-Item -ItemType Directory -Force $RutaImagenes | Out-Null
Copy-Item "$Carpeta\imagenes\*" $RutaImagenes -Recurse -Force

Write-Host "Restauracion completa" -ForegroundColor Green