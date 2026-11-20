# Actualizar Mamba (para los compañeros de Cristian; 19-11-2026).
# El instalador lo deja en _forever_\Interface\Mamba_actualizador\ junto con canal.json e instalada.json, y crea
# el acceso directo "Actualizar Mamba" en el escritorio. Hace, en orden:
#   1. lee en canal.json el lugar fijo de las versiones (mamba_grupo.json: build, versión, notas, zip, sha256);
#   2. si la versión publicada no es más nueva que la instalada, dice "ya tienes la última" y termina;
#   3. muestra "Qué cambió" y pregunta;
#   4. espera a que el juego esté cerrado;
#   5. baja el ZIP, comprueba su sha256 (si no coincide, NO instala), lo descomprime en una carpeta temporal;
#   6. corre el instalador de ESE ZIP, que respalda y deja su VOLVER_ATRAS (el mismo de siempre).
# -SoloRevisar: no hace nada si no hay versión nueva (sin ventanas); si la hay, pregunta. Lo usa la tarea al
#  iniciar sesión.
# Parámetros solo para probar: -Canal <url o archivo>, -Forever, -SinVentanas, -ProcesoJuego.
param([string]$Canal = '', [string]$Forever = '', [switch]$SoloRevisar, [switch]$SinVentanas,
      [string]$ProcesoJuego = 'Wow')
$ErrorActionPreference = 'Stop'
function Decir($t) { Write-Host $t }
function Aviso($titulo, $texto, $botones = 'OK', $icono = 'Information') {
    if ($SinVentanas) { Decir "[$titulo] $texto"; if ($botones -eq 'OK') { return 'OK' } elseif ($botones -eq 'YesNo') { return 'Yes' } else { return 'Cancel' } }
    Add-Type -AssemblyName System.Windows.Forms
    return [string][System.Windows.Forms.MessageBox]::Show($texto, $titulo, $botones, $icono)
}
function Bajar($origen, $destino) {
    if ($origen -match '^https?://') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $origen -OutFile $destino -UseBasicParsing -TimeoutSec 600
    } else {
        Copy-Item -LiteralPath ($origen -replace '^file:///', '') $destino
    }
}
function Junto($base, $rel) {  # una ruta relativa del manifiesto se resuelve junto al manifiesto
    if ($rel -match '^(https?|file)://' -or [IO.Path]::IsPathRooted($rel)) { return $rel }
    if ($base -match '^https?://') { return ($base.Substring(0, $base.LastIndexOf('/') + 1) + $rel) }
    return (Join-Path (Split-Path -LiteralPath $base) $rel)
}

$aqui = $PSScriptRoot
if (-not $Forever) { $Forever = Split-Path (Split-Path $aqui) }   # ...\_forever_\Interface\Mamba_actualizador
if (-not $Canal) {
    $cj = Join-Path $aqui 'canal.json'
    if (-not (Test-Path -LiteralPath $cj)) { Aviso 'Mamba' 'Falta canal.json: vuelve a instalar Mamba con INSTALAR_MAMBA.' 'OK' 'Error' | Out-Null; exit 3 }
    $Canal = (Get-Content -LiteralPath $cj -Raw -Encoding UTF8 | ConvertFrom-Json).manifiesto
}
$instalada = 0; $instTxt = 'ninguna'
$ij = Join-Path $aqui 'instalada.json'
if (Test-Path -LiteralPath $ij) { $x = Get-Content -LiteralPath $ij -Raw -Encoding UTF8 | ConvertFrom-Json; $instalada = [int64]$x.build; $instTxt = $x.version }

$tmp = Join-Path $env:TEMP "Mamba_actualizar_$PID"
New-Item -ItemType Directory -Force $tmp | Out-Null
try {
    try { Bajar $Canal (Join-Path $tmp 'mamba_grupo.json') }
    catch {
        if ($SoloRevisar) { exit 0 }   # sin internet al iniciar sesión: no molestar
        Aviso 'Mamba' "No pude revisar si hay versión nueva (¿sin internet?).`n`n$($_.Exception.Message)" 'OK' 'Warning' | Out-Null; exit 4
    }
    $m = Get-Content -LiteralPath (Join-Path $tmp 'mamba_grupo.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $nueva = [int64]$m.build
    Decir "Instalada: $instTxt ($instalada) · publicada: $($m.version) ($nueva)"
    if ($nueva -le $instalada) {
        if (-not $SoloRevisar) { Aviso 'Mamba' "Ya tienes la última versión de Mamba ($instTxt)." | Out-Null }
        exit 0
    }
    $notas = (@($m.notas) | ForEach-Object { "• $_" }) -join "`n"
    $r = Aviso 'Mamba: versión nueva' "Hay una versión nueva de Mamba: $($m.version).`n`nQué cambió:`n$notas`n`n¿La instalo ahora? (Se guarda una copia de lo que tienes.)" 'YesNo' 'Question'
    if ($r -ne 'Yes') { Decir 'No se instaló nada.'; exit 0 }
    while (Get-Process -Name $ProcesoJuego -ErrorAction SilentlyContinue) {
        $r = Aviso 'Mamba: cierra el juego' "El juego está abierto.`n`nCierra World of Warcraft y aprieta Reintentar." 'RetryCancel' 'Warning'
        if ($r -ne 'Retry') { Decir 'Cancelado: el juego seguía abierto. No se instaló nada.'; exit 2 }
    }
    Decir 'Bajando la versión nueva...'
    $zip = Join-Path $tmp 'Mamba.zip'
    try { Bajar (Junto $Canal $m.zip) $zip }
    catch { Aviso 'Mamba' "No pude bajar la versión nueva. No se cambió nada.`n`n$($_.Exception.Message)" 'OK' 'Error' | Out-Null; exit 4 }
    $h = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if ($h -ne ([string]$m.sha256).ToLower()) {
        Aviso 'Mamba' 'La descarga llegó dañada o no es la publicada (la huella no coincide). No se cambió nada: vuelve a intentarlo más tarde.' 'OK' 'Error' | Out-Null
        exit 5
    }
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp 'zip') -Force
    $inst = Join-Path $tmp 'zip\archivos\instalar.ps1'
    if (-not (Test-Path -LiteralPath $inst)) { Aviso 'Mamba' 'El ZIP publicado no trae el instalador. No se cambió nada.' 'OK' 'Error' | Out-Null; exit 5 }
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $inst, '-Forever', $Forever, '-ProcesoJuego', $ProcesoJuego)
    if ($SinVentanas) { $a += '-SinVentanas' }
    & powershell @a
    exit $LASTEXITCODE
} finally {
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
}
