# Pruebas de Mamba_Errores (por dónde escucha los errores sin manchar la interfaz), con Lua 5.1 (lupa).
# Uso: python -I tools/asistente/pruebas/test_errores.py [archivo Errores.lua]
# Escenarios, según el código de Blizzard (Gethe/wow-ui-source classic_era: Blizzard_ScriptErrors y
# Blizzard_ScriptErrorsFrame):
#   A) cliente moderno con scriptErrors=0 y ScriptErrorsFrame que se carga DESPUÉS: anota por DisplayMessageInternal
#   B) sin ScriptErrorsFrame, solo ScriptErrors (Blizzard_ScriptErrors): anota por AddUnhandledError
#   C) sin ninguna de las dos: el diag dice mudo = true
# Control negativo: pasar el Errores.lua de antes (19-11, solo OnError) → A falla (quedaba mudo).
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
ARCHIVO = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parents[2] / "addon" / "Mamba_Errores" / "Errores.lua"
SRC = ARCHIVO.read_text(encoding="utf-8")
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


BASE = """
local marcos = {}
function CreateFrame()
  local f = { ev = {} }
  function f:RegisterEvent(e) self.ev[e] = true end
  function f:SetScript(n, fn) self[n] = fn end
  marcos[#marcos + 1] = f
  return f
end
function Fire(e, ...) for _, f in ipairs(marcos) do if f.ev[e] and f.OnEvent then f.OnEvent(f, e, ...) end end end
function hooksecurefunc(t, k, fn)
  local orig = t[k]
  t[k] = function(...) local r = { orig(...) }; fn(...); return unpack(r) end
end
function GetCVar(n) if n == "scriptErrors" then return "0" end end
function debugstack() return "pila" end
date = function() return "2026-11-19 23:00:00" end
SLASH_MAMBAERRORES1 = nil
SlashCmdList = {}
-- como en Blizzard: ErrorMessageType y WarningMessageType son LOCALES del marco (0 y 1), no globales
ErrorMessageType, WarningMessageType = nil, nil
"""


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(BASE)
    return L


def cargar(L):
    f = L.eval('function(src) local f = assert(loadstring(src, "@Mamba_Errores/Errores.lua")); f("Mamba_Errores", {}) end')
    f(SRC)
    L.execute('Fire("ADDON_LOADED", "Mamba_Errores")')


# A) scriptErrors=0, ScriptErrorsFrame (con DisplayMessageInternal, sin OnError) se carga después
L = nuevo()
cargar(L)
L.execute("""
ScriptErrorsFrame = { DisplayMessageInternal = function(self, msg, tipo, pila, locales) end }
Fire("ADDON_LOADED", "Blizzard_ScriptErrorsFrame")
Fire("PLAYER_LOGIN")
ScriptErrorsFrame:DisplayMessageInternal("X.lua:1: error de prueba", 0, "pila de X", "")
ScriptErrorsFrame:DisplayMessageInternal("una advertencia", 1)
""")
G = L.globals()
lista = G.MambaErroresDB.lista
check(len(list(lista.values())) == 1 and "error de prueba" in str(lista[1].msg), "A: con scriptErrors=0 anota el error por DisplayMessageInternal (y no la advertencia)")
check(G.MambaErroresDB.diag.descartadosPorTipo == 1 and str(G.MambaErroresDB.diag.ultimoTipoDescartado) == "1", "A: el diag cuenta la advertencia descartada por tipo (y guarda el tipo)")
check(G.MambaErroresDB.diag.enganchado is True and "DisplayMessageInternal" in str(G.MambaErroresDB.diag.via), f"A: el diag dice enganchado por DisplayMessageInternal ({G.MambaErroresDB.diag.via})")
check(str(lista[1].pila) == "pila de X", f"A: guarda la pila que manda Blizzard (tercer argumento) ({lista[1].pila})")
check(G.MambaErroresDB.diag.mudo is None, "A: no queda mudo")
check(str(G.MambaErroresDB.diag.scriptErrors) == "0", "A: el diag guarda scriptErrors")

# B) solo ScriptErrors (sin el marco)
L = nuevo()
L.execute("""
ScriptErrors = { AddUnhandledError = function(self, msg, pila, locales) end }
""")
cargar(L)
L.execute('Fire("PLAYER_LOGIN"); ScriptErrors:AddUnhandledError("Y.lua:2: otro", "pila de Y", "")')
G = L.globals()
lista = G.MambaErroresDB.lista
check(len(list(lista.values())) == 1 and "otro" in str(lista[1].msg), "B: sin ScriptErrorsFrame anota por ScriptErrors:AddUnhandledError")

# D) cliente viejo con OnError (sin pila): la pila queda nil (la de debugstack sería la del manejador, engañosa)
L = nuevo()
L.execute('ScriptErrorsFrame = { OnError = function(self, msg) end }')
cargar(L)
L.execute('Fire("PLAYER_LOGIN"); ScriptErrorsFrame:OnError("Z.lua:3: viejo")')
G = L.globals()
lista = G.MambaErroresDB.lista
check(len(list(lista.values())) == 1 and lista[1].pila is None, f"D: por OnError anota el error sin pila, no una engañosa ({lista[1].pila if len(list(lista.values())) else None})")

# C) nada por dónde escuchar: lo declara
L = nuevo()
cargar(L)
L.execute('Fire("PLAYER_LOGIN")')
G = L.globals()
check(G.MambaErroresDB.diag.mudo is True, "C: sin ninguna vía, el diag dice mudo = true")

# y nunca reemplaza el manejador del juego (K113)
check(not any("seterrorhandler(" in l.split("--")[0] for l in SRC.splitlines()), "no llama a seterrorhandler (K113)")

print(f"\n{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
