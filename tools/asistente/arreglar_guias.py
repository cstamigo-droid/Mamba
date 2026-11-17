"""Arreglos mecánicos de las guías de Mamba donde los datos sin QuestieDB difieren (17-11).

Las guías de Polestar se escribieron contra QuestieDB. Con pfQuest + CMaNGOS + forever-db (P7) quedan
unas decenas de líneas que forge rechaza. Este paso corre `forge guide lint` sobre la copia que arma
guias_sin_fuente.py (nunca sobre guides/ del repositorio) y aplica solo lo que el propio mensaje de
forge dice cómo arreglar:

  - `turnin … direct` que la cadena ya aceptó: se quita `direct`.
  - `quest N.k` que apunta a otro objetivo: se cambia al índice que forge nombra (N.j).
  - `quest N.k` cuando los datos tienen menos objetivos: se quita la referencia (la acción queda).
  - `kill` de un élite: queda `optional` con el consejo "X is elite: grouping up is advised."
  - `learn N` sin nombre: el nombre del hechizo sale de SpellName.csv (tablas del juego, wago.tools).
  - Objeto sin datos o sin vendedor: la línea sale (NO VERIFICADO).
  - Misión "never accepted": la línea sale SOLO si la construcción anterior (pack-errors de forge
    build) también la marcó; lint no ve las cadenas de las rutas y daría falsos positivos.

Todo lo demás queda en el informe sin tocar. Repite hasta 4 vueltas.
Uso:  python -I tools/asistente/arreglar_guias.py <carpeta de guías>
Informe: <carpeta>_ARREGLOS.md
"""
from __future__ import annotations

import csv
import re
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
FORGE = Path(r"D:\rust\target\release\forge.exe")
OUT_DATA = Path(r"D:\rust\forge-out\data\forever")
FLOW = Path(r"D:\rust\forge-out\.forge\flow")
ERR = re.compile(r"^(?P<f>.+?\.guide):(?P<l>\d+): error: (?P<m>.*)$")
PACK = re.compile(r"^(?P<f>.+?\.guide):(?P<l>\d+) (?P<m>.*)$")
NUNCA = re.compile(r"^`(turnin|collect|kill)` for quest (\d+) that is never accepted")


def lint(guias: Path) -> list[tuple[Path, int, str]]:
    # professions.json y travel.json los escribe forge build (no el paso de datos): sin ellos lint
    # marca cada `learn`/`craft`/`train` de profesión. Se toman de la construcción anterior y se quitan.
    puestos = []
    for n in ("professions.json", "travel.json"):
        src, dst = OUT_DATA / n, RAIZ / "data" / "forever" / n
        if src.is_file() and not dst.exists():
            shutil.copyfile(src, dst)
            puestos.append(dst)
    try:
        r = subprocess.run([str(FORGE), "guide", "lint", "--guides", str(guias), "--quiet"], cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace")
    finally:
        for p in puestos:
            p.unlink(missing_ok=True)
    out = []
    for l in (r.stdout + r.stderr).splitlines():
        m = ERR.match(l)
        if m:
            out.append((Path(m["f"]), int(m["l"]), m["m"]))
    return out


def nunca_en_build() -> set[tuple[str, int]]:
    """(guía relativa, misión) que forge build marcó como "never accepted"."""
    s = set()
    for f in FLOW.glob("*.pack-errors.txt"):
        for l in f.read_text(encoding="utf-8", errors="replace").splitlines():
            m = PACK.match(l)
            if not m:
                continue
            n = NUNCA.match(m["m"])
            if n:
                rel = m["f"].replace("\\", "/").split("/flow/", 1)[-1].split("/", 1)[-1]
                s.add((rel, int(n[2])))
    return s


def hechizos() -> dict[int, str]:
    d: dict[int, str] = {}
    for f in sorted((RAIZ / "data" / "sources" / "wago").glob("*/SpellName.csv")):
        with f.open(encoding="utf-8", newline="") as h:
            for row in csv.DictReader(h):
                try:
                    d[int(row["ID"])] = row["Name_lang"] if "Name_lang" in row else list(row.values())[1]
                except (KeyError, ValueError):
                    pass
    return d


def con_comentario(linea: str, agregar: str) -> str:
    cod, sep, com = linea.partition("--")
    return cod.rstrip() + " " + agregar + ("   " + sep + com if sep else "")


def arreglar(linea: str, msg: str, rel: str, nunca: set, spells: dict) -> tuple[str | None, list[str], str] | None:
    """(línea nueva o None si sale, líneas extra después, qué se hizo) o None si no se sabe."""
    if "is marked `direct`" in msg:
        return re.sub(r"\s+direct\b", "", linea, count=1), [], "sin `direct`"
    m = re.match(r"^quest (\d+)\.(\d+) is .*; .* is (\d+)\.(\d+)$", msg)
    if m and m[1] == m[3] and f"quest {m[1]}.{m[2]}" in linea:
        return linea.replace(f"quest {m[1]}.{m[2]}", f"quest {m[1]}.{m[4]}", 1), [], f"índice {m[1]}.{m[2]} → {m[1]}.{m[4]}"
    m = re.match(r"^quest (\d+) has \d+ objective\(s\) in data, not \d+", msg)
    if m:
        nueva = re.sub(rf"\s+quest {m[1]}\.\d+\b", "", linea, count=1)
        if nueva != linea:
            return nueva, [], f"sin la referencia al objetivo de {m[1]} (los datos tienen menos)"
    m = re.match(r"^`kill` npc (\d+) \((.+?)\) is elite", msg)
    if m and "optional" not in linea.split("--")[0]:
        ind = linea[: len(linea) - len(linea.lstrip())]
        return con_comentario(linea, "optional"), [f"{ind}tip {m[2]} is elite: grouping up is advised."], "élite → optional"
    m = re.match(r'^spell (\d+) is not in data; give its name: `learn', msg)
    if m and int(m[1]) in spells and '"' not in linea.split("--")[0]:
        nueva = re.sub(rf"\blearn {m[1]}\b", f'learn {m[1]} "{spells[int(m[1])]}"', linea, count=1)
        return nueva, [], f"nombre del hechizo {m[1]} desde SpellName.csv"
    if re.match(r"^item \d+ is not in data", msg) or msg.startswith("`buy` found no vendor"):
        return None, [], "línea fuera (NO VERIFICADO: sin datos)"
    n = NUNCA.match(msg)
    if n and (rel, int(n[2])) in nunca:
        return None, [], "línea fuera (la cadena nunca acepta la misión, también en forge build)"
    return None


def desde_build(guias: Path) -> list[tuple[str, int, str, str]]:
    """Segunda fase: lo que forge build marcó al armar las rutas (pack-errors) y lint no ve.

    Las líneas de los flujos no coinciden con las de las guías de origen: cada arreglo ubica su línea
    por el contenido (verbo e id) en la guía del mismo nombre, o por el título del paso.
    """
    hechos = []
    errores: set[tuple[str, int, str]] = set()
    for f in FLOW.glob("*.pack-errors.txt"):
        start = f.name.split(".pack-errors")[0]
        for l in f.read_text(encoding="utf-8", errors="replace").splitlines():
            m = PACK.match(l)
            if m:
                rel = m["f"].replace("\\", "/").split("/flow/", 1)[-1].split("/", 1)[-1]
                errores.add((rel, int(m["l"]), m["m"], start))
    for rel_flujo, fl, msg, start in sorted(errores):
        # La ruta puede mover pasos a otro archivo de su flujo (p. ej. horde/tauren/02-silverpine-forest
        # no existe en las guías): entonces el arreglo va a cada guía que nombra el id del mensaje.
        idm = re.search(r"\b(\d{3,7})\b", msg)
        clave = idm[1] if idm else None
        propia = guias / rel_flujo
        if propia.is_file() and clave and re.search(rf"^\s*\w+ .*\b{clave}\b", propia.read_text(encoding="utf-8"), re.M) and not NUNCA.match(msg):
            destinos = [propia]
        elif clave:
            destinos = [x for x in sorted(guias.rglob("*.guide")) if re.search(rf"^\s*\w+ .*\b{clave}\b", x.read_text(encoding="utf-8"), re.M)]
        else:
            destinos = [propia] if propia.is_file() else []
        if msg.startswith("duplicate `loop`") or msg.startswith("unknown label"):
            destinos = [propia] if propia.is_file() else []
        for g in destinos:
            hechos += _arreglo_build(g, g.relative_to(guias).as_posix(), rel_flujo, fl, msg, start)
    print(f"desde forge build: {len(hechos)} arreglos")
    return hechos


def _arreglo_build(g: Path, rel: str, rel_flujo: str, fl: int, msg: str, start: str) -> list:
    hechos: list = []
    if True:
        lineas = g.read_bytes().decode("utf-8").split("\n")
        quitar: list[int] = []
        que = ""
        m = re.match(r"^npc (\d+) is not in data", msg)
        if m:
            quitar = [i for i, x in enumerate(lineas) if re.match(rf"^\s*(talk|kill|vendor|train|interact) {m[1]}\b", x)]
            que = f"línea fuera (PNJ {m[1]} sin datos en ninguna fuente autorizada: NO VERIFICADO)"
        n = NUNCA.match(msg)
        if n:
            v, q = n[1], n[2]
            # Una entrega que la ruta pone antes de aceptar: la misión entera sale de esa guía.
            pat = rf"^\s*(turnin|accept|complete) {q}\b" if v == "turnin" else rf"^\s*{v} .*\bquest {q}(\.\d+)?\b"
            quitar = [i for i, x in enumerate(lineas) if re.match(pat, x)]
            que = f"línea fuera ({v} de la misión {q}, que la ruta pone antes de aceptarla)"
        m = re.match(r'^unknown label "(.+?)"', msg)
        if m:
            quitar = [i for i, x in enumerate(lineas) if re.match(rf"^\s*\w+ until {re.escape(m[1])}\s*$", x.split("--")[0])]
            que = f"línea fuera (la etiqueta {m[1]} quedó en un paso que la ruta no usa)"
        if quitar:
            for i in reversed(quitar):
                hechos.append((rel, i + 1, que, lineas[i].strip()))
                del lineas[i]
            g.write_bytes("\n".join(lineas).encode("utf-8"))
            return hechos
        m = re.match(r'^`collect` item (\d+) \((.+?)\) drops only from elites.*with the tip "(.+?)"', msg)
        if m:
            for i, x in enumerate(lineas):
                if re.match(rf"^\s*collect {m[1]}\b", x) and "optional" not in x.split("--")[0]:
                    cr = "\r" if x.endswith("\r") else ""
                    ind = x[: len(x) - len(x.lstrip())]
                    lineas[i] = con_comentario(x.rstrip("\r"), "optional") + cr
                    lineas.insert(i + 1, f"{ind}tip {m[3]}{cr}")
                    hechos.append((rel, i + 1, "élite → optional", x.strip()))
                    break
            g.write_bytes("\n".join(lineas).encode("utf-8"))
            return hechos
        if msg.startswith("duplicate `loop` in step"):
            flujo = FLOW / start / rel_flujo
            if flujo.is_file():
                fll = flujo.read_text(encoding="utf-8", errors="replace").split("\n")
                titulo = next((fll[i] for i in range(min(fl, len(fll)) - 1, -1, -1) if fll[i].startswith("step ")), None)
                if titulo:
                    t = titulo.strip()
                    try:
                        ini = next(i for i, x in enumerate(lineas) if x.strip() == t)
                    except StopIteration:
                        return hechos
                    for i in range(ini + 1, len(lineas)):
                        if lineas[i].startswith("step "):
                            break
                        if lineas[i].strip() == "loop":
                            hechos.append((rel, i + 1, "sin el `loop` propio: la ruta pone el suyo (salía duplicado)", lineas[i].strip()))
                            del lineas[i]
                            g.write_bytes("\n".join(lineas).encode("utf-8"))
                            break
    return hechos


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    guias = Path(sys.argv[1])
    nunca = nunca_en_build()
    spells = hechizos()
    hechos: list[tuple[str, int, str, str]] = []
    pendientes: list[tuple[str, int, str]] = []
    for vuelta in range(4):
        errs = lint(guias)
        por_archivo: dict[Path, list[tuple[int, str]]] = {}
        pendientes = []
        for f, l, m in errs:
            por_archivo.setdefault(f, []).append((l, m))
        cambios = 0
        for f, lista in por_archivo.items():
            if not f.is_file():
                continue
            rel = f.resolve().relative_to(guias.resolve()).as_posix()
            texto = f.read_bytes().decode("utf-8")
            lineas = texto.split("\n")
            for l, m in sorted(lista, key=lambda x: -x[0]):
                if not (1 <= l <= len(lineas)):
                    continue
                if m == "step has no goals" and lineas[l - 1].startswith("step "):
                    # Un paso que se quedó vacío por los arreglos de arriba (o por guias_sin_fuente): sale entero.
                    fin = l
                    while fin < len(lineas) and not lineas[fin].startswith("step "):
                        fin += 1
                    hechos.append((rel, l, "paso vacío fuera", lineas[l - 1].strip()))
                    del lineas[l - 1 : fin]
                    cambios += 1
                    continue
                r = arreglar(lineas[l - 1].rstrip("\r"), m, rel, nunca, spells)
                if r is None:
                    pendientes.append((rel, l, m))
                    continue
                nueva, extra, que = r
                cr = "\r" if lineas[l - 1].endswith("\r") else ""
                antes = lineas[l - 1].strip()
                if nueva is None:
                    del lineas[l - 1]
                else:
                    lineas[l - 1] = nueva + cr
                    for i, e in enumerate(extra):
                        lineas.insert(l + i, e + cr)
                hechos.append((rel, l, que, antes))
                cambios += 1
            f.write_bytes("\n".join(lineas).encode("utf-8"))
        print(f"vuelta {vuelta + 1}: {len(errs)} errores de lint, {cambios} arreglos")
        if cambios == 0:
            break
    hechos += desde_build(guias)
    rep = guias.parent / (guias.name + "_ARREGLOS.md")
    with rep.open("w", encoding="utf-8") as h:
        h.write("# Arreglos mecánicos de las guías de Mamba (arreglar_guias.py)\n\n")
        h.write(f"{len(hechos)} arreglos; {len(pendientes)} errores de lint sin arreglo automático.\n\n| Guía | Línea | Qué | Antes |\n|---|---|---|---|\n")
        for g, l, q, a in hechos:
            h.write(f"| {g} | {l} | {q} | `{a.replace('|', '/')}` |\n")
        h.write("\n## Sin arreglo automático\n\n")
        for g, l, m in pendientes:
            h.write(f"- {g}:{l} {m}\n")
    print(f"{len(hechos)} arreglos; {len(pendientes)} sin arreglo; informe en {rep}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
