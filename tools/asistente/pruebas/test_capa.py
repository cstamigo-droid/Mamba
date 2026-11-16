"""Pruebas de la capa (Asistente/Capa.lua), con Lua 5.1 (lupa).
Uso: python test_capa.py <carpeta addon>"""
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
BASE = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parents[2] / "addon"
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


toc = (BASE / "Asistente" / "Asistente.toc").read_text(encoding="utf-8")
archivos = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
check("Capa.lua" in archivos and archivos.index("Capa.lua") > archivos.index("Nucleo.lua"), "Capa.lua va en el toc, después del núcleo")

ENTORNO = r'''
chat, errores, handlers = {}, {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(chat, m) end }
UIErrorsFrame = { AddMessage = function(_, m) table.insert(errores, m) end }
SlashCmdList = {}
T = 100
function GetTime() return T end
SECRETO = setmetatable({}, {})
function issecretvalue(v) return v == SECRETO end
function strsplit(sep, s)
  local t = {}
  for parte in (s .. sep):gmatch("(.-)" .. sep:gsub("%-", "%%-")) do t[#t + 1] = parte end
  return unpack(t)
end
GUIDS = {}
function UnitGUID(u) return GUIDS[u] end
MAPA = 1413
C_Map = { GetBestMapForUnit = function() return MAPA end }
function CreateFrame()
  local f = { ev = {} }
  function f:RegisterEvent(e) self.ev[e] = true end
  function f:SetScript(_, fn) table.insert(handlers, { f = self, fn = fn }) end
  return f
end
function Fire(e, ...) for _, h in ipairs(handlers) do if h.f.ev[e] then h.fn(h.f, e, ...) end end end
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(ENTORNO)
    cargar = L.eval('function(src, name) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Asistente", {}) end')
    for n in ("Nucleo.lua", "Capa.lua"):
        cargar((BASE / "Asistente" / n).read_text(encoding="utf-8"), n)
    return L


L = nuevo()
C = L.eval("Asistente.Capa")
leer_lua = L.eval("function(g) local a, b, c = Asistente.Capa.Leer(g); return {a, b, c} end")


def leer(g):
    r = leer_lua(g)
    return r[1], r[2], r[3]

# 1. Leer el GUID
z, clave, motivo = leer("Creature-0-5250-1-2045-3100-0000ABCDEF")
check(z == "2045" and clave == "5250:1:2045" and motivo is None, f"PNJ normal: zona 2045 ({z}, {clave})")
z, clave, motivo = leer("Vehicle-0-5250-1-77-3100-0000ABCDEF")
check(z == "77", "vehículo también sirve")
z, clave, motivo = leer("Player-5250-0ABCDEF1")
check(z is None and motivo == "sin_pnj", "un jugador no dice la capa")
z, clave, motivo = leer(None)
check(z is None and motivo == "sin_pnj", "sin objetivo")
z, clave, motivo = leer(L.eval("SECRETO"))
check(z is None and motivo == "restringido", "GUID secreto: no se usa, sin error")
z, clave, motivo = leer("Pet-0-5250-1-2045-3100-0000ABCDEF")
check(z is None, "mascota no cuenta")

# 2. Observar: primera vez no avisa, cambio de capa en el mismo mapa avisa
g = L.eval("GUIDS")
g["target"] = "Creature-0-5250-1-2045-3100-0000ABCDEF"
L.execute('Fire("PLAYER_TARGET_CHANGED")')
check(C.actual is not None and C.actual.zona == "2045", "guarda la capa del objetivo")
check(len(L.eval("chat")) == 0, "la primera lectura no avisa")
g["mouseover"] = "Creature-0-5250-1-3001-99-0000000001"
L.execute('Fire("UPDATE_MOUSEOVER_UNIT")')
chat = L.eval("chat")
check(C.actual.zona == "3001" and len(chat) == 1 and "2045" in chat[1] and "3001" in chat[1], "cambio de capa: avisa con las dos")
check(len(L.eval("errores")) == 1, "y en el centro de la pantalla")
L.execute('Fire("UPDATE_MOUSEOVER_UNIT")')
check(len(L.eval("chat")) == 1, "la misma capa no repite el aviso")

# 3. Otro mapa no es "cambio de capa"
L.execute("MAPA = 1411")
g["target"] = "Creature-0-5250-1-4444-3100-0000ABCDEF"
L.execute('Fire("PLAYER_TARGET_CHANGED")')
check(len(L.eval("chat")) == 1 and C.actual.zona == "4444", "al cambiar de zona no avisa: es otra zona, no otra capa")

# 4. Pantalla de carga: olvida
L.execute('Fire("PLAYER_ENTERING_WORLD")')
check(C.actual is None, "tras una pantalla de carga se olvida la capa")
check("?" in C.Texto(), "sin capa, el texto pide apuntar a un PNJ")

# 5. Avisos apagados
L.execute('SlashCmdList.ASISTENTECAPA("avisos")')
g["target"] = "Creature-0-5250-1-1-3100-0000ABCDEF"
L.execute('Fire("PLAYER_TARGET_CHANGED")')
g["target"] = "Creature-0-5250-1-2-3100-0000ABCDEF"
n_antes = len(L.eval("chat"))
L.execute('Fire("PLAYER_TARGET_CHANGED")')
check(len(L.eval("chat")) == n_antes and C.actual.zona == "2", "con avisos apagados, sigue midiendo pero no avisa")

# 6. Texto con la edad
L.execute("T = 100 + 130")
check(C.Texto() == "Capa: 2  (hace 2 min)", C.Texto())
check(L.eval("SLASH_ASISTENTECAPA1") == "/capa" and L.eval("SLASH_ASISTENTECAPA2") == "/layer", "comandos /capa y /layer (el de MyLayerTracker)")

# 7. No escribe nada del juego (solo lee)
src = (BASE / "Asistente" / "Capa.lua").read_text(encoding="utf-8")
for prohibido in ("SetCVar", "TargetUnit", "CastSpell", "UseAction", "SendChatMessage"):
    check(prohibido not in src, f"Capa no usa {prohibido}")

print(f"OK {ok} · FALLAS {fail}")
sys.exit(1 if fail else 0)
