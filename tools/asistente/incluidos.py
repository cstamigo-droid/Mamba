"""Addons de otros autores, de licencia libre, que Mamba lleva dentro (ARQUITECTURA §16).

Se copian SIN cambiar su código. El único cambio es en su .toc: el título dice
"· Mamba" y una línea X-Mamba avisa que la copia viene dentro de Mamba y que
se modificó ese archivo (GPL-3.0 §5a). Su LICENSE y sus créditos van intactos.

    python -I tools/asistente/incluidos.py traer <carpeta AddOns>   # copia o actualiza desde un juego instalado
    python -I tools/asistente/incluidos.py revisar                  # comprueba licencia, versión y huellas (sale 1 si algo falla)

`incluidos.json` guarda, por addon: autor, licencia, versión, de dónde sale el
código fuente y la huella sha256 de cada archivo tal como lo publicó su autor
(antes de marcar el .toc). Así `revisar` detecta un cambio a mano en su código.
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
ADDON = RAIZ / "addon"
MANIFIESTO = Path(__file__).with_name("incluidos.json")
FECHA = "2026-11-16"
REPO = "https://github.com/cstamigo-droid/Mamba"
CR, LF = chr(13), chr(10)

INCLUIDOS = {
    "ForeverCore": {
        "autor": "cjber", "licencia": "GPL-3.0-or-later", "archivo_licencia": "LICENSE",
        "fuente": "https://github.com/cjber/forever-core",
        "reemplaza": "ForeverCore (lo necesita SkillUp Forever)",
    },
    "SkillUpForever": {
        "autor": "cjber", "licencia": "GPL-3.0-or-later", "archivo_licencia": "LICENSE",
        "fuente": "https://github.com/cjber/skillup-forever",
        "reemplaza": "SkillUpForever: qué receta subir, colores, probabilidad y materiales",
    },
    "WhatsTraining": {
        "autor": "Sveng (fusionpit)", "licencia": "MIT", "archivo_licencia": "LICENSE",
        "fuente": "https://github.com/fusionpit/WhatsTraining",
        "reemplaza": "WhatsTraining: qué aprender en el instructor y cuánto cuesta",
        "nota": "Lleva librerías de terceros: LibStub y LibBabble-3.0 (dominio público), "
                "LibBabble-CreatureType-3.0 (MIT), CallbackHandler-1.0 y LibDBIcon-1.0 (Ace3, BSD con "
                "la condición de no repartirlas sueltas: van dentro de WhatsTraining, como las publica su autor), "
                "LibDataBroker-1.1 (dominio público) y FusionIgnoreStore (del autor de WhatsTraining, MIT).",
    },
    "ForeverLootSparkles": {
        "autor": "Ashtar Senior", "licencia": "GPL-3.0-or-later", "archivo_licencia": "LICENSE",
        "fuente": "https://www.curseforge.com/wow/addons/forever-loot-sparkles (proyecto 1729017; el código es el del zip)",
        "reemplaza": "ForeverLootSparkles: brillo en los objetos de misión que se pueden recoger",
    },
}

TITULO = re.compile(r"^(## Title(?:-\w+)?: )([^\r\n]*?)(?: · Mamba)?(\r?)$", re.M)
MARCA = re.compile(r"^## X-Mamba:[^\r\n]*", re.M)
VERSION = re.compile(r"^## Version: *([^\r\n]+)", re.M)
LIC_TOC = re.compile(r"^## X-License: *([^\r\n]+)", re.M)


def _huella(datos: bytes) -> str:
    # El repositorio guarda el texto con LF (.gitattributes): se cuenta igual con CRLF o LF.
    if b"\0" not in datos:
        datos = datos.replace(b"\r\n", b"\n")
    return hashlib.sha256(datos).hexdigest()


def _huellas(carpeta: Path) -> dict[str, str]:
    return {p.relative_to(carpeta).as_posix(): _huella(p.read_bytes())
            for p in sorted(carpeta.rglob("*")) if p.is_file()}


def _marcar_toc(texto: str, nombre: str) -> str:
    texto = TITULO.sub(lambda m: f"{m.group(1)}{m.group(2)} · Mamba{m.group(3)}", texto)
    marca = (f"## X-Mamba: incluido sin cambios de código en Mamba ({REPO}); "
             f"solo este .toc se modificó el {FECHA}. Autor y licencia: ver LICENSE.")
    if MARCA.search(texto):
        return MARCA.sub(marca, texto)
    lineas = texto.splitlines(keepends=True)
    ultimo = max(i for i, l in enumerate(lineas) if l.startswith("## "))
    fin = CR + LF if lineas[ultimo].endswith(CR + LF) else LF
    lineas.insert(ultimo + 1, marca + fin)
    return "".join(lineas)


def traer(origen: Path) -> int:
    manifiesto = {}
    for nombre, info in INCLUIDOS.items():
        src = origen / nombre
        if not (src / info["archivo_licencia"]).is_file():
            print(f"FALTA {nombre}: no está en {origen} o no trae {info['archivo_licencia']}")
            return 1
        dst = ADDON / nombre
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        toc = dst / f"{nombre}.toc"
        t = toc.read_bytes().decode("utf-8")
        version = VERSION.search(t).group(1).strip()
        huellas = _huellas(dst)
        toc.write_bytes(_marcar_toc(t, nombre).encode("utf-8"))
        manifiesto[nombre] = {**info, "version": version, "toc": f"{nombre}.toc", "huellas": huellas}
        print(f"traído {nombre} {version}: {len(huellas)} archivos")
    MANIFIESTO.write_text(json.dumps(manifiesto, ensure_ascii=False, indent=1) + LF, "utf-8")
    return revisar()


def revisar() -> int:
    errores = []
    manifiesto = json.loads(MANIFIESTO.read_text("utf-8"))
    for nombre, info in manifiesto.items():
        dst = ADDON / nombre
        lic = dst / info["archivo_licencia"]
        if not lic.is_file():
            errores.append(f"{nombre}: falta su {info['archivo_licencia']}")
            continue
        texto_lic = lic.read_text("utf-8", "replace")
        esperado = "MIT License" if info["licencia"] == "MIT" else "GNU GENERAL PUBLIC LICENSE"
        if esperado not in texto_lic:
            errores.append(f"{nombre}: su LICENSE no es {info['licencia']}")
        toc = (dst / info["toc"]).read_bytes().decode("utf-8")
        if VERSION.search(toc).group(1).strip() != info["version"]:
            errores.append(f"{nombre}: la versión del .toc no es {info['version']}")
        m = LIC_TOC.search(toc)
        if m and info["licencia"] not in m.group(1):
            errores.append(f"{nombre}: el .toc dice licencia {m.group(1)}")
        if "## X-Mamba:" not in toc or "· Mamba" not in toc:
            errores.append(f"{nombre}: falta el aviso de modificación en el .toc")
        actuales = _huellas(dst)
        for rel, h in info["huellas"].items():
            if rel == info["toc"]:
                continue
            if actuales.get(rel) != h:
                errores.append(f"{nombre}/{rel}: cambió o falta (el código va sin cambios)")
        for rel in set(actuales) - set(info["huellas"]):
            errores.append(f"{nombre}/{rel}: archivo nuevo que no viene de su autor")
    for e in errores:
        print("ERROR:", e)
    print(f"{len(manifiesto)} addons incluidos, {len(errores)} errores")
    return 1 if errores else 0


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "traer":
        sys.exit(traer(Path(sys.argv[2])))
    if len(sys.argv) >= 2 and sys.argv[1] == "revisar":
        sys.exit(revisar())
    print(__doc__)
    sys.exit(2)
