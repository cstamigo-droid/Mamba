# Instalador de Mamba para el grupo (beta privada, 18-11-2026).
# Lo lanza INSTALAR_MAMBA.bat con doble clic. Hace, en orden:
#   1. encuentra la carpeta _forever_ del juego (busca en todos los discos; si no la halla, pide elegirla);
#   2. no sigue mientras el juego esté abierto;
#   3. respalda lo que va a reemplazar (y la carpeta WTF) en _forever_\Interface\Mamba_respaldos\<fecha>;
#   4. copia Mamba a Interface\AddOns;
#   5. deja en el respaldo su propio VOLVER_ATRAS.bat.
# Parámetros solo para probar (el jugador no los usa):
#   -Forever <carpeta _forever_>   no busca: usa esa carpeta
#   -Raices <c1,c2>                busca solo en esas carpetas (en vez de los discos)
#   -SinVentanas                   sin ventanas de Windows (responde "cancelar" donde habría que elegir)
#   -ProcesoJuego <nombre>         nombre del proceso del juego (por defecto Wow)
param([string]$Forever = '', [string[]]$Raices = @(), [switch]$SinVentanas, [string]$ProcesoJuego = 'Wow',
      [string]$Paquete = '', [string]$Escritorio = '', [switch]$SinTarea)
$ErrorActionPreference = 'Stop'
if (-not $Paquete) { $Paquete = Join-Path $PSScriptRoot 'Mamba' }
$Terceros = @('ForeverCore', 'SkillUpForever', 'WhatsTraining', 'ForeverLootSparkles')
$VersionMamba = 'sin versión'
$vtxt = Join-Path $PSScriptRoot 'VERSION.txt'
if (Test-Path -LiteralPath $vtxt) { $VersionMamba = (Get-Content -LiteralPath $vtxt -Encoding UTF8 | Select-Object -First 1).Trim() }

function Decir($t) { Write-Host $t }
function Aviso($titulo, $texto, $botones = 'OK', $icono = 'Information') {
    if ($SinVentanas) { Decir "[$titulo] $texto"; if ($botones -eq 'OK') { return 'OK' } else { return 'Cancel' } }
    Add-Type -AssemblyName System.Windows.Forms
    return [string][System.Windows.Forms.MessageBox]::Show($texto, $titulo, $botones, $icono)
}
function Terminar($codigo) { exit $codigo }

Decir ''
Decir '  ==============================================='
Decir "   MAMBA  -  instalador  ($VersionMamba)"
Decir '  ==============================================='
Decir ''

if (-not (Test-Path -LiteralPath (Join-Path $Paquete 'Polestar\Polestar.toc'))) {
    Aviso 'Mamba' "Falta la carpeta de Mamba junto al instalador.`n`nDescomprime el ZIP completo (clic derecho > Extraer todo) y vuelve a hacer doble clic en INSTALAR_MAMBA." 'OK' 'Error' | Out-Null
    Terminar 1
}

# ---------- 1. Encontrar _forever_ ----------
function EsForever($p) { return ($p -and (Test-Path -LiteralPath $p) -and ((Test-Path -LiteralPath (Join-Path $p 'Wow.exe')) -or (Test-Path -LiteralPath (Join-Path $p 'Interface')) -or (Test-Path -LiteralPath (Join-Path $p 'WTF')))) }
function Normalizar($p) {
    # Acepta la carpeta World of Warcraft, la _forever_ o la AddOns.
    if (-not $p) { return $null }
    $p = $p.TrimEnd('\')
    if ((Split-Path $p -Leaf) -ieq 'AddOns') { $p = Split-Path (Split-Path $p) }
    if ((Split-Path $p -Leaf) -ieq 'Interface') { $p = Split-Path $p }
    if ((Split-Path $p -Leaf) -ine '_forever_' -and (Test-Path -LiteralPath (Join-Path $p '_forever_'))) { $p = Join-Path $p '_forever_' }
    if (EsForever $p) { return $p } else { return $null }
}
if ($Forever) {
    $Forever = Normalizar $Forever
} else {
    if (-not $Raices -or $Raices.Count -eq 0) {
        $Raices = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and (Test-Path -LiteralPath $_.Root) } | ForEach-Object { $_.Root }
    }
    $relativas = @('Program Files (x86)\World of Warcraft', 'Program Files\World of Warcraft', 'World of Warcraft',
                   'Games\World of Warcraft', 'Juegos\World of Warcraft', 'Blizzard\World of Warcraft',
                   'Battle.net\World of Warcraft', 'Program Files (x86)\Battle.net\World of Warcraft',
                   'Blizzard Games\World of Warcraft', 'Program Files (x86)\Blizzard\World of Warcraft')
    $hallados = @()
    foreach ($r in $Raices) {
        foreach ($rel in $relativas) {
            $c = Join-Path (Join-Path $r $rel) '_forever_'
            if (EsForever $c) { $hallados += (Resolve-Path -LiteralPath $c).Path }
        }
    }
    $hallados = @($hallados | Select-Object -Unique)
    if ($hallados.Count -ge 1) { $Forever = $hallados[0] }
    if ($hallados.Count -gt 1) { Decir "Encontré el juego en más de un lugar; uso el primero: $Forever" }
}
if (-not $Forever) {
    if ($SinVentanas) { Decir 'No encontré la carpeta del juego.'; Terminar 3 }
    Add-Type -AssemblyName System.Windows.Forms
    Aviso 'Mamba' "No encontré solo la carpeta de WoW Forever.`n`nEn la ventana que se abre ahora, elige la carpeta «World of Warcraft» (la que tiene adentro «_forever_») y aprieta Aceptar." | Out-Null
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = 'Elige la carpeta World of Warcraft (la que tiene adentro _forever_)'
    if ($d.ShowDialog() -ne 'OK') { Decir 'Cancelado: no se instaló nada.'; Terminar 3 }
    $Forever = Normalizar $d.SelectedPath
    if (-not $Forever) {
        Aviso 'Mamba' "Esa carpeta no tiene «_forever_».`n`nNo se instaló nada. Vuelve a intentarlo eligiendo la carpeta World of Warcraft." 'OK' 'Error' | Out-Null
        Terminar 3
    }
}
$AddOns = Join-Path $Forever 'Interface\AddOns'
$WTF = Join-Path $Forever 'WTF'
Decir "Carpeta del juego: $Forever"
New-Item -ItemType Directory -Force $AddOns | Out-Null

# ---------- 2. El juego tiene que estar cerrado ----------
function JuegoAbierto { return [bool](Get-Process -Name $ProcesoJuego -ErrorAction SilentlyContinue) }
while (JuegoAbierto) {
    $r = Aviso 'Mamba: cierra el juego' "El juego está abierto.`n`nCierra World of Warcraft (salir del juego, no solo del personaje) y aprieta Reintentar." 'RetryCancel' 'Warning'
    if ($r -ne 'Retry') { Decir 'Cancelado: el juego seguía abierto. No se instaló nada.'; Terminar 2 }
}

# ¿Podemos escribir? (si no, se vuelve a abrir como administrador)
$prueba = Join-Path $AddOns ".mamba_prueba_$PID"
try { Set-Content -LiteralPath $prueba -Value 'x' -ErrorAction Stop; Remove-Item $prueba -Force }
catch {
    if ($SinVentanas) { Decir "Sin permiso para escribir en $AddOns"; Terminar 4 }
    Decir 'Windows no deja escribir en la carpeta del juego: pido permiso de administrador...'
    $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Forever `"$Forever`""
    Start-Process powershell -Verb RunAs -ArgumentList $a -Wait
    Terminar 0
}

# ---------- Qué se copia, qué se salta, qué se aparta ----------
function Version($toc) {
    if (-not (Test-Path -LiteralPath $toc)) { return $null }
    $l = Select-String -LiteralPath $toc -Pattern '^## Version:\s*v?(.+)$' | Select-Object -First 1
    if ($l) { return $l.Matches[0].Groups[1].Value.Trim() } else { return $null }
}
function Comparar($a, $b) {
    $x = @($a -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    $y = @($b -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    for ($i = 0; $i -lt [Math]::Max($x.Count, $y.Count); $i++) {
        $p = if ($i -lt $x.Count) { $x[$i] } else { 0 }; $q = if ($i -lt $y.Count) { $y[$i] } else { 0 }
        if ($p -lt $q) { return -1 } elseif ($p -gt $q) { return 1 }
    }
    return 0
}
$nuevas = @(Get-ChildItem -LiteralPath $Paquete -Directory | Select-Object -ExpandProperty Name)
$copiar = @(); $saltar = @()
foreach ($n in $nuevas) {
    if ($Terceros -contains $n) {
        $vi = Version (Join-Path $AddOns "$n\$n.toc"); $vp = Version (Join-Path $Paquete "$n\$n.toc")
        if ($vi -and $vp -and (Comparar $vi $vp) -ge 0) { $saltar += "$n (ya tienes la $vi)"; continue }
    }
    $copiar += $n
}
# Módulos de Polestar que Mamba no trae (Alianza, otros idiomas, mapas viejos): se apartan al respaldo,
# porque mezclados con el Polestar de Mamba darían errores. Vuelven con VOLVER_ATRAS.
$apartar = @(Get-ChildItem -LiteralPath $AddOns -Directory | Where-Object { $_.Name -like 'Polestar_*' -and ($nuevas -notcontains $_.Name) } | Select-Object -ExpandProperty Name)

# ---------- 3. Respaldo ----------
$Fecha = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$Respaldo = Join-Path $Forever "Interface\Mamba_respaldos\$Fecha"
New-Item -ItemType Directory -Force (Join-Path $Respaldo 'AddOns'), (Join-Path $Respaldo 'apartadas') | Out-Null
Decir "Respaldo en: $Respaldo"
$reemplazadas = @()
foreach ($n in $copiar) {
    $src = Join-Path $AddOns $n
    if (Test-Path -LiteralPath $src) {
        robocopy $src (Join-Path $Respaldo "AddOns\$n") /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
        if ($LASTEXITCODE -ge 8) { Aviso 'Mamba' "No pude respaldar $n. No se instaló nada." 'OK' 'Error' | Out-Null; Terminar 5 }
        $reemplazadas += $n
    }
}
if (Test-Path -LiteralPath $WTF) {
    robocopy $WTF (Join-Path $Respaldo 'WTF') /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Aviso 'Mamba' 'No pude respaldar la carpeta WTF. No se instaló nada.' 'OK' 'Error' | Out-Null; Terminar 5 }
}
$agregadas = @($copiar | Where-Object { $reemplazadas -notcontains $_ })
# Justo antes de marcar el respaldo como válido y copiar: si el juego se abrió, se sale y el respaldo
# queda sin respaldo.json (QUITAR no lo usa).
if (JuegoAbierto) { Aviso 'Mamba' 'El juego se abrió mientras respaldaba. No se instaló nada: ciérralo y vuelve a empezar.' 'OK' 'Error' | Out-Null; Terminar 2 }
$info = [ordered]@{
    mamba = $VersionMamba; fecha = $Fecha; forever = $Forever
    agregadas = $agregadas; reemplazadas = $reemplazadas; apartadas = $apartar; saltadas = $saltar
}
$info | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $Respaldo 'respaldo.json')
# Su propio "volver atrás", dentro del respaldo (sirve aunque se borre la carpeta del ZIP).
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'volver_atras.ps1') (Join-Path $Respaldo 'volver_atras.ps1')
$bat = "@echo off`r`ntitle Mamba - volver atras`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0volver_atras.ps1`" -Respaldo `"%~dp0.`"`r`npause`r`n"
[IO.File]::WriteAllText((Join-Path $Respaldo 'VOLVER_ATRAS.bat'), $bat, (New-Object Text.ASCIIEncoding))

# ---------- 4. Copiar ----------
$total = $copiar.Count; $i = 0
try {
    foreach ($n in $apartar) { Move-Item -LiteralPath (Join-Path $AddOns $n) (Join-Path $Respaldo "apartadas\$n") -ErrorAction Stop }
    foreach ($n in $copiar) {
        $i++; Write-Progress -Activity 'Copiando Mamba' -Status $n -PercentComplete ([int](100 * $i / [Math]::Max(1, $total)))
        robocopy (Join-Path $Paquete $n) (Join-Path $AddOns $n) /MIR /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "falló la copia de $n" }
    }
    Write-Progress -Activity 'Copiando Mamba' -Completed
} catch {
    Aviso 'Mamba' "Algo falló al copiar ($($_.Exception.Message)).`n`nHaz doble clic en VOLVER_ATRAS.bat, dentro de:`n$Respaldo" 'OK' 'Error' | Out-Null
    Terminar 6
}

# ---------- 5. Comprobar ----------
$malas = @()
foreach ($n in $copiar) {
    $a = @(Get-ChildItem -LiteralPath (Join-Path $Paquete $n) -Recurse -File).Count
    $b = @(Get-ChildItem -LiteralPath (Join-Path $AddOns $n) -Recurse -File).Count
    if ($a -ne $b) { $malas += "$n ($b de $a archivos)" }
}
if ($malas.Count) {
    Aviso 'Mamba' ("Quedaron carpetas incompletas: " + ($malas -join ', ') + "`n`nHaz doble clic en VOLVER_ATRAS.bat, dentro de:`n$Respaldo") 'OK' 'Error' | Out-Null
    Terminar 7
}
"Mamba $VersionMamba instalada el $Fecha. Respaldo: $Respaldo" | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $Forever 'Interface\Mamba_respaldos\ULTIMA_INSTALACION.txt')


# ---------- K127: SkillUpForever, WhatsTraining y ForeverLootSparkles habilitados en cada personaje ----------
# El juego los deja "disabled" en AddOns.txt; se cambian SOLO esas líneas (WTF ya está respaldada entera arriba, y
# cada archivo que cambia se copia además a $Respaldo\AddOns_txt_antes). El juego está cerrado (se revisó antes).
$habil = Join-Path $PSScriptRoot 'habilitar_addons.ps1'
$avisoHab = ''
if ((Test-Path -LiteralPath $habil) -and (Test-Path -LiteralPath $WTF)) {
    try {
        . $habil
        $rh = Enable-MambaAddons -WTF $WTF -Respaldo (Join-Path $Respaldo 'AddOns_txt_antes')
        if ($rh.lineas -gt 0) { Decir ("Habilitados SkillUpForever, WhatsTraining y ForeverLootSparkles: {0} líneas en {1} personajes." -f $rh.lineas, $rh.cambiados.Count) }
        if ($rh.errores.Count) { $avisoHab = "`n`n(No pude habilitar los addons de profesiones en algún personaje: actívalos en «AddOns» de la pantalla de personajes.)" }
    } catch { $avisoHab = "`n`n(No pude habilitar los addons de profesiones: actívalos en «AddOns» de la pantalla de personajes.)" }
}

# ---------- 6. El actualizador (19-11): "Actualizar Mamba" en el escritorio y una revisión al iniciar sesión ----------
# Va fuera de AddOns (el juego no lo carga) y se reescribe en cada instalación, así se actualiza solo.
$Act = Join-Path $Forever 'Interface\Mamba_actualizador'
$avisoAct = ''
try {
    New-Item -ItemType Directory -Force $Act | Out-Null
    foreach ($f in 'actualizar.ps1', 'canal.json') {
        $src = Join-Path $PSScriptRoot $f
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src (Join-Path $Act $f) -Force }
    }
    $vj = Join-Path $PSScriptRoot 'VERSION.json'
    if (Test-Path -LiteralPath $vj) { Copy-Item -LiteralPath $vj (Join-Path $Act 'instalada.json') -Force }
    if (Test-Path -LiteralPath (Join-Path $Act 'actualizar.ps1')) {
        if (-not $Escritorio) { $Escritorio = [Environment]::GetFolderPath('Desktop') }
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut((Join-Path $Escritorio 'Actualizar Mamba.lnk'))
        $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Act 'actualizar.ps1')`""
        $lnk.WorkingDirectory = $Act
        $lnk.Description = 'Baja e instala la última versión de Mamba (con el juego cerrado)'
        $lnk.Save()
        if (-not $SinTarea) {
            $acc = New-ScheduledTaskAction -Execute $lnk.TargetPath -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $Act 'actualizar.ps1')`" -SoloRevisar"
            $dis = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
            $aj = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            Register-ScheduledTask -TaskName 'Mamba - revisar version nueva' -Action $acc -Trigger $dis -Settings $aj -Force | Out-Null
        }
    }
} catch { $avisoAct = "`n`n(No pude dejar el acceso directo «Actualizar Mamba»: $($_.Exception.Message). Mamba quedó instalada igual.)" }

Decir ''
Decir ("Copiadas: {0} carpetas." -f $copiar.Count)
if ($saltar.Count) { Decir ("No se tocaron (ya tenías una igual o más nueva): " + ($saltar -join '; ')) }
if ($apartar.Count) { Decir ("Apartadas al respaldo (vuelven con VOLVER_ATRAS): " + ($apartar -join ', ')) }
Decir 'LISTO.'
Aviso 'Mamba instalada' ("Listo: Mamba $VersionMamba quedó instalada.`n`nAbre el juego y, en la pantalla de personajes, entra a «AddOns» y revisa que estén marcados Polestar y los de la categoría Mamba.`n`nSi algo no te gusta, para volver a como estabas: doble clic en QUITAR_MAMBA.bat (en la carpeta del ZIP) o en VOLVER_ATRAS.bat dentro de:`n$Respaldo$avisoAct$avisoHab") | Out-Null
Terminar 0
