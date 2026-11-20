# K127 (20-11-2026): SkillUpForever, WhatsTraining y ForeverLootSparkles vienen en el paquete, pero el juego los deja
# "disabled" en el AddOns.txt de cada personaje, y entonces Profesiones, N7 y K83 no hacen nada.
# Esta función cambia SOLO esas líneas ("<addon>: disabled" -> "<addon>: enabled") en
# WTF\Account\<cuenta>\<reino>\<personaje>\AddOns.txt. No agrega líneas (si un addon no figura, el juego lo
# carga habilitado) y no toca nada más del archivo. Antes de escribir, copia cada archivo que cambia a $Respaldo,
# con su misma ruta relativa a WTF. Hay que llamarla con el juego CERRADO: el juego reescribe AddOns.txt al salir.
#
# Uso (dot-source):
#   . .\habilitar_addons.ps1
#   $r = Enable-MambaAddons -WTF '<_forever_>\WTF' -Respaldo '<carpeta de respaldo>'   # -Addons para otra lista
#   $r.cambiados  -> rutas de AddOns.txt que se cambiaron
#   $r.lineas     -> cuántas líneas pasaron a enabled
# Sin param(): se carga con dot-source dentro de instalar.ps1, y un param() aquí pisaría sus variables ($WTF).

$MambaAddonsHabilitar = @('SkillUpForever', 'WhatsTraining', 'ForeverLootSparkles')

function Enable-MambaAddons {
    param([Parameter(Mandatory)][string]$WTF, [Parameter(Mandatory)][string]$Respaldo,
          [string[]]$Addons = $MambaAddonsHabilitar)
    $res = [pscustomobject]@{ cambiados = @(); lineas = 0; errores = @() }
    $cuentas = Join-Path $WTF 'Account'
    if (-not (Test-Path -LiteralPath $cuentas)) { return $res }
    $nombres = ($Addons | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $patron = New-Object System.Text.RegularExpressions.Regex ("(?im)^(\s*(?:$nombres)\s*:\s*)disabled(\s*)$")
    # AddOns.txt de personaje: Account\<cuenta>\<reino>\<personaje>\AddOns.txt (profundidad 3 bajo Account)
    $archivos = Get-ChildItem -LiteralPath $cuentas -Recurse -Filter 'AddOns.txt' -File -ErrorAction SilentlyContinue |
        Where-Object { ($_.FullName.Substring($cuentas.Length).Trim('\').Split('\')).Count -eq 4 }
    $sinBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($f in $archivos) {
        try {
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
            $texto = [IO.File]::ReadAllText($f.FullName)
            $n = $patron.Matches($texto).Count
            if ($n -eq 0) { continue }
            $nuevo = $patron.Replace($texto, '${1}enabled${2}')
            $rel = $f.FullName.Substring($WTF.TrimEnd('\').Length).TrimStart('\')
            $dst = Join-Path $Respaldo $rel
            New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
            Copy-Item -LiteralPath $f.FullName $dst -Force
            $enc = if ($bom) { New-Object System.Text.UTF8Encoding($true) } else { $sinBom }
            [IO.File]::WriteAllText($f.FullName, $nuevo, $enc)
            $res.cambiados += $f.FullName
            $res.lineas += $n
        } catch { $res.errores += "$($f.FullName): $($_.Exception.Message)" }
    }
    return $res
}
