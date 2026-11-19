"""Pruebas de Mamba_Curacion con Lua 5.1 (lupa). Uso: python test_curacion.py [--romper]

Simula lo que ya rompió cosas en el juego: tocar marcos protegidos en combate (ADDON_ACTION_BLOCKED), eventos
que Forever no conoce y los "valores secretos" de Forever (vida y auras que no se pueden comparar ni restar: aquí
dan error si se hace una cuenta con ellos). --romper quita la espera de combate: tiene que fallar.
"""
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = AQUI.parent.parent.parent / "addon" / "Mamba_Curacion"
ROMPER = "--romper" in sys.argv
toc = (D / "Mamba_Curacion.toc").read_text(encoding="utf-8")
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
-- un valor secreto: se puede pasar a una barra, pero sumar, restar o comparar da error (como en Forever)
local MS = { __sub = function() error("attempt to perform arithmetic on a secret value") end,
  __add = function() error("attempt to perform arithmetic on a secret value") end,
  __lt = function() error("attempt to compare a secret value") end, __le = function() error("attempt to compare a secret value") end }
function Secreto() return setmetatable({}, MS) end
function issecretvalue(v) return type(v) == "table" and getmetatable(v) == MS end
CONOCE = { [774] = true, [8936] = true, [5185] = true, [2782] = true, [8946] = true, [18562] = true }
NOMBRES = { [774] = "Rejuvenecimiento", [8936] = "Recrecimiento", [5185] = "Toque de sanación", [2782] = "Quitar maldición",
  [8946] = "Curar envenenamiento", [18562] = "Presteza" }
function IsPlayerSpell(id) return CONOCE[id] or false end
C_Spell = { GetSpellName = function(id) return NOMBRES[id] end,
  IsSpellInRange = function(sp, u) return RANGO end,
  GetSpellCooldown = function(id) return { startTime = CD_INICIO or 0, duration = 0 } end }
SPEC = 1
function GetActiveTalentGroup() return SPEC end
function UnitExists(u) return u ~= nil end
function UnitHealth(u) return SECRETOS and Secreto() or 800 end
function UnitHealthMax(u) return SECRETOS and Secreto() or 1000 end
function UnitName(u) return u == "player" and "Hope" or "Compa" end
function UnitIsDeadOrGhost() return false end
function UnitIsConnected() return true end
function UnitInRange() return true, true end
function UnitIsUnit(a, b) return a == b end
function IsInGroup() return EN_GRUPO end
RAID_CLASS_COLORS = { DRUID = { r = 1, g = 0.49, b = 0.04 } }
AURAS = {}
C_UnitAuras = { GetAuraDataByIndex = function(u, i, f) local l = AURAS[f] or {}; return l[i] end }
local mt = getmetatable(CreateFrame("Frame")).__index
mt.SetStatusBarTexture = function() end
mt.SetStatusBarColor = function() end
mt.SetMinMaxValues = function(self, a, b) self.max = b end
mt.SetValue = function(self, v) self.valor = v end
mt.SetCooldown = function(self, a, b) self.cd = { a, b } end
mt.SetHideCountdownNumbers = function() end
mt.SetBindingClick = function() end
mt.EnableMouse = function(self, v) self.raton = v end
mt.RegisterForClicks = function(self, v) self.clics = v end
MambaAPI = { Movible = function(f, n, asa) f.raton = true; if asa then asa.raton = true end end }
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Curacion", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Marcos.lua":
            src = src.replace("if enCombate() then pendiente = true; return false end", "")
        cargar(src, n, M)
    return L


L = nuevo()
G = L.globals()
Cu = G.MambaCuracion
check(len(list(G.ERRORES.values())) == 0, "carga sin errores")
L.execute('Polestar = { UI = { RegisterSection = function(s) SECCION = s; return true end } }')
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaInterfaz.modulos["curacion"] is not None, "Curación en Interfaz")
cab = G.MambaCuraCabecera
check(cab is not None and cab.plantilla == "SecureGroupHeaderTemplate", "cabecera segura del juego")
check(cab.attr["template"].find("SecureActionButtonTemplate") >= 0 and cab.attr["template"].find("ShowHide") >= 0, "botones con plantilla segura de acción y ocultar (como HealBot)")

at = Cu.Atributos(Cu.Perfil())
check(at["type1"] == "spell" and at["spell1"] == "Rejuvenecimiento", "clic izquierdo = Rejuvenecimiento (druida)")
check(at["ctrl-spell1"] == "Quitar maldición", "Ctrl + clic = Quitar maldición")
check(at["alt-type1"] == "target" and at["alt-type2"] == "togglemenu", "Alt: objetivo y menú")
check(at["type4"] == "spell" and at["spell4"] == "Rejuvenecimiento", "rueda arriba = Rejuvenecimiento")
check(at["spell5"] == "Recrecimiento", "rueda abajo = Recrecimiento")
frag = cab.attr["initialConfigFunction"]
compila = L.eval("function(s) return loadstring(s) ~= nil end")(frag)
check(compila, "el fragmento seguro compila")
check('"spell1", "Rejuvenecimiento"' in frag and cab.attr["_initialAttribute-_onenter"] is not None, "el fragmento copia el perfil y la cabecera, la rueda")

# botón nuevo (lo crea la cabecera)
b = L.eval('CreateFrame("Button", "MambaCuraCabeceraUnitButton1", MambaCuraCabecera, "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate")')
b.attr["unit"] = "party1"
cab.scripts["OnAttributeChanged"](cab, "child1", b)
check(b.attr["_onenter"] is not None and b.attr["_onhide"] is not None, "el botón ata la rueda al pasar el ratón y la suelta al ocultarse")
check(b.attr["useOnKeyDown"] is False and "RegisterForClicks" not in frag, "clic al soltar, sin RegisterForClicks en el fragmento")
check("SHIFT-" in cab.attr["_initialAttribute-_onenter"], "rueda con Mayús también")
check(b.vida is not None and b.vida.valor == 800, "pinta la vida")
# valores secretos
G.SECRETOS = True
G.AURAS = L.eval('{ ["HELPFUL|PLAYER"] = { { icon = 1, duration = Secreto(), expirationTime = Secreto() } }, ["HARMFUL|RAID"] = { { dispelName = Secreto() } } }')
Cu.Pintar(b)
check(len(list(G.ERRORES.values())) == 0 and Cu.DB().diag.fallas is None, "con valores secretos no hay cuentas ni errores: %s" % (Cu.DB().diag.fallas and list(Cu.DB().diag.fallas.values())))
check(b.hots[1].visible, "muestra mi HoT aunque su tiempo sea secreto")
G.SECRETOS = False
G.AURAS = L.eval('{ ["HELPFUL|PLAYER"] = { { icon = 1, duration = 12, expirationTime = 112 } }, ["HARMFUL|RAID"] = { { dispelName = "Poison" } } }')
Cu.Pintar(b)
check(b.hots[1].cd.cd[1] == 100 and b.hots[1].cd.cd[2] == 12, "cuenta regresiva del HoT")
G.RANGO = False
Cu.Pintar(b)
check(b.alfa == 0.45, "fuera de alcance: atenuado")
G.RANGO = True
Cu.Pintar(b)
check(b.alfa == 1, "en alcance: normal")
check(Cu.PrestezaLista() is True, "Presteza lista sin enfriamiento")
G.CD_INICIO = 50
L.execute("C_Spell.GetSpellCooldown = function() return { startTime = 50, duration = 15 } end")
check(Cu.PrestezaLista() is False, "Presteza en enfriamiento")

# combate: nada protegido se toca
G.COMBATE = True
L.execute("BLOQUEOS = {}")
Cu.Perfil()["1"] = 5185
r = Cu.Aplicar()
check(len(list(G.BLOQUEOS.values())) == 0, "en combate no toca marcos protegidos: %s" % list(G.BLOQUEOS.values()))
check(r is False and Cu.Pendiente(), "queda pendiente para después del combate")
G.COMBATE = False
L.execute('Fire("PLAYER_REGEN_ENABLED")')
check(b.attr["spell1"] == "Toque de sanación", "al salir de combate el botón recibe el clic nuevo")
# doble especialización: otro perfil
G.SPEC = 2
p2 = Cu.Perfil()
p2["1"] = 8936
L.execute('Fire("ACTIVE_TALENT_GROUP_CHANGED")')
check(b.attr["spell1"] == "Recrecimiento", "la especialización 2 tiene su propio perfil")
G.SPEC = 1
L.execute('Fire("ACTIVE_TALENT_GROUP_CHANGED")')
check(b.attr["spell1"] == "Toque de sanación", "y la 1 vuelve al suyo")
# mostrar
Cu.DB().mostrar = "grupo"; G.EN_GRUPO = False; Cu.MostrarSegun()
check(not cab.visible, "solo en grupo: escondidos sin grupo")
G.EN_GRUPO = True; Cu.MostrarSegun()
check(cab.visible, "en grupo: a la vista")
Cu.Mostrar(False)
check(not cab.visible, "el modo de pelea puede esconderlos")
Cu.Mostrar(None)
# panel
padre = L.eval('CreateFrame("Frame")')
m = G.MambaInterfaz.modulos["curacion"]
m.dibujar(padre, 620, 480)
m.elegir("clics"); m.refrescar()
check(len(list(G.ERRORES.values())) == 0, "paneles de Curación sin errores: %s" % list(G.ERRORES.values())[:3])
# ---------- GATE 18-11: el ancla no se come los clics; se mueve con un asa fuera de combate
check(G.MambaCuraAncla.raton is False, "el ancla de los marcos no recibe el ratón")
asa = Cu.Asa()
check(asa is not None and not asa.visible, "el asa está escondida por defecto")
Cu.DB().mover = True; G.COMBATE = False; Cu.MostrarAsa()
check(asa.visible, "Mover marcos: el asa se ve fuera de combate")
G.COMBATE = False; L.execute('Fire("PLAYER_REGEN_DISABLED")'); G.COMBATE = True  # en el evento, InCombatLockdown() todavía da false
check(not asa.visible, "en combate el asa se esconde")
b2 = L.eval('CreateFrame("Button", "MambaCuraCabeceraUnitButton2", MambaCuraCabecera, "SecureActionButtonTemplate")')
b2.attr["unit"] = "party2"
cab.scripts["OnAttributeChanged"](cab, "child2", b2)
check(b2.clics is None, "botón creado en combate: no toca RegisterForClicks")
G.COMBATE = False; L.execute('Fire("PLAYER_REGEN_ENABLED")')
check(b2.clics == "AnyUp" and asa.visible, "al salir de combate: todos los clics y el asa de vuelta")
check(L.eval("MambaCuracion.BotonDe('party1') == MambaCuraCabeceraUnitButton1 and MambaCuracion.BotonDe('party2') == MambaCuraCabeceraUnitButton2"), "tabla unidad -> botón")
b.vida.valor = None
L.execute('Fire("UNIT_HEALTH", "party1")')
check(b.vida.valor == 800, "UNIT_HEALTH de party1 repinta su botón")
L.execute('ERRORES = {}')
for _ in range(5): Cu.Falla("alcance", "x")
check(len(list(G.ERRORES.values())) == 1 and Cu.DB().diag.repetidas["alcance"] == 4, "una falla repetida avisa una sola vez")
# K55 ampliado: el modo «Mover elementos» de Mamba muestra el asa
L = nuevo(); G = L.globals()
L.execute('MambaAPI.AlModoMover = function(fn) MODO_MOVER = fn end')
L.execute('Fire("PLAYER_LOGIN")')
asa2 = L.eval("MambaCuracion.Asa()")
check(G.MODO_MOVER is not None, "Curación se engancha al modo Mover de Mamba")
if G.MODO_MOVER is not None and asa2 is not None:
    G.MODO_MOVER(True); check(asa2.visible, "modo Mover: el asa se ve")
    G.MODO_MOVER(False); check(not asa2.visible, "al salir del modo Mover: el asa se esconde")
# ---------- 19-11, error del juego (275 veces): el código restringido no puede poner atributos con "_"
import re as _re
def prohibidos(fragmento):
    return _re.findall(r'SetAttribute\("(_[^"]*)"', fragmento)
frag2 = G.MambaCuraCabecera.attr["initialConfigFunction"]
check(not prohibidos(frag2), "el fragmento seguro no pone atributos que empiezan con _: %s" % prohibidos(frag2))
check(prohibidos('self:SetAttribute("_onenter", "x")') == ["_onenter"], "control negativo: el detector ve el atributo prohibido")
check(G.MambaCuraCabecera.attr["_initialAttribute-_onenter"] is not None, "la rueda llega a los botones por _initialAttribute- de la cabecera")
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
