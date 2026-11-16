# -*- coding: utf-8 -*-
"""Pruebas del generador y del módulo Lua del asistente.

Uso:  python -I pruebas/test_generador.py <carpeta polestar clonada>
Sale con código 1 si alguna falla.
"""
import collections
import json
import os
import pathlib
import shutil
import sqlite3
import sys
import tempfile

sys.stdout.reconfigure(encoding="utf-8")
AQUI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
import foreverdb_api  # noqa: E402
import generador as g  # noqa: E402

RAIZ = pathlib.Path(sys.argv[1]).resolve()
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


tmp = pathlib.Path(tempfile.mkdtemp(prefix="asistente_"))
SALIDA = tmp / "Asistente_Datos"

# ------------------------------------------------------------------ 1. generar con una clave falsa puesta
CLAVE_FALSA = "CLAVE-FALSA-NO-DEBE-SALIR-1234567890"
os.environ["FOREVERDB_KEY"] = CLAVE_FALSA
d = g.construir(RAIZ)
g.escribir_lua(d, SALIDA)
g.escribir_sqlite(d, tmp / "cruce.sqlite")
for p in SALIDA.rglob("*"):
    check(CLAVE_FALSA not in p.read_text(encoding="utf-8", errors="ignore"), f"la clave aparece en {p.name}")
check(CLAVE_FALSA not in (tmp / "cruce.sqlite").read_bytes().decode("latin-1"), "la clave aparece en el sqlite")
del os.environ["FOREVERDB_KEY"]
try:
    foreverdb_api.leer_clave(None)
    check(False, "sin clave, ForeverDB debería negarse")
except foreverdb_api.SinClave:
    check(True, "")

# ------------------------------------------------------------------ 2. zonas de nivel 30-40 de la Horda
zonas = {z["uimap"] for z in d["zonas"].values()}
check(zonas == {1417, 1434, 1424, 1418, 1435, 1441, 1445, 1443}, f"zonas inesperadas: {sorted(zonas)}")
# El mapa área->uiMap es a mano: se comprueba que quien DA las misiones de cada zona vive en esa zona.
T = g.cargar_forever_db(RAIZ)
um = {u["ui_map"]: u for u in T["ui_map"]}
sp = collections.defaultdict(list)
for s in T["spawn"]:
    if s["kind"] == "npc":
        sp[s["id"]].append(s)
starts = collections.defaultdict(list)
for r in T["quest_start"]:
    if r["kind"] == "npc":
        starts[r["quest"]].append(r["id"])
for z in d["zonas"].values():
    total = dentro = 0
    for qid, q in d["misiones"].items():
        if q["zona"] != z["uimap"]:
            continue
        for n in starts.get(qid, []):
            if sp.get(n):
                total += 1
                dentro += any(g.en_mapa(um[z["uimap"]], s["map"], s["x"], s["y"]) for s in sp[n])
    # 0,6: hay misiones de zona que se toman en una ciudad (p. ej. Cima del Trueno); un mapa equivocado daría ~0.
    check(total and dentro / total >= 0.6, f"{z['nombre_en']}: solo {dentro}/{total} dadores de misión caen en el mapa {z['uimap']}")

# ------------------------------------------------------------------ 3. solo datos seguros (decisión de Cristian, 16-11)
# La Carne de raptor NO sale: forever-db no tiene su botín y el 38 % de la guía de Polestar tiene origen sin verificar.
CARNE, RAPTOR_ASADO = 12184, 15855
check(not g.USAR_GUIA_BOTIN, "el botín de las guías debe estar apagado")
check(not any(c["item"] == CARNE for c in d["consejos"]), "la Carne de raptor no debe aconsejarse sin fuente segura")
check(all(o["fuente"] == "fdb" for c in d["consejos"] for o in c["origenes"]), "todo origen debe ser forever-db")
# La receta sí queda (la guía la lee de las tablas del cliente): Raptor asado 175-225 con 52 carnes
t = [t for t in d["tramos"] if t["hechizo"] == RAPTOR_ASADO]
check(len(t) == 1 and (t[0]["desde"], t[0]["hasta"]) == (175, 225) and t[0]["colores"] == (175, 215, 235, 255), f"Raptor asado: {t}")
check(t and any(m["item"] == CARNE and m["cantidad"] == 52 for m in t[0]["materiales"]), "Raptor asado lleva 52 carnes")
check(t and t[0]["receta_item"] == 12228, "la receta que se compra es 12228")
# Ejemplo seguro: Paño de seda (4306) en Arathi, % de diseño de forever-db, para Venda de seda (7928) 150-180
SEDA, VENDA_SEDA, VINDICADOR, SIGILO_ROTO = 4306, 7928, 2585, 640
k = [c for c in d["consejos"] if c["item"] == SEDA and c["zona"] == 1417]
check(len(k) == 1, "falta el Paño de seda en Arathi")
if k:
    k = k[0]
    o = k["origenes"][0]
    check(o["pnj"] == VINDICADOR and o["pct"] == 30.8 and o["fuente"] == "fdb", f"origen: {o}")
    check(SIGILO_ROTO in k["misiones"], f"El sigilo roto (640) pide matar Vindicadores: {k['misiones']}")
    tv = [d["tramos"][i] for i in k["tramos"]]
    check(any(x["hechizo"] == VENDA_SEDA and (x["desde"], x["hasta"]) == (150, 180) for x in tv), f"tramos seda: {tv}")
# El 30,8 % está tal cual en forever-db (item_source: PNJ 2585, objeto 4306)
check(any(s["item"] == SEDA and s["id"] == VINDICADOR and s.get("chance") == 30.8 for s in T["item_source"]),
      "el 30,8 % debe estar tal cual en forever-db")
# El dato fuente de ese %: item_source de forever-db dice 30.8 para el PNJ 2585 y el objeto 4306

# ------------------------------------------------------------------ 4. cada dato lleva fuente y licencia
F = d["fuentes"]
for nombre, f in F.items():
    check(f["licencia"] and f["url"] and f["credito"], f"fuente {nombre} sin licencia/url/crédito")
    check(f["redistribuible"] is True, f"fuente {nombre} no redistribuible no puede entrar")
check(F["fdbapi"].get("activa") is False, "ForeverDB debe estar apagada sin clave")
usadas = set()
for c in d["consejos"]:
    check(c["fuente"], f"consejo sin fuente: {c['item']}")
    for o in c["origenes"]:
        check(o["fuente"] in F and F[o["fuente"]].get("activa", True), f"origen con fuente inválida: {o}")
        usadas.add(o["fuente"])
        if o["fuente"] == "fdb" and "pnj" in o:
            check(o["pct"] is not None and o["pct"] >= g.MIN_PCT, f"caída sin % o muy baja: {o}")
for t in d["tramos"]:
    check(t["guia"].endswith(".guide") and t["hechizo"] and t["materiales"], f"tramo sin guía, receta o materiales: {t['prof']} {t['desde']}")
    check(t["desde"] < t["hasta"], f"tramo al revés: {t['prof']} {t['desde']}-{t['hasta']}")
# Alquimia: cada material va con SU receta (el revisor halló Sangrerreal pegada al Elixir de defensa).
#   Mana Potion (3452): 1 Stranglekelp, 1 Kingsblood, 1 Leaded Vial; Elixir of Defense (11450): Wild Steelbloom, Goldthorn.
alq = {t["hechizo"]: t for t in d["tramos"] if t["prof"] == "Alquimia"}
SANGRERREAL, ACERITA, ESPINA_ORO = 3356, 3355, 3821
check(SANGRERREAL in {m["item"] for m in alq[3452]["materiales"]}, "Sangrerreal debe servir a la Poción de maná")
check(SANGRERREAL not in {m["item"] for m in alq[11450]["materiales"]}, "Sangrerreal NO sirve al Elixir de defensa")
check({ACERITA, ESPINA_ORO} <= {m["item"] for m in alq[11450]["materiales"]}, "Elixir de defensa: Acérita y Espina de oro")
check((alq[3452]["desde"], alq[3452]["hasta"]) == (160, 195), f"Poción de maná: {alq[3452]['desde']}-{alq[3452]['hasta']}")
check(next(m["cantidad"] for m in alq[3452]["materiales"] if m["item"] == SANGRERREAL) == 39, "39 sangrerreales (39 fabricaciones x 1)")
for b in d["bolsas"]:
    check(b["fuente"] == ["fdb"], f"bolsa sin fuente: {b}")
check(usadas == {"fdb"} and any("pg" in c["fuente"] for c in d["consejos"]), f"orígenes solo fdb, recetas pg: {usadas}")
# huellas de las guías: coinciden con los archivos leídos
for nombre, h in F["pg"]["huellas"].items():
    check(g.sha256(RAIZ / "guides" / "forever" / "professions" / nombre) == h, f"huella de {nombre}")
lic = (SALIDA / "LICENSE-DATA.txt").read_text(encoding="utf-8")
check("GPL-3.0-only" in lic and "[pg]" in lic and "forever-db" in lic and F["fdb"]["version"] in lic, "LICENSE-DATA incompleto")
check(d["build"] in (SALIDA / "Datos.lua").read_text(encoding="utf-8")[:300], "Datos.lua no dice el build")
# sqlite: toda fila tiene una fuente registrada y redistribuible
db = sqlite3.connect(tmp / "cruce.sqlite")
malas = db.execute("""SELECT count(*) FROM origen_objeto o LEFT JOIN fuente f ON f.id=o.fuente_id
                      WHERE f.id IS NULL OR f.se_puede_redistribuir=0""").fetchone()[0]
check(malas == 0, f"{malas} filas de origen sin fuente válida en sqlite")
check(db.execute("SELECT count(*) FROM mision WHERE fuente_id IS NULL OR build IS NULL").fetchone()[0] == 0, "misión sin fuente o build")
db.close()

# ------------------------------------------------------------------ 5. huella alterada = no genera
copia = tmp / "polestar_alterado"
shutil.copytree(RAIZ / "forever-db", copia / "forever-db")
with open(copia / "forever-db" / "data" / "ui_map.jsonl", "a", encoding="utf-8") as f:
    f.write("\n")
try:
    g.cargar_forever_db(copia)
    check(False, "una tabla alterada debería frenar la generación")
except g.ErrorFuente:
    check(True, "")

# ------------------------------------------------------------------ 6. bolsas
ids = {(b["mision"], b["item"]) for b in d["bolsas"]}
check(any(b["mision"] == 791 for b in d["bolsas"]), "falta Carry Your Weight (791)")
check(any(b["mision"] == 96260 for b in d["bolsas"]), "falta Stronger than Steel (96260, bolsas de seda de araña)")
for b in d["bolsas"]:
    n = b["nombre_en"]
    check(not n.startswith(("Pattern:", "Recipe:")) and "Fireworks" not in n and "Supply Bag" not in n, f"no es bolsa: {n}")

# ------------------------------------------------------------------ 7. Lua: lo que el jugador lee
from lupa.lua51 import LuaRuntime  # noqa: E402

L = LuaRuntime(unpack_returned_tuples=True)
# Simulación del cliente. Los nombres en español de aquí son SOLO para la prueba: en el juego los pone el cliente.
L.execute("""
NOMBRES = { [4306] = "Paño de seda", [12184] = "Carne de raptor" }
HECHIZOS = { [7928] = "Venda de seda", [15855] = "Raptor asado" }
MAPAS = { [1417] = "Tierras Altas de Arathi", [1445] = "Marjal Revolcafango" }
MISIONES = { [640] = "El sigilo roto" }
PNJ = { [2585] = "Vindicador de Stromgarde" }
-- clase, subclase: 5976 bolsa normal, 22243 bolsa de almas, 2101 carcaj (clase 11), 12184 material
CLASES = { [5976] = {1, 0}, [22243] = {1, 1}, [2101] = {11, 2}, [12184] = {7, 8} }
C_Item = { GetItemNameByID = function(id) return NOMBRES[id] end,
           GetItemInfoInstant = function(id) local c = CLASES[id] or {}; return id, "", "", "", 0, c[1], c[2] end }
-- Forever no tiene arqueología: GetProfessions devuelve huecos nil antes de cocina y primeros auxilios.
PROFS = { [1] = {"Herboristería", 182, 150}, [5] = {"Cocina", 185, 175}, [6] = {"Primeros auxilios", 129, 160} }
function GetProfessions() return 1, nil, nil, nil, 5, 6 end
function GetProfessionInfo(i) local p = PROFS[i]; return p[1], "", p[3], 300, 0, 0, p[2] end
C_Spell = { GetSpellName = function(id) return HECHIZOS[id] end }
C_Map = { GetMapInfo = function(id) return MAPAS[id] and { name = MAPAS[id] } end }
C_QuestLog = { GetTitleForQuestID = function(id) return MISIONES[id] end }
C_TooltipInfo = { GetHyperlink = function(l) local id = tonumber(l:match("Creature%-0%-0%-0%-0%-(%d+)"))
                  return PNJ[id] and { lines = { { leftText = PNJ[id] } } } end }
SlashCmdList = {}
""")
cargar = L.eval('function(src, name, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Asistente_Datos", ns) end')
ns = L.table()
ADDON = AQUI.parent.parent / "addon" / "Asistente_Datos"     # Consejos.lua es código, no se genera
for nombre in ["Datos.lua", "Nombres_enUS.lua", "Consejos.lua"]:
    cargar(((ADDON if nombre == "Consejos.lua" else SALIDA) / nombre).read_text(encoding="utf-8"), nombre, ns)
C, B = ns.Consejos, ns.Bolsas


def hab(**kw):
    t = L.table()
    for k, v in kw.items():
        t[int(k[1:])] = v
    return t


NL = chr(10)


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)]


# Hope: nivel 37, Primeros auxilios 150, Cocina 175 -> sale la seda; la carne ya no
txt = NL.join(lista(C.ParaZona(1417, 37, hab(p129=150, p185=175))))
print("---- /asistente en Arathi, Primeros auxilios 150 ----" + NL + txt + NL + "-----------------------------------------")
check("junta 42 Paño de seda: sube Primeros auxilios de 150 a 180 con Venda de seda." in txt, "frase principal de la seda")
check("Vindicador de Stromgarde (30,8 % de diseño, sin muestra; forever-db (Polestar))" in txt, "origen con % y fuente")
check("Queda de paso con: El sigilo roto" in txt, "misión de paso")
check("Carne de raptor" not in txt, "la carne no se aconseja sin fuente segura")
check("junta 21 Paño de seda: sube Primeros auxilios de 165 a 180" in NL.join(lista(C.ParaZona(1417, 37, hab(p129=165)))), "cantidad a mitad de tramo")
check("Paño de seda" not in NL.join(lista(C.ParaZona(1417, 37, hab()))), "sin Primeros auxilios no se aconseja")
check(any("Paño de seda" in t for t in lista(C.ParaMision(640, 37, hab(p129=150)))), "consejo al tener 640 en el registro")
# Herboristería: alguna hierba en el Marjal Revolcafango para Herboristería 150
check(any(t.startswith("recoge") for t in lista(C.ParaZona(1445, 37, hab(p182=150)))), "sin consejo de hierbas en Revolcafango")
# créditos visibles: las dos fuentes activas, no ForeverDB apagada
cred = lista(C.Creditos())
check(len(cred) == 2 and all("GPL-3.0" in c for c in cred), f"créditos: {cred}")

# Bolsas
TAUREN, DRUIDA = 6, 11
plan = [b.mision for b in lista(B.Plan(28, TAUREN, DRUIDA))]
check(96260 in plan, "a nivel 28 debería aparecer la bolsa de seda de araña (96260)")
check(1474 not in plan and 1513 not in plan, "la Bolsa de almas pequeña es de brujo: no para druida")
plan15 = [b.mision for b in lista(B.Plan(14, TAUREN, DRUIDA))]
check(1474 not in plan15, "la Bolsa de almas no es para druida (filtro de clase)")
check(any(m in [b.mision for b in lista(B.Plan(18, 5, 9))] for m in (1474, 1513)), "un brujo no-muerto sí ve la Bolsa de almas")
check(B.EsBolsa(12184) is False, "un material no es bolsa")
check(B.EsBolsa(5976) is True, "clase 1 subclase 0 = bolsa normal")
check(B.EsBolsa(22243) is False, "una bolsa de almas no cuenta como espacio normal")
check(B.EsBolsa(2101) is False, "un carcaj no es bolsa")
# habilidades leídas del juego con huecos nil (hallazgo ALTA 1 del revisor)
hj = C.HabilidadesDelJugador()
check(hj[185] == 175 and hj[129] == 160 and hj[182] == 150, f"habilidades del jugador: {dict(hj)}")
check("Paño de seda" in NL.join(lista(C.ParaZona(1417, 37, hj))), "con las profesiones leídas del juego sale la seda")


def eq(*s):
    t = L.table()
    for i, v in enumerate(s, 1):
        t[i] = v
    return t


msg, idx = B.QueHacer(eq(6, 6, 8, 10), 12, 1)
check(idx == 1 and "ganas 6 ranuras" in msg and "al banco" in msg, f"cambio con banco: {msg}")
msg, idx = B.QueHacer(eq(6, 6, 8, 10), 12, 0)
check("véndela o ponla en la subasta" in msg, f"cambio sin banco: {msg}")
msg, idx = B.QueHacer(eq(6, 8, 0, 10), 12, 0)
check(idx == 3 and "hueco vacío 3" in msg, f"hueco vacío: {msg}")
msg, idx = B.QueHacer(eq(12, 12, 14, 14), 10, 0)
check(idx is None and "No te sirve" in msg, f"bolsa peor: {msg}")
print("Bolsas:", B.QueHacer(eq(6, 6, 8, 10), 12, 1)[0])

shutil.rmtree(tmp, ignore_errors=True)
print(f"OK {ok} · FALLAS {fail}")
sys.exit(1 if fail else 0)
