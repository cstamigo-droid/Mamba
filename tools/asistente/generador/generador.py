# -*- coding: utf-8 -*-
"""Generador de datos cruzados para el asistente de WoW: Forever (etapas 4, 5 y 6).

Corre AFUERA del juego. Cruza:
  misiones de cada zona -> criaturas que mandan matar -> qué sueltan (con %) ->
  qué receta de Cocina, Alquimia, Primeros auxilios o Herboristería sube con eso.
Y arma el plan de bolsas (misiones que regalan bolsas).

Fuentes (ver FUENTES.md y LICENSE-DATA.txt que se genera):
  fdb = forever-db de Polestar (GPL-3.0-only): misiones, PNJ, apariciones, botín de objetos de misión,
        telas y hierbas (cuando son "objetos de misión" en algún lado).
  pg  = guías de profesiones de Polestar (GPL-3.0): tramos, recetas, colores, materiales y el PNJ que
        más suelta cada carne (con %). No se copia texto de las guías: solo números e ids.
  fdbapi = API de ForeverDB (solo si Cristian consigue la clave; hoy APAGADA).

Uso:  python -I generador.py <carpeta polestar clonada> <carpeta de salida del addon> [<sqlite>]
"""
import collections
import hashlib
import json
import math
import pathlib
import re
import sqlite3
import sys

FACCION = "Horde"
RAZAS_HORDA = {"Orc", "Troll", "Tauren", "Undead", "Horde"}
# Zonas candidatas: área (AreaTable) -> (uiMap, nombre en inglés). Hechos del cliente.
# El nombre en español lo pone el juego con C_Map.GetMapInfo(uiMap).name.
AREAS = {
    3: (1418, "Badlands"), 8: (1435, "Swamp of Sorrows"), 15: (1445, "Dustwallow Marsh"),
    33: (1434, "Stranglethorn Vale"), 36: (1416, "Alterac Mountains"), 45: (1417, "Arathi Highlands"),
    267: (1424, "Hillsbrad Foothills"), 400: (1441, "Thousand Needles"), 405: (1443, "Desolace"),
    406: (1442, "Stonetalon Mountains"), 17: (1413, "The Barrens"), 331: (1440, "Ashenvale"),
    47: (1425, "The Hinterlands"), 357: (1444, "Feralas"), 440: (1446, "Tanaris"),
    11: (1437, "Wetlands"), 10: (1431, "Duskwood"), 130: (1421, "Silverpine Forest"),
}
NIVEL_ZONA = (30, 40)       # la zona entra si al menos PARTE_MINIMA de sus misiones de la Horda son de este nivel
PARTE_MINIMA = 0.40
MIN_MISIONES_ZONA = 8
# Decisión de Cristian (16-11): solo información segura/oficial. Los PNJ y % de caída de las guías de Polestar
# vienen de sus datos de referencia, que en parte salen de páginas web (THIRD_PARTY.md: "the web quest database's
# Forever pages ... (the drop chance)"), y sus listas de hierbas por zona son una SUPOSICIÓN ("ASSUMED: past level 30
# Forever's spawns are Classic's"). Quedan APAGADOS. De las guías solo se usan recetas, colores y materiales, que
# Polestar lee de las tablas del cliente del juego ("recipes and their skill colours from the Forever client tables").
USAR_GUIA_BOTIN = False
MIN_PCT = 5.0               # una caída de menos de 5 % no se aconseja
MAX_ORIGENES = 3           # se muestran los 3 PNJ que más sueltan cada material
MIN_CERCA = 3               # y al menos 3 criaturas de la misión (un PNJ único no cuenta)
MIN_SOLAPE = 0.5            # de paso: al menos la mitad de las criaturas de la misión tienen al PNJ cerca
CERCA_YARDAS = 250.0        # "de paso": el PNJ que suelta el material vive a menos de esto del objetivo (~7 % del mapa)
PROFESIONES = {             # archivo de guía -> (nombre, id de habilidad del juego)
    "cooking": ("Cocina", 185), "alchemy": ("Alquimia", 171),
    "first-aid": ("Primeros auxilios", 129), "herbalism": ("Herboristería", 182),
}
BOLSA_RX = re.compile(r"\b(Bag|Pouch|Sack|Satchel|Backpack|Rucksack|Knapsack|Haversack|Pack|Quiver|Ammo Pouch)\b", re.I)
NO_BOLSA_RX = re.compile(r"\b(Sleeping Bag|Bag of|Pack of|Sack of|Pouch of|Six Pack|Wolfpack|Fireworks Pack|Gift Pack|Booty Bag|Supply Bag|Bag of Loot)\b|^(Pattern|Recipe|Plans|Schematic|Formula):", re.I)


# ----------------------------------------------------------------------------- utilidades
def sha256(p):
    return "sha256:" + hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()


def leer_jsonl(p):
    with open(p, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


class ErrorFuente(Exception):
    pass


# ----------------------------------------------------------------------------- fuente 1: forever-db
def cargar_forever_db(raiz):
    """Lee forever-db y comprueba la huella sha256 de cada tabla contra datapackage.json."""
    fdb = pathlib.Path(raiz) / "forever-db"
    paquete = json.loads((fdb / "datapackage.json").read_text(encoding="utf-8"))
    indice = json.loads((fdb / "index.json").read_text(encoding="utf-8"))
    licencias, tablas = {}, {}
    for r in paquete["resources"]:
        p = fdb / r["path"]
        if sha256(p) != r["hash"]:
            raise ErrorFuente(f"forever-db: la huella de {r['path']} no coincide con datapackage.json")
        lic = [l["name"] for l in r.get("licenses", [])]
        licencias[r["name"]] = lic
    # Solo usamos tablas GPL-3.0 (base de datos). La capa CC BY 4.0 (step/mechanic/note) no se usa.
    for t in ["quest", "quest_start", "quest_end", "quest_objective", "quest_reward", "npc",
              "object", "item", "item_source", "spawn", "ui_map"]:
        if licencias.get(t) != ["GPL-3.0-only"]:
            raise ErrorFuente(f"forever-db: la tabla {t} cambió de licencia: {licencias.get(t)}")
        tablas[t] = leer_jsonl(fdb / "data" / f"{t}.jsonl")
    tablas["_indice"] = indice
    tablas["_licencias"] = licencias
    return tablas


# ----------------------------------------------------------------------------- fuente 2: guías de profesiones de Polestar
RX_SECCION = re.compile(r"^section .*? (\d+)-(\d+)\s*$")
RX_COLORES = re.compile(r"orange from (\d+) \(yellow at (\d+), green at (\d+), grey at (\d+)\)")
RX_COLORES2 = re.compile(r"orange at (\d+) \(yellow (\d+), green (\d+), grey (\d+)\)")
RX_CADA = re.compile(r"about (\d+) crafts[^.]*\. Each takes ([^.]+)\.")
RX_PARTE = re.compile(r"(\d+) ([A-Z][A-Za-z' ]+?)(?:,| and |$)")
RX_SUELTA = re.compile(r"([A-Z][A-Za-z' -]+?) \((\d+(?:\.\d+)?)%\)")
RX_HIERBA = re.compile(r"([A-Z][A-Za-z']+(?: [A-Z][A-Za-z']+)*) \((\d+), (?:orange|yellow|green|grey)")


def paso_es_de_la_horda(lineas):
    for l in lineas:
        m = re.match(r"^  only (.+)$", l)
        if m:
            return bool(set(m.group(1).split(",")) & RAZAS_HORDA)
    return True


def cargar_guias(raiz, item_por_nombre=None, nombres=None):
    """Extrae de cada guía de profesión: tramos (desde-hasta), receta, colores y materiales.

    Devuelve (tramos, hierbas, huellas). Un tramo = dict con prof, desde, hasta, hechizo, colores,
    materiales [{item, cantidad, como: comprar|subasta|juntar, sueltan:[(nombre, %)], zona, niveles}].
    """
    item_por_nombre, nombres = item_por_nombre or {}, nombres or {}
    base = pathlib.Path(raiz) / "guides" / "forever" / "professions"
    tramos, hierbas, huellas = [], {}, {}
    for archivo, (prof, skill_id) in PROFESIONES.items():
        p = base / f"{archivo}.guide"
        huellas[p.name] = sha256(p)
        texto = p.read_text(encoding="utf-8").splitlines()
        # partir en pasos
        pasos, actual, seccion = [], None, None
        for l in texto:
            if l.startswith("section "):
                m = RX_SECCION.match(l)
                seccion = (int(m.group(1)), int(m.group(2))) if m else None
            elif l.startswith("step "):
                actual = {"titulo": l[5:].strip(), "lineas": [], "seccion": seccion}
                pasos.append(actual)
            elif actual is not None and l.startswith("  "):
                actual["lineas"].append(l)
        # Herboristería: habilidad de cada hierba, sacada de los consejos "Liferoot (150, orange)".
        if archivo == "herbalism":
            for paso in pasos:
                zona = next((l[7:].strip() for l in paso["lineas"] if l.startswith("  zone ")), None)
                for l in paso["lineas"]:
                    if l.startswith("  tip "):
                        for nombre, nivel in RX_HIERBA.findall(l):
                            h = hierbas.setdefault(nombre, {"habilidad": int(nivel), "zonas": set()})
                            if zona:
                                h["zonas"].add(zona)
            continue
        # Las demás: un tramo = UNA receta ("Raptor asado 175-225"), con SUS materiales.
        #  - Si el consejo del paso dice "Each takes 1 X, 2 Y and 1 Z" (Alquimia), los materiales salen de ahí:
        #    cantidad = por fabricación x "about N crafts".
        #  - Si no (Cocina, Primeros auxilios), son los que la guía mandó comprar/juntar desde la receta anterior.
        for paso_i, paso in enumerate(pasos):
            paso["i"] = paso_i
        seccion_mats, pendientes, ultimo_hasta, seccion_actual = {}, {}, None, None
        for paso in pasos:
            if paso["seccion"] != seccion_actual:
                seccion_actual, seccion_mats, pendientes = paso["seccion"], {}, {}
                ultimo_hasta = seccion_actual[0] if seccion_actual else None
            if seccion_actual is None or not paso_es_de_la_horda(paso["lineas"]):
                continue
            zona = next((l[7:].strip() for l in paso["lineas"] if l.startswith("  zone ")), None)
            tip = " ".join(l[6:] for l in paso["lineas"] if l.startswith("  tip "))
            for l in paso["lineas"]:
                m = re.match(r"^  (buy|auction|collect) (\d+)(?: x(\d+))?(.*)$", l)
                if m:
                    como = {"buy": "comprar", "auction": "subasta", "collect": "juntar"}[m.group(1)]
                    iid, cant, resto = int(m.group(2)), int(m.group(3) or 1), m.group(4)
                    if como == "comprar" and cant == 1:          # una compra x1 es la receta, no un material
                        pendientes.setdefault("_receta", iid)
                        continue
                    for donde in (seccion_mats, pendientes):
                        mat = donde.get(iid)
                        if mat is None:
                            mat = donde[iid] = {"item": iid, "cantidad": cant, "como": como, "sueltan": [],
                                                "zona": None, "niveles": None, "hierba": None}
                        if como == "juntar":
                            mat["como"] = "juntar"
                        mat["cantidad"] = max(mat["cantidad"], cant)
                        if "--" in resto:
                            com = resto.split("--", 1)[1]
                            mat["sueltan"] = [(n.strip(), float(pc)) for n, pc in RX_SUELTA.findall(com)]
                            mz = re.search(r" in (.+?), or wherever", com)
                            mat["zona"] = mz.group(1) if mz else zona
                        mn = re.search(r"gather levels (\d+)-(\d+)", resto)
                        if mn:
                            mat["niveles"] = (int(mn.group(1)), int(mn.group(2)))
                        mh = re.search(r"gather Herbalism (\d+)", resto)
                        if mh:
                            mat["hierba"] = int(mh.group(1))
            for l in paso["lineas"]:
                mc = re.match(r"^  craft (\d+) until (\d+)", l)
                if not mc:
                    continue                                      # "craft X xN" = paso intermedio, no tramo
                hasta = int(mc.group(2))
                mt = re.search(r"\((\d+)-(\d+)\)\s*$", paso["titulo"])
                md = re.search(r" is (?:orange|yellow|green) (?:at|from) (\d+)", tip)
                desde = int(mt.group(1)) if mt else (int(md.group(1)) if md else ultimo_hasta)
                col = RX_COLORES.search(tip) or RX_COLORES2.search(tip)
                me = RX_CADA.search(tip)
                if me:
                    veces = int(me.group(1))
                    mats = []
                    for n, nombre in RX_PARTE.findall(me.group(2)):
                        iid = next((k for k, v in seccion_mats.items() if nombres.get(k) == nombre),
                                   item_por_nombre.get(nombre))
                        if iid is None:
                            raise ErrorFuente(f"{p.name}: no encuentro el objeto '{nombre}'")
                        base_m = seccion_mats.get(iid, {"como": "comprar", "sueltan": [], "zona": None,
                                                         "niveles": None, "hierba": None})
                        mats.append(dict(base_m, item=iid, cantidad=int(n) * veces))
                else:
                    mats = [dict(v) for k, v in pendientes.items() if k != "_receta"]
                tramos.append({"prof": prof, "skill_id": skill_id, "desde": desde, "hasta": hasta,
                               "hechizo": int(mc.group(1)), "receta_item": pendientes.get("_receta"),
                               "colores": tuple(int(c) for c in col.groups()) if col else None,
                               "materiales": mats, "guia": p.name, "linea_paso": paso["titulo"]})
                ultimo_hasta, pendientes = hasta, {}
    unicos = collections.OrderedDict()
    for t in tramos:
        k = (t["prof"], t["hechizo"], t["desde"], t["hasta"])
        if k in unicos:
            ya = {m["item"] for m in unicos[k]["materiales"]}
            unicos[k]["materiales"] += [m for m in t["materiales"] if m["item"] not in ya]
        else:
            unicos[k] = t
    return list(unicos.values()), hierbas, huellas


# ----------------------------------------------------------------------------- geometría
def en_mapa(um, mapa, x, y):
    """¿El punto (mundo, yardas) cae dentro del recuadro del uiMap? Devuelve (px, py) en % o None."""
    if um["map"] != mapa:
        return None
    px = (um["left"] - y) / (um["left"] - um["right"]) * 100
    py = (um["top"] - x) / (um["top"] - um["bottom"]) * 100
    if 0 <= px <= 100 and 0 <= py <= 100:
        return round(px, 1), round(py, 1)
    return None


# ----------------------------------------------------------------------------- el cruce
def construir(raiz):
    T = cargar_forever_db(raiz)
    nombres_item = {r["id"]: r.get("name") for r in T["item"]}
    por_nombre = {}
    for i, n in sorted(nombres_item.items()):
        por_nombre.setdefault(n, i)
    tramos, hierbas, huellas_guias = cargar_guias(raiz, por_nombre, nombres_item)
    indice = T["_indice"]
    build = indice["clientBuild"]

    npc = {r["id"]: r for r in T["npc"]}
    item = {r["id"]: r for r in T["item"]}
    quest = {r["id"]: r for r in T["quest"]}
    uimap = {r["ui_map"]: r for r in T["ui_map"]}
    obj_por_q = collections.defaultdict(list)
    for o in T["quest_objective"]:
        obj_por_q[o["quest"]].append(o)
    fuentes_item = collections.defaultdict(list)       # item -> [(kind, id, chance)]
    suelta_npc = collections.defaultdict(list)         # npc -> [(item, chance)]
    for s in T["item_source"]:
        fuentes_item[s["item"]].append(s)
        if s["kind"] == "npc":
            suelta_npc[s["id"]].append((s["item"], s.get("chance")))
    spawns = collections.defaultdict(list)             # (kind, id) -> [(map, x, y)]
    for s in T["spawn"]:
        spawns[(s["kind"], s["id"])].append((s["map"], s["x"], s["y"]))
    npc_por_nombre = collections.defaultdict(list)
    for n in npc.values():
        if "name" in n:
            npc_por_nombre[n["name"]].append(n["id"])
    item_por_nombre = {}
    for i in item.values():
        item_por_nombre.setdefault(i.get("name"), i["id"])
    inicio_q = collections.defaultdict(list)
    for r in T["quest_start"]:
        inicio_q[r["quest"]].append(r)

    # 1) zonas de nivel 30-40 para la Horda
    por_area = collections.defaultdict(list)
    for q in quest.values():
        if q.get("side") in (0, 2) and q.get("zone_area") in AREAS and q.get("level"):
            por_area[q["zone_area"]].append(q)
    zonas = {}
    for area, qs in por_area.items():
        niveles = sorted(q["level"] for q in qs)
        med = niveles[len(niveles) // 2]
        parte = sum(1 for v in niveles if NIVEL_ZONA[0] <= v <= NIVEL_ZONA[1]) / len(niveles)
        if len(qs) >= MIN_MISIONES_ZONA and parte >= PARTE_MINIMA:
            ui, nombre = AREAS[area]
            if ui not in uimap:
                raise ErrorFuente(f"forever-db no trae el recuadro del uiMap {ui} ({nombre})")
            zonas[area] = {"area": area, "uimap": ui, "nombre_en": nombre, "mediana": med,
                           "nivel_min": niveles[0], "nivel_max": niveles[-1]}

    # Cada aparición se asigna a UNA zona: los recuadros de mapas vecinos se solapan en los bordes,
    # así que gana la zona donde el punto queda más al centro (más lejos del borde).
    zonales = [u for u in uimap.values() if abs(u["left"] - u["right"]) < 15000]
    zona_de_punto = {}

    def zona_de(m, x, y):
        k = (m, x, y)
        if k not in zona_de_punto:
            mejor, puntaje = None, -1.0
            for u in zonales:
                pos = en_mapa(u, m, x, y)
                if pos:
                    c = min(pos[0], 100 - pos[0], pos[1], 100 - pos[1])
                    if c > puntaje:
                        mejor, puntaje = u["ui_map"], c
            zona_de_punto[k] = mejor
        return zona_de_punto[k]

    memo_zona = {}

    def puntos_en_zona(clave, ui):
        """Apariciones de un PNJ u objeto en la zona. Un punto suelto en el borde no cuenta: la criatura
        tiene que tener ahí al menos el 20 % de sus apariciones, o 3."""
        k = (clave, ui)
        if k not in memo_zona:
            todos = spawns.get(clave, [])
            aqui = [(m, x, y) for (m, x, y) in todos if zona_de(m, x, y) == ui]
            if len(aqui) < 3 and len(aqui) < 0.2 * len(todos):
                aqui = []
            memo_zona[k] = aqui
        return memo_zona[k]

    # 2) materiales que interesan: todo lo que piden los tramos de las 4 profesiones
    usa = collections.defaultdict(list)                # item -> [índice de tramo]
    for i, t in enumerate(tramos):
        for m in t["materiales"]:
            usa[m["item"]].append(i)
    # Herboristería: la hierba misma sube la profesión al recogerla.
    hierba_item = {}
    for t in tramos:                                   # "gather Herbalism 125" en la guía de Alquimia
        for m in t["materiales"]:
            if m.get("hierba") is not None:
                hierba_item[m["item"]] = {"nombre_en": item.get(m["item"], {}).get("name"), "habilidad": m["hierba"]}
    for nombre, h in hierbas.items():
        iid = item_por_nombre.get(nombre)
        if iid:
            hierba_item[iid] = {"nombre_en": nombre, "habilidad": h["habilidad"]}

    consejos, misiones_out = [], {}
    for area, z in sorted(zonas.items()):
        ui = z["uimap"]
        qs = [q for q in por_area[area] if 25 <= q["level"] <= 45]
        objetivos_zona = {}                            # npc que vive en la zona -> {quest ids}
        for q in qs:
            objetivos = []
            for o in obj_por_q.get(q["id"], []):
                if o["kind"] == "kill" and o.get("target"):
                    objetivos.append(("matar", o["target"], o.get("count")))
                    if puntos_en_zona(("npc", o["target"]), ui):
                        objetivos_zona.setdefault(o["target"], set()).add(q["id"])
                elif o["kind"] == "item" and o.get("target"):
                    for s in fuentes_item.get(o["target"], []):
                        if s["kind"] == "npc" and puntos_en_zona(("npc", s["id"]), ui):
                            objetivos.append(("botin", s["id"], o.get("count"), o["target"], s.get("chance")))
                            objetivos_zona.setdefault(s["id"], set()).add(q["id"])
            misiones_out[q["id"]] = {"nivel": q["level"], "nivel_min": q.get("min_level"),
                                     "zona": ui, "titulo_en": q.get("title"), "objetivos": objetivos}

        agrupado = collections.OrderedDict()           # (tipo, item) -> consejo

        def agregar(tipo, iid, origen, misiones):
            k = agrupado.setdefault((tipo, iid), {"zona": ui, "tipo": tipo, "item": iid, "origenes": [],
                                                  "misiones": set(), "tramos": usa.get(iid, []),
                                                  "hierba": hierba_item.get(iid, {}).get("habilidad")})
            k["origenes"].append(origen)
            k["misiones"] |= set(misiones)

        # A) lo que sueltan las criaturas de las misiones de la zona (fdb, % de diseño)
        for pnj, qids in sorted(objetivos_zona.items()):
            for iid, ch in suelta_npc.get(pnj, []):
                # Solo materiales de las 4 profesiones, con un % de diseño que valga la pena.
                # Las hierbas se juntan de los nodos (parte C), no de los bichos.
                if iid in usa and iid not in hierba_item and ch is not None and ch >= MIN_PCT:
                    agregar("botin_mision", iid, {"pnj": pnj, "pct": ch, "muestra": None, "fuente": "fdb",
                                                   "misiones": sorted(qids)}, qids)
        # B) el PNJ que la guía de profesión nombra como el que más suelta (pg), si vive en esta zona
        for iid, idx in (sorted(usa.items()) if USAR_GUIA_BOTIN else []):
            ya = set()
            for i in idx:
                for mat in tramos[i]["materiales"]:
                    if mat["item"] != iid:
                        continue
                    for nombre, pct in mat["sueltan"]:
                        for pnj in npc_por_nombre.get(nombre, []):
                            pts = puntos_en_zona(("npc", pnj), ui)
                            if not pts or pnj in ya:
                                continue
                            ya.add(pnj)
                            # misiones cuyos objetivos viven a menos de CERCA_YARDAS de este PNJ
                            # solape = mirado desde la misión: parte de las criaturas que pide la misión que
                            # tienen a este PNJ a menos de CERCA_YARDAS. Se ordena de más a menos.
                            solape = {}
                            for obj_pnj, qids in objetivos_zona.items():
                                otros = puntos_en_zona(("npc", obj_pnj), ui)
                                if not otros:
                                    continue
                                cerca = sum(1 for (_, x2, y2) in otros
                                            if any(math.hypot(x1 - x2, y1 - y2) <= CERCA_YARDAS for (_, x1, y1) in pts))
                                parte = cerca / len(otros)
                                if parte >= MIN_SOLAPE and cerca >= MIN_CERCA:
                                    # orden: 1) la misión manda matar a ESTE mismo PNJ; 2) cuántas criaturas
                                    # de la misión lo tienen cerca; 3) qué parte de ellas.
                                    puntaje = (obj_pnj == pnj, cerca, parte)
                                    for q in qids:
                                        if q not in solape or puntaje > solape[q]:
                                            solape[q] = puntaje
                            cercanas = sorted(solape, key=lambda q: (tuple(-x for x in solape[q]), q))
                            agregar("botin_zona", iid, {"pnj": pnj, "pct": pct, "muestra": None,
                                                        "fuente": "pg", "apariciones_fuente": "fdb",
                                                        "misiones": cercanas,
                                                        "solape": {q: round(solape[q][2], 2) for q in cercanas}}, cercanas)
        # C) nodos de hierbas que hay en la zona (fdb: el nodo y sus apariciones; pg: habilidad)
        for iid, h in sorted(hierba_item.items()):
            nodos = [s["id"] for s in fuentes_item.get(iid, []) if s["kind"] == "object"]
            total = sum(len(puntos_en_zona(("object", o), ui)) for o in nodos)
            if total >= 3:
                agregar("nodo", iid, {"nodos": total, "fuente": "fdb", "habilidad_fuente": "pg",
                                      "misiones": []}, [])
        # D) hierbas que la ruta de Herboristería de Polestar recoge en esta zona (pg). forever-db solo trae
        #    los nodos de hierbas que alguna misión pide, así que sin esto faltarían casi todas.
        for nombre, h in (sorted(hierbas.items()) if USAR_GUIA_BOTIN else []):
            iid = item_por_nombre.get(nombre)
            if iid and z["nombre_en"] in h["zonas"] and ("nodo", iid) not in agrupado:
                agregar("nodo", iid, {"guiaZona": True, "fuente": "pg", "misiones": []}, [])
        for k in agrupado.values():
            # los 3 que más sueltan; sin % al final
            k["origenes"].sort(key=lambda o: -(o.get("pct") or 0))
            k["origenes"] = k["origenes"][:MAX_ORIGENES]
            orden = []                                 # se respeta el orden de cada origen (el más cercano primero)
            for o in k["origenes"]:
                for q in o["misiones"]:
                    if q not in orden:
                        orden.append(q)
            k["misiones"] = orden
            k["cerca"] = bool(k["misiones"])
            k["fuente"] = sorted({o["fuente"] for o in k["origenes"]} |
                                 {o.get("apariciones_fuente") or o.get("habilidad_fuente") for o in k["origenes"]} - {None}
                                 | ({"pg"} if k["tramos"] else set()))
            consejos.append(k)

    # 3) bolsas: misiones de la Horda que regalan una bolsa (elegible o fija)
    bolsas = []
    for r in T["quest_reward"]:
        if r["kind"] not in ("item", "choice"):
            continue
        it = item.get(r["id"], {})
        nombre = it.get("name", "")
        if not BOLSA_RX.search(nombre) or NO_BOLSA_RX.search(nombre) or it.get("quest_item"):
            continue
        q = quest.get(r["quest"])
        if not q or q.get("side") not in (0, 2):
            continue
        area = q.get("zone_area")
        bolsas.append({"mision": q["id"], "nivel": q.get("level"), "nivel_min": q.get("min_level"),
                       "razas": q.get("races", 0), "clases": q.get("classes", 0), "lado": q.get("side"),
                       "item": r["id"], "eleccion": r["kind"] == "choice", "titulo_en": q.get("title"),
                       "nombre_en": nombre, "zona": AREAS.get(area, (None, None))[0],
                       "fuente": ["fdb"]})
    bolsas.sort(key=lambda b: (b["nivel"] or 0, b["mision"]))

    fuentes = {
        "fdb": {"nombre": "forever-db (Polestar)", "url": "https://github.com/fitzforge/polestar/tree/next/forever-db",
                "licencia": "GPL-3.0-only", "redistribuible": True, "version": indice["version"],
                "build": build, "commit_productor": indice.get("producerCommit"),
                "credito": "Datos de misiones, PNJ y botín: forever-db de Polestar (GPL-3.0)",
                "aviso": "Nombres y títulos del juego son de Blizzard; ninguna licencia los cubre (NOTICE.md)."},
        "pg": {"nombre": "Guías de profesiones de Polestar", "url": "https://github.com/fitzforge/polestar/tree/next/guides/forever/professions",
               "licencia": "GPL-3.0", "redistribuible": True, "huellas": huellas_guias,
               "credito": "Tramos, recetas y % del que más suelta: guías de profesiones de Polestar (GPL-3.0)",
               "aviso": "Solo números e ids; el texto de las guías no se copia. Origen de los % según Polestar: sus datos de referencia (NO VERIFICADO cuál)."},
        "fdbapi": {"nombre": "ForeverDB.net (API)", "url": "https://foreverdb.net", "licencia": "condiciones de https://foreverdb.net/developers",
                   "redistribuible": True, "activa": False,
                   "credito": "Datos: ForeverDB.net — https://foreverdb.net",
                   "aviso": "Apagada: falta la clave de Cristian. La clave nunca va dentro del addon."},
    }
    fdb_dir = pathlib.Path(raiz) / "forever-db"
    textos = {"gpl": (fdb_dir / "LICENSE").read_text(encoding="utf-8"),
              "notice": (fdb_dir / "NOTICE.md").read_text(encoding="utf-8")}
    return {"_textos": textos, "build": build, "zonas": zonas, "tramos": tramos, "consejos": consejos,
            "misiones": misiones_out, "bolsas": bolsas, "fuentes": fuentes,
            "nombres_en": {"item": {i: item[i].get("name") for i in
                                    {c["item"] for c in consejos} | {b["item"] for b in bolsas} if i in item},
                           "npc": {n: npc[n].get("name") for n in {o["pnj"] for c in consejos for o in c["origenes"] if o.get("pnj")}},
                           "mision": {q: quest[q].get("title") for q in
                                      {q for c in consejos for q in c["misiones"]} | {b["mision"] for b in bolsas}}}}


# ----------------------------------------------------------------------------- SQLite (esquema de ESQUEMA_Y_ACTUALIZACION.md, parte usada)
def escribir_sqlite(d, ruta):
    ruta = pathlib.Path(ruta)
    if ruta.exists():
        ruta.unlink()
    db = sqlite3.connect(ruta)
    c = db.cursor()
    c.executescript("""
    CREATE TABLE fuente(id TEXT PRIMARY KEY, nombre TEXT, url TEXT, licencia TEXT, se_puede_redistribuir INTEGER, credito_requerido TEXT, detalle TEXT);
    CREATE TABLE build(id TEXT PRIMARY KEY);
    CREATE TABLE zona(uimap INTEGER PRIMARY KEY, area INTEGER, nombre_en TEXT, nivel_mediana INTEGER, fuente_id TEXT, build TEXT);
    CREATE TABLE mision(id_mision INTEGER PRIMARY KEY, nivel INTEGER, nivel_minimo INTEGER, zona_uimap INTEGER, titulo_en TEXT, objetivos TEXT, fuente_id TEXT, build TEXT);
    CREATE TABLE tramo(id INTEGER PRIMARY KEY, profesion TEXT, desde INTEGER, hasta INTEGER, id_objeto_receta INTEGER, fuente_id TEXT, build TEXT);
    CREATE TABLE receta(tramo_id INTEGER, id_hechizo INTEGER, hasta INTEGER, umbral_naranja INTEGER, umbral_amarillo INTEGER, umbral_verde INTEGER, umbral_gris INTEGER, fuente_id TEXT, build TEXT);
    CREATE TABLE reactivo(tramo_id INTEGER, id_objeto INTEGER, cantidad_total INTEGER, como TEXT, fuente_id TEXT);
    CREATE TABLE origen_objeto(id INTEGER PRIMARY KEY, id_objeto INTEGER, tipo_origen TEXT, ref_id INTEGER, probabilidad REAL, muestra INTEGER, metodo TEXT, zona_uimap INTEGER, fuente_id TEXT, build TEXT);
    CREATE TABLE bolsa_mision(id_mision INTEGER, id_objeto INTEGER, nivel INTEGER, eleccion INTEGER, fuente_id TEXT, build TEXT);
    """)
    b = d["build"]
    c.execute("INSERT INTO build VALUES(?)", (b,))
    for k, f in d["fuentes"].items():
        c.execute("INSERT INTO fuente VALUES(?,?,?,?,?,?,?)", (k, f["nombre"], f["url"], f["licencia"],
                  int(f["redistribuible"]), f["credito"], json.dumps({x: y for x, y in f.items() if x not in
                  ("nombre", "url", "licencia", "redistribuible", "credito")}, ensure_ascii=False)))
    for z in d["zonas"].values():
        c.execute("INSERT INTO zona VALUES(?,?,?,?,?,?)", (z["uimap"], z["area"], z["nombre_en"], z["mediana"], "fdb", b))
    for qid, q in d["misiones"].items():
        c.execute("INSERT INTO mision VALUES(?,?,?,?,?,?,?,?)", (qid, q["nivel"], q["nivel_min"], q["zona"],
                  q["titulo_en"], json.dumps(q["objetivos"]), "fdb", b))
    for i, t in enumerate(d["tramos"]):
        c.execute("INSERT INTO tramo VALUES(?,?,?,?,?,?,?)", (i, t["prof"], t["desde"], t["hasta"], t["receta_item"], "pg", b))
        col = t["colores"] or (None,) * 4
        c.execute("INSERT INTO receta VALUES(?,?,?,?,?,?,?,?,?)", (i, t["hechizo"], t["hasta"], *col, "pg", b))
        for m in t["materiales"]:
            c.execute("INSERT INTO reactivo VALUES(?,?,?,?,?)", (i, m["item"], m["cantidad"], m["como"], "pg"))
    n = 0
    for k in d["consejos"]:
        for o in k["origenes"]:
            n += 1
            nodo = k["tipo"] == "nodo"
            c.execute("INSERT INTO origen_objeto VALUES(?,?,?,?,?,?,?,?,?,?)", (n, k["item"],
                      "nodo de recolección" if nodo else "caída de PNJ", o.get("pnj"), o.get("pct"), o.get("muestra"),
                      {"fdb": "dato de diseño (forever-db)", "pg": "guía de Polestar"}[o["fuente"]],
                      k["zona"], o["fuente"], b))
    for x in d["bolsas"]:
        c.execute("INSERT INTO bolsa_mision VALUES(?,?,?,?,?,?)", (x["mision"], x["item"], x["nivel"], int(x["eleccion"]), "fdb", b))
    db.commit()
    db.close()


# ----------------------------------------------------------------------------- Lua
def a_lua(v, ind=0):
    sp = "\t" * ind
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v) if not (isinstance(v, float) and v.is_integer()) else str(int(v))
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(v, (list, tuple)):
        if not v:
            return "{}"
        return "{" + ", ".join(a_lua(x, ind + 1) for x in v) + "}"
    if isinstance(v, (set, frozenset)):
        return a_lua(sorted(v), ind)
    if isinstance(v, dict):
        if not v:
            return "{}"
        partes = []
        for k in sorted(v, key=lambda k: (isinstance(k, str), k)):
            clave = f"[{k}]" if isinstance(k, int) else (k if re.match(r"^[A-Za-z_]\w*$", k) else f"[{a_lua(k)}]")
            partes.append(f"{sp}\t{clave} = {a_lua(v[k], ind + 1)},")
        return "{\n" + "\n".join(partes) + f"\n{sp}}}"
    raise TypeError(type(v))


CABECERA = ("-- Generado por WOW_FOREVER/generador/generador.py. NO editar a mano: volver a generar.\n"
            "-- Licencia: GPL-3.0 (ver LICENSE-DATA.txt). Build del juego: {build}.\n")


def escribir_lua(d, carpeta):
    carpeta = pathlib.Path(carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    cab = CABECERA.format(build=d["build"])
    fuentes_lua = {k: {"nombre": f["nombre"], "url": f["url"], "licencia": f["licencia"],
                       "credito": f["credito"], "redistribuible": f["redistribuible"],
                       "activa": f.get("activa", True)} for k, f in d["fuentes"].items()}
    tramos_lua = []
    for t in d["tramos"]:
        tramos_lua.append({"prof": t["skill_id"], "desde": t["desde"], "hasta": t["hasta"],
                           "receta": t["receta_item"],
                           "hechizo": t["hechizo"], "colores": list(t["colores"]) if t["colores"] else None,
                           "mats": [[m["item"], m["cantidad"], m["como"]] for m in t["materiales"]],
                           "fuente": "pg"})
    zonas_lua = {z["uimap"]: {"area": z["area"], "min": z["nivel_min"], "max": z["nivel_max"],
                              "mediana": z["mediana"], "fuente": "fdb"} for z in d["zonas"].values()}
    consejos_lua = []
    for k in d["consejos"]:
        x = {"zona": k["zona"], "tipo": k["tipo"], "item": k["item"], "misiones": k["misiones"],
             "tramos": [i + 1 for i in k["tramos"]], "cerca": k["cerca"], "fuente": k["fuente"],
             "hierba": k["hierba"],
             "origenes": [{c2: o.get(c2) for c2 in ("pnj", "pct", "muestra", "nodos", "fuente") if o.get(c2) is not None}
                          for o in k["origenes"]]}
        consejos_lua.append(x)
    por_mision = collections.defaultdict(list)
    for n, k in enumerate(d["consejos"]):
        for q in k["misiones"]:
            por_mision[q].append(n + 1)
    misiones_lua = {q: {"nivel": m["nivel"], "nivelMin": m["nivel_min"], "zona": m["zona"]} for q, m in d["misiones"].items()}
    datos = {"build": d["build"], "fuentes": fuentes_lua, "zonas": zonas_lua, "tramos": tramos_lua,
             "consejos": consejos_lua, "porMision": dict(por_mision), "misiones": misiones_lua,
             "bolsas": [{"mision": b["mision"], "nivel": b["nivel"], "nivelMin": b["nivel_min"], "item": b["item"],
                         "razas": b["razas"], "clases": b["clases"],
                         "eleccion": b["eleccion"], "zona": b["zona"], "fuente": b["fuente"]} for b in d["bolsas"]],
             "profesiones": {sid: n for (n, sid) in PROFESIONES.values()}}
    (carpeta / "Datos.lua").write_text(cab + "local _, ns = ...\nns = ns or {}\nns.Datos = " + a_lua(datos) +
                                       "\nAsistenteDatos = ns.Datos\n", encoding="utf-8")
    # Nombres en inglés solo como respaldo: en el juego se piden en español a GetItemInfo / el cuadro del PNJ.
    (carpeta / "Nombres_enUS.lua").write_text(cab + "-- Respaldo: nombres del juego (de Blizzard), solo si el juego aún no los tiene en caché.\n"
                                              "local _, ns = ...\nns = ns or {}\nns.NombresEN = " +
                                              a_lua(d["nombres_en"]) + "\nAsistenteNombresEN = ns.NombresEN\n",
                                              encoding="utf-8")
    f = d["fuentes"]
    lic = [
        "Asistente_Datos: de dónde sale cada dato",
        "=======================================",
        "",
        f"Build del juego: {d['build']}. Licencia de este paquete: GPL-3.0.",
        "",
        "[fdb] forever-db de Polestar",
        f"  URL: {f['fdb']['url']}",
        f"  Versión: {f['fdb']['version']} · commit productor: {f['fdb']['commit_productor']}",
        "  Licencia: GPL-3.0-only (tablas quest*, npc, object, item, item_source, spawn, ui_map).",
        "  Se usa: misiones, objetivos, PNJ, apariciones, botín de objetos de misión, telas y hierbas, recompensas.",
        "  Créditos de forever-db (su NOTICE.md): EG Link (CC BY 4.0), CMaNGOS classic-db (GPL-3.0), VMaNGOS/Factoruide",
        "  (GPL-2.0-or-later), ForeverTDB (GPL-2.0), QuestieDB, tablas del cliente, pfQuest (MIT).",
        "  " + f["fdb"]["aviso"],
        "",
        "[pg] Guías de profesiones de Polestar",
        f"  URL: {f['pg']['url']}",
        "  Licencia: GPL-3.0 (repositorio de Polestar). Huellas de los archivos leídos:",
        *[f"    {k}: {v}" for k, v in sorted(f["pg"]["huellas"].items())],
        "  " + f["pg"]["aviso"],
        "",
        "[fdbapi] ForeverDB.net — APAGADA en esta versión (sin clave). Si se activa: crédito visible con enlace a",
        "  https://foreverdb.net donde se muestren sus datos; la clave nunca va dentro del addon.",
        "",
        "World of Warcraft y Blizzard Entertainment son marcas de Blizzard Entertainment, Inc.",
        "Este paquete no está hecho ni respaldado por Blizzard.",
    ]
    (carpeta / "LICENSE-DATA.txt").write_text("\n".join(lic) + "\n", encoding="utf-8")
    # Textos de licencia que van junto a los datos: GPL-3.0 y el NOTICE de forever-db
    # (trae el aviso MIT de pfQuest, que exige ir en toda copia, y los créditos CC BY 4.0 de EG Link).
    (carpeta / "LICENSE").write_text(d["_textos"]["gpl"], encoding="utf-8")
    (carpeta / "NOTICE-forever-db.md").write_text(d["_textos"]["notice"], encoding="utf-8")


def main(argv):
    raiz, salida = argv[1], argv[2]
    d = construir(raiz)
    escribir_lua(d, salida)
    if len(argv) > 3:
        escribir_sqlite(d, argv[3])
    print(f"zonas={len(d['zonas'])} tramos={len(d['tramos'])} consejos={len(d['consejos'])} "
          f"misiones={len(d['misiones'])} bolsas={len(d['bolsas'])}")
    for z in d["zonas"].values():
        print("  zona", z["uimap"], z["nombre_en"], f"mediana {z['mediana']}")
    return d


if __name__ == "__main__":
    main(sys.argv)
