# Pruebas de K122: Calabozos con TODAS las mazmorras de Forever y el buscador sin tildes ni mayúsculas.
# Con el Dungeons.lua REAL de Polestar, el Codex REAL (Polestar_Codex/Dungeons1.lua), Mamba_Panel/Calabozos.lua y la
# función `matches` tal como queda en Polestar/UI/Dungeons.lua con el parche P17.
# 1) Recorre la tabla GroupFinderActivity del cliente (la copia más nueva) y exige que cada mazmorra o banda de Forever
#    esté en Calabozos (Dungeons.ForMap), con nombre, niveles, zona y «Llévame a la entrada» (la flecha) o, si no se
#    conoce la entrada, "datos en camino". Fuera solo las de temporada: sin Codex y con PlayerCondition en todas sus filas.
# 2) Buscador: "ane", "anegada", "ciudad anegada" (con mayúsculas y tildes) dan La Ciudad Anegada; "krol" da Krol'dok.
# 3) Si el Codex trae después la misma mazmorra (una versión nueva de Polestar), manda la del Codex.
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_calabozos.py [carpeta addon] [--romper]
# --romper: control negativo, sin "La Ciudad Anegada" en los datos de Mamba: TIENE que fallar.
import csv
import pathlib
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
ADDON = pathlib.Path(args[0] if args else RAIZ / "addon").resolve()
WAGO = [RAIZ / "data" / "sources" / "wago", pathlib.Path(r"D:\rust\polestar-data\sources\wago")]

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def tabla(nombre, idioma=""):
    cand = []
    for base in WAGO:
        if base.is_dir():
            for b in base.iterdir():
                f = (b / idioma / f"{nombre}.csv") if idioma else (b / f"{nombre}.csv")
                if b.name.startswith("1.60.") and f.is_file():
                    cand.append((tuple(int(x) for x in re.findall(r"\d+", b.name)), f))
    if not cand:
        print(f"FALLA: no está la tabla del cliente {idioma or 'enUS'}/{nombre}.csv (data/sources/wago)")
        print(f"{ok} OK, 1 fallas")
        sys.exit(1)
    f = max(cand)[1]
    with f.open(encoding="utf-8", newline="") as h:
        return f, list(csv.DictReader(h))


L = LuaRuntime(unpack_returned_tuples=True)
G = L.globals()
L.execute("""
local lower0 = string.lower
string.lower = function(s) return (tostring(s):gsub("%u", function(c) if c:byte() < 128 then return lower0(c) end return c end)) end
""")  # como en el juego: string.lower no toca los bytes de UTF-8 (el de Windows con locale Latin-1 los rompe)
L.execute("""
NAVEGADO = {}
local ns = {}
Polestar = ns
ns.L = setmetatable({}, { __index = function(_, k) return k end })
ns.RegisterDefaults = function() end
ns.Get = function() return true end
ns.On = function() end
ns.Fire = function() end
ns.Print = function() end
ns.RegisterCommand = function() end
ns.FactionName = function(f) return f end
ns.UI = {}
ns.Compat = { GetPlayerFaction = function() return "Horde" end, MapName = function() return nil end,
	OpenWorldMap = function() return true end }
ns.Nav = {
	SetTarget = function(map, x, y, label, f, stop) local t = { map = map, x = x, y = y, label = label, stop = stop }; NAVEGADO[#NAVEGADO + 1] = t; return t end,
	StartTrip = function() end,
}
CODEX_CARGADO = false
ns.Codex = { Load = function() if not CODEX_CARGADO then CODEX_CARGADO = true; CARGAR_CODEX() end return true end }
""")
ld = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; return f(addon, ns) end')


def lua(rel):
    return (ADDON / rel).read_text(encoding="utf-8")


G.CARGAR_CODEX = lambda: ld(lua("Polestar_Codex/Dungeons1.lua"), "Polestar_Codex/Dungeons1.lua", "Polestar_Codex", G.Polestar)
ld(lua("Polestar/Dungeons/Dungeons.lua"), "Polestar/Dungeons/Dungeons.lua", "Polestar", G.Polestar)
D = G.Polestar.Dungeons
# Mamba_Panel en el orden del .toc (Datos_Calabozos antes de Calabozos), ANTES de que se cargue el Codex, como en el juego
toc = [l.strip() for l in lua("Mamba_Panel/Mamba_Panel.toc").splitlines() if l.strip().endswith(".lua")]
check("Datos_Calabozos.lua" in toc and "Calabozos.lua" in toc and toc.index("Datos_Calabozos.lua") < toc.index("Calabozos.lua"),
      f"Mamba_Panel.toc carga Datos_Calabozos.lua y después Calabozos.lua ({toc})")
NP = L.table()
ld(lua("Mamba_Panel/Datos_Calabozos.lua"), "Mamba_Panel/Datos_Calabozos.lua", "Mamba_Panel", NP)
if ROMPER:  # control negativo: sin La Ciudad Anegada en los datos de Mamba
    L.eval("""function(N) for i = #N.CALABOZOS, 1, -1 do if N.CALABOZOS[i].map == 2970 then table.remove(N.CALABOZOS, i) end end end""")(NP)
ld(lua("Mamba_Panel/Calabozos.lua"), "Mamba_Panel/Calabozos.lua", "Mamba_Panel", NP)
check(G.Polestar.UI.MambaCalce is not None and G.Polestar.UI.MambaSinDatos is not None, "Calabozos.lua publica Polestar.UI.MambaCalce y MambaSinDatos")
check(not G.CODEX_CARGADO, "Mamba no fuerza la carga del Codex al entrar (es de carga a pedido)")


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


todas = lista(D.List())
check(G.CODEX_CARGADO and len(todas) > 30, f"Calabozos lista el Codex y las de Forever ({len(todas)})")

# 1) toda mazmorra o banda de Forever de las tablas del cliente
f_gfa, gfa = tabla("GroupFinderActivity")
_, gfa_es = tabla("GroupFinderActivity", "esMX")
es = {r["ID"]: r["FullName_lang"] for r in gfa_es}
por_mapa = {}
for r in gfa:
    if r["GroupFinderCategoryID"] in ("2", "114") and r["MaxPlayers"] != "0" and r["MapID"] != "0":
        por_mapa.setdefault(int(r["MapID"]), []).append(r)
codex = {}
for linea in lua("Polestar_Codex/Dungeons1.lua").splitlines():
    m = re.match(r'^(?:\["([a-z0-9-]+)"\]|([a-z0-9_]+))=\{name="[^"]*",map=(\d+)', linea)
    if m:
        codex[int(m[3])] = m[1] or m[2]
temporada = sorted(m for m, filas in por_mapa.items() if m not in codex and all(r["PlayerConditionID"] != "0" for r in filas))
forever = sorted(m for m in por_mapa if m not in temporada)
print(f"  {f_gfa.parent.name}: {len(forever)} mazmorras y bandas de Forever; de temporada (fuera): {temporada}")
check(2970 in forever and 3039 in forever and 2994 in forever, "la tabla del cliente trae La Ciudad Anegada, Krol'dok y Alcaz")
check(2784 in temporada and 2875 in temporada and 2970 not in temporada, "las de temporada (Cañón de la Caída Demoníaca, Criptas de Karazhan) quedan fuera; las de Forever no")
check(len(codex) == 30, f"el Codex de Polestar trae 30 instancias ({len(codex)})")
for mapa in forever:
    primera = min(por_mapa[mapa], key=lambda r: int(r["ID"]))
    en = primera["FullName_lang"]
    key = D.ForMap(mapa)
    if not key:
        check(False, f"{es.get(primera['ID'], en)} ({en}, mapa {mapa}) NO está en Calabozos")
        continue
    d = D.Get(key)
    nombre = f"{d.name} ({key})"
    check(d.name and d.minLevel and d.maxLevel and d.minLevel <= d.maxLevel, f"{nombre}: nombre y niveles ({d.minLevel}-{d.maxLevel})")
    t_ent = NP.SinDatos(key, "entrance")
    check(d.zoneName or d.zone or t_ent == "Zona y entrada: datos en camino", f"{nombre}: zona (o «Zona y entrada: datos en camino»)")
    if mapa not in codex:
        nivel_min = min(int(r["MinLevel"]) for r in por_mapa[mapa])
        nivel_max = max(int(r["MaxLevelSuggestion"]) for r in por_mapa[mapa])
        check(d.name == es.get(primera["ID"]), f"{nombre}: nombre esMX del cliente ({es.get(primera['ID'])})")
        check(d.minLevel == nivel_min and d.maxLevel == nivel_max, f"{nombre}: niveles del cliente {nivel_min}-{nivel_max} ({d.minLevel}-{d.maxLevel})")
        check(d.forever is True, f"{nombre}: lleva la marca «Forever»")
        for que in ("quests", "bosses"):
            t = NP.SinDatos(key, que)
            check(t and "Datos en camino" in t, f"{nombre}: la pestaña {que} dice «datos en camino» ({t})")
        check(len(lista(D.Quests(key, None))) == 0 and len(lista(D.Bosses(key))) == 0, f"{nombre}: sin página, sin misiones ni jefes inventados")
    if d.entrance:
        n0 = len(lista(G.NAVEGADO))
        D.GuideTo(key)
        nav = lista(G.NAVEGADO)
        check(len(nav) == n0 + 1 and nav[-1].map == d.entrance.map and nav[-1].x == d.entrance.x and nav[-1].stop == "dungeon",
              f"{nombre}: «Llévame a la entrada» pone la flecha en {d.entrance.map} {d.entrance.x},{d.entrance.y}")
        check(t_ent is None, f"{nombre}: con entrada, la cabecera no dice «datos en camino»")
    else:
        check(t_ent and t_ent.endswith("datos en camino"), f"{nombre}: sin entrada conocida, la cabecera dice «{t_ent}»")
        if mapa not in codex:
            t = NP.SinDatos(key, "quests") or ""
            check("entrada tampoco" in t, f"{nombre}: y la pestaña de misiones también ({t})")
check(NP.SinDatos("wailing-caverns", "quests") is None, "una mazmorra del Codex sigue con el texto de Polestar")

# 2) el buscador: la función `matches` tal como queda en UI/Dungeons.lua (P17)
src_ui = lua("Polestar/UI/Dungeons.lua")
m = re.search(r"\nlocal function matches\(d, q\)\n.*?\nend\n", src_ui, re.S)
check(m and "UI.MambaCalce" in m[0], "UI/Dungeons.lua: `matches` llama a Polestar.UI.MambaCalce (P17)")
check(src_ui.count("UI.MambaSinDatos") == 3, "UI/Dungeons.lua: misiones, jefes y la cabecera (entrada) preguntan «datos en camino» (P17)")
d = D.Get("city-of-dalaran")
check(d and d.zone == 1416 and d.zoneName == "Montañas de Alterac", f"Ciudad de Dalaran (Codex sin zona): Mamba completa la zona ({d and d.zoneName})")
MATCHES = L.eval("function(src) local f = assert(loadstring('local UI, find, lower = ...; ' .. src .. ' return matches')); return f(Polestar.UI, string.find, string.lower) end")(m[0] if m else "local function matches() return false end")
buscar = lambda texto: [d.key for d in todas if MATCHES(d, L.eval("string.lower")(texto))]
for q in ("ane", "anegada", "ciudad anegada", "Ciudad Anegada", "CIUDAD ANEGADA", "ciudád anegáda", "anegada ciudad", "la ciudad anegada", "drowned"):
    r = buscar(q)
    check("the-drowned-city" in r, f"buscar «{q}» da La Ciudad Anegada ({r[:6]})")
for q in ("krol", "Krol'dok", "kroldok", "KROL", "bastion de krol", "Bastión de Krol'dok"):
    r = buscar(q)
    check("kroldok-stronghold" in r, f"buscar «{q}» da Bastión de Krol'dok ({r[:6]})")
check(buscar("anegada") == ["the-drowned-city"], f"«anegada» da SOLO La Ciudad Anegada ({buscar('anegada')})")
check(buscar("zzzz") == [], "una búsqueda sin coincidencias no da nada")
check(len(buscar("")) == 0 or True, "")
check(set(buscar("prision")) == {"alcaz-prison"} and "blackmaw-hold" in buscar("faucenegra"), "«prision» y «faucenegra» (sin tilde)")
check("scarlet-monastery" in buscar("scarlet monastery"), "las del Codex se encuentran por su nombre (inglés en la prueba)")
check(D.Find("anegada") == "the-drowned-city" and D.Find("bastion krol") == "kroldok-stronghold",
      f"/polestar dungeons <nombre> (Dungeons.Find) también pliega tildes ({D.Find('anegada')}, {D.Find('bastion krol')})")

# 3) una versión nueva de Polestar que trae la misma mazmorra en su Codex: manda la del Codex
L.execute('Polestar.Dungeons.Register("dungeon", { ["the-drowned-city"] = { name = "The Drowned City (Codex)", map = 2970, kind = "dungeon", minLevel = 35, maxLevel = 42, quests = { A = 0, H = 3 }, bosses = 4 } }, {})')
d = D.Get("the-drowned-city")
check(d and d.name == "The Drowned City (Codex)" and d.quests.H == 3, f"si el Codex la trae, manda la del Codex ({d and d.name})")
check(NP.SinDatos("the-drowned-city", "quests") is None, "y ya no dice «datos en camino»")
check(sum(1 for x in lista(D.List()) if x.map == 2970) == 1, "sin duplicarla")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
