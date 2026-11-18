"""Pruebas de Mamba_Mapa con Lua 5.1 (lupa). Uso: python test_mapa.py [--romper]

Simulación: la de mock_barras.lua (eventos desconocidos, combate) más el mapa del mundo, el minimapa y las
posiciones. --romper apaga el 2-opt de la ruta: la prueba de la ruta corta tiene que fallar.
"""
import sys, pathlib, math, random
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = AQUI.parent.parent.parent / "addon" / "Mamba_Mapa"
ROMPER = "--romper" in sys.argv
toc = (D / "Mamba_Mapa.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
ok = fail = 0


def check(c, m):
    global ok, fail
    if c:
        ok += 1
    else:
        fail += 1
        print("FALLA:", m)


MOCK = r'''
function UnitLevel() return 39 end
function UnitRace() return "Tauren", "Tauren" end
PROFS = { { "Herboristería", 212, 225 } }
function GetProfessions() return 1 end
function GetProfessionInfo(i) local p = PROFS[i]; if p then return p[1], 0, p[2], p[3] end end
function CreateVector2D(x, y) return { GetXY = function() return x, y end } end
-- mapa de 1000 x 1000 yd: x% -> oeste-este, y% -> norte-sur. Mundo: X = norte, Y = oeste.
POS = { 0.5, 0.5 }
C_Map = {
  GetMapInfo = function(id) return { name = "Zona " .. id } end,
  GetBestMapForUnit = function() return 1411 end,
  GetWorldPosFromMapPos = function(m, v) local x, y = v:GetXY(); return 1, CreateVector2D(1000 - y * 1000, 1000 - x * 1000) end,
  GetPlayerMapPosition = function() return CreateVector2D(POS[1], POS[2]) end,
}
function UnitPosition() return 1000 - POS[2] * 1000, 1000 - POS[1] * 1000, 0, 1 end
function GetCVar(k) return CVARS and CVARS[k] end
function GetPlayerFacing() return 0 end
function IsIndoors() return false end
function hooksecurefunc() end
function ShowUIPanel(f) f:Show() end
local mt = getmetatable(CreateFrame("Frame")).__index
mt.CreateLine = function(self) LINEAS = (LINEAS or 0) + 1; return setmetatable({}, { __index = function() return function() end end }) end
mt.GetChildren = function(self) return unpack(self.hijos or {}) end
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame.ScrollContainer = CreateFrame("Frame")
WorldMapFrame.ScrollContainer.Child = CreateFrame("Frame")
WorldMapFrame.ScrollContainer.Child:SetSize(1000, 667)
WorldMapFrame.GetMapID = function() return 1411 end
WorldMapFrame.SetMapID = function() end
Minimap = CreateFrame("Frame", "Minimap")
Minimap:SetSize(140, 140)
Minimap.GetZoom = function() return 0 end
Minimap.SetZoom = function(self, z) ZOOM = z end
Minimap.GetZoomLevels = function() return 6 end
Minimap.hijos = { CreateFrame("Button", "LibDBIcon10_Otro", Minimap) }
NAVEGO = {}
Polestar = { Nav = { API = { Navigate = function(o, m, x, y, t) table.insert(NAVEGO, { o, m, x, y, t }); return true end } },
  UI = { RegisterSection = function(s) SECCION = s; return true end } }
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Mapa", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Nucleo.lua":
            src = src.replace("while mejoro and vueltas < 20 do", "while false do")
        cargar(src, n, M)
    return L


L = nuevo()
G = L.globals()
Mp = G.MambaMapa
check(len(list(G.ERRORES.values())) == 0, "carga sin errores")
L.execute('Fire("PLAYER_LOGIN")')
check(G.SECCION is not None and G.SECCION.label == "Interfaz", "se cuelga de la sección Interfaz")
check(G.MambaInterfaz.modulos["mapa"] is not None, "módulo Mapa en Interfaz")

todos = Mp.NodosDe(1411, L.eval("{}"))
check(len(todos) > 100, "Durotar tiene más de 100 nodos")
f = Mp.Filtro()
check(f.vetas is False, "sin Minería no muestra vetas")
mios = Mp.NodosDe(1411, f)
check(len(mios) > 0 and all(p.tipo == "h" and p.habilidad <= 212 for p in mios.values()), "solo hierbas que puedo recoger (≤ 212)")
cx, cy = Mp.CentroNodos("hierbas", 1411)
check(cx is not None and 0 <= cx <= 100, "centro de las hierbas de Durotar")
check(Mp.CentroNodos("hierbas", 999999) is None, "mapa sin nodos: nil")

pts = L.eval("{ {x=0,y=0}, {x=10,y=10}, {x=10,y=0}, {x=0,y=10} }")
orden, largo = Mp.Ruta(pts, 100, 100)
check(abs(largo - 40) < 0.01, "ruta por 4 esquinas = el perímetro (40), largo=%s" % largo)
random.seed(4)
P = [(random.uniform(0, 100), random.uniform(0, 100)) for _ in range(60)]
tabla = L.eval("{}")
for i, (x, y) in enumerate(P, 1):
    tabla[i] = L.eval("{x=%f,y=%f}" % (x, y))
orden, largo = Mp.Ruta(tabla, 1000, 1000)
rest = P[:]; cur = rest.pop(0); nn = 0; first = cur
while rest:
    j = min(range(len(rest)), key=lambda k: math.dist(cur, rest[k])); nn += math.dist(cur, rest[j]) * 10; cur = rest.pop(j)
nn += math.dist(cur, first) * 10
check(len(orden) == 60, "la ruta pasa por los 60 nodos")
check(largo < nn * 0.97, "2-opt mejora al vecino más cercano: %.0f vs %.0f" % (largo, nn))
check(abs(Mp.MinutosVuelta(4200, 30) - (600 + 120) / 60) < 0.01, "minutos de una vuelta")

x, y = Mp.EnMinimapa(0, 0, 100, 0, 466, 70, 0)
check(abs(x) < 0.01 and y > 0, "un punto al norte queda arriba")
x, y = Mp.EnMinimapa(0, 0, 0, -100, 466, 70, 0)
check(x > 0 and abs(y) < 0.01, "un punto al este queda a la derecha")
check(Mp.EnMinimapa(0, 0, 400, 0, 466, 70, 0) is None, "fuera del radio no se dibuja")
x, y = Mp.EnMinimapa(0, 0, 0, -100, 466, 70, math.pi / 2)
check(abs(x) < 0.01 and y > 0, "minimapa girado mirando al este: el este queda arriba")

Mp.DibujarMapa(); Mp.DibujarMinimapa(); Mp.ActualizarCoords()
check(len(list(G.ERRORES.values())) == 0, "dibujar mapa, minimapa y coordenadas sin errores: %s" % list(G.ERRORES.values())[:3])
r = Mp.MostrarRuta(1411, None, "hierbas")
check(r.yardas and r.minutos > 0 and len(r.orden) > 0, "ruta de hierbas de Durotar con minutos")
check((G.LINEAS or 0) >= len(r.orden), "la ruta se dibuja con líneas")
check(Mp.SeguirRuta() and G.NAVEGO[1][1] == "MambaMapa", "seguir la ruta pone la flecha")
p1 = r.orden[1]
G.POS = L.eval("{ %f, %f }" % (p1.x / 100, p1.y / 100))
Mp.TickRuta()
check(r.i == 2 and len(G.NAVEGO) == 2, "al llegar al nodo pasa al siguiente")

G.COMBATE = True
Mp.DB().escalaMapa = 1.2
Mp.AplicarEscala()
check(G.WorldMapFrame.escala != 1.2, "en combate no cambia el mapa")
G.COMBATE = False
L.execute('Fire("PLAYER_REGEN_ENABLED")')
check(G.WorldMapFrame.escala == 1.2, "al salir de combate sí")
Mp.DB().ocultarBotones = True
Mp.AplicarMinimapa()
check(G.LibDBIcon10_Otro.alfa == 0, "botones del minimapa ocultos hasta pasar el ratón")
padre = L.eval('CreateFrame("Frame")')
G.MambaInterfaz.modulos["mapa"].dibujar(padre, 620, 480)
G.MambaInterfaz.modulos["mapa"].refrescar()
check(len(list(G.ERRORES.values())) == 0, "panel de Interfaz › Mapa sin errores: %s" % list(G.ERRORES.values())[:3])
check(Mp.DB().diag.fallas is None, "sin fallas en diag: %s" % (Mp.DB().diag.fallas and list(Mp.DB().diag.fallas.values())))
# coordenadas duplicadas (captura 18-11): si Polestar ya las muestra en el minimapa, Mamba no dibuja las suyas
check(Mp.OtrasCoords() is None, "sin otras coordenadas: Mamba dibuja las suyas")
L.eval("function(t) t.Show = function(s) s.visible = true end; t.Hide = function(s) s.visible = false end end")(Mp.TextoMini()); Mp.ActualizarCoords()
check(Mp.TextoMini() is not None and Mp.TextoMini().visible, "sin otras: las de Mamba se ven")
L.execute('PolestarMinimapCoords = CreateFrame("Frame", "PolestarMinimapCoords", Minimap); PolestarMinimapCoords:Show()')
check(Mp.OtrasCoords() == "Polestar", "detecta las coordenadas de Polestar en el minimapa")
Mp.ActualizarCoords()
check(Mp.TextoMini() is not None and not Mp.TextoMini().visible, "con las de Polestar, Mamba esconde las suyas (no se ven dos)")
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
