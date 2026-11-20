# Instala Mamba desde D:\rust\mamba_instalar en el AddOns de WoW Forever (18-11).
# Uso:  powershell -ExecutionPolicy Bypass -File tools\asistente\instalar_mamba.ps1 -Simular   (solo dice qué haría)
#       powershell -ExecutionPolicy Bypass -File tools\asistente\instalar_mamba.ps1             (instala)
# Antes de copiar:
#   - se niega si Wow.exe está abierto (tasklist);
#   - respalda las carpetas de AddOns que va a reemplazar y WTF completo (SavedVariables incluidas) en
#     D:\rust\respaldos\mamba_<fecha>; las que saca de AddOns van movidas a <respaldo>\movidas;
#   - escribe VOLVER_ATRAS.ps1 en ese respaldo (deja AddOns y WTF exactamente como estaban).
# Mueve (no borra) al respaldo las carpetas Polestar_* que el paquete ya no trae (Alianza, otros idiomas,
# Experimental, Nav_EK, Nav_Kalimdor). No toca los addons de terceros que el paquete trae con versión
# igual o más vieja que la instalada (ForeverCore, SkillUpForever, WhatsTraining, ForeverLootSparkles).
# La tarea Mamba_Actualizar (actualizar_mamba.py, 18-11) lo llama con su paquete y su carpeta de respaldo:
#   -Paquete <carpeta armada> -Respaldo <carpeta nueva> [-AddOns <carpeta de prueba> -WTF <carpeta de prueba>]
# Sin esos parámetros hace lo mismo que antes.
param([switch]$Simular, [string]$Paquete = 'D:\rust\mamba_instalar', [string]$AddOns = '', [string]$WTF = '',
      [string]$Respaldo = '', [switch]$IgnorarJuego)
$ErrorActionPreference = 'Stop'
$Wow = 'C:\Program Files (x86)\World of Warcraft\_forever_'
if (-not $AddOns) { $AddOns = Join-Path $Wow 'Interface\AddOns' }
if (-not $WTF) { $WTF = Join-Path $Wow 'WTF' }
$Fecha = Get-Date -Format 'yyyy-MM-dd_HHmm'
if (-not $Respaldo) { $Respaldo = "D:\rust\respaldos\mamba_$Fecha" }
if (-not (Test-Path (Join-Path $Paquete 'Polestar\Polestar.toc'))) { Write-Output "NO SE INSTALA: el paquete $Paquete no trae Polestar."; exit 1 }
$Terceros = @('ForeverCore', 'SkillUpForever', 'WhatsTraining', 'ForeverLootSparkles')

function Version($toc) {
    if (-not (Test-Path $toc)) { return $null }
    $l = Select-String -Path $toc -Pattern '^## Version:\s*v?(.+)$' | Select-Object -First 1
    if ($l) { return $l.Matches[0].Groups[1].Value.Trim() } else { return $null }
}
function Comparar($a, $b) {  # -1, 0, 1 por números
    $x = ($a -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    $y = ($b -split '[^0-9]+' | Where-Object { $_ -ne '' } | ForEach-Object { [int]$_ })
    for ($i = 0; $i -lt [Math]::Max($x.Count, $y.Count); $i++) {
        $p = if ($i -lt $x.Count) { $x[$i] } else { 0 }; $q = if ($i -lt $y.Count) { $y[$i] } else { 0 }
        if ($p -lt $q) { return -1 } elseif ($p -gt $q) { return 1 }
    }
    return 0
}

$wowAbierto = tasklist /FI "IMAGENAME eq Wow.exe" /NH | Select-String -Pattern 'Wow.exe'
# -IgnorarJuego solo vale para una carpeta AddOns de PRUEBA (ensayos de la tarea), nunca para la del juego.
$ignorar = [bool]($IgnorarJuego -and ($AddOns -ne (Join-Path $Wow 'Interface\AddOns')) -and ($WTF -ne (Join-Path $Wow 'WTF')))
if ($ignorar) { $wowAbierto = $null }
# La simulación solo LEE: con el juego abierto sigue (y lo dice), para poder ensayar mientras se juega.
if ($wowAbierto -and -not $Simular) { Write-Output 'NO SE INSTALA: Wow.exe está abierto. Cierra el juego y vuelve a correr.'; exit 2 }
if ($wowAbierto) { Write-Output 'Wow.exe abierto: la simulacion sigue porque no cambia nada.' }

$nuevas = Get-ChildItem $Paquete -Directory | Select-Object -ExpandProperty Name
$copiar = @(); $saltar = @()
foreach ($n in $nuevas) {
    if ($Terceros -contains $n) {
        $vi = Version (Join-Path $AddOns "$n\$n.toc"); $vp = Version (Join-Path $Paquete "$n\$n.toc")
        if ($vi -and (Comparar $vi $vp) -ge 0) { $saltar += "$n (instalada $vi, paquete $vp)"; continue }
    }
    $copiar += $n
}
$mover = Get-ChildItem $AddOns -Directory | Where-Object { $_.Name -like 'Polestar_*' -and ($nuevas -notcontains $_.Name) } | Select-Object -ExpandProperty Name

Write-Output "Respaldo: $Respaldo (las carpetas que se reemplazan, las movidas y WTF completo)"
Write-Output ("Copiar ({0}): {1}" -f $copiar.Count, ($copiar -join ', '))
Write-Output ("No se tocan (la instalada es igual o más nueva): {0}" -f ($saltar -join '; '))
Write-Output ("Mover al respaldo ({0}): {1}" -f $mover.Count, ($mover -join ', '))
# Para la tarea: listas en una línea, sin acentos.
Write-Output ("LISTA_COPIAR: {0}" -f ($copiar -join '|'))
Write-Output ("LISTA_MOVER: {0}" -f ($mover -join '|'))
if ($Simular) { Write-Output 'SIMULACIÓN: no se cambió nada.'; exit 0 }

# Respaldo de lo que se toca (AddOns pesa ~5 GB por el audio de Spoken: no se copia entero) y WTF entero.
New-Item -ItemType Directory -Force "$Respaldo\movidas", "$Respaldo\AddOns" | Out-Null
$existian = @()
foreach ($n in $copiar) {
    $src = Join-Path $AddOns $n
    if (Test-Path $src) {
        robocopy $src "$Respaldo\AddOns\$n" /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "falló el respaldo de $n (robocopy $LASTEXITCODE)" }
        $existian += $n
    }
}
robocopy $WTF "$Respaldo\WTF" /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
if ($LASTEXITCODE -ge 8) { throw "falló el respaldo de WTF (robocopy $LASTEXITCODE)" }
$nuevasTxt = ($copiar | Where-Object { $existian -notcontains $_ }) -join "','"
$copiaTxt = $existian -join "','"
$moverTxt = $mover -join "','"
@"
# Deja AddOns y WTF como estaban el $Fecha, antes de instalar Mamba. Con Wow.exe cerrado:
#   powershell -ExecutionPolicy Bypass -File "$Respaldo\VOLVER_ATRAS.ps1"
if (tasklist /FI "IMAGENAME eq Wow.exe" /NH | Select-String 'Wow.exe') { 'Cierra el juego primero.'; exit 2 }
`$A = '$AddOns'
foreach (`$n in @('$nuevasTxt')) { if (`$n -and (Test-Path "`$A\`$n")) { Remove-Item -Recurse -Force "`$A\`$n" } }
foreach (`$n in @('$copiaTxt')) { if (`$n) { robocopy "$Respaldo\AddOns\`$n" "`$A\`$n" /MIR /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null } }
foreach (`$n in @('$moverTxt')) { if (`$n -and (Test-Path "$Respaldo\movidas\`$n")) { Move-Item "$Respaldo\movidas\`$n" "`$A\`$n" } }
# OJO: WTF vuelve a como estaba el $Fecha (se pierden barras, macros y SavedVariables posteriores);
# la WTF de este momento se guarda antes en $Respaldo\WTF_antes_de_volver.
robocopy "$WTF" "$Respaldo\WTF_antes_de_volver" /E /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
if (`$LASTEXITCODE -ge 8) { 'No se pudo guardar la WTF actual: no se vuelve atrás.'; exit 1 }
robocopy "$Respaldo\WTF" "$WTF" /MIR /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
'Listo: AddOns y WTF quedaron como el $Fecha. La WTF de antes de volver quedó en $Respaldo\WTF_antes_de_volver.'
"@ | Set-Content -Encoding utf8 "$Respaldo\VOLVER_ATRAS.ps1"

# Justo antes de copiar, otra vez.
if (-not $ignorar -and (tasklist /FI "IMAGENAME eq Wow.exe" /NH | Select-String -Pattern 'Wow.exe')) { throw 'Wow.exe se abrió durante el respaldo: no se copia nada.' }
foreach ($n in $mover) { Move-Item (Join-Path $AddOns $n) "$Respaldo\movidas\$n" -ErrorAction Stop }
foreach ($n in $copiar) {
    robocopy (Join-Path $Paquete $n) (Join-Path $AddOns $n) /MIR /NFL /NDL /NJH /NJS /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "falló la copia de $n (robocopy $LASTEXITCODE)" }
}
# K127 + 20-11: el juego deja "disabled" en el AddOns.txt de cada personaje los addons que fallan (Forever apagó
# Mamba_Combate por las placas) y los de terceros que trae el paquete. Todo lo que viene en el paquete queda
# enabled; solo esas líneas, con copia en <respaldo>\AddOns_txt_antes (y WTF entera ya está respaldada arriba).
. (Join-Path $PSScriptRoot 'grupo\habilitar_addons.ps1')
$hab = Enable-MambaAddons -WTF $WTF -Respaldo (Join-Path $Respaldo 'AddOns_txt_antes') -Addons (@($MambaAddonsHabilitar) + @($nuevas) | Select-Object -Unique)
Write-Output "AddOns.txt: $($hab.lineas) lineas pasaron a enabled en $(@($hab.cambiados).Count) personajes."
foreach ($e in $hab.errores) { Write-Output "AVISO AddOns.txt: $e" }
Write-Output "INSTALADO. Para volver atrás: $Respaldo\VOLVER_ATRAS.ps1"
