# Pruebas del motor de «Llévame» (Asistente/Llevame.lua, fila K58) con el planificador REAL de Polestar
# (Nav/Travel.lua + Nav/TravelData.lua, con el parche P8) y los servicios reales de Mamba (Asistente_Servicios).
# Caso: Hope, druida tauren de la Horda, en El Cruce (Los Baldíos), con la piedra de hogar en Cima del Trueno.
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_llevame.py [carpeta addon] [--romper]
# --romper: control negativo (Polestar sin el parche P8 y sin la API: las pruebas de tramos TIENEN que fallar).
import pathlib
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
ADDON = pathlib.Path(args[0] if args else AQUI.parents[2] / "addon").resolve()

L = LuaRuntime(unpack_returned_tuples=True)
G = L.globals()
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


# marcos de zona de TravelData (los mismos que usa Polestar)
datos = (ADDON / "Polestar/Nav/TravelData.lua").read_text(encoding="utf-8")
marcos = {}
for m in re.finditer(r'\[(\d+)\] = \{ name = "[^"]*", c = (\d+), top = ([-\d.]+), bottom = ([-\d.]+), left = ([-\d.]+), right = ([-\d.]+) \}', datos):
    marcos[int(m[1])] = dict(c=int(m[2]), top=float(m[3]), bottom=float(m[4]), left=float(m[5]), right=float(m[6]))
check(1456 in marcos and 1454 in marcos and 1413 in marcos, "TravelData trae los marcos de Cima del Trueno, Orgrimmar y Los Baldíos")
L.execute("MARCOS = {}")
for k, v in marcos.items():
    G.MARCOS[k] = L.table_from(v)

L.execute((AQUI / "mock_polestar_nav.lua").read_text(encoding="utf-8"))
ld = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f(addon, ns) end')
if ROMPER:
    # Polestar sin P8: el texto original de Nav.EstimateTravel (sin tramos) -> el motor no puede dar tramos
    src = (ADDON / "Polestar/Nav/Travel.lua").read_text(encoding="utf-8")
    src = src.replace("return seconds, nil, plan", "return seconds").replace("return hit.seconds, nil, hit.legs", "return hit.seconds")
    ld(src, "Nav/Travel.lua", "Polestar", G.NS_POLESTAR)
else:
    ld((ADDON / "Polestar/Nav/Travel.lua").read_text(encoding="utf-8"), "Nav/Travel.lua", "Polestar", G.NS_POLESTAR)
ld((ADDON / "Polestar/Nav/TravelData.lua").read_text(encoding="utf-8"), "Nav/TravelData.lua", "Polestar", G.NS_POLESTAR)

# la API pública de Polestar (Journey.lua), simulada: registra la flecha y el seguimiento
L.execute("""
Polestar = NS_POLESTAR
NAVEGADO, SEGUIDOR, ACTIVO, RUTA, CI, SALTOS = {}, nil, false, nil, nil, 0
Polestar.Nav.API = { version = 1, minor = 1,
  Navigate = function(owner, map, x, y, title) NAVEGADO[#NAVEGADO + 1] = { owner = owner, map = map, x = x, y = y, title = title }; ACTIVO = owner; return true end,
  Cancel = function(owner) if ACTIVO == owner then ACTIVO = false return true end return false end,
  Active = function() return ACTIVO and true or false, ACTIVO or nil end,
  Follow = function(owner, fn) SEGUIDOR = fn; return true end,
  Unfollow = function(owner) SEGUIDOR = nil; return true end,
  Estimate = function() return 420 end,
}
Polestar.Nav.GetRoute = function() return RUTA, CI end
Polestar.Nav.travel.SkipLeg = function() SALTOS = SALTOS + 1; return true end
-- el juego
FACCION, CLASE = "Horde", "DRUID"
function UnitFactionGroup() return "Horde" end
function UnitClass() return "Druida", "DRUID" end
function InCombatLockdown() return COMBATE == true end
C_AddOns = { IsAddOnLoaded = function() return true end }
C_Map = { GetMapInfo = function(m) return ({ [1454] = { name = "Orgrimmar" }, [1456] = { name = "Cima del Trueno" }, [1458] = { name = "Entrañas" } })[m] end,
  GetMapChildrenInfo = function(cont, tipo, todos)
    if cont == 1414 then return { { mapID = 1456, name = "Cima del Trueno" }, { mapID = 1454, name = "Orgrimmar" }, { mapID = 1413, name = "Los Baldíos" }, { mapID = 1412, name = "Mulgore" } } end
    return { { mapID = 1458, name = "Entrañas" } }
  end }
C_Timer = { After = function() end }
AsistenteDB = { ajustes = {} }
Asistente = { modulos = {} }
MambaAPI = {}
-- Hope: El Cruce, todas las rutas de vuelo de la Horda en Kalimdor aprendidas
CHAR.flags.taxi = {}
for _, n in ipairs(Polestar.Nav.GetTravelData().taxi) do
  if n.c == 1 and (n.faction == 2 or n.faction == 3) and not n.class then CHAR.flags.taxi[n.id] = true end
end
local c, wx, wy = Polestar.Compat.MapToWorld(1413, 52, 30)
JUGADOR = { c = c, wx = wx, wy = wy }
PIEDRA = "Thunder Bluff"
""")
sns = L.table()
for f in ("Ciudades.lua", "Logica.lua"):
    ld((ADDON / "Asistente_Servicios" / f).read_text(encoding="utf-8"), f"Asistente_Servicios/{f}", "Asistente_Servicios", sns)
ld((ADDON / "Asistente/Llevame.lua").read_text(encoding="utf-8"), "Asistente/Llevame.lua", "Asistente", L.table())
LL = G.Asistente.Llevame
check(LL is not None, "Llevame.lua carga y deja Asistente.Llevame")

# 1) R0: el formato del tiempo
check(LL.Tiempo(10, False) == "10 s", "10 s sin ≈ (no estimado)")
check(LL.Tiempo(258, True) == "≈ 4:18", f"≈ 4:18 ({LL.Tiempo(258, True)})")
check(LL.Tiempo(3900, True) == "≈ 1 h 05 min", f"≈ 1 h 05 min ({LL.Tiempo(3900, True)})")

# 2) El planificador real con P8: tramos con su tiempo, de El Cruce al banco de Cima del Trueno
check(LL.ConTramos() is True, "Polestar trae Nav.EstimateTravel (parche P8)")
s = G.Asistente_Servicios
banco_tb = [l for l in lista(G.Asistente_ServiciosDatos.ciudades[1456].lugares) if l.cat == "banco"][0]
dest = L.table_from({"map": 1456, "x": banco_tb.px, "y": banco_tb.py})
res = LL.Rutas(dest, False)
check(res.estado == "ok", f"la ruta al banco de Cima del Trueno se calcula ({res.estado})")
r1 = res.rutas[1] if res.rutas else None
tramos = lista(r1.tramos) if r1 else []
tipos = [t.tipo for t in tramos]
print("  El Cruce -> banco de Cima del Trueno:", LL.Resumen(r1) if r1 else "-", "| total", LL.Tiempo(r1.total, r1.estimado) if r1 else "-")
check(len(tramos) >= 2, f"la ruta va TRAMO POR TRAMO ({tipos})")
check(all(isinstance(t.seg, (int, float)) and t.seg >= 0 for t in tramos), "cada tramo trae su tiempo")
check(r1 is not None and abs(sum(t.seg for t in tramos) - r1.total) < 0.01, "el total es la suma de los tramos")
check("hearth" in tipos, f"con la piedra en Cima del Trueno, la más rápida usa la piedra de hogar ({tipos})")
check(any(t.tipo == "hearth" and not t.estimado for t in tramos), "la piedra (sin espera) no lleva ≈: son 10 s + la carga")
check(r1 is not None and r1.estimado, "la ruta completa es estimada (≈) mientras haya un tramo estimado")
# las alternativas: sin piedra de hogar y sin pagar vuelos
claves = [r.clave for r in lista(res.rutas)]
check("sinPiedra" in claves, f"alternativa «Sin piedra de hogar» ({claves})")
alt = {r.clave: r for r in lista(res.rutas)}
if "sinPiedra" in alt:
    print("  sin piedra:", LL.Resumen(alt["sinPiedra"]), "|", alt["sinPiedra"].nota)
    check("hearth" not in [t.tipo for t in lista(alt["sinPiedra"].tramos)], "la alternativa sin piedra no la usa")
    check(alt["sinPiedra"].total >= r1.total, "la más rápida es la más rápida")
    check("más" in (alt["sinPiedra"].nota or ""), "la alternativa dice cuánto más tarda (R0)")
    if "fly" in [t.tipo for t in lista(alt["sinPiedra"].tramos)]:
        check("sinVuelos" in claves, "si la alternativa vuela, hay otra «Sin pagar vuelos»")
if "sinVuelos" in alt:
    check("fly" not in [t.tipo for t in lista(alt["sinVuelos"].tramos)], "la de sin vuelos no vuela")
check(2 <= len(claves) <= 3, f"2 o 3 alternativas ({len(claves)})")

# 3) La piedra en espera: el planificador la pesa con su espera y la alternativa lo dice
L.execute("PIEDRA_ESPERA = 3000; RELOJ = 2000")
LL.OlvidarCache()
res2 = LL.Rutas(dest, False)
t2 = [t.tipo for t in lista(res2.rutas[1].tramos)] if res2.rutas else []
check("hearth" not in t2 or any(t.espera for t in lista(res2.rutas[1].tramos)), f"con 50 min de espera la piedra no se usa o muestra su espera ({t2})")
L.execute("PIEDRA_ESPERA = nil; RELOJ = 3000")
LL.OlvidarCache()

# 4) El servicio más cercano EN TIEMPO (no en distancia): el banco desde El Cruce
mejor = LL.MasCercano("banco", None, False)
check(mejor is not None, "encuentra un banco")
cands = lista(LL.Candidatos("banco", None))
check(len(cands) >= 3, f"candidatos de banco en las 3 capitales ({len(cands)})")
tiempos = []
for c in cands:
    r = LL.Rutas(c, False)
    if r.rutas and r.rutas[1]:
        tiempos.append((r.rutas[1].total, c.sub))
tiempos.sort()
if mejor is not None and tiempos:
    print("  banco más cercano en tiempo:", mejor.sub, LL.Tiempo(mejor.rutas.rutas[1].total, True), "| todos:", [(s_, round(t)) for t, s_ in tiempos[:4]])
    check(abs(mejor.rutas.rutas[1].total - tiempos[0][0]) < 0.5, "elige el de MENOR TIEMPO entre todos los candidatos")
if mejor is not None:
    check(len(lista(mejor.rutas.rutas)) >= 2, "el ganador trae sus alternativas (las demás solo se miden con la más rápida)")
# el maestro de vuelo más cercano: también fuera de las capitales (los de Polestar)
vuelos = lista(LL.Candidatos("vuelo", None))
check(len(vuelos) > 10 and any(v.map == 1413 for v in vuelos), f"maestros de vuelo de todo el mundo, El Cruce incluido ({len(vuelos)})")
mv = LL.MasCercano("vuelo", None, False)
check(mv is not None and mv.map == 1413, f"el maestro de vuelo más cercano a El Cruce es el de El Cruce ({mv and mv.map})")
posadas = lista(LL.Candidatos("posada", None))
check(len(posadas) > 5, f"posadas de todo el mundo ({len(posadas)})")

# 5) Buscar: servicio, ciudad, mazmorra; "Cima del Trueno" primero en ciudades
b = lista(LL.Buscar("banco"))
check(b and b[0].tipo == "servicio" and b[0].cat == "banco", "«banco» -> Banco más cercano")
b = lista(LL.Buscar("cima del trueno"))
check(b and b[0].tipo == "ciudad" and b[0].map == 1456, f"«cima del trueno» -> la ciudad ({b and b[0].nombre})")
b = lista(LL.Buscar("instructor de druida"))
check(b and b[0].cat == "clase", "«instructor de druida» -> instructor de tu clase")
b = lista(LL.Buscar("alquimia"))
check(b and b[0].cat == "profesion" and b[0].det == "alquimia", "«alquimia» -> instructor de alquimia más cercano")
b = lista(LL.Buscar("zzzz qqq"))
check(len(b) == 0, "sin resultados para basura")

# 6) Llévame: pone la flecha (dueño Mamba), sigue el viaje y deja los tramos para el panel de la guía
G.NAVEGADO = L.table()
oidos = []
L.execute("OIDOS = 0; Asistente.Llevame.AlCambiar(function() OIDOS = OIDOS + 1 end)")
okk, info = LL.Llevame("banco")
check(okk is True, f"Llevame('banco') pone la flecha ({info})")
nav = lista(G.NAVEGADO)
check(len(nav) == 1 and nav[0].owner == "Mamba", "la flecha es de Mamba (Polestar.Nav.API.Navigate)")
check(nav and 0 <= nav[0].x <= 1 and 0 <= nav[0].y <= 1, "el punto va en 0-1, como lo pide la API")
check(nav and "Banco" in (nav[0].title or ""), f"el título dice adónde ({nav and nav[0].title})")
act = LL.Actual()
check(act is not None and len(lista(act.tramos)) >= 1, "RutaActual() tiene los tramos")
check(G.OIDOS >= 1, "AlCambiar avisa (el panel de la guía se entera)")
# Polestar avanza de tramo: lo que tardó de verdad queda medido
legs = lista(info.punto.rutas.rutas[1].tramos)
L.execute("RUTA = { { kind = 'walk', seconds = 60, label = 'Camina' }, { kind = 'fly', seconds = 200, label = 'Vuela a X' } }; CI = 1; RELOJ = 4000")
G.SEGUIDOR()
L.execute("CI = 2; RELOJ = 4066")
G.SEGUIDOR()
check(G.AsistenteDB.viajes and G.AsistenteDB.viajes.walk and G.AsistenteDB.viajes.walk.n == 1, "terminar un tramo guarda lo que tardó de verdad (walk: 66 s vs 60)")
check(len(lista(LL.Actual().tramos)) == 1, "RutaActual() deja solo lo que falta")
L.execute("ACTIVO = false")
G.SEGUIDOR()
check(LL.Actual() is None, "al llegar (o soltar la flecha) el viaje termina")

# 7) R0 corregido: 3 caminatas medidas 20 % más lentas -> las caminatas se estiman 20 % más largas
G.AsistenteDB.viajes = L.table()
for _ in range(3):
    LL.Medir("walk", 100, 120)
check(abs((LL.Factor("walk") or 0) - 1.2) < 0.001, f"factor de caminata 1.2 ({LL.Factor('walk')})")
LL.OlvidarCache()
tr = lista(LL.Tramos(L.table_from([L.table_from({"kind": "walk", "seconds": 100, "label": "Camina", "yards": 300})])))
check(abs(tr[0].seg - 120) < 0.01 and tr[0].ajustado, "la caminata sale corregida con tus viajes")
check(not LL.Medir("walk", 100, 900), "un tramo absurdo (te paraste) no se cuenta")
# un vuelo que ya hiciste: medido, sin ≈
G.CHAR.flightTimes["10>22"] = 133
tv = lista(LL.Tramos(L.table_from([L.table_from({"kind": "fly", "seconds": 150, "label": "Vuela", "stops": L.table_from([L.table_from({"id": 10}), L.table_from({"id": 22})])})])))
check(tv[0].seg == 133 and tv[0].medido and not tv[0].estimado, "un vuelo ya hecho usa su tiempo medido, sin ≈")

# 8) La alternativa elegida se cumple: «sin piedra» salta la piedra si Polestar la propone
L.execute("ACTIVO = false; SALTOS = 0")
okk, info = LL.Llevame(L.table_from({"map": 1456, "x": banco_tb.px / 100, "y": banco_tb.py / 100, "nombre": "Banco"}), L.table_from({"ruta": "sinPiedra"}))
check(okk and info.ruta.clave == "sinPiedra", "Llevame con { ruta = 'sinPiedra' }")
L.execute("RUTA = { { kind = 'hearth', seconds = 15 }, { kind = 'walk', seconds = 30 } }; CI = 1")
G.SEGUIDOR()
check(G.SALTOS == 1, "si Polestar propone la piedra, se salta (Nav.travel.SkipLeg)")
L.execute("ACTIVO = false"); G.SEGUIDOR()

# 9) Ciudad, en combate, punto libre
L.execute("ACTIVO = false")
okk, info = LL.Llevame("Cima del Trueno")
check(okk and info.destino.tipo == "ciudad", "Llevame('Cima del Trueno') va a la ciudad")
L.execute("ACTIVO = false; COMBATE = true")
okk, motivo = LL.Llevame("banco")
check(not okk and motivo == "combate", "en combate no pone la flecha y dice por qué")
L.execute("COMBATE = false")
okk, motivo = LL.Llevame("zzzz qqq")
check(not okk and motivo == "no_encontrado", "un lugar que no existe: no_encontrado")

# 10) PNJ por su nombre (el buscador de Polestar) a su aparición más cercana
L.execute("""
Polestar.Search = { Query = function(t, o) if t:lower():find('karus') then return { { kind = 'npc', id = 3309, title = 'Karus' } } end return {} end }
Polestar.Codex = { IsLoaded = function() return true end, Npc = function(id) return { name = 'Karus', spawns = { { map = 1454, x = 49.58, y = 69.1 } } } end }
ACTIVO = false
""")
b = lista(LL.Buscar("Karus"))
check(b and b[0].tipo == "pnj", "un PNJ se busca por su nombre")
okk, info = LL.Llevame("Karus")
check(okk and info.punto.map == 1454, "Llevame('Karus') va a su aparición")

# 11) MambaAPI para las demás secciones
api = G.MambaAPI
check(api.Llevame and api.RutasA and api.RutaActual and api.AlCambiarRuta, "MambaAPI.Llevame / RutasA / RutaActual / AlCambiarRuta")
ra = api.RutasA("banco")
check(ra.estado == "ok" and ra.rutas[1] is not None and ra.punto is not None, f"MambaAPI.RutasA('banco') da rutas sin poner la flecha ({ra.estado})")
check(api.TiempoTexto(258, True) == "≈ 4:18", "MambaAPI.TiempoTexto (R0)")

print(f"{ok} OK, {fail} fallas" + (" (control negativo)" if ROMPER else ""))
sys.exit(1 if fail else 0)
