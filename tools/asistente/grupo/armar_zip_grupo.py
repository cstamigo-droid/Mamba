"""Arma el ZIP de Mamba para el grupo (beta privada; alcance Horda, esMX/esES). 18-11-2026.

Uso:
    python -I tools/asistente/grupo/armar_zip_grupo.py --paquete D:\\rust\\mamba_grupo\\paquete \
        --manifiesto D:\\rust\\mamba_grupo\\manifiesto_67e7d3e89.json --version "beta 1" --commit 67e7d3e89 \
        --salida D:\\rust\\mamba_grupo

--paquete es una carpeta armada por armar_instalar.py (la misma que se instaló en el PC de Cristian).
Antes de empaquetar corre control_zip.py --estricto: si hay un rechazo, NO arma nada.

Dentro del ZIP (una carpeta Mamba_Horda_<version>):
    INSTALAR_MAMBA.bat · QUITAR_MAMBA.bat · LEEME.txt
    archivos/instalar.ps1 · archivos/volver_atras.ps1 · archivos/VERSION.txt · archivos/Mamba/<addons>
    LICENCIAS/  (GPL-3.0, permisos extra de Polestar, terceros, aviso del código fuente)
"""
from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
import zipfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]

BAT_INSTALAR = (
    "@echo off\r\n"
    "title Mamba - instalar\r\n"
    "if not exist \"%~dp0archivos\\instalar.ps1\" (\r\n"
    "  echo.\r\n"
    "  echo  Primero descomprime el ZIP: clic derecho sobre el ZIP, \"Extraer todo...\".\r\n"
    "  echo  Despues haz doble clic en INSTALAR_MAMBA dentro de la carpeta nueva.\r\n"
    "  echo.\r\n"
    "  pause\r\n"
    "  exit /b 1\r\n"
    ")\r\n"
    "powershell -NoProfile -ExecutionPolicy Bypass -File \"%~dp0archivos\\instalar.ps1\"\r\n"
    "echo.\r\n"
    "pause\r\n"
)
BAT_QUITAR = (
    "@echo off\r\n"
    "title Mamba - volver a como estaba\r\n"
    "if not exist \"%~dp0archivos\\volver_atras.ps1\" (\r\n"
    "  echo  Primero descomprime el ZIP: clic derecho sobre el ZIP, \"Extraer todo...\".\r\n"
    "  pause\r\n"
    "  exit /b 1\r\n"
    ")\r\n"
    "powershell -NoProfile -ExecutionPolicy Bypass -File \"%~dp0archivos\\volver_atras.ps1\"\r\n"
    "echo.\r\n"
    "pause\r\n"
)


def aviso_fuente(version: str, commit: str) -> str:
    return f"""CÓDIGO FUENTE DE MAMBA ({version}, commit {commit})
================================================

Mamba es software libre: GPL-3.0-only (archivo LICENSE), con los permisos extra
de Polestar (LICENSE-EXCEPTION.md). Es un fork de Polestar
(https://github.com/fitzforge/polestar), de "The Polestar authors".

El código de los addons va tal cual en la carpeta archivos/Mamba (Lua y XML).
Las herramientas y los datos de origen con que se generaron sus archivos de
datos están en el repositorio de Mamba: https://github.com/cstamigo-droid/Mamba
(rama asistente, commit {commit}).

Oferta escrita (GPL-3.0, sección 6b): durante al menos tres años, cualquiera que
tenga esta copia puede pedirle a Cristian Amigo el código fuente correspondiente
completo de esta versión, gratis, por el mismo canal por el que la recibió.

Los addons de otros autores que van incluidos conservan su licencia y sus
créditos dentro de su carpeta. Ver LICENCIAS_TERCEROS.md y THIRD_PARTY.md.

World of Warcraft y Blizzard Entertainment son marcas de Blizzard Entertainment, Inc.
Ni Mamba ni Polestar están hechos ni respaldados por Blizzard.
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--paquete", type=Path, required=True)
    ap.add_argument("--manifiesto", type=Path, required=True)
    ap.add_argument("--version", required=True, help='por ejemplo "beta 1"')
    ap.add_argument("--commit", required=True)
    ap.add_argument("--fecha", default="2026-11-18")
    ap.add_argument("--salida", type=Path, required=True)
    a = ap.parse_args()

    if not (a.paquete / "Polestar" / "Polestar.toc").exists():
        print(f"NO SE ARMA: {a.paquete} no trae Polestar")
        return 1
    control = subprocess.run([sys.executable, "-I", str(RAIZ / "tools/asistente/control_zip.py"), str(a.paquete),
                              "--manifiesto", str(a.manifiesto), "--estricto"], capture_output=True, text=True)
    print("control_zip:", control.stdout.strip().splitlines()[-1] if control.stdout.strip() else control.stderr)
    if control.returncode != 0:
        print(control.stdout)
        print("NO SE ARMA: control_zip rechazó el paquete")
        return 1

    nombre_v = a.version.replace(" ", "")
    tope = f"Mamba_Horda_{nombre_v}"
    a.salida.mkdir(parents=True, exist_ok=True)
    zpath = a.salida / f"{tope}_{a.fecha}.zip"
    version_txt = f"{a.version} ({a.fecha}, commit {a.commit})"

    def ps1(p: Path) -> bytes:  # PowerShell 5.1 lee como ANSI un .ps1 sin BOM: va con BOM
        datos = p.read_bytes()
        return datos if datos.startswith(b"\xef\xbb\xbf") else b"\xef\xbb\xbf" + datos

    def crlf(t: str) -> bytes:
        return t.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8")

    n = 0
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        def poner(rel: str, datos: bytes):
            nonlocal n
            z.writestr(f"{tope}/{rel}", datos)
            n += 1
        poner("INSTALAR_MAMBA.bat", BAT_INSTALAR.encode("ascii"))
        poner("QUITAR_MAMBA.bat", BAT_QUITAR.encode("ascii"))
        poner("LEEME.txt", b"\xef\xbb\xbf" + crlf((AQUI / "LEEME.txt").read_text("utf-8")))
        poner("archivos/instalar.ps1", ps1(AQUI / "instalar.ps1"))
        poner("archivos/volver_atras.ps1", ps1(AQUI / "volver_atras.ps1"))
        poner("archivos/VERSION.txt", b"\xef\xbb\xbf" + version_txt.encode("utf-8") + b"\r\n")
        for lic in ("LICENSE", "LICENSE-EXCEPTION.md", "LICENCIAS_TERCEROS.md", "THIRD_PARTY.md"):
            poner(f"LICENCIAS/{lic}", (RAIZ / lic).read_bytes())
        poner("LICENCIAS/CODIGO_FUENTE.txt", b"\xef\xbb\xbf" + crlf(aviso_fuente(a.version, a.commit)))
        for p in sorted(a.paquete.rglob("*")):
            if p.is_file():
                poner("archivos/Mamba/" + p.relative_to(a.paquete).as_posix(), p.read_bytes())
    h = hashlib.sha256(zpath.read_bytes()).hexdigest()
    (a.salida / (zpath.name + ".sha256")).write_text(f"{h}  {zpath.name}\n", "utf-8")
    print(f"ZIP: {zpath} ({zpath.stat().st_size / 1e6:.1f} MB, {n} archivos)\nsha256 {h}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
