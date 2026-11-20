"""Sella la versión de un armado de Mamba (19-11-2026).

Escribe Mamba_Version/Sello.lua dentro de la carpeta armada (la de armar_instalar.py), ANTES de instalarla en el
PC de Cristian. Así la instalación de Cristian y el ZIP del grupo, que salen de la misma carpeta, llevan el mismo
número: el aviso del juego ("hay una versión nueva") compara justo eso.

Uso:
    python -I tools/asistente/grupo/sellar_version.py <carpeta armada> --texto "beta 2" --commit <commit> [--build AAAAMMDDHHMM]
    python -I tools/asistente/grupo/sellar_version.py <carpeta armada> --leer      (muestra el sello)
Sin --build usa la hora actual. Sale con 1 si la carpeta no trae Mamba_Version.
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path

PLANTILLA = '''-- Sello de la versión de este armado de Mamba. Lo reescribe tools/asistente/grupo/sellar_version.py al armar
-- (la instalación de Cristian y el ZIP del grupo salen del mismo armado y llevan el mismo sello).
-- build = AAAAMMDDHHMM del armado: el número más alto es el más nuevo. 0 = sin sellar (copia de desarrollo).
MambaSello = {{ build = {build}, texto = "{texto}", commit = "{commit}" }}
'''
PATRON = re.compile(r'MambaSello = \{ build = (\d+), texto = "([^"]*)", commit = "([^"]*)" \}')


def leer(carpeta: Path) -> dict | None:
    p = carpeta / "Mamba_Version" / "Sello.lua"
    if not p.exists():
        return None
    m = PATRON.search(p.read_text("utf-8"))
    return {"build": int(m.group(1)), "texto": m.group(2), "commit": m.group(3)} if m else None


def sellar(carpeta: Path, texto: str, commit: str, build: int) -> Path:
    p = carpeta / "Mamba_Version" / "Sello.lua"
    if not p.parent.is_dir():
        raise FileNotFoundError(f"{carpeta} no trae Mamba_Version")
    if '"' in texto or '"' in commit:
        raise ValueError("el texto y el commit no pueden llevar comillas")
    p.write_text(PLANTILLA.format(build=build, texto=texto, commit=commit), "utf-8", newline="\n")
    return p


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("carpeta", type=Path)
    ap.add_argument("--texto")
    ap.add_argument("--commit")
    ap.add_argument("--build", type=int)
    ap.add_argument("--leer", action="store_true")
    a = ap.parse_args()
    if a.leer:
        s = leer(a.carpeta)
        print(s if s else "sin Mamba_Version o sin sello")
        return 0 if s else 1
    if not a.texto or not a.commit:
        ap.error("--texto y --commit son obligatorios para sellar")
    build = a.build or int(dt.datetime.now().strftime("%Y%m%d%H%M"))
    try:
        p = sellar(a.carpeta, a.texto, a.commit, build)
    except (FileNotFoundError, ValueError) as e:
        print("NO SE SELLA:", e)
        return 1
    print(f"sellado {p}: build {build}, {a.texto}, {a.commit}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
