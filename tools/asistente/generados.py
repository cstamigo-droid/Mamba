"""Escribe GENERADOS.txt: los archivos generados de Polestar que están en git (ARQUITECTURA §13f.3).

    python -I tools/asistente/generados.py           # reescribe GENERADOS.txt
    python -I tools/asistente/generados.py --revisar # sale 1 si GENERADOS.txt quedó viejo

Un archivo es [AJENO] si su cabecera o su marca de datos nombra Leffe, QuestieDB, DingDB
o forever-vo (mismo criterio que control_zip.py), o si el LICENSE-DATA.txt de su carpeta
dice que sus datos salen de una de esas fuentes, o si sale de las guias de Polestar (que son [AJENO]).
Se miran las carpetas de Polestar y las de Mamba (Asistente*, Tasador, Medidor); los addons
incluidos (incluidos.py) van como los publica su autor.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import control_zip as cz  # noqa: E402

RAIZ = Path(__file__).resolve().parents[2]
SALIDA = RAIZ / "GENERADOS.txt"
CABECERA = [
    "# Archivos GENERADOS de Polestar que están en git (ARQUITECTURA §13f.3). No editar: lo escribe",
    "# tools/asistente/generados.py.",
    "# Al fusionar una versión nueva de Polestar: git checkout --theirs -- <estos> y regenerarlos con nuestras opciones.",
    "# [AJENO] = hecho con fuentes de permiso solo para Polestar (Leffe, QuestieDB, DingDB, forever-vo):",
    "#           NO va en un zip de Mamba hasta regenerarlo sin ellas (forge --no-questie --nav grid).",
    "# [REGENERAR] = sale de data/forever, que en la máquina de Polestar incluye la capa de QuestieDB:",
    "#           se regenera desde nuestra construcción --no-questie antes de repartir un zip.",
    "# Sin marca = sale solo de las tablas del cliente, de fuentes libres o del propio Polestar.",
]


def carpeta_ajena(carpeta: Path) -> bool:
    lic = carpeta / "LICENSE-DATA.txt"
    if not lic.is_file():
        return False
    return any(cz.AJENAS.search(t) for t in cz._secciones_fuente(lic.read_text("utf-8", "replace")))


def lista() -> list[str]:
    archivos = subprocess.run(["git", "ls-files", "addon"], capture_output=True, text=True, cwd=RAIZ, check=True).stdout.split()
    lineas = []
    for rel in archivos:
        partes = rel.split("/")
        if len(partes) < 3 or not partes[1].startswith(("Polestar", "Asistente", "Tasador", "Medidor")) or not rel.endswith(".lua"):
            continue
        datos = (RAIZ / rel).read_bytes()
        cab = cz._cabecera(datos)
        gen = [l for l in cab.splitlines() if cz.GENERADO.match(l)]
        if not gen:
            continue
        fuentes = "\n".join(l for l in cab.splitlines() if cz.GENERADO.match(l))
        ajeno = (cz.AJENAS.search(fuentes) or cz.LEFFE.search(datos[:65536].decode("utf-8", "replace"))
                 or carpeta_ajena(RAIZ / partes[0] / partes[1]))
        # data/forever se construye por capas y en la máquina de Polestar lleva la de QuestieDB
        # (docs/forge/data.md, "How the merge works"): lo que sale de ahí se regenera con --no-questie.
        # Lo que sale de las guías de Polestar hereda su marca: --no-questie no lo limpia (revisor, M4).
        ajeno = ajeno or "leveling guides" in fuentes or "guides' `reward` lines" in fuentes
        regenerar = not ajeno and "data/forever" in fuentes
        lineas.append(("[AJENO] " if ajeno else "[REGENERAR] " if regenerar else "") + rel)
    return lineas


def main() -> int:
    texto = "\n".join(CABECERA + lista()) + "\n"
    if "--revisar" in sys.argv:
        viejo = SALIDA.read_text("utf-8") if SALIDA.exists() else ""
        if viejo != texto:
            print("GENERADOS.txt quedó viejo: correr tools/asistente/generados.py")
            return 1
        print("GENERADOS.txt al día")
        return 0
    SALIDA.write_text(texto, "utf-8")
    n = texto.count("\n") - len(CABECERA)
    print(f"{n} generados, {texto.count('[AJENO]')} ajenos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
