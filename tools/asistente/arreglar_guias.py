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
# Los pack-errors de cada construcción se acumulan aquí: la copia de las guías se rehace desde cero en
# cada corrida y una construcción que ya pasó no vuelve a listar lo que se arregló (17-11).
ACUMULADOS = RAIZ / "data" / "local" / "pack-errors-acumulados.txt"
NUNCA_REPORT = RAIZ / "data" / "local" / "nunca-report-acumulados.txt"
REGISTRO = Path(r"D:\rust\noche\registro.log")
META = re.compile(r"^\s*(tip|when|zone|only|map|note|#|--)")


def pack_errores() -> list[tuple[str, str]]:
    """(start, línea) de los pack-errors actuales más los acumulados; guarda la unión."""
    vistos: set[tuple[str, str]] = set()
    if ACUMULADOS.is_file():
        for l in ACUMULADOS.read_text(encoding="utf-8").splitlines():
            if "\t" in l:
                s, x = l.split("\t", 1)
                vistos.add((s, x))
    for f in FLOW.glob("*.pack-errors.txt"):
        start = f.name.split(".pack-errors")[0]
        for l in f.read_text(encoding="utf-8", errors="replace").splitlines():
            if PACK.match(l):
                vistos.add((start, l))
    ACUMULADOS.parent.mkdir(parents=True, exist_ok=True)
    ACUMULADOS.write_text("".join(f"{s}\t{x}" + chr(10) for s, x in sorted(vistos)), encoding="utf-8")
    return sorted(vistos)


def sin_pasos_vacios(lineas: list[str], tocadas: list[int]) -> list[str]:
    """Saca los pasos donde se quitó una línea y no quedó ninguna meta (solo tip/when/zone…)."""
    inicios = [i for i, x in enumerate(lineas) if x.startswith("step ")]
    fuera: list[tuple[int, int]] = []
    for k, ini in enumerate(inicios):
        fin = inicios[k + 1] if k + 1 < len(inicios) else len(lineas)
        if not any(ini < t < fin + 1 for t in tocadas):
            continue
        cuerpo = [x for x in lineas[ini + 1 : fin] if x.strip()]
        if not any(not META.match(x) for x in cuerpo):
            fuera.append((ini, fin))
    for ini, fin in reversed(fuera):
        del lineas[ini:fin]
    return lineas


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
    for _start, l in pack_errores():
            m = PACK.match(l)
            if not m:
                continue
            n = NUNCA.match(m["m"])
            if n:
                rel = m["f"].replace("\\", "/").split("/flow/", 1)[-1].split("/", 1)[-1]
                s.add((rel, int(n[2])))
    # La etapa final de forge build («report») revisa las guías de entrada y escribe sus errores solo en
    # el registro, no en pack-errors (18-11: 5 "never accepted" de la Horda, guías de la semilla). Se
    # guardan en NUNCA_REPORT porque cada corrida rehace el registro.
    vistos = set(NUNCA_REPORT.read_text(encoding="utf-8").splitlines()) if NUNCA_REPORT.is_file() else set()
    if REGISTRO.is_file():
        for l in REGISTRO.read_text(encoding="utf-8", errors="replace").splitlines():
            m = PACK.match(l)
            if m and "guias-mamba" in m["f"] and NUNCA.match(m["m"]):
                vistos.add(l)
    NUNCA_REPORT.write_text("".join(x + chr(10) for x in sorted(vistos)), encoding="utf-8")
    for l in vistos:
        m = PACK.match(l)
        n = NUNCA.match(m["m"]) if m else None
        if n:
            s.add((m["f"].replace("\\", "/").split("guias-mamba/", 1)[-1], int(n[2])))
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
    for start, l in pack_errores():
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
            # La ruta de un bando solo lee guías de ese bando (y las comunes): no tocar las del otro.
            bando = next((b for b in ("alliance", "horde") if f"/{b}/" in "/" + rel_flujo), None)
            otro = {"alliance": "horde", "horde": "alliance"}.get(bando or "")
            if otro:
                destinos = [x for x in destinos if f"/{otro}/" not in "/" + x.relative_to(guias).as_posix()]
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
            # La misión entera sale de esa guía: si solo sale el `kill`/`collect`, la ruta vuelve a generar
            # el objetivo antes de aceptarla (17-11: 98512 en Zephras Isle, tres veces).
            quitar = [i for i, x in enumerate(lineas) if re.match(rf"^\s*(turnin|accept|complete|skip) {q}\b", x) or re.search(rf"\bquest {q}(\.\d+)?\b", x.split("--")[0])]
            que = f"línea fuera ({v} de la misión {q}, que la ruta pone antes de aceptarla: sale la misión entera)"
        m = re.match(r'^unknown label "(.+?)"', msg)
        if m:
            quitar = [i for i, x in enumerate(lineas) if re.match(rf"^\s*\w+ until {re.escape(m[1])}\s*$", x.split("--")[0])]
            que = f"línea fuera (la etiqueta {m[1]} quedó en un paso que la ruta no usa)"
        # Una misión con título comodín ("<UNUSED>"): v0.4.1 no deja mostrarlo; la misión sale de la guía.
        # Desde el 17-11 21:57 lo hace guias_sin_fuente.py desde los datos (título comodín): los errores
        # acumulados traen números de línea de flujos viejos y aquí podían apuntar a otra misión.
        if False and re.match(r"^`\w+` shows the game's placeholder name", msg):
            flujo = FLOW / start / rel_flujo
            fll = flujo.read_text(encoding="utf-8", errors="replace").split("\n") if flujo.is_file() else []
            qm = re.search(r"^\s*(?:accept|turnin|complete|skip) (\d+)\b|\bquest (\d+)", fll[fl - 1]) if 0 < fl <= len(fll) else None
            if qm:
                q = qm[1] or qm[2]
                quitar = [i for i, x in enumerate(lineas) if re.match(rf"^\s*(accept|turnin|complete|skip) {q}\b", x) or re.search(rf"\bquest {q}(\.\d+)?\b", x.split("--")[0])]
                que = f"línea fuera (la misión {q} tiene un título comodín del juego, \"<UNUSED>\")"
        if quitar:
            for i in reversed(quitar):
                hechos.append((rel, i + 1, que, lineas[i].strip()))
                del lineas[i]
            lineas = sin_pasos_vacios(lineas, [i - k for k, i in enumerate(sorted(quitar))])
            g.write_bytes("\n".join(lineas).encode("utf-8"))
            return hechos
        # Recompensa sin datos en ninguna fuente autorizada: el id sale de la cabecera `reward item`.
        m = re.match(r"^reward item (\d+) is not in data", msg)
        if m:
            for i, x in enumerate(lineas):
                cod = x.split("--")[0].split()
                if cod[:2] == ["reward", "item"] and m[1] in cod[2:]:
                    resto = [w for w in cod[2:] if w != m[1]]
                    hechos.append((rel, i + 1, f"recompensa {m[1]} fuera (sin datos: NO VERIFICADO)", x.strip()))
                    if resto:
                        cr = "\r" if x.endswith("\r") else ""
                        lineas[i] = "reward item " + " ".join(resto) + cr
                    else:
                        del lineas[i]
                    break
            g.write_bytes("\n".join(lineas).encode("utf-8"))
            return hechos
        # Paso `when group N` con todas sus metas `optional` (el arreglo de élites las dejó así): se
        # quita `optional`, como dice forge; el consejo de élite queda.
        if "step is `optional`" in msg or re.match(r"^every goal of this `when group", msg):
            flujo = FLOW / start / rel_flujo
            fll = flujo.read_text(encoding="utf-8", errors="replace").split("\n") if flujo.is_file() else []
            titulo = next((fll[i] for i in range(min(fl, len(fll)) - 1, -1, -1) if fll[i].startswith("step ")), None)
            if titulo:
                ini = next((i for i, x in enumerate(lineas) if x.strip() == titulo.strip()), None)
                if ini is not None:
                    for i in range(ini + 1, len(lineas)):
                        if lineas[i].startswith("step "):
                            break
                        cod, sep, com = lineas[i].partition("--")
                        if re.search(r"\boptional\b", cod):
                            nuevo = re.sub(r"\s+optional\b", "", cod)
                            hechos.append((rel, i + 1, "sin `optional` (paso de `when group`)", lineas[i].strip()))
                            lineas[i] = nuevo + sep + com
                    g.write_bytes("\n".join(lineas).encode("utf-8"))
            return hechos
        m = re.match(r'^`collect` item (\d+) \((.+?)\) drops only from elites.*with the tip "(.+?)"', msg)
        if m:
            def en_when_group(i: int) -> bool:
                # Un paso `when group N` lo ve solo quien eligió el grupo: no puede quedar todo optional.
                for j in range(i, -1, -1):
                    if lineas[j].startswith("step "):
                        k = j + 1
                        while k < len(lineas) and not lineas[k].startswith("step "):
                            if re.match(r"^\s*when group\b", lineas[k]):
                                return True
                            k += 1
                        return False
                return False
            for i, x in enumerate(lineas):
                if re.match(rf"^\s*collect {m[1]}\b", x) and rel != rel_flujo and en_when_group(i):
                    # La ruta sacó el paso `when group Q` a la ruta de todos (v0.4.1, Raptor Mastery en la Horda):
                    # en su paso de grupo no puede ser optional y fuera de él tiene que serlo. La misión de
                    # élite sale de esta guía (pasos `when group Q` y sus líneas); la ruta recupera la XP.
                    qm = re.search(r"\bquest (\d+)", x)
                    if not qm:
                        break
                    q = qm[1]
                    inicios = [j for j, y in enumerate(lineas) if y.startswith("step ")] + [len(lineas)]
                    fuera = []
                    for a, b in zip(inicios, inicios[1:]):
                        if any(re.match(rf"^\s*when group {q}\s*$", y.split("--")[0]) for y in lineas[a:b]):
                            fuera.append((a, b))
                    for a, b in reversed(fuera):
                        hechos.append((rel, a + 1, f"paso fuera (misión de élite {q} de grupo, que la ruta saca del grupo)", lineas[a].strip()))
                        del lineas[a:b]
                    g.write_bytes("\n".join(lineas).encode("utf-8"))
                    return hechos
                if re.match(rf"^\s*collect {m[1]}\b", x) and "optional" not in x.split("--")[0] and not en_when_group(i):
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


def cascada(guias: Path) -> list[tuple[str, int, str, str]]:
    """Entregas y objetivos huérfanos: lint dice "never accepted" y la misión no tiene `accept` en
    NINGUNA guía de su bando (ni de class/, collectibles/…), así que ninguna cadena puede aceptarla.
    Sale la línea; se repite hasta que no quede ninguna (una salida puede dejar otra huérfana).
    18-11: la etapa report de forge build los encontraba de a uno por construcción (~55 min cada una);
    las aceptaciones las habían sacado guias_sin_fuente, los arreglos o la semilla."""
    hechos = []
    for vuelta in range(6):
        acepta: dict[str, set[int]] = {}
        for g in guias.rglob("*.guide"):
            r = g.relative_to(guias).as_posix()
            b = next((x for x in ("alliance", "horde") if f"/{x}/" in "/" + r), "")
            for x in g.read_text(encoding="utf-8").splitlines():
                m = re.match(r"^\s*accept (\d+)\b", x)
                if m:
                    acepta.setdefault(b, set()).add(int(m[1]))
        quitar: dict[Path, set[int]] = {}
        for f, l, m in lint(guias):
            n = NUNCA.match(m)
            if not n or not f.is_file():
                continue
            r = f.resolve().relative_to(guias.resolve()).as_posix()
            b = next((x for x in ("alliance", "horde") if f"/{x}/" in "/" + r), "")
            q = int(n[2])
            if q in acepta.get(b, set()) or q in acepta.get("", set()):
                continue
            quitar.setdefault(f, set()).add(l)
        if not quitar:
            break
        for f, ls in quitar.items():
            r = f.resolve().relative_to(guias.resolve()).as_posix()
            lineas = f.read_bytes().decode("utf-8").split("\n")
            for l in sorted(ls, reverse=True):
                if 1 <= l <= len(lineas):
                    hechos.append((r, l, "línea fuera (cascada: la misión no se acepta en ninguna guía del bando)", lineas[l - 1].strip()))
                    del lineas[l - 1]
            lineas = sin_pasos_vacios(lineas, [l - 1 - k for k, l in enumerate(sorted(ls))])
            f.write_bytes("\n".join(lineas).encode("utf-8"))
        print(f"cascada {vuelta + 1}: {sum(len(x) for x in quitar.values())} líneas huérfanas fuera")
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
    hechos += cascada(guias)
    rep =guias.parent / (guias.name + "_ARREGLOS.md")
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
