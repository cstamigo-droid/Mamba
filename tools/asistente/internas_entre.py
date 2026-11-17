"""¿Cambió alguna función INTERNA de Polestar que usa un módulo de Mamba entre dos etiquetas?

    python -I tools/asistente/internas_entre.py v0.4.0 v0.4.0.1

Usa la lista INTERNAS y FORMATOS y la forma de medir (cuerpo de la definición, cabecera de formato)
del vigía `generador/polestar_al_dia.py` (copia en tools/asistente/generador/, o la del proyecto si se
pasa --vigia RUTA). Lee las dos versiones desde git (no descarga nada). Sale 1 si alguna cambió.
"""
from __future__ import annotations

import hashlib
import importlib.util
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]


def cargar_vigia(ruta: Path):
    spec = importlib.util.spec_from_file_location("vigia", ruta)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def git_show(tag: str, ruta: str) -> str:
    return subprocess.run(["git", "show", f"{tag}:{ruta}"], cwd=RAIZ, capture_output=True, check=True).stdout.decode("utf-8")


def ruta_repo(url_o_ruta: str) -> str:
    # El vigía guarda rutas del repositorio (addon/Polestar/Gear/Gear.lua) o URLs raw que las terminan.
    i = url_o_ruta.find("addon/")
    return url_o_ruta[i:] if i >= 0 else url_o_ruta


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    a, b = argv[0], argv[1]
    vigia = Path(argv[argv.index("--vigia") + 1]) if "--vigia" in argv else RAIZ / "tools/asistente/generador/polestar_al_dia.py"
    v = cargar_vigia(vigia)
    cambios, total = [], 0
    for archivo, prefijo, nombre, modulo in v.INTERNAS:
        r = ruta_repo(archivo)
        h = [hashlib.sha256(v.cuerpo_definicion(git_show(t, r), prefijo, nombre).encode()).hexdigest()[:12] for t in (a, b)]
        total += 1
        if h[0] != h[1]:
            cambios.append(f"{prefijo}.{nombre} ({r}, {modulo})")
    for archivo in getattr(v, "FORMATOS", []):
        r = ruta_repo(archivo)
        h = [hashlib.sha256(v.cabecera_formato(git_show(t, r)).encode()).hexdigest()[:12] for t in (a, b)]
        total += 1
        if h[0] != h[1]:
            cambios.append(f"formato de {r}")
    for c in cambios:
        print("CAMBIÓ:", c)
    print(f"{total} huellas internas comparadas entre {a} y {b}: {len(cambios)} cambiaron")
    return 1 if cambios else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
