"""Genera addon/Mamba_Panel/Datos_Calabozos.lua: las mazmorras y bandas de Forever que el Codex de Polestar no trae
(fila K122). Cristian buscó "Ciudad Anegada" en Calabozos y no salía: el Codex (Polestar_Codex/Dungeons1.lua) tiene 30
instancias y le faltan las propias de Forever (La Ciudad Anegada, Bastión de Krol'dok, Prisión de Alcaz, Bastión
Faucenegra, El Bancal del Creador).

Qué cuenta como "de Forever" (lo mismo exige tools/asistente/pruebas/test_calabozos.py):
  * cada fila de GroupFinderActivity del cliente (la copia más nueva) de mazmorra o banda (categorías 2 y 114, no
    campos de batalla), por su MapID;
  * MENOS las de temporada: un mapa que el Codex no tiene y cuyas filas llevan TODAS una PlayerCondition (Season of
    Discovery: Cañón de la Caída Demoníaca, Criptas de Karazhan, Acantilados de la Tormenta...). Las nuevas de Forever
    no llevan ninguna.
Por cada mapa que falta: nombre esMX y en inglés (GroupFinderActivity esMX / enUS), niveles (el menor MinLevel y el
mayor MaxLevelSuggestion de sus filas; el piso de data/codex/levels.json si lo nombra), jugadores, zona y entrada:
  1. data/codex/entrances.json de Polestar (grabaciones de jugadores, con su fuente);
  2. si no está: el punto de paso de Polestar con el nombre del área exterior (Polestar_Nav/Nav/Chokepoints.lua),
     pasado a % del mapa con los marcos de Nav/TravelData.lua ("aprox.");
  3. si tampoco: sin entrada ("datos en camino") y la zona del área exterior (AreaTable, padre de la que se llama
     igual que la instancia).
Las misiones conocidas de cada una (data/codex/journal-quests.json) se cuentan para decirlo en "datos en camino".

Uso (desde el repositorio Mamba):  python -I tools/asistente/generador/calabozos.py
Licencia: GPL-3.0-only. Datos: tablas del cliente (Blizzard) vía wago.tools; data/codex y Polestar_Nav (Polestar,
GPL-3.0, con las grabaciones de jugadores que citan); zonas en español de Asistente_Equipo/Datos_Mazmorras.lua.
"""
from __future__ import annotations

import csv
import json
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[3]
ADDON = RAIZ / "addon"
SALIDA = ADDON / "Mamba_Panel" / "Datos_Calabozos.lua"
WAGO = [RAIZ / "data" / "sources" / "wago", pathlib.Path(r"D:\rust\polestar-data\sources\wago")]
CATEGORIAS = {"2", "114"}  # mazmorras y bandas; 118 = campos de batalla


def _build(p: pathlib.Path) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", p.name))


def tabla(nombre: str, idioma: str = "") -> tuple[pathlib.Path, list[dict]]:
    """La copia más nueva (por build) de una tabla del cliente 1.60.x; idioma "esMX" lee la subcarpeta."""
    cand = []
    for base in WAGO:
        if base.is_dir():
            for b in base.iterdir():
                f = (b / idioma / f"{nombre}.csv") if idioma else (b / f"{nombre}.csv")
                if b.name.startswith("1.60.") and f.is_file():
                    cand.append((_build(b), f))
    if not cand:
        sys.exit(f"falta la tabla del cliente {idioma or 'enUS'}/{nombre}.csv en data/sources/wago")
    f = max(cand)[1]
    with f.open(encoding="utf-8", newline="") as h:
        return f, list(csv.DictReader(h))


def mapas_codex() -> dict[int, str]:
    """mapa -> clave de las instancias del Codex de Polestar (Polestar_Codex/Instances1.lua)."""
    src = (ADDON / "Polestar_Codex" / "Dungeons1.lua").read_text(encoding="utf-8")
    out = {}
    # el resumen de cada una: ["clave"]={name=...,map=N,...} o clave={name=...} (la página es clave="return ...")
    for m in re.finditer(r'^(?:\["([a-z0-9-]+)"\]|([a-z0-9_]+))=\{name="[^"]*",map=(\d+)', src, re.M):
        out[int(m[3])] = m[1] or m[2]
    return out


def info_codex() -> dict[int, dict]:
    """mapa -> { entrance, zone }: qué trae el resumen de cada instancia del Codex."""
    src = (ADDON / "Polestar_Codex" / "Dungeons1.lua").read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'^(?:\["[a-z0-9-]+"\]|[a-z0-9_]+)=\{name="[^"]*",map=(\d+)(.*)$', src, re.M):
        out[int(m[1])] = {"entrance": "entrance=" in m[2], "zone": ",zone=" in m[2]}
    return out


def instancias_forever() -> tuple[dict[int, dict], list[int], pathlib.Path]:
    """mapa -> { filas } de las mazmorras y bandas de Forever; y los mapas de temporada que se dejan fuera."""
    f, gfa = tabla("GroupFinderActivity")
    codex = mapas_codex()
    por_mapa: dict[int, list[dict]] = {}
    for r in gfa:
        if r["GroupFinderCategoryID"] in CATEGORIAS and r["MaxPlayers"] != "0" and r["MapID"] != "0":
            por_mapa.setdefault(int(r["MapID"]), []).append(r)
    temporada = sorted(m for m, filas in por_mapa.items()
                       if m not in codex and all(r["PlayerConditionID"] != "0" for r in filas))
    return {m: {"filas": filas} for m, filas in por_mapa.items() if m not in temporada}, temporada, f


def slug(nombre: str) -> str:
    """Como las claves de Polestar: "Krol'dok Stronghold" -> "kroldok-stronghold"."""
    s = re.sub(r"['’]", "", nombre.lower())
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def marcos() -> dict[int, dict]:
    datos = (ADDON / "Polestar" / "Nav" / "TravelData.lua").read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'\[(\d+)\] = \{ name = "([^"]*)", c = (\d+), top = ([-\d.]+), bottom = ([-\d.]+), left = ([-\d.]+), right = ([-\d.]+) \}', datos):
        out[int(m[1])] = dict(nombre=m[2], c=int(m[3]), top=float(m[4]), bottom=float(m[5]), left=float(m[6]), right=float(m[7]))
    return out


def zonas_es() -> dict[str, str]:
    """nombre esMX de la mazmorra -> su zona en esMX (Asistente_Equipo/Datos_Mazmorras.lua, "donde")."""
    src = (ADDON / "Asistente_Equipo" / "Datos_Mazmorras.lua").read_text(encoding="utf-8")
    out = {}
    for bloque in re.findall(r"\{\s*clave = .*?\}", src, re.S):
        n, d = re.search(r'nombre = "([^"]*)"', bloque), re.search(r'donde = "([^"]*)"', bloque)
        if n and d:
            out[n[1]] = d[1]
    return out


def lua(v) -> str:
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(round(v, 1)) if isinstance(v, float) else str(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {lua(x)}" for k, x in v.items() if x is not None) + " }"
    raise TypeError(v)


def generar() -> str:
    inst, temporada, f_gfa = instancias_forever()
    codex = mapas_codex()
    codex_info = info_codex()
    _, gfa_es = tabla("GroupFinderActivity", "esMX")
    es = {r["ID"]: r["FullName_lang"] for r in gfa_es}
    _, areas = tabla("AreaTable")
    _, areas_es = tabla("AreaTable", "esMX")
    area_es = {r["ID"]: r["AreaName_lang"] for r in areas_es}
    entradas = {e["instance"]: e for e in json.loads((RAIZ / "data/codex/entrances.json").read_text("utf-8"))["entrances"]}
    pisos = {e["key"]: e for e in json.loads((RAIZ / "data/codex/levels.json").read_text("utf-8"))["levels"]}
    misiones: dict[str, int] = {}
    for q in json.loads((RAIZ / "data/codex/journal-quests.json").read_text("utf-8"))["quests"]:
        misiones[q["instance"]] = misiones.get(q["instance"], 0) + 1
    paso = (ADDON / "Polestar_Nav" / "Nav" / "Chokepoints.lua").read_text(encoding="utf-8")
    mf = marcos()
    zes = zonas_es()

    def zona_es(ui: int | None) -> str | None:
        """El nombre esMX de una zona (uiMap): su nombre en TravelData -> AreaTable (zona, sin padre) -> esMX."""
        if ui is None or ui not in mf:
            return None
        a = next((x for x in areas if x["AreaName_lang"] == mf[ui]["nombre"] and x["ParentAreaID"] == "0"
                  and x["ContinentID"] == str(mf[ui]["c"])), None)
        return (a and area_es.get(a["ID"])) or mf[ui]["nombre"]

    def ubicar(mapa: int, en: str):
        """-> (zona uiMap, entrada {map,x,y} | None, fuente). Solo fuentes de Polestar libres de ataduras: las
        grabaciones de jugadores de data/codex/entrances.json o un punto de paso de Polestar_Nav (aprox.)."""
        e = entradas.get(mapa)
        if e and isinstance(e.get("source"), dict) and e["source"].get("kind") == "recording":
            return e["map"], {"map": e["map"], "x": e["x"], "y": e["y"]}, "grabaciones de jugadores (Polestar, data/codex/entrances.json)"
        # el área exterior que se llama como la instancia (o una de sus áreas), en Kalimdor o los Reinos del Este
        nombres = {en} | {x["AreaName_lang"] for x in areas if x["ContinentID"] == str(mapa)}
        # (una subzona: Dalaran trae un área "Hillsbrad Foothills" adentro, que no dice dónde está la puerta)
        ext = [x for x in areas if x["AreaName_lang"] in nombres and x["ContinentID"] in ("0", "1") and x["ParentAreaID"] != "0"]
        ext.sort(key=lambda x: f"area = {x['ID']}, zone" not in paso)  # primero las que Polestar_Nav conoce
        zona = None
        for a in ext:
            pasos = re.findall(r"\{ wx = ([-\d.]+), wy = ([-\d.]+),[^}]*area = " + a["ID"] + r", zone = \"[^\"]*\", zoneArea = (\d+)", paso)
            zona_area = (pasos and pasos[0][2]) or a["ParentAreaID"]
            nz = next((x["AreaName_lang"] for x in areas if x["ID"] == zona_area), None)
            zona = next((k for k, v in mf.items() if v["nombre"] == nz and v["c"] == int(a["ContinentID"])), None)
            # un solo punto de paso con ese nombre: es la puerta (Bastión Faucenegra); varios (los muros de Dalaran), no se sabe cuál
            if len(pasos) == 1 and zona:
                f = mf[zona]
                wx, wy = float(pasos[0][0]), float(pasos[0][1])
                ent = {"map": zona, "x": round((f["left"] - wy) / (f["left"] - f["right"]) * 100, 1),
                       "y": round((f["top"] - wx) / (f["top"] - f["bottom"]) * 100, 1)}
                return zona, ent, "aprox.: el punto de paso de Polestar en " + (area_es.get(a["ID"]) or a["AreaName_lang"]) + " (Polestar_Nav)"
            if zona:
                break
        return zona, None, None

    filas_out, huecos = [], []
    for mapa in sorted(inst):
        filas = inst[mapa]["filas"]
        primera = min(filas, key=lambda r: int(r["ID"]))
        en = primera["FullName_lang"]
        nombre = es.get(primera["ID"]) or en
        if mapa in codex:
            # del Codex: Mamba solo completa la zona que no trae y dice "entrada: datos en camino"
            clave, tiene = codex[mapa], codex_info[mapa]
            if tiene["entrance"] and tiene["zone"]:
                continue
            zona, ent, fuente = ubicar(mapa, en)
            h = {"key": clave}
            if not tiene["zone"]:
                h["zone"] = zona
                h["zoneName"] = zona_es(zona)
            if not tiene["entrance"]:
                h["entrance"] = ent
                h["entradaFuente"] = fuente
                h["sinEntrada"] = ent is None
            huecos.append(h)
            continue
        clave = slug(en)
        mx = max(int(r["MaxPlayers"]) for r in filas)
        d = {
            "key": clave, "name": nombre, "en": en, "map": mapa,
            "kind": "raid" if mx > 5 else "dungeon", "forever": True,
            "minLevel": min(int(r["MinLevel"]) for r in filas),
            "maxLevel": max(int(r["MaxLevelSuggestion"]) for r in filas),
            "players": min(int(r["MaxPlayers"]) for r in filas),
        }
        if mx > d["players"]:
            d["playersMax"] = mx
        d["floor"] = pisos.get(clave, {}).get("floor") or d["minLevel"]
        zona, ent, fuente = ubicar(mapa, en)
        d["entrance"] = ent
        d["zone"] = zona
        d["zoneName"] = zes.get(nombre) or zona_es(zona)
        d["entradaFuente"] = fuente
        d["misiones"] = misiones.get(clave, 0)
        filas_out.append(d)
    lineas = [
        "-- Generado por tools/asistente/generador/calabozos.py. NO editar a mano: volver a generar.",
        "-- Licencia: GPL-3.0-only. Datos: tablas del cliente WoW Forever (Blizzard) vía wago.tools, "
        f"build {f_gfa.parent.name} (GroupFinderActivity, AreaTable, enUS y esMX);",
        "-- entradas: data/codex/entrances.json de Polestar (grabaciones de jugadores) o un punto de paso de Polestar_Nav (aprox.);",
        "-- zonas en español: Asistente_Equipo/Datos_Mazmorras.lua.",
        "-- Las mazmorras y bandas de Forever que el Codex de Polestar no trae (K122). Mamba_Panel/Calabozos.lua las registra.",
        "-- De temporada, fuera (todas sus filas con PlayerCondition, sin Codex): mapas " + ", ".join(map(str, temporada)) + ".",
        "local _, N = ...",
        "N.CALABOZOS = {",
    ]
    for d in filas_out:
        lineas.append("\t" + lua(d) + ",")
    lineas.append("}")
    lineas.append('-- Las del Codex sin zona o sin entrada: Mamba completa la zona y dice "entrada: datos en camino".')
    lineas.append("N.CALABOZOS_HUECOS = {")
    for h in huecos:
        lineas.append("\t" + lua(h) + ",")
    lineas.append("}")
    return "\n".join(lineas) + "\n"


if __name__ == "__main__":
    texto = generar()
    if "--revisar" in sys.argv:
        viejo = SALIDA.read_text(encoding="utf-8") if SALIDA.is_file() else ""
        if viejo != texto:
            print("Datos_Calabozos.lua quedó viejo: correr tools/asistente/generador/calabozos.py")
            sys.exit(1)
        print("Datos_Calabozos.lua al día")
        sys.exit(0)
    SALIDA.write_text(texto, encoding="utf-8", newline="\n")
    print(texto)
