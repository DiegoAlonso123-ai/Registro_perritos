# Respaldo de la base de datos y de las imagenes.
# Uso (desde la raiz del repo):  .\database\respaldo.ps1
param(
  [string]$RutaImagenes = "C:\perritos-imagenes",
  [string]$Destino = "respaldos"
)

$fecha = Get-Date -Format "yyyy-MM-dd_HH-mm"
$carpeta = Join-Path $Destino $fecha
New-Item -ItemType Directory -Force $carpeta | Out-Null

# 1. Respaldo de la base (incluye CREATE DATABASE, por eso se restaura sin pasos extra)
mysqldump -u root -p --single-transaction --databases perritos_db --result-file="$carpeta\perritos_db.sql"

# 2. Respaldo de las imagenes
New-Item -ItemType Directory -Force "$carpeta\imagenes" | Out-Null
Copy-Item "$RutaImagenes\*" "$carpeta\imagenes" -Recurse -Force

Write-Host "Respaldo guardado en $carpeta"