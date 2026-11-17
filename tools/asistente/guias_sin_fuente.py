"""Guías de entrada de Mamba sin las misiones que ninguna fuente autorizada tiene.

Sin QuestieDB, forge no tiene datos de ~126 misiones propias de Forever (Riverglades, Shen'dralas…):
forever-db (P7) trae la mayoría, pero no esas. Las guías de Polestar las nombran y el escritor de
guías se detiene ("quest N is not in data"). Decisión de Mamba 1.0 (traspaso 17-11): esas misiones
**salen de la guía** y quedan anotadas como NO VERIFICADO, en vez de inventar títulos u objetivos.

Qué hace (sin tocar guides/ del repositorio):
  1. Arma las guías que lee forge build igual que forge (generated.rs, input_guides): guides/ con
     cada guía generada reemplazada por su semilla (forge/seed/guides) y sin las que solo escribió
     publish.
  2. Quita las líneas que nombran una misión sin fuente (accept/turnin/complete/skip N y los
     objetivos `quest N.x`). Un paso con un `when` que nombra una de ellas sale entero, y un paso que
     se queda sin ninguna acción también.
  3. Escribe la copia en la carpeta de salida y un informe (qué guía, qué paso, qué misión).

Uso:  python -I tools/asistente/guias_sin_fuente.py <datos quests.json> <carpeta de salida>
Luego: forge build ... --guides <carpeta de salida>

Modo --necesita (ANTES del paso de datos):
      python -I tools/asistente/guias_sin_fuente.py --necesita data/local/forever-db-need.txt
  Lista los objetos de inventario, PNJ y objetos del mundo que nombran las guías (collect/buy/use…,
  kill/talk/vendor/train, interact, turnin … reward). P7 agrega a los datos los que faltan y
  forever-db tiene (17-11: ~185 de los ~350 errores del armado de paquetes eran eso).
"""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
SEMILLA = RAIZ / "forge" / "seed"
ACCION = re.compile(r"^\s*(accept|turnin|complete|skip|collect|kill|use|talk|interact|learn|train|buy|fly|vendor|hearth|enter|goto|item|loot|equip|cast|emote|say|wait)\b")
QUEST_LINEA = re.compile(r"^\s*(accept|turnin|complete|skip)\s+(\d+)\b")
QUEST_OBJ = re.compile(r"\bquest\s+(\d+)(?:\.\d+)?\b")
WHEN = re.compile(r"^\s*(when|only)\b")


def entradas(dest: Path) -> int:
    """Copia de las guías que lee forge build (generated.rs, input_guides)."""
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(RAIZ / "guides", dest)
    semilla = json.loads((SEMILLA / "SEED.json").read_text(encoding="utf-8"))["files"]
    for f in semilla:
        o = dest / f
        o.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(SEMILLA / "guides" / f, o)
    gen = RAIZ / "guides" / "GENERATED.json"
    if gen.is_file():
        for f in json.loads(gen.read_text(encoding="utf-8")).get("files", {}):
            if f.endswith(".guide") and f not in semilla:
                (dest / f).unlink(missing_ok=True)
    return len(semilla)


def nombra(linea: str, faltan: set[int]) -> int | None:
    m = QUEST_LINEA.match(linea)
    if m and int(m.group(2)) in faltan:
        return int(m.group(2))
    if linea.lstrip().startswith("#"):
        return None
    for q in QUEST_OBJ.findall(linea):
        if int(q) in faltan:
            return int(q)
    if WHEN.match(linea):
        for q in re.findall(r"\b(\d{4,6})\b", linea):
            if int(q) in faltan:
                return int(q)
    return None


def filtrar(texto: str, faltan: set[int], informe: list, nombre: str) -> str:
    lineas = texto.splitlines(keepends=True)
    # Bloques: cabecera (antes del primer "step") y cada paso.
    bloques, actual = [], []
    for l in lineas:
        if l.startswith("step ") and actual:
            bloques.append(actual)
            actual = []
        actual.append(l)
    bloques.append(actual)
    salida = []
    for b in bloques:
        if not b or not b[0].startswith("step "):
            salida.extend(b)
            continue
        titulo = b[0].strip()
        quitadas = [(l, nombra(l, faltan)) for l in b[1:]]
        if not any(q for _, q in quitadas):
            salida.extend(b)
            continue
        if any(q and WHEN.match(l) for l, q in quitadas):
            informe.append((nombre, titulo, "paso entero (su condición nombra una misión sin fuente)", sorted({q for _, q in quitadas if q})))
            continue
        quedan = [b[0]] + [l for l, q in quitadas if not q]
        if not any(ACCION.match(l) for l in quedan[1:]):
            informe.append((nombre, titulo, "paso entero (se quedó sin acciones)", sorted({q for _, q in quitadas if q})))
            continue
        informe.append((nombre, titulo, f"{sum(1 for _, q in quitadas if q)} línea(s)", sorted({q for _, q in quitadas if q})))
        salida.extend(quedan)
    return "".join(salida)


VERBO_ITEM = {"collect", "buy", "use", "equip", "loot", "item"}
VERBO_NPC = {"kill", "talk", "vendor", "train"}
VERBO_OBJ = {"interact"}


def necesita(salida: Path) -> int:
    """Ids que nombran las guías (guides/ y la semilla), por tipo."""
    ids: set[tuple[str, int]] = set()
    for base in (RAIZ / "guides", SEMILLA / "guides"):
        for g in base.rglob("*.guide"):
            for l in g.read_text(encoding="utf-8").splitlines():
                for k, x in re.findall(r"\{(item|npc|object):(\d+)\}", l):
                    ids.add((k, int(x)))
                cod = l.split("--", 1)[0].replace(",", " ").split()
                if not cod:
                    continue
                v = cod[0]
                if v == "turnin" and ("reward" in cod or "choose" in cod):
                    resto, kind = cod[cod.index("reward" if "reward" in cod else "choose") + 1:], "item"
                elif v in ("collects", "reward"):
                    resto, kind = [w for w in cod[1:] if w != "item"], "item"
                elif v in VERBO_ITEM | VERBO_NPC | VERBO_OBJ:
                    resto = cod[1:]
                    kind = "item" if v in VERBO_ITEM else "npc" if v in VERBO_NPC else "object"
                else:
                    continue
                for w in resto:
                    if not w.isdigit():
                        break
                    ids.add((kind, int(w)))
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text("".join(f"{k} {i}" + chr(10) for k, i in sorted(ids)), encoding="utf-8")
    print(f"necesita: {len(ids)} ids nombrados por las guías en {salida}")
    return 0


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--necesita":
        return necesita(Path(sys.argv[2]))
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    datos = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    dest = Path(sys.argv[2])
    n = entradas(dest)
    faltan: set[int] = set()
    # Una misión cuyos objetivos `kill`/`talk` nombran un PNJ que ninguna fuente tiene (ni pfQuest, ni
    # CMaNGOS, ni forever-db) tampoco se puede guiar: forge la expande en un `talk N` sin datos (17-11:
    # Camping 101: Cooking ×4, Locating the Lost City, Abominable Magics).
    # Solo los PNJ que forge build marcó así en la construcción anterior (pack-errors): otras misiones
    # con PNJ sin datos se guían con líneas propias y forge las acepta (Call of Fire, p. ej.).
    npcs_p = Path(sys.argv[1]).with_name("npcs.json")
    marcados: set[int] = set()
    for f in Path(r"D:\rust\forge-out\.forge\flow").glob("*.pack-errors.txt"):
        marcados |= {int(x) for x in re.findall(r"npc (\d+) is not in data", f.read_text(encoding="utf-8", errors="replace"))}
    # Se acumulan en data/local/pnj-sin-fuente.txt: una construcción que ya pasó no los vuelve a listar.
    guardados = RAIZ / "data" / "local" / "pnj-sin-fuente.txt"
    if guardados.is_file():
        marcados |= {int(x) for x in guardados.read_text(encoding="utf-8").split()}
    if marcados:
        guardados.write_text("".join(f"{x}" + chr(10) for x in sorted(marcados)), encoding="utf-8")
    if npcs_p.is_file() and marcados:
        npcs = json.loads(npcs_p.read_text(encoding="utf-8"))
        for qid, q in datos.items():
            for o in q.get("objectives") or []:
                if o.get("type") in ("kill", "talk") and o.get("id") is not None and int(o["id"]) in marcados and str(int(o["id"])) not in npcs:
                    faltan.add(int(qid))
    for g in dest.rglob("*.guide"):
        for l in g.read_text(encoding="utf-8").splitlines():
            m = QUEST_LINEA.match(l)
            if m and m.group(2) not in datos:
                faltan.add(int(m.group(2)))
            for q in QUEST_OBJ.findall(l):
                if q not in datos and not l.lstrip().startswith("#"):
                    faltan.add(int(q))
    informe: list = []
    for g in sorted(dest.rglob("*.guide")):
        t = g.read_bytes().decode("utf-8")
        nuevo = filtrar(t, faltan, informe, g.relative_to(dest).as_posix())
        if nuevo != t:
            g.write_bytes(nuevo.encode("utf-8"))
    rep = dest.parent / (dest.name + "_SIN_FUENTE.md")  # fuera de la carpeta que lee forge
    with rep.open("w", encoding="utf-8") as f:
        f.write("# Misiones fuera de las guías de Mamba (NO VERIFICADO)\n\n")
        f.write(f"Sin fuente autorizada (ni pfQuest, ni CMaNGOS, ni forever-db): {len(faltan)} misiones.\n")
        f.write("Ids: " + ", ".join(map(str, sorted(faltan))) + "\n\n| Guía | Paso | Qué salió | Misiones |\n|---|---|---|---|\n")
        for g, s, q, ids in informe:
            f.write(f"| {g} | {s} | {q} | {', '.join(map(str, ids))} |\n")
    print(f"guías: {n} desde la semilla; {len(faltan)} misiones sin fuente; {len(informe)} pasos tocados; informe en {rep}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
