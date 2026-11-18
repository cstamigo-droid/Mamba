# Instala UN módulo nuevo de Mamba (por ejemplo Mamba_Barras) sin rearmar todo Mamba (18-11).
# Por qué no instalar_mamba.ps1: ese copia D:\rust\mamba_instalar, que se arma desde addon\ completo, y en
# addon\ hay trabajo sin terminar de otras sesiones. Este script copia solo la carpeta pedida.
# Uso:  powershell -ExecutionPolicy Bypass -File tools\asistente\instalar_modulo.ps1 -Modulo Mamba_Barras -Simular
#       powershell -ExecutionPolicy Bypass -File tools\asistente\instalar_modulo.ps1 -Modulo Mamba_Barras
# Mismas reglas que instalar_mamba.ps1:
#   - se niega si Wow.exe está abierto (tasklist, justo antes de copiar);
#   - respalda la carpeta que reemplaza y las SavedVariables de ese módulo (WTF\...\SavedVariables\<Modulo>.lua, de cuenta y de cada personaje) en D:\rust\respaldos\modulo_<mod>_<fecha>;
#   - escribe VOLVER_ATRAS.ps1 en ese respaldo.
# Mamba_Barras: escribe DeBartender.lua en la copia instalada con las barras de Bartender4 de este PC.
param([Parameter(Mandatory = $true)][string]$Modulo, [switch]$Simular)
$ErrorActionPreference = 'Stop'
$Raiz = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Origen = Join-Path $Raiz "addon\$Modulo"
$Wow = 'C:\Program Files (x86)\World of Warcraft\_forever_'
$AddOns = Join-Path $Wow 'Interface\AddOns'
$Destino = Join-Path $AddOns $Modulo
$Fecha = Get-Date -Format 'yyyy-MM-dd_HHmm'
$Respaldo = "D:\rust\respaldos\modulo_${Modulo}_$Fecha"

if (-not (Test-Path (Join-Path $Origen "$Modulo.toc"))) { Write-Output "NO EXISTE el módulo $Origen"; exit 3 }
$sv = @()
foreach ($l in Select-String -Path (Join-Path $Origen "$Modulo.toc") -Pattern '^## SavedVariables(PerCharacter)?:\s*(.+)$') {
    $sv += ($l.Matches[0].Groups[2].Value -split ',\s*')
}
Write-Output "Módulo: $Modulo  ->  $Destino"
Write-Output "Respaldo: $Respaldo  (carpeta actual + SavedVariables: $($sv -join ', '))"
if ($Simular) { Write-Output 'SIMULACIÓN: no se copió nada.'; exit 0 }

$wowAbierto = tasklist /FI "IMAGENAME eq Wow.exe" /NH | Select-String -Pattern 'Wow.exe'
if ($wowAbierto) { Write-Output 'NO SE INSTALA: Wow.exe está abierto. Cierra el juego y vuelve a correr.'; exit 2 }

New-Item -ItemType Directory -Force $Respaldo | Out-Null
$habia = Test-Path $Destino
if ($habia) { Copy-Item $Destino (Join-Path $Respaldo $Modulo) -Recurse }
$svCopiadas = @()
foreach ($f in Get-ChildItem (Join-Path $Wow 'WTF\Account') -Recurse -File -Include "$Modulo.lua", "$Modulo.lua.bak" -ErrorAction SilentlyContinue) {
    $rel = $f.FullName.Substring($Wow.Length + 1)
    $dst = Join-Path $Respaldo "WTF_$($rel -replace '[\\:]', '_')"
    Copy-Item $f.FullName $dst
    $svCopiadas += "@('$dst', '$($f.FullName)')"
}
$volver = @"
# Deja $Modulo como estaba antes del $Fecha. Cerrar el juego antes.
`$ErrorActionPreference = 'Stop'
if (tasklist /FI "IMAGENAME eq Wow.exe" /NH | Select-String 'Wow.exe') { 'Cierra el juego primero.'; exit 2 }
if (Test-Path '$Destino') { Remove-Item '$Destino' -Recurse -Force }
$(if ($habia) { "Copy-Item '$(Join-Path $Respaldo $Modulo)' '$Destino' -Recurse" } else { "# no había versión anterior" })
foreach (`$p in @($($svCopiadas -join ', '))) { Copy-Item `$p[0] `$p[1] -Force }
'Listo: $Modulo volvió a como estaba.'
"@
Set-Content -Path (Join-Path $Respaldo 'VOLVER_ATRAS.ps1') -Value $volver -Encoding UTF8

if ($habia) { Remove-Item $Destino -Recurse -Force }
Copy-Item $Origen $Destino -Recurse
if ($Modulo -eq 'Mamba_Barras') {
    python -I (Join-Path $Raiz 'tools\asistente\barras\copiar_bartender.py') (Join-Path $Wow 'WTF\Account') (Join-Path $Destino 'DeBartender.lua')
}
$a = Get-ChildItem $Origen -Recurse -File | Measure-Object; $b = Get-ChildItem $Destino -Recurse -File | Measure-Object
Write-Output "Instalado: $($b.Count) archivos (origen $($a.Count)). Volver atrás: $Respaldo\VOLVER_ATRAS.ps1"
