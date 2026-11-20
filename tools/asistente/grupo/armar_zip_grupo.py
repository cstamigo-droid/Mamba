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
import datetime as dt
import hashlib
import shutil
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
# Lugar fijo de las versiones (recomendado: GitHub Releases; «latest» siempre apunta a la última publicada).
CANAL = "https://github.com/cstamigo-droid/Mamba/releases/latest/download/mamba_grupo.json"
ZIP_FIJO = "Mamba_Horda.zip"  # nombre fijo del ZIP en el canal: el manifiesto lo nombra relativo a sí mismo
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


def aviso_fuente(version: str, commit: str, fuente: str) -> str:
    return f"""CÓDIGO FUENTE DE MAMBA ({version}, commit {commit})
================================================

Mamba es software libre: GPL-3.0-only (archivo LICENSE), con los permisos extra
de Polestar (LICENSE-EXCEPTION.md). Es un fork de Polestar
(https://github.com/fitzforge/polestar), de "The Polestar authors".
No es el Polestar oficial.

El código de los addons va tal cual en la carpeta archivos/Mamba (Lua y XML).
El código fuente correspondiente completo de esta versión (incluidas las
herramientas y los datos de origen con que se generaron los archivos de datos)
está en el archivo {fuente}, que se entrega en el MISMO lugar y por el
mismo enlace que este ZIP, sin costo (GPL-3.0, sección 6d).

Los addons de otros autores que van incluidos conservan su licencia y sus
créditos dentro de su carpeta; su único cambio es una línea en su .toc que
avisa que van dentro de Mamba. Ver CREDITOS.txt, LICENCIAS_TERCEROS.md y
THIRD_PARTY.md.

World of Warcraft y Blizzard Entertainment son marcas de Blizzard Entertainment, Inc.
Ni Mamba ni Polestar están hechos ni respaldados por Blizzard.
"""


def creditos(paquete: Path) -> str:
    inc = json.loads((RAIZ / "tools/asistente/incluidos.json").read_text("utf-8"))
    l = ["CRÉDITOS DE LO QUE TRAE MAMBA", "=============================", "",
         "Addons de otros autores, incluidos sin cambios de código (solo se agregó una",
         "línea X-Mamba en su .toc). Su licencia va dentro de su carpeta:"]
    for nombre, e in inc.items():
        if (paquete / nombre).is_dir():
            l.append(f"- {nombre} {e.get('version','')}: {e.get('autor','')}, {e.get('licencia','')}, {e.get('fuente','')}")
    l += ["",
          "Librerías dentro de Mamba_Barras/libs (detalle en Mamba_Barras/LICENCIAS.txt):",
          "- LibActionButton-1.0 y LibButtonGlow-1.0, de Hendrik \"nevcairiel\" Leppkes: BSD de 3 cláusulas.",
          "- CallbackHandler-1.0, del equipo de Ace3: licencia BSD de Ace3 (ver LICENCIAS_TERCEROS.md).",
          "- LibStub: dominio público.",
          "",
          "Datos:",
          "- Data from ForeverDB.net (https://foreverdb.net) — árboles y builds en Asistente_Clase",
          "  (GPL-3.0 con término de crédito; ver Asistente_Clase/NOTICE-ForeverDB.txt).",
          "- Builds de jugadores conocidos en Asistente_Clase: solo la repartición de puntos (un hecho),",
          "  cada una con el enlace a su fuente (foreverdb.net, mobalytics.gg, leprestore.com,",
          "  warcrafttavern.com, wowforeverbuilds.com, talentsforever.com, skill-capped.com, wowhead.com).",
          "- forever-db (Polestar, GPL-3.0 / CC BY 4.0), CMaNGOS classic-db (GPL-3.0), pfQuest (MIT),",
          "  ForeverLevelingBiS (MIT), wowsims (MIT), ForeverTDB (GPL-2.0, solo hechos) y tablas del",
          "  cliente del juego (Blizzard): cada carpeta de datos lo detalla en su LICENSE-DATA.txt.",
          "- XP por misión que les faltaba a las otras fuentes: leída de dos sitios web de Forever",
          "  (wowforevertalents.com y foreverchanges.pro). Solo números, sin textos, nombres ni páginas.",
          "  Esos sitios no publican licencia y sus dueños no la autorizaron. Cristian Amigo decidió",
          "  incluirla igual el 19-11-2026: \"asumamos el riesgo\". Es provisional: se reemplazará",
          "  por la XP calculada con ForeverTDB y la tabla QuestXP del cliente.",
          "",
          "Fuentes tipográficas (SIL OFL 1.1, texto junto a cada una): Inter, Open Sans, Fira Sans,",
          "Barlow Semi Condensed. Polestar_Arcade: Freedoom Arcade (GPL-2.0) y Freedoom (BSD-3).",
          "",
          "Polestar, de \"The Polestar authors\" (Fitz y colaboradores): todo lo demás de las carpetas",
          "Polestar*. Ver THIRD_PARTY.md.",
          ""]
    return "\n".join(l)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--paquete", type=Path, required=True)
    ap.add_argument("--manifiesto", type=Path, required=True)
    ap.add_argument("--version", required=True, help='por ejemplo "beta 1"')
    ap.add_argument("--commit", required=True)
    ap.add_argument("--fecha", default="2026-11-18")
    ap.add_argument("--salida", type=Path, required=True)
    ap.add_argument("--fuente", action="store_true", help="también arma Mamba_fuente_<commit>.zip con git archive")
    ap.add_argument("--build", type=int, help="AAAAMMDDHHMM; solo si el armado no viene sellado (sellar_version.py)")
    ap.add_argument("--notas", type=Path, help="«Qué cambió»: un archivo de texto, una novedad por línea")
    ap.add_argument("--canal", default=CANAL, help="dirección fija de mamba_grupo.json (la lee «Actualizar Mamba»)")
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

    sys.path.insert(0, str(AQUI))
    import sellar_version
    sello = sellar_version.leer(a.paquete)
    sello_zip = None  # contenido de Sello.lua que va en el ZIP si el armado no venía sellado
    if sello is None:
        print("AVISO: el armado no trae Mamba_Version: no habrá aviso de versión nueva dentro del juego")
        build = a.build or int(dt.datetime.now().strftime("%Y%m%d%H%M"))
    elif sello["build"] > 0:
        build = sello["build"]
        if a.build and a.build != build:
            print(f"NO SE ARMA: el armado está sellado con {build} y se pidió --build {a.build}")
            return 1
    else:
        build = a.build or int(dt.datetime.now().strftime("%Y%m%d%H%M"))
        sello_zip = sellar_version.PLANTILLA.format(build=build, texto=a.version, commit=a.commit).encode("utf-8")
        print(f"AVISO: el armado venía sin sellar; el ZIP lleva build {build}. Sella la carpeta ANTES de instalarla "
              "en el PC de Cristian (sellar_version.py) para que los dos números coincidan.")
    notas = [l.strip() for l in a.notas.read_text("utf-8").splitlines() if l.strip()] if a.notas else []
    if not notas:
        notas = ["Arreglos y mejoras."]
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
            z.writestr(rel, datos)
            n += 1
        poner("INSTALAR_MAMBA.bat", BAT_INSTALAR.encode("ascii"))
        poner("QUITAR_MAMBA.bat", BAT_QUITAR.encode("ascii"))
        poner("LEEME.txt", b"\xef\xbb\xbf" + crlf((AQUI / "LEEME.txt").read_text("utf-8")))
        poner("archivos/instalar.ps1", ps1(AQUI / "instalar.ps1"))
        poner("archivos/volver_atras.ps1", ps1(AQUI / "volver_atras.ps1"))
        poner("archivos/VERSION.txt", b"\xef\xbb\xbf" + version_txt.encode("utf-8") + b"\r\n")
        version_json = {"build": build, "version": a.version, "commit": a.commit, "fecha": a.fecha}
        poner("archivos/VERSION.json", json.dumps(version_json, ensure_ascii=False, indent=1).encode("utf-8"))
        poner("archivos/canal.json", json.dumps({"manifiesto": a.canal}, indent=1).encode("utf-8"))
        poner("archivos/actualizar.ps1", ps1(AQUI / "actualizar.ps1"))
        poner("QUE_CAMBIO.txt", b"\xef\xbb\xbf" + crlf(f"Mamba {version_txt}\n\nQué cambió:\n" + "".join(f"- {x}\n" for x in notas)))
        for lic in ("LICENSE", "LICENSE-EXCEPTION.md", "LICENCIAS_TERCEROS.md", "THIRD_PARTY.md"):
            poner(f"LICENCIAS/{lic}", (RAIZ / lic).read_bytes())
        fuente = f"Mamba_fuente_{a.commit}.zip"
        poner("LICENCIAS/CODIGO_FUENTE.txt", b"\xef\xbb\xbf" + crlf(aviso_fuente(a.version, a.commit, fuente)))
        poner("LICENCIAS/CREDITOS.txt", b"\xef\xbb\xbf" + crlf(creditos(a.paquete)))
        for p in sorted(a.paquete.rglob("*")):
            rel = p.relative_to(a.paquete).as_posix()
            if not p.is_file() or "/.github/" in "/" + rel or p.name == ".gitignore":
                continue
            datos = p.read_bytes()
            if sello_zip is not None and rel == "Mamba_Version/Sello.lua":
                datos = sello_zip
            if p.name == "LICENSE-DATA.txt":  # rutas de la máquina donde se construyó: no son datos
                datos = re.sub(rb"[A-Za-z]:/Users/[^/\s]+/Mamba/", b"<repo Mamba>/", datos)
                datos = re.sub(rb"[A-Za-z]:/rust/", b"<construccion>/", datos)
            poner("archivos/Mamba/" + rel, datos)
    if a.fuente:
        fz = a.salida / f"Mamba_fuente_{a.commit}.zip"
        subprocess.run(["git", "-C", str(RAIZ), "archive", "--format=zip", "-o", str(fz), a.commit], check=True)
        print(f"fuente: {fz} ({fz.stat().st_size / 1e6:.1f} MB)")
    h = hashlib.sha256(zpath.read_bytes()).hexdigest()
    (a.salida / (zpath.name + ".sha256")).write_text(f"{h}  {zpath.name}\n", "utf-8")
    print(f"ZIP: {zpath} ({zpath.stat().st_size / 1e6:.1f} MB, {n} archivos)\nsha256 {h}")
    # Lo que se publica en el lugar fijo (SOLO con el sí de Cristian): el ZIP con nombre fijo y su manifiesto.
    canal = a.salida / "canal"
    canal.mkdir(exist_ok=True)
    shutil.copyfile(zpath, canal / ZIP_FIJO)
    man = {"build": build, "version": a.version, "commit": a.commit, "fecha": a.fecha,
           "zip": ZIP_FIJO, "sha256": h, "notas": notas}
    (canal / "mamba_grupo.json").write_text(json.dumps(man, ensure_ascii=False, indent=1), "utf-8")
    print(f"canal: {canal} (mamba_grupo.json + {ZIP_FIJO}); build {build}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
