# Mamba: volver a como estaba antes de instalar (beta privada, 18-11-2026).
# Dos formas de lanzarlo:
#   - VOLVER_ATRAS.bat dentro de un respaldo  -> -Respaldo <esa carpeta>
#   - QUITAR_MAMBA.bat en la carpeta del ZIP  -> busca el juego y usa el respaldo más nuevo que no se haya usado
# Deja Interface\AddOns como estaba: borra las carpetas que Mamba agregó, repone las que reemplazó y
# devuelve las que apartó. La carpeta WTF (ajustes y personajes) NO se toca: si se repusiera, se perderían
# los cambios de barras, macros y ajustes hechos después de instalar. Su copia queda en el respaldo.
# Parámetros solo para probar: -Forever, -Raices, -SinVentanas, -ProcesoJuego (como en instalar.ps1).
param([string]$Respaldo = '', [string]$Forever = '', [string[]]$Raices = @(), [switch]$SinVentanas,
      [string]$ProcesoJuego = 'Wow')
$ErrorActionPreference = 'Stop'
function Decir($t) { Write-Host $t }
function Aviso($titulo, $texto, $botones = 'OK', $icono = 'Information') {
    if ($SinVentanas) { Decir "[$titulo] $texto"; if ($botones -eq 'OK') { return 'OK' } else { return 'Cancel' } }
    Add-Type -AssemblyName System.Windows.Forms
    return [string][System.Windows.Forms.MessageBox]::Show($texto, $titulo, $botones, $icono)
}

Decir ''
Decir '  ==============================================='
Decir '   MAMBA  -  volver a como estaba'
Decir '  ==============================================='
Decir ''

function EsForever($p) { return ($p -and (Test-Path $p) -and ((Test-Path (Join-Path $p 'Wow.exe')) -or (Test-Path (Join-Path $p 'Interface')))) }
if (-not $Respaldo) {
    if (-not $Forever) {
        if (-not $Raices -or $Raices.Count -eq 0) {
            $Raices = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and (Test-Path $_.Root) } | ForEach-Object { $_.Root }
        }
        $relativas = @('Program Files (x86)\World of Warcraft', 'Program Files\World of Warcraft', 'World of Warcraft',
                       'Games\World of Warcraft', 'Juegos\World of Warcraft', 'Blizzard\World of Warcraft',
                       'Battle.net\World of Warcraft', 'Program Files (x86)\Battle.net\World of Warcraft',
                       'Blizzard Games\World of Warcraft', 'Program Files (x86)\Blizzard\World of Warcraft')
        foreach ($r in $Raices) { foreach ($rel in $relativas) {
            $c = Join-Path (Join-Path $r $rel) '_forever_'
            if (-not $Forever -and (Test-Path (Join-Path $c 'Interface\Mamba_respaldos'))) { $Forever = (Resolve-Path $c).Path }
        } }
    }
    if (-not $Forever -and -not $SinVentanas) {
        Add-Type -AssemblyName System.Windows.Forms
        $d = New-Object System.Windows.Forms.FolderBrowserDialog
        $d.Description = 'Elige la carpeta World of Warcraft (la que tiene adentro _forever_)'
        if ($d.ShowDialog() -eq 'OK') {
            $p = $d.SelectedPath.TrimEnd('\')
            if ((Split-Path $p -Leaf) -ine '_forever_') { $p = Join-Path $p '_forever_' }
            if (EsForever $p) { $Forever = $p }
        }
    }
    if (-not $Forever) { Aviso 'Mamba' 'No encontré la carpeta del juego con respaldos de Mamba. No se cambió nada.' 'OK' 'Error' | Out-Null; exit 3 }
    $base = Join-Path $Forever 'Interface\Mamba_respaldos'
    $Respaldo = Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
        Where-Object { (Test-Path (Join-Path $_.FullName 'respaldo.json')) -and -not (Test-Path (Join-Path $_.FullName 'YA_USADO.txt')) } |
        Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $Respaldo) { Aviso 'Mamba' 'No quedan respaldos sin usar: tu carpeta AddOns ya está como antes de Mamba. No se cambió nada.' | Out-Null; exit 0 }
}
$Respaldo = (Resolve-Path $Respaldo).Path.TrimEnd('\')
$jf = Join-Path $Respaldo 'respaldo.json'
if (-not (Test-Path $jf)) { Aviso 'Mamba' "Esta carpeta no es un respaldo de Mamba:`n$Respaldo" 'OK' 'Error' | Out-Null; exit 3 }
$info = Get-Content $jf -Raw -Encoding UTF8 | ConvertFrom-Json
# La carpeta del juego es la que está dos niveles arriba del respaldo (_forever_\Interface\Mamba_respaldos\<fecha>).
$Forever = Split-Path (Split-Path (Split-Path $Respaldo))
$AddOns = Join-Path $Forever 'Interface\AddOns'
if (-not (Test-Path $AddOns)) { Aviso 'Mamba' "No encuentro $AddOns. No se cambió nada." 'OK' 'Error' | Out-Null; exit 3 }

$r = Aviso 'Mamba: volver atrás' "Voy a dejar tus AddOns como estaban el $($info.fecha), antes de instalar Mamba $($info.mamba).`n`nTus personajes, barras y ajustes (carpeta WTF) no se tocan.`n`n¿Sigo?" 'OKCancel' 'Question'
if ($SinVentanas) { $r = 'OK' }
if ($r -ne 'OK') { Decir 'Cancelado: no se cambió nada.'; exit 0 }
while (Get-Process -Name $ProcesoJuego -ErrorAction SilentlyContinue) {
    $r = Aviso 'Mamba: cierra el juego' "El juego está abierto.`n`nCierra World of Warcraft y aprieta Reintentar." 'RetryCancel' 'Warning'
    if ($r -ne 'Retry') { Decir 'Cancelado: el juego seguía abierto. No se cambió nada.'; exit 2 }
}

$fallas = @()
foreach ($n in @($info.agregadas)) {
    if ($n -and (Test-Path (Join-Path $AddOns $n))) {
        try { Remove-Item -Recurse -Force (Join-Path $AddOns $n) } catch { $fallas += "borrar $n" }
    }
}
foreach ($n in @($info.reemplazadas)) {
    if (-not $n) { continue }
    robocopy (Join-Path $Respaldo "AddOns\$n") (Join-Path $AddOns $n) /MIR /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { $fallas += "reponer $n" }
}
foreach ($n in @($info.apartadas)) {
    if (-not $n) { continue }
    $src = Join-Path $Respaldo "apartadas\$n"
    if (Test-Path $src) {
        try {
            if (Test-Path (Join-Path $AddOns $n)) { Remove-Item -Recurse -Force (Join-Path $AddOns $n) }
            Move-Item $src (Join-Path $AddOns $n)
        } catch { $fallas += "devolver $n" }
    }
}
if ($fallas.Count) {
    Aviso 'Mamba' ("No pude terminar: " + ($fallas -join ', ') + "`n`nEl respaldo sigue intacto en:`n$Respaldo") 'OK' 'Error' | Out-Null
    exit 6
}
"Usado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content -Encoding UTF8 (Join-Path $Respaldo 'YA_USADO.txt')
Decir 'LISTO: AddOns quedó como antes.'
Aviso 'Mamba' "Listo: tus AddOns quedaron como el $($info.fecha).`n`nSi habías instalado Mamba más de una vez, vuelve a hacer doble clic en QUITAR_MAMBA.bat para retroceder otra vez." | Out-Null
exit 0
