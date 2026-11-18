"""Carpeta de guías para `forge guide compile` de Mamba (18-11).

guides/ del repositorio, después de `forge guide publish`, tiene las guías que escribió la ruta
(GENERATED.json) y el resto tal como vienen de Polestar, sin los filtros de Mamba: compilarlo da cientos
de errores por misiones sin fuente. Esta carpeta toma guides/ entero (pack.json, legs.json, locales…) y
reemplaza cada guía que NO generó la ruta por su versión filtrada de la copia de construcción
(guias_sin_fuente.py + arreglar_guias.py), que es la que forge build aprobó.

Uso: python -I tools/asistente/guias_para_compilar.py <guías filtradas> <carpeta de salida>
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]


def arreglar(dest: Path, salida: Path) -> int:
    """Arreglos de los errores que `guide compile` no deja pasar ni con --force (18-11 03:20):
    - "`turnin` for quest N that is never accepted": sale la línea (y su paso, si quedó sin metas);
    - "`next` points to unknown guide \"polestar-experimental/…\"": el paquete experimental no se compila
      junto; sale la línea `next`."""
    import re
    n = 0
    for l in salida.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r"^(?P<f>.+?\.guide):(?P<l>\d+): error: (?P<m>.*)$", l)
        if not m:
            continue
        rel = m["f"].replace("\\", "/").split(dest.name + "/", 1)[-1]
        g = dest / rel
        if not g.is_file():
            continue
        lineas = g.read_bytes().decode("utf-8").split("\n")
        i = int(m["l"]) - 1
        if not (0 <= i < len(lineas)):
            continue
        nunca = re.match(r"^`(?:turnin|collect)` for quest (\d+) that is never accepted", m["m"])
        exp = re.match(r'^`next` points to unknown guide "polestar-experimental/', m["m"])
        if nunca and (re.match(rf"^\s*turnin {nunca[1]}\b", lineas[i])
                      or re.match(rf"^\s*collect .*\bquest {nunca[1]}\b", lineas[i])):
            del lineas[i]
            ini = max(k for k in range(i + 1) if k < len(lineas) and lineas[k].startswith("step ")) if any(lineas[k].startswith("step ") for k in range(min(i + 1, len(lineas)))) else None
            if ini is not None:
                fin = next((k for k in range(ini + 1, len(lineas)) if lineas[k].startswith("step ")), len(lineas))
                if not any(x.strip() and not re.match(r"^\s*(when|zone|tip|note|goto|#|--)", x) for x in lineas[ini + 1 : fin]):
                    del lineas[ini:fin]
        elif exp and lineas[i].startswith("next "):
            del lineas[i]
        else:
            continue
        g.write_bytes("\n".join(lineas).encode("utf-8"))
        print(f"compilar: arreglo {rel}:{i + 1} ({m['m'][:60]})")
        n += 1
    return n


def main() -> int:
    if len(sys.argv) == 4 and sys.argv[1] == "--arreglar":
        arreglar(Path(sys.argv[2]), Path(sys.argv[3]))
        return 0
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    filtradas, dest = Path(sys.argv[1]), Path(sys.argv[2])
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(RAIZ / "guides", dest)
    gen = set(json.loads((RAIZ / "guides" / "GENERATED.json").read_text(encoding="utf-8")).get("files", {}))
    cambiadas = quitadas = 0
    for g in dest.rglob("*.guide"):
        rel = g.relative_to(dest).as_posix()
        if rel in gen:
            continue
        f = filtradas / rel
        if f.is_file():
            if f.read_bytes() != g.read_bytes():
                shutil.copyfile(f, g)
                cambiadas += 1
        else:
            g.unlink()
            quitadas += 1
    print(f"compilar: {len(gen)} guías de la ruta; {cambiadas} reemplazadas por la versión filtrada; {quitadas} quitadas")
    vacias(dest)
    return 0


def vacias(dest: Path) -> None:
    """Una guía que en Polestar tenía misiones y aquí quedó sin ninguna (todas sin fuente, p. ej.
    Shen'dralas) sería puro viaje en la ruta: sale, y cada `next` que la nombraba pasa a su `next`
    (revisión wow-leveo 18-11)."""
    import re
    mision = re.compile(r"^\s*(accept|turnin)\s+\d+", re.M)
    ids, siguiente, sin = {}, {}, set()
    for g in dest.rglob("*.guide"):
        t = g.read_text(encoding="utf-8")
        m = re.search(r"^guide (\S+)", t, re.M)
        if not m:
            continue
        gid = m[1]
        ids[gid] = g
        siguiente[gid] = re.findall(r"^next (\S+)", t, re.M)  # una por facción, a veces
        orig = RAIZ / "guides" / g.relative_to(dest)
        if not mision.search(t) and orig.is_file() and mision.search(orig.read_text(encoding="utf-8")):
            sin.add(gid)
    def destino_para(gid: str, quien: str):
        """El `next` de `gid` que sigue la facción de `quien` (forever/horde/… o forever/alliance/…),
        saltando las otras guías vacías."""
        lado = next((f for f in ("/horde/", "/alliance/") if f in quien + "/"), None)
        visto = set()
        while gid in sin and gid not in visto:
            visto.add(gid)
            ops = siguiente.get(gid) or []
            gid = next((o for o in ops if lado and lado in o + "/"), next((o for o in ops if "/horde/" not in o and "/alliance/" not in o), ops[0] if ops else None))
        return gid

    for gid in sorted(sin):
        for otro, g in ids.items():
            if otro in sin:
                continue
            t = g.read_text(encoding="utf-8")
            destino = destino_para(gid, otro)
            nuevo = re.sub(rf"^next {re.escape(gid)}[ 	]*$", f"next {destino}" if destino else "", t, flags=re.M)
            if nuevo != t:
                g.write_text(nuevo, encoding="utf-8", newline=chr(10))
                print(f"compilar: {otro}: next {gid} -> {destino or '(ninguna)'}")
        ids[gid].unlink()
        print(f"compilar: guía sin misiones quitada: {gid}")


if __name__ == "__main__":
    sys.exit(main())
