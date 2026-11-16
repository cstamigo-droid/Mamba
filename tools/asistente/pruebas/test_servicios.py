"""Pruebas del núcleo Asistente y del buscador de servicios, con Lua 5.1 (lupa).

Uso:  python -I test_servicios.py <carpeta addon> <carpeta polestar descargada>
      python -I test_servicios.py ..  ../../generador/_descargas/polestar
Revisa los datos de Orgrimmar y Cima del Trueno contra forever-db, la búsqueda en español,
la carga del módulo al entrar a la ciudad, la flecha (recta y a pie con Polestar simulado),
el minimapa y el mapa del mundo.
"""
import json
import math
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
BASE = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent
FDB = (pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else AQUI.parent.parent / "generador" / "_descargas" / "polestar") / "forever-db"

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def archivos(carpeta, toc):
    t = (BASE / carpeta / toc).read_text(encoding="utf-8")
    return t, [l.strip() for l in t.splitlines() if l.strip().endswith(".lua")]


# ---------------------------------------------------------------- 1. los .toc
t_nuc, F_NUC = archivos("Asistente", "Asistente.toc")
t_ser, F_SER = archivos("Asistente_Servicios", "Asistente_Servicios.toc")
check("## Interface: 16001" in t_nuc and "## SavedVariables: AsistenteDB" in t_nuc, "toc del núcleo")
check("## Group: Asistente" in t_nuc and "## Group: Asistente" in t_ser, "un solo grupo en la lista de addons")
check("## LoadOnDemand: 1" in t_ser and "## Dependencies: Asistente" in t_ser, "servicios se carga cuando hace falta")
check("## LoadOnDemand" not in t_nuc, "el núcleo se carga siempre")
check("## X-License: GPL-3.0-only" in t_nuc and "## X-License: GPL-3.0-only" in t_ser, "licencia en los toc")
check(F_SER[0] == "Ciudades.lua", "los datos se cargan primero")
for c in ("Asistente", "Asistente_Servicios"):
    check((BASE / c / "LICENSE").read_text(encoding="utf-8").lstrip().startswith("GNU GENERAL PUBLIC LICENSE"), f"LICENSE en {c}")
check("pfQuest" in (BASE / "Asistente_Servicios" / "NOTICE-forever-db.md").read_text(encoding="utf-8"), "aviso MIT de pfQuest junto a los datos")


# ---------------------------------------------------------------- juego simulado
def nuevo(cargar_modulo=True):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_servicios.lua").read_text(encoding="utf-8"))
    cargar = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f(addon, ns) end')
    ns_nuc = L.table()
    for n in F_NUC:
        cargar((BASE / "Asistente" / n).read_text(encoding="utf-8"), n, "Asistente", ns_nuc)
    ns_ser = L.table()

    def modulo():
        for n in F_SER:
            cargar((BASE / "Asistente_Servicios" / n).read_text(encoding="utf-8"), n, "Asistente_Servicios", ns_ser)
    L.globals().CARGAR_MODULO = modulo
    L.execute('Fire("ADDON_LOADED", "Asistente")')
    if cargar_modulo:
        L.execute('C_AddOns.LoadAddOn("Asistente_Servicios")')
    return L


def chat(L):
    return [str(x) for x in L.globals().chat.values()]


# ---------------------------------------------------------------- 2. datos contra forever-db
L = nuevo()
G = L.globals()
S = G.Asistente_Servicios
check(S is not None and S.datos is not None, "módulo cargado")

um = {}
for l in open(FDB / "data" / "ui_map.jsonl", encoding="utf-8"):
    r = json.loads(l)
    um[r["ui_map"]] = r
spawns = {}
for l in open(FDB / "data" / "spawn.jsonl", encoding="utf-8"):
    r = json.loads(l)
    spawns.setdefault((r["kind"], r["id"]), []).append(r)
npcs = {}
for l in open(FDB / "data" / "npc.jsonl", encoding="utf-8"):
    r = json.loads(l)
    npcs[r["id"]] = r


def lugares(uimap):
    c = S.datos.ciudades[uimap]
    return [dict(l.items()) for l in c.lugares.values()]


NECESARIAS = ["banco", "subasta", "buzon", "posada", "vuelo", "establo", "reparar", "clase", "profesion", "vendedor"]
for uimap, nombre in ((1454, "Orgrimmar"), (1456, "Cima del Trueno")):
    ls = lugares(uimap)
    cats = {l["cat"] for l in ls}
    for c in NECESARIAS:
        check(c in cats, f"{nombre}: tiene {c}")
    m = um[uimap]
    malos = 0
    for l in ls:
        # cada punto cae dentro del mapa de la ciudad y el % coincide con el marco de forever-db
        px = (l["y"] - m["left"]) / (m["right"] - m["left"]) * 100
        py = (l["x"] - m["top"]) / (m["bottom"] - m["top"]) * 100
        if not (abs(px - l["px"]) < 0.05 and abs(py - l["py"]) < 0.05 and 0 <= px <= 100 and 0 <= py <= 100):
            malos += 1
        if l["id"] > 0:
            # el PNJ existe y tiene una aparición real a menos de 15 yardas del punto
            cerca = [s for s in spawns.get(("npc", l["id"]), []) if s["map"] == m["map"]
                     and math.hypot(s["x"] - l["x"], s["y"] - l["y"]) <= 15]
            if not cerca or npcs[l["id"]]["name"] != l["nombre"]:
                malos += 1
    check(malos == 0, f"{nombre}: {malos} lugares no coinciden con forever-db")


def buscar(ls, **kw):
    return [l for l in ls if all(l.get(k) == v for k, v in kw.items())]


org, tb = lugares(1454), lugares(1456)
banco = buscar(org, cat="banco", nombre="Karus")
check(len(banco) == 1 and abs(banco[0]["px"] - 49.6) < 0.5 and abs(banco[0]["py"] - 69.1) < 0.5, "Orgrimmar: Karus, banquero en 49,69")
check(len(buscar(org, cat="posada", nombre="Innkeeper Gryshka")) == 1, "Orgrimmar: posadera Gryshka")
check(len(buscar(org, cat="vuelo", nombre="Doras")) == 1, "Orgrimmar: Doras, maestro de vuelo")
check(len(buscar(org, cat="subasta")) == 3, "Orgrimmar: 3 subastadores")
check(len(buscar(org, cat="clase", det="DRUID")) == 0, "Orgrimmar no tiene instructor de druida (es así en el juego)")
druidas = buscar(tb, cat="clase", det="DRUID")
check(len(druidas) == 3 and all(d["px"] > 75 for d in druidas), "Cima del Trueno: 3 instructores de druida en el Alto de los Ancianos")
check(len(buscar(tb, cat="profesion", det="cocina", nombre="Aska Mistrunner")) == 1, "Cima del Trueno: instructora de cocina")
check(len(buscar(tb, cat="profesion", det="primeros_auxilios")) == 1, "Cima del Trueno: instructor de primeros auxilios")
check(all(l["conf"] == "titulo" for l in org if l["cat"] == "reparar"), "reparar siempre marcado como 'sin verificar'")
check(all(l["conf"] == "fdb" for l in org if l["cat"] != "reparar"), "lo demás, dato de forever-db")
check(not any(l["nombre"] == "Test Auctioneer" for l in org + tb), "sin PNJ de prueba")

# ---------------------------------------------------------------- 3. búsqueda en español
def grupos(uimap, x=None, y=None):
    g = S.Grupos(uimap, "DRUID", x, y)
    g = g[0] if isinstance(g, tuple) else g
    return list(g.values())


def etiquetas(gs):
    return [str(g.etiqueta) for g in gs]


GO = grupos(1454)
GT = grupos(1456)
check(etiquetas(GO)[0] == "Banco", "la lista empieza por el banco")
r = etiquetas(list(S.Buscar(L.table_from(GO), "alquimia").values()))
check(r == ["Instructor de Alquimia"], f"'alquimia' -> {r}")
r = etiquetas(list(S.Buscar(L.table_from(GO), "instructor de alquimia").values()))
check(r == ["Instructor de Alquimia"], f"'instructor de alquimia' -> {r}")
check(etiquetas(list(S.Buscar(L.table_from(GO), "BANCO").values())) == ["Banco"], "mayúsculas")
check(etiquetas(list(S.Buscar(L.table_from(GO), "buzón").values())) == ["Buzón"], "con tilde")
check(etiquetas(list(S.Buscar(L.table_from(GO), "buzon").values())) == ["Buzón"], "sin tilde")
check("Reparar" in etiquetas(list(S.Buscar(L.table_from(GO), "reparar").values())), "reparar")
check(etiquetas(list(S.Buscar(L.table_from(GO), "vuelo").values())) == ["Maestro de vuelo"], "vuelo")
check(len(list(S.Buscar(L.table_from(GO), "xyzzy").values())) == 0, "nada con texto raro")
check(etiquetas(list(S.Buscar(L.table_from(GT), "druida").values())) == ["Instructor de druida"], "Cima: druida")
check(len(list(S.Buscar(L.table_from(GO), "instructor").values())) > 10, "'instructor' a secas muestra todos los instructores")
tuya = [g for g in GT if g.cat == "clase" and g.tuya]
otras = [g for g in GT if g.cat == "clase" and not g.tuya]
check(len(tuya) == 1 and etiquetas(GT).index("Instructor de druida") < etiquetas(GT).index(str(otras[0].etiqueta)), "tu clase va antes que las otras")
check(list(S.CiudadConClase("DRUID").values()) == ["Cima del Trueno"], "druida: está en Cima del Trueno")

# el más cercano: parado junto al buzón de 49,71 en Orgrimmar
buz = min(buscar(org, cat="buzon"), key=lambda l: abs(l["px"] - 49.34) + abs(l["py"] - 71.43))
gb = [g for g in grupos(1454, buz["x"] + 3, buz["y"]) if g.cat == "buzon"][0]
check(abs(gb.mejor.x - buz["x"]) < 0.01 and gb.mejor.dist < 4, "elige el buzón más cercano")

# ---------------------------------------------------------------- 4. entrar a la ciudad carga el módulo
L2 = nuevo(cargar_modulo=False)
G2 = L2.globals()
G2.MAPA = 1454
L2.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(G2.CARGADOS["Asistente_Servicios"], "entrar a Orgrimmar carga el módulo")
v = G2.AsistenteServiciosVentana
check(v is not None and v.visible and str(v.titulo.text) == "Servicios de Orgrimmar", "abre 'Servicios de Orgrimmar'")
n = len(list(G2.CARGAS.values()))
L2.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(len(list(G2.CARGAS.values())) == n, "otra vez la misma ciudad: no recarga")
fila1 = v.filas[1]
check(fila1.visible and "Banco" in str(fila1.texto.text), "primera fila: Banco")
G2.MAPA = 1411
L2.execute('Fire("ZONE_CHANGED_NEW_AREA")')
v.visible = False
G2.MAPA = 1454
L2.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(v.visible, "salir y volver a entrar la abre de nuevo")

# en combate no se carga; al salir del combate, sí
L3 = nuevo(cargar_modulo=False)
G3 = L3.globals()
G3.COMBATE = True
G3.MAPA = 1456
L3.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(not G3.CARGADOS["Asistente_Servicios"], "en combate no carga módulos")
G3.COMBATE = False
L3.execute('Fire("PLAYER_REGEN_ENABLED")')
check(G3.CARGADOS["Asistente_Servicios"], "al salir del combate lo carga")
check(str(G3.AsistenteServiciosVentana.titulo.text) == "Servicios de Cima del Trueno", "y abre la lista de Cima del Trueno")

# apagar la apertura automática
L4 = nuevo(cargar_modulo=False)
G4 = L4.globals()
G4.MAPA = 1411
L4.execute('Slash("/servicios", "auto no")')
check(G4.AsistenteDB.ajustes.servicios.abrirAlEntrar is False, "/servicios auto no se guarda")
G4.MAPA = 1454
L4.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(G4.AsistenteServiciosVentana is None or not G4.AsistenteServiciosVentana.visible, "con auto no, no abre sola")

# ---------------------------------------------------------------- 5. flecha en línea recta (sin Polestar)
G.MAPA = 1454
gbanco = [g for g in grupos(1454) if g.cat == "banco"][0]
dest = gbanco.lugares[1]
G.POS.x, G.POS.y, G.POS.mapa = dest.x - 100, dest.y, 1  # 100 yardas al sur del banco
G.FACING = 0                                               # mirando al norte
L.execute('Asistente_Servicios.ciudadActual = 1454')
S.Elegir(gbanco)
F = S.flecha
check(F.destino is not None and F.modo == "recta", "sin Polestar: línea recta")
a, total, modo = S.Paso()
check(abs(a) < 0.05 and abs(total - 100) < 1, f"mirando al norte, el banco está adelante: {a}, {total}")
G.FACING = math.pi / 2                                     # mirando al oeste
a, _, _ = S.Paso()
check(abs(a + math.pi / 2) < 0.05, f"mirando al oeste, el banco está a la derecha: {a}")
check(any("Banco" in c and "Sigue la flecha" in c for c in chat(L)), "dice a dónde ir")
G.POS_SECRETA = True
r = S.Paso()
check((r[0] if isinstance(r, tuple) else r) is None, "posición secreta: no apunta, no se cae")
G.POS_SECRETA = False
G.POS.x, G.POS.y = dest.x - 2, dest.y
S.Paso()
check(F.destino is None and any("Llegaste" in c for c in chat(L)), "a menos de 5 yardas: Llegaste")

# ---------------------------------------------------------------- 6. el motor INTERNO de Polestar no se usa (revisor v3, A5)
motor = G.NuevoMotor()
G.Polestar_NavEngine = motor
G.MOTOR_AL_CARGAR = motor
G.CARGADOS.Polestar = True
G.CARGABLES.Polestar_Nav = True
G.POS.x, G.POS.y = dest.x - 100, dest.y
G.FACING = 0
G.NOW = 10
S.Elegir(gbanco)
check("Polestar_Nav" not in list(G.CARGAS.values()), "no fuerza la carga de Polestar_Nav (respeta la opción del jugador)")
check(len(list(motor.pedidos.values())) == 0 and F.modo == "recta", "respaldo: solo línea recta, sin Polestar_NavEngine")
S.Detener(False)
G.Polestar_NavEngine = None
# Avanzar por un camino (función pura que queda para un camino futuro)
cam = L.table_from([L.table_from({"x": 0, "y": 0}), L.table_from({"x": 50, "y": 50}), L.table_from({"x": 100, "y": 0})])
check(S.Avanzar(cam, 1, 1, 1) == 2 and S.Avanzar(cam, 1, 49, 48) == 3, "Avanzar salta los puntos alcanzados")

# en combate no se pide ruta ni se carga Polestar Nav
L5 = nuevo()
G5 = L5.globals()
G5.CARGADOS.Polestar = True
G5.CARGABLES.Polestar_Nav = True
G5.MOTOR_AL_CARGAR = G5.NuevoMotor()
G5.COMBATE = True
L5.execute('Asistente_Servicios.ciudadActual = 1454')
S5 = G5.Asistente_Servicios
gb5 = [g for g in S5.Grupos(1454, "DRUID", None, None)[0].values() if g.cat == "banco"][0]
S5.Elegir(gb5)
check("Polestar_Nav" not in list(G5.CARGAS.values()) and S5.flecha.modo == "recta", "en combate: solo línea recta, sin cargar nada")

# ---------------------------------------------------------------- 7. minimapa y mapa del mundo
dx, dy, borde = S.PuntoMinimapa(0, 0, 100, 0, 233.3, 140, False, 0)
check(abs(dx) < 0.01 and abs(dy - 100 * 70 / 233.3) < 0.01 and not borde, f"100 yardas al norte: arriba ({dx},{dy})")
dx, dy, borde = S.PuntoMinimapa(0, 0, 0, 100, 233.3, 140, False, 0)
check(dx < -29 and abs(dy) < 0.01, "al oeste: a la izquierda")
dx, dy, borde = S.PuntoMinimapa(0, 0, 0, 100, 233.3, 140, True, math.pi / 2)
check(abs(dx) < 0.01 and dy > 29, "minimapa que gira, mirando al oeste: el oeste queda arriba")
dx, dy, borde = S.PuntoMinimapa(0, 0, 1000, 0, 233.3, 140, False, 0)
check(borde and abs(math.hypot(dx, dy) - 64) < 0.01, "lejos: pegado al borde")
check(S.RadioMinimapa(0, False, None) == 233.3 and S.RadioMinimapa(2, True, None) == 90 and S.RadioMinimapa(0, False, 300) == 300, "radio del minimapa")

G.POS.x, G.POS.y = dest.x - 100, dest.y
G.CARGADOS.Polestar = False
G.Polestar_NavEngine = None
S.Elegir(gbanco)
mundo, mini, vigia = S._Pines()
G.WORLDMAP_ID = 1454
vigia.scripts.OnUpdate(vigia, 1)
check(mundo.visible, "marca visible en el mapa de Orgrimmar")
pt = list(mundo.point.values())
check(abs(pt[3] - 1000 * dest.px / 100) < 0.01 and abs(pt[4] + 667 * dest.py / 100) < 0.01, f"marca en el % del banco: {pt[3:]}")
check(str(mundo.tex.texture).endswith("Banker"), "icono del banco del juego")
G.WORLDMAP_ID = 1456
vigia.scripts.OnUpdate(vigia, 1)
check(not mundo.visible, "en otro mapa no se ve")
S.ActualizarMinimapa()
pm = list(mini.point.values())
check(mini.visible and abs(pm[3]) < 0.5 and pm[4] > 20, f"minimapa: el banco arriba ({pm[3]},{pm[4]})")
L.execute('Slash("/servicios", "parar")')
check(F.destino is None and not mini.visible, "/servicios parar quita flecha y marcas")

# ---------------------------------------------------------------- 8. comandos
G.MAPA = 1454
L.execute('Slash("/servicios", "banco")')
check(F.destino is not None and str(F.destino.etiqueta) == "Banco", "/servicios banco: un resultado, va directo")
S.Detener(False)
L.execute('chat = {}')
L.execute('Slash("/servicios", "druida")')
check(F.destino is None and any("Cima del Trueno" in c for c in chat(L)), "/servicios druida en Orgrimmar: dice que está en Cima del Trueno")
G.MAPA = 1411
L.execute('chat = {}')
L.execute('Slash("/servicios", "")')
check(any("no hay lista" in c for c in chat(L)), "fuera de una ciudad lo dice")
L.execute('chat = {}')
L.execute('Slash("/asis", "creditos")')
check(any("forever-db" in c for c in chat(L)) and any("Cillian Berragan" in c for c in chat(L)), "/asis creditos")

# ---------------------------------------------------------------- 9. hallazgos del revisor externo
# A1: ningún marco se crea con padre (la interfaz de mando intercepta CreateFrame con padre en el mapa)
con_padre = [c for c in G.CREADOS.values() if c.padre is not None]
check(len(con_padre) == 0, f"A1: {len(con_padre)} marcos creados con padre (deben colgarse con SetParent)")
check(mundo.parent is not None and mini.parent is not None, "A1: los pines quedan colgados del mapa y del minimapa")
# A1: el pin del mapa no crece con el zoom
G.WorldMapFrame.GetCanvasScale = L.eval("function() return 2 end")
G.WORLDMAP_ID = 1454
L.execute('Asistente_Servicios.ciudadActual = 1454')
S.Elegir(gbanco)
vigia.scripts.OnUpdate(vigia, 1)
check(mundo.w == 14, f"A1: con zoom x2 el pin mide la mitad en el lienzo ({mundo.w})")
S.Detener(False)
# B2: un solo título (el de la plantilla)
check(str(G.AsistenteServiciosVentana.TitleText.text).startswith("Servicios de"), "B2: usa el título de la plantilla")
# B6: entró en combate a la ciudad y al salir del combate ya no está ahí: no abre
L6 = nuevo(cargar_modulo=False)
G6 = L6.globals()
G6.COMBATE = True
G6.MAPA = 1454
L6.execute('Fire("ZONE_CHANGED_NEW_AREA")')
G6.MAPA = 1411
G6.COMBATE = False
L6.execute('Fire("PLAYER_REGEN_ENABLED")')
check(G6.AsistenteServiciosVentana is None or not G6.AsistenteServiciosVentana.visible, "B6: ya saliste de la ciudad: no abre")
# M8: con interfaz de mando la ventana no entra a UISpecialFrames
L7 = nuevo(cargar_modulo=False)
G7 = L7.globals()
L7.execute('Enum = { InputDeviceInterfaceType = { Gamepad = 1 } }; C_InputInterfaceStyle = { GetCurrentStyle = function() return 1 end }')
G7.MAPA = 1454
L7.execute('Fire("ZONE_CHANGED_NEW_AREA")')
check(len(list(G7.UISpecialFrames.values())) == 0, "M8: con mando no se agrega a UISpecialFrames")
check(len(list(G2.UISpecialFrames.values())) == 1, "M8: con teclado sí (Escape la cierra)")

# ---------------------------------------------------------------- 10. Polestar como base: su flecha hace el viaje
L8 = nuevo()
G8 = L8.globals()
L8.execute('''LLAMADAS = {}
Polestar = { Nav = { API = { version = 1,
	Navigate = function(owner, map, x, y, title) table.insert(LLAMADAS, {"Navigate", owner, map, x, y, title}); return true end,
	Cancel = function(owner) table.insert(LLAMADAS, {"Cancel", owner}); return true end } } }''')
L8.execute('Asistente_Servicios.ciudadActual = 1456')
S8 = G8.Asistente_Servicios
gd = [g for g in S8.Grupos(1456, "DRUID", None, None)[0].values() if g.cat == "clase" and g.det == "DRUID"][0]
S8.Elegir(gd)
ll = list(G8.LLAMADAS.values())
check(len(ll) == 1 and ll[0][1] == "Navigate" and ll[0][2] == "Asistente" and ll[0][3] == 1456, "con Polestar: su flecha (Nav.API.Navigate) con el mapa de la ciudad")
check(abs(ll[0][4] - gd.mejor.px / 100) < 1e-9 and abs(ll[0][5] - gd.mejor.py / 100) < 1e-9 and 0 < ll[0][4] < 1, "coordenadas como fracción 0-1")
check("Instructor de druida" in str(ll[0][6]), "título en español")
check(S8.flecha.modo == "polestar" and (G8.AsistenteServiciosFlecha is None or not G8.AsistenteServiciosFlecha.visible), "nuestra flecha no aparece: nunca dos flechas")
check(not any(p.visible for p in S8._Pines()[:2] if p is not None), "nuestras marcas tampoco")
S8.Detener(False)
ll = list(G8.LLAMADAS.values())
check(ll[-1][1] == "Cancel" and ll[-1][2] == "Asistente", "quitar: le avisa a Polestar (Cancel)")
L8.execute('Polestar.Nav.API.version = 2')
S8.Elegir(gd)
check(S8.flecha.modo == "recta" and len(list(G8.LLAMADAS.values())) == 2, "API de otra versión: no se usa, flecha propia de respaldo")
S8.Detener(False)
L8.execute('Polestar.Nav.API.version = 1; Polestar.Nav.API.Navigate = function() return false end')
S8.Elegir(gd)
check(S8.flecha.modo == "recta", "si Polestar rechaza el destino: flecha propia")
S8.Detener(False)
# revisor v3, M1: destino con Polestar y después uno que Polestar rechaza: se cancela el de Polestar primero
L8.execute('Polestar.Nav.API.Navigate = function(owner, map, x, y, title) table.insert(LLAMADAS, {"Navigate", owner}); return NAV_OK end; NAV_OK = true')
S8.Elegir(gd)
L8.execute('NAV_OK = false')
n_antes = len(list(G8.LLAMADAS.values()))
S8.Elegir(gd)
ll = list(G8.LLAMADAS.values())[n_antes:]
check(ll and ll[0][1] == "Cancel", "M1: antes del destino nuevo se le quita el viejo a Polestar (nunca dos flechas)")
S8.Detener(False)
# revisor v3, M3: Polestar presente con otra versión: avisa una vez
L8.execute('chat = {}; Polestar.Nav.API.version = 3; Asistente_Servicios.avisoApi = nil')
S8.Elegir(gd); S8.Detener(False); S8.Elegir(gd)
check(sum(1 for c in chat(L8) if "cambió su API" in c) == 1, "M3: avisa (una sola vez) que Polestar cambió su API")

print(f"OK {ok} · FALLAS {fail}")
sys.exit(1 if fail else 0)
