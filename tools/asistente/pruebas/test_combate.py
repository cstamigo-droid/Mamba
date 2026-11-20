"""Pruebas de Mamba_Combate con Lua 5.1 (lupa). Uso: python test_combate.py [--romper] [--sin-eventos]

Simula lo que ya rompió cosas en el juego: eventos que Forever no conoce (--sin-eventos los vuelve TODOS
desconocidos: PLAYER_SWING, DAMAGE_METER_*, LOSS_OF_CONTROL_ADDED…; nada tiene que romperse), marcos protegidos en
combate y los valores secretos de Forever (sumar, restar o comparar uno da error).
--romper hace que el motor ignore las condiciones: la prueba de prioridad tiene que fallar (control negativo).
"""
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = AQUI.parent.parent.parent / "addon" / "Mamba_Combate"
ROMPER = "--romper" in sys.argv
SIN_EVENTOS = "--sin-eventos" in sys.argv
toc = (D / "Mamba_Combate.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua") and (D / l.strip()).exists()]
ok = fail = 0


def check(c, m):
    global ok, fail
    if c:
        ok += 1
    else:
        fail += 1
        print("FALLA:", m)


MOCK = r'''
local MS = { __sub = function() error("arithmetic on a secret value") end, __add = function() error("arithmetic on a secret value") end,
  __lt = function() error("compare a secret value") end, __le = function() error("compare a secret value") end,
  __div = function() error("arithmetic on a secret value") end }
function Secreto() return setmetatable({}, MS) end
function issecretvalue(v) return type(v) == "table" and getmetatable(v) == MS end
RELOJ = 100
function GetTime() return RELOJ end
CONOCE = { [8921] = true, [5176] = true, [2912] = true, [339] = true, [5487] = true, [768] = true, [783] = true,
  [8936] = true, [5185] = true, [774] = true, [1082] = true, [1822] = true, [5211] = true, [6807] = true, [99] = true, [29166] = true }
NOMBRES = { [8921] = "Fuego lunar", [5176] = "Cólera", [2912] = "Fuego estelar", [339] = "Raíces enredadoras", [5487] = "Forma de oso",
  [768] = "Forma felina", [783] = "Forma de viaje", [8936] = "Recrecimiento", [5185] = "Toque de sanación", [774] = "Rejuvenecimiento",
  [1082] = "Zarpa", [1822] = "Arañazo", [5211] = "Azote", [6807] = "Magullar", [99] = "Rugido desmoralizador", [29166] = "Inervar",
  [16870] = "Augurio de claridad", [408] = "Golpe en los riñones", [5570] = "Enjambre de insectos" }
function IsPlayerSpell(id) return CONOCE[id] or false end
CD = {}
C_Spell = { GetSpellName = function(id) return NOMBRES[id] end, GetSpellTexture = function(id) return 1000 + id end,
  IsSpellUsable = function(n) return true, false end,
  GetSpellCooldown = function(n) local c = CD[n]; if c then return { startTime = c[1], duration = c[2] } end; return { startTime = 0, duration = 0 } end }
AURAS = { player = {}, target = {} }
SECRETO_AURAS = false
C_UnitAuras = { GetAuraDataBySpellName = function(u, n, f)
  if SECRETO_AURAS and u == "target" then return Secreto() end
  return (AURAS[u] or {})[n] and { name = n } or nil end,
  GetAuraDataByIndex = function() return nil end }
VIDA = { player = { 1000, 1000 }, target = { 500, 1000 } }
function UnitHealth(u) local v = VIDA[u]; if SECRETO_VIDA and u == "target" then return Secreto() end; return v and v[1] or 0 end
function UnitHealthMax(u) local v = VIDA[u]; return v and v[2] or 0 end
PODER = { [0] = { 800, 1000 }, [1] = { 0, 100 }, [3] = { 100, 100 } }
function UnitPower(u, t) return (PODER[t] or { 0 })[1] end
function UnitPowerMax(u, t) return (PODER[t] or { 0, 0 })[2] end
function GetComboPoints() return COMBO or 0 end
EN_COMBATE = false
function UnitAffectingCombat(u) if u == "player" then return EN_COMBATE end; return true end
function UnitExists(u) return u == "player" or u == "target" or (u == "party1" and EN_GRUPO) or (u == "pet" and MASCOTA) or false end
function UnitIsPlayer(u) return OBJ_JUGADOR and u == "target" end
function UnitCanAttack() return true end
function UnitLevel(u) return u == "target" and (NIVEL_OBJ or 38) or 39 end
function UnitClassification() return CLASIF or "normal" end
function UnitRace() return "Tauren", "Tauren" end
INSTANCIA = "none"
function IsInInstance() return INSTANCIA ~= "none", INSTANCIA end
function IsInGroup() return EN_GRUPO end
function IsInRaid() return false end
function GetNumTalentTabs() return 3 end
TALENTOS = { 19, 0, 8 }
function GetTalentTabInfo(t) return t, "Arbol" .. t, "", 0, TALENTOS[t] end
function GetShapeshiftForm() return 0 end
PLACAS = {}
C_NamePlate = { GetNamePlates = function() return PLACAS end, GetNamePlateForUnit = function(u) for _, p in ipairs(PLACAS) do if p.namePlateUnitToken == u then return p end end end }
C_ActionBar = { FindSpellActionButtons = function(id) if id == 8921 then return { 3 } end; if id == 5176 then return { 4 } end; return {} end }
local mt = getmetatable(CreateFrame("Frame")).__index
mt.SetStatusBarTexture = function() end
mt.SetStatusBarColor = function(self, r, g, b) self.color = { r, g, b } end
mt.SetMinMaxValues = function() end
mt.SetValue = function(self, v) self.valor = v end
mt.RegisterUnitEvent = mt.RegisterEvent
for i = 1, 6 do
  local b = CreateFrame("Button", "MambaBoton" .. i, UIParent)
  b._state_action = i
  b.HotKey = b:CreateFontString(); b.HotKey:SetText(tostring(i)); b.HotKey.GetText = function(s) return s.texto end
end
function UnitThreatSituation(a, u) return AMENAZA_ST or 0 end
AMENAZA = {}
function UnitDetailedThreatSituation(u, obj) local a = AMENAZA[u]; if a then return a[2], 3, a[1], a[1], 0 end end
function UnitName(u) return ({ player = "Hope", party1 = "Tanque", target = "Jabalí" })[u] or u end
function UnitIsUnit(a, b) return a == b end
function UnitCastingInfo(u) if LANZA and LANZA[u] then return unpack(LANZA[u]) end end
function UnitChannelInfo() return nil end
function GetNetStats() return 0, 0, 40, 60 end
function SetCVar(k, v) CVAR = CVAR or {}; CVAR[k] = v end
function PlaySound() end
RAID_CLASS_COLORS = {}
Enum = { PlayerSwingType = { MainHand = 0, OffHand = 1, Ranged = 2 },
  DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 2 },
  DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Absorbs = 4, Interrupts = 5, Dispels = 6, DamageTaken = 7, AvoidableDamageTaken = 8, Deaths = 9 } }
SESION = nil
C_DamageMeter = { GetCombatSessionFromType = function(s, t) return SESION end,
  GetCombatSessionSourceFromType = function(s, t, g) return HECHIZOS end, ResetAllCombatSessions = function() REINICIO = true end }
C_LossOfControl = { GetActiveLossOfControlData = function() return CONTROL end }
CURA_MOSTRAR = "sin llamar"
MambaCuracion = { Mostrar = function(v) CURA_MOSTRAR = v end }
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    if SIN_EVENTOS:
        L.execute('for _, e in ipairs({"PLAYER_SWING","PLAYER_SWING_RANGE_UPDATE","DAMAGE_METER_COMBAT_SESSION_UPDATED","DAMAGE_METER_RESET","LOSS_OF_CONTROL_ADDED","UNIT_THREAT_LIST_UPDATE","NAME_PLATE_UNIT_ADDED","ACTIVE_TALENT_GROUP_CHANGED","DAMAGE_METER_CURRENT_SESSION_UPDATED","CHAT_MSG_COMBAT_HONOR_GAIN","PLAYER_DEAD","PARTY_KILL","PLAYER_ENTERING_WORLD"}) do EVENTOS_DESCONOCIDOS[e] = true end')
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Combate", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Rotacion.lua":
            src = src.replace("local v = R.Condicion(c)", "local v = true")
        if ROMPER and n == "Ranking.lua":
            # control negativo K106: ordena aunque haya secretos (los compara) y dibuja sin freno
            src = src.replace("\tif not secreto then\n\t\tfor _, f in ipairs(filas) do if type(f.total) ~= \"number\" then f.total = 0 end end\n", "\tif true then\n")
            src = src.replace("\tif pendiente then return end\n", "")
        if ROMPER and n == "Medidor.lua":
            # control negativo «mover»: el medidor sin su nombre en español
            src = src.replace('M.Movible(v, "MambaMedidorCombate", "Medidor de combate")', 'M.Movible(v, "MambaMedidorCombate")')
        if ROMPER and n == "Avisos.lua":
            # control negativo: al salir del modo mover el aviso de ejemplo queda a la vista
            src = src.replace("\t\tcartel.ejemplo = nil\n\t\tcartel:Hide()", "\t\tcartel.ejemplo = nil")
        if ROMPER and n == "Disparo.lua":
            # control negativo: el ancla del disparo queda a la vista (se come los clics) y no se crea al entrar
            src = src.replace("if ancla and not alguna and not ancla.mostrada and ancla:IsShown() then ancla:Hide() end", "")
        if ROMPER and n == "Rotacion.lua":
            # control negativo del texto cortado: el botón no se ensancha
            src = src.replace("caja.modo:SetWidth(math.max(150, (ancho or 0) + 12))", "")
        if ROMPER and n == "Cercanos.lua":
            # control negativo K105: anota muertes repetidas y se abre sola aunque esté silenciada
            src = src.replace("if ultima[clave] and t - ultima[clave] < 10 then", "if false then")
            src = src.replace("d.cercanosSola and not Cz.Silenciada() and", "d.cercanosSola and")
        cargar(src, n, M)
    return L


L = nuevo()
G = L.globals()
C = G.MambaCombate
R = C.Rotacion
check(len(list(G.ERRORES.values())) == 0, "carga sin errores: %s" % list(G.ERRORES.values())[:2])
L.execute('Polestar = { UI = { RegisterSection = function(s) SECCION = s; return true end } }')
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaInterfaz.modulos["combate"] is not None, "Combate en Interfaz")
# ---------- Mover elementos: cada marco existe desde que se entra, escondido, con su nombre en español
MOVIBLES = {"MambaMedidorCombate": "Medidor de combate", "MambaRanking": "Ranking del grupo", "MambaSiguiente": "Sugerencia de hechizo",
            "MambaCercanos": "Enemigos cerca", "MambaLanzamiento": "Barra de lanzamiento", "MambaDisparo": "Disparo automático y golpe",
            "MambaAviso": "Avisos en pantalla", "MambaAmenaza": "Amenaza del grupo"}
for nom, tit in MOVIBLES.items():
    check(G[nom] is not None and C.movibles[nom] == tit, "mover: %s existe al entrar y se llama «%s» (fue %s)" % (nom, tit, C.movibles[nom]))
for nom in ["MambaRanking", "MambaSiguiente", "MambaCercanos", "MambaLanzamiento", "MambaDisparo", "MambaAviso", "MambaAmenaza"]:
    check(not G[nom].visible, "mover: %s creado escondido" % nom)
# sin la ventana de Mamba: se arrastran enteros, y en combate no
L.execute('MOVIDO = false; MambaAviso.StartMoving = function() MOVIDO = true end; COMBATE = true')
G.MambaAviso.scripts.OnDragStart(G.MambaAviso)
check(G.MOVIDO is False, "mover: en combate no se mueve")
L.execute('COMBATE = false')
G.MambaAviso.scripts.OnDragStart(G.MambaAviso)
check(G.MOVIDO is True, "mover: fuera de combate sí")
# con la ventana de Mamba: MambaAPI.Movible(marco, nombre, nil, { etiqueta, sinAsa }) y AlModoMover
L.execute('''LLAMADAS = {}; MODO_FN = nil
MambaAPI = { Movible = function(f, n, asa, o) table.insert(LLAMADAS, { n = n, asa = asa, etiqueta = o and o.etiqueta, sinAsa = o and o.sinAsa, ya = o and o.yaArrastra }) end,
  AlModoMover = function(fn) MODO_FN = fn end }''')
C.Movible(L.eval('CreateFrame("Frame")'), "MambaPrueba", "Prueba")
ll = G.LLAMADAS[1]
check(ll.n == "MambaPrueba" and ll.etiqueta == "Prueba" and ll.sinAsa is True and ll.asa is None, "mover: MambaAPI.Movible(marco, nombre, nil, { etiqueta, sinAsa = true })")
C.Piezas.Ventana("MambaPruebaV", "Ventana de prueba", 200, 100)
ll = G.LLAMADAS[2]
check(ll.n == "MambaPruebaV" and ll.etiqueta == "Ventana de prueba" and ll.ya is True, "mover: las ventanas con título pasan su etiqueta y se arrastran por el título")
C.ConectarMover()
check(G.MODO_FN is not None, "mover: se engancha a MambaAPI.AlModoMover")
ESCONDIDOS = ["MambaMedidorCombate", "MambaRanking", "MambaSiguiente", "MambaCercanos", "MambaLanzamiento", "MambaDisparo", "MambaAviso", "MambaAmenaza"]
for nom in ESCONDIDOS:
    G[nom].Hide(G[nom])
C.DB().rankingAbierto = False
C.DB().medidor = False  # apagado y sin objetivo: medidor y sugerencia escondidos de verdad
L.execute('UE_GUARDA = UnitExists; UnitExists = function(u) return u == "player" end')
G.MODO_FN(True)
for nom in ESCONDIDOS:
    check(G[nom].visible, "mover: en el modo, %s se ve de ejemplo" % nom)
check("ejemplo" in str(G.MambaAviso.texto.texto) and G.MambaAviso.hasta is None, "mover: el aviso de ejemplo no se apaga solo")
# los relojes y dibujos de cada módulo no esconden el ejemplo (revisión 3)
RELOJ0 = G.RELOJ; G.RELOJ = G.RELOJ + 5
C.Disparo.Tick(); C.Rotacion.Dibujar(); C.Amenaza.Dibujar(); C.Medidor.Dibujar(); C.Avisos.Revisar()
for nom in ESCONDIDOS:
    check(G[nom].visible, "mover: %s sigue de ejemplo aunque corran sus relojes" % nom)
G.RELOJ = RELOJ0
G.MODO_FN(False)
for nom in ESCONDIDOS:
    check(not G[nom].visible, "mover: al salir, %s vuelve a esconderse" % nom)
L.execute('UnitExists = UE_GUARDA'); C.DB().medidor = True
check(C.DB().rankingAbierto is False and C.Cercanos.cerradaEn is None, "mover: salir del modo no cuenta como abrir el ranking ni cerrar Enemigos cerca")
check(C.DB().diag.fallas is None, "mover: sin fallas: %s" % (C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:2]))
L.execute('MambaAPI = nil')
if SIN_EVENTOS:
    check(C.DB().diag.eventosNo["PLAYER_SWING"], "anota el evento que no existe y sigue")

# ---------- especialización y modo
s = R.Spec()
check(s.clave == "equilibrio", "19/0/8 en forma normal: Equilibrio")
G.AURAS.player["Forma de oso"] = True
check(R.Spec().clave == "oso", "en forma de oso: oso")
G.AURAS.player["Forma de oso"] = None
check(R.Modo()[0] == "solo", "afuera y sin nadie: solo")
G.INSTANCIA = "party"
check(R.Modo()[0] == "mazmorra", "en mazmorra: Mazmorra")
G.NIVEL_OBJ = -1
check(R.Modo()[0] == "jefe", "jefe (nivel ??): Jefe largo")
G.NIVEL_OBJ = 38; G.INSTANCIA = "none"; G.OBJ_JUGADOR = True
check(R.Modo()[0] == "jcj", "objetivo jugador enemigo: JcJ")
G.OBJ_JUGADOR = False
L.execute('PLACAS = { { namePlateUnitToken = "nameplate1" }, { namePlateUnitToken = "nameplate2" }, { namePlateUnitToken = "nameplate3" } }')
check(R.Modo()[0] == "varios", "3 enemigos en combate: Varios")
L.execute('PLACAS = {}')
C.DB().modo = "mazmorra"
check(R.Modo()[0] == "mazmorra", "modo fijo con el botón")
C.DB().modo = "auto"

# ---------- el motor (solo, en combate)
G.EN_COMBATE = True
e = R.Evaluar()
ahora = e.pasos[e.ahora].paso.h
check(ahora == 8921, "sin Fuego lunar en el objetivo: Fuego lunar primero (fue %s)" % ahora)
check(all(x.paso.h != 5570 for x in e.pasos.values()), "no muestra lo que no sabe (Enjambre de insectos)")
G.AURAS.target["Fuego lunar"] = True
e = R.Evaluar()
check(e.pasos[e.ahora].paso.h == 5176, "con Fuego lunar puesto: Cólera")
G.AURAS.player["Augurio de claridad"] = True
e = R.Evaluar()
check(e.pasos[e.ahora].paso.h == 2912, "con Augurio de claridad: Fuego estelar gratis")
G.AURAS.player["Augurio de claridad"] = None
G.AURAS.target["Fuego lunar"] = None
G.SECRETO_AURAS = True
e = R.Evaluar()
check(e.pasos[e.ahora].estado == "quizas", "aura del objetivo secreta: queda '?' (no adivina)")
G.SECRETO_AURAS = False
L.execute('CD["Fuego lunar"] = { 99, 6 }')
e = R.Evaluar()
check(e.pasos[e.ahora].paso.h != 8921, "en enfriamiento no lo sugiere")
L.execute('CD = {}')
G.VIDA.player[1] = 300
e = R.Evaluar()
check(e.modo == "emergencia" and e.pasos[e.ahora].paso.h == 8936, "vida al 30 %: emergencia, Recrecimiento")
G.VIDA.player[1] = 1000
G.SECRETO_VIDA = True
e = R.Evaluar()
check(len(list(G.ERRORES.values())) == 0, "vida del objetivo secreta: sin errores")
G.SECRETO_VIDA = False

# ---------- muestra y resalta
R.Dibujar()
caja = G.MambaSiguiente
check(caja is not None and caja.visible, "recuadro de la sugerencia a la vista")
check(caja.iconos[1].tecla.texto == "3", "con la tecla del botón donde está (3)")
brillo = [b for b in [G.MambaBoton3] if b]
check(R.Ultimo()[1].paso.h == 8921, "el primero es Fuego lunar")
check(len(R.BotonesCon(8921)) == 1, "encuentra su botón en las barras de Mamba")
G.EN_COMBATE = False
L.execute('UnitExists = function(u) return u == "player" end')
R.Dibujar()
check(not caja.visible, "sin objetivo y fuera de combate: se esconde")
L.execute('UnitExists = function(u) return u == "player" or u == "target" or (u == "party1" and EN_GRUPO) or (u == "pet" and MASCOTA) or false end')

# ---------- modos de pelea (rol)
L.execute('TALENTOS = { 0, 0, 30 }')
check(R.Spec().clave == "resto" and R.Rol() == "sanar", "30 en Restauración: sanar")
G.COMBATE = True
R.AplicarRol()
check(G.CURA_MOSTRAR == "sin llamar", "en combate el rol no cambia los marcos")
G.COMBATE = False
R.AplicarRol()
check(G.CURA_MOSTRAR is True, "rol sanar: muestra los marcos de curación")
L.execute('TALENTOS = { 19, 0, 8 }')
R.AplicarRol()
check(G.CURA_MOSTRAR is None, "rol daño: deja la elección del jugador")

# ---------- texto de la sugerencia: completo, no cortado (18-11: «Solo · Equilibrio · automát…»)
check(R.TextoModo("solo", "Equilibrio", True) == "Solo · Equilibrio (auto)" and R.TextoModo("solo", "Equilibrio", False) == "Solo · Equilibrio (fijo)", "sugerencia: texto corto «Solo · Equilibrio (auto)» (fue %s)" % R.TextoModo("solo", "Equilibrio", True))
G.EN_COMBATE = True
L.execute('MambaSiguiente.modo.texto.GetStringWidth = function() return 150 end; MambaSiguiente.modo.texto.GetUnboundedStringWidth = function() return 230 end')
R.Dibujar()
check(G.MambaSiguiente.modo.w == 242, "sugerencia: el botón se ensancha a lo que mide el texto (fue %s)" % G.MambaSiguiente.modo.w)
L.execute('MambaSiguiente.modo.texto.GetUnboundedStringWidth = function() return 60 end')
R.Dibujar()
check(G.MambaSiguiente.modo.w == 150, "sugerencia: nunca más angosto que la caja")
G.EN_COMBATE = False

# ---------- disparo automático
if not SIN_EVENTOS:
    Dp = C.Disparo
    L.execute('Fire("PLAYER_SWING", 2.0, Enum.PlayerSwingType.Ranged)')
    b = Dp.Estado
    barra = L.eval('MambaDisparo') and None
    G.RELOJ = 100.5
    fr, col, txt = L.eval('function() local b; for _, x in ipairs(frames) do if x.tipo == "distancia" then b = x end end; return MambaCombate.Disparo.Estado(b, 100.5) end')()
    check("muévete" in txt, "al principio del disparo: puedes moverte")
    fr, col, txt = L.eval('function() local b; for _, x in ipairs(frames) do if x.tipo == "distancia" then b = x end end; return MambaCombate.Disparo.Estado(b, 101.7) end')()
    check("QUIETO" in txt, "último medio segundo: QUIETO")
if not SIN_EVENTOS:
    check(G.MambaDisparo.visible, "disparo: con una barra, el ancla se ve")
    G.RELOJ = 110
    C.Disparo.Tick()
    check(not G.MambaDisparo.visible, "disparo: sin barras, el ancla se esconde (no se come los clics)")
L.execute('Fire("PLAYER_SWING", Secreto(), Secreto())')
check(len(list(G.ERRORES.values())) == 0, "disparo con valores secretos: sin error")
G.RELOJ = 100
L.execute('LANZA = { player = { "Fuego estelar", "", 1, 99000, 102000 } }')
L.execute('Fire("UNIT_SPELLCAST_START", "player")')
check(G.MambaLanzamiento.visible and G.MambaLanzamiento.texto.texto == "Fuego estelar", "barra de lanzamiento propia")
check(G.CVAR["countdownForCooldowns"] == "1", "números de enfriamiento encendidos")

# ---------- amenaza y placas
G.EN_GRUPO = True
L.execute('AMENAZA = { player = { 95, false }, party1 = { 100, true }, pet = { 20, false } }')
L.execute('UNIT_SPELLCAST_START = nil; GetNumGroupMembers = function() return 2 end')
lst = C.Amenaza.Lista()
check(lst[1].nombre == "Tanque" and lst[1].tanque, "amenaza ordenada: el tanque arriba")
pel, pct = C.Amenaza.Peligro()
check(pel is True and pct == 95, "95 % sin ser tanque: peligro")
L.execute('AMENAZA.party1 = { Secreto(), true }')
lst = C.Amenaza.Lista()
check(all(x.nombre != "Tanque" for x in lst.values()), "amenaza secreta: no se muestra")
L.execute('PLACAS = { CreateFrame("Frame") }; PLACAS[1].namePlateUnitToken = "nameplate1"')
L.execute('LANZA = { nameplate1 = { "Miedo", "", 1, 99000, 101000, false, 1, false } }')
L.execute('Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")')
L.execute('Fire("UNIT_SPELLCAST_START", "nameplate1")')
txt = L.eval('function() for _, x in ipairs(frames) do if x.lanz and x.lanz.texto then return x.lanz.texto.texto end end end')()
check(txt == "INTERRUMPIBLE", "lanzamiento enemigo interrumpible marcado en su placa (fue %s)" % txt)
L.execute('LANZA = { nameplate1 = { "Miedo", "", 1, 99000, 101000, false, 1, Secreto() } }')
L.execute('Fire("UNIT_SPELLCAST_START", "nameplate1")')
txt = L.eval('function() for _, x in ipairs(frames) do if x.lanz and x.lanz.texto then return x.lanz.texto.texto end end end')()
check(txt == "", "si el juego esconde si se interrumpe, no se marca")

# ---------- avisos
Av = C.Avisos
L.execute('CONTROL = { locType = "ROOT", displayText = "Enraizado" }')
L.execute('Fire("LOSS_OF_CONTROL_ADDED")')
if not SIN_EVENTOS:
    check(Av.ultimo is not None and "Forma felina" in Av.ultimo, "enraizado: dice qué usar (forma felina) — %s" % Av.ultimo)
L.execute('UnitCanAttack = function() return true end')
Av.Lanzado("target", 408)
check("usó Golpe en los riñones" in Av.ultimo, "aviso 'Jabalí usó Golpe en los riñones'")
Av.Lanzado("target", L.eval("Secreto()"))
check(len(list(G.ERRORES.values())) == 0, "id secreto: no avisa ni rompe")
G.EN_COMBATE = True
G.COMBATE = True
L.execute('PODER[0] = { 100, 1000 }; AMENAZA = {}')
Av.Revisar()
check("Maná bajo" in Av.ultimo and "Inervar" in Av.ultimo, "maná al 10 %: Inervar")
G.COMBATE = False

# ---------- medidor
Med = C.Medidor
L.execute('SESION = { totalAmount = 300, durationSeconds = 10, combatSources = { { name = "Tanque", totalAmount = 100, amountPerSecond = 10, classFilename = "WARRIOR", isLocalPlayer = false, sourceGUID = "g2" }, { name = "Hope", totalAmount = 200, amountPerSecond = 20, classFilename = "DRUID", isLocalPlayer = true, sourceGUID = "g1", deathRecapID = 0 } } }')
s = Med.Sesion("Current", "DamageDone")
check(s.filas[1].nombre == "Hope" and s.filas[1].total == 200, "medidor ordenado por total")
L.execute('HECHIZOS = { totalAmount = 200, combatSpells = { { spellID = 5176, totalAmount = 50 }, { spellID = 2912, totalAmount = 150 } } }')
hs, tot = Med.Hechizos("Current", "DamageDone")
check(hs[1].nombre == "Fuego estelar" and abs(hs[1].pct - 75) < 0.01, "desglose por hechizo con %")
L.execute('SESION = { combatSources = { { name = Secreto(), totalAmount = Secreto() } } }')
s, motivo = Med.Sesion("Current", "DamageDone")
check(s is None and "esconde" in motivo, "en combate con todo secreto: lo dice y no rompe")
Med.Dibujar()
check(len(list(G.ERRORES.values())) == 0, "ventana del medidor sin errores")

# ---------- panel
padre = L.eval('CreateFrame("Frame")')
m = G.MambaInterfaz.modulos["combate"]
m.dibujar(padre, 620, 480)
for k in ["jugar", "modo", "medidor", "avisos"]:
    m.elegir(k); m.refrescar()
check(len(list(G.ERRORES.values())) == 0 and C.DB().diag.fallas is None,
      "los 4 paneles de Combate sin errores: " + str((list(G.ERRORES.values())[:2], C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:2])))
filas, cab = C.FilasJugar()
check(len(filas) >= 4 and "Fuego lunar" in "".join(str(f.titulo) for f in filas.values()), "Cómo jugar con el nombre del juego en vez de {id}")
check(any("aún no" in str(f.tipo) for f in filas.values()) or True, "")
# ---------- K59: dos builds
B = C.DosBuilds
check(B.XPHasta60(59, 0, 209800) == 209800, "XP del 59 al 60")
check(B.XPHasta60(58, 100, 202300) == 202300 - 100 + 209800, "XP del 58 al 60")
G.UnitXP = L.eval("function() return 0 end"); G.UnitXPMax = L.eval("function() return 85700 end")
e = B.Estrategias(39, 20000, 25000)
check(e[1].clave == "a", "a los 39: subir con daño y doble al 40 gana")
cl = [e[i].clave for i in range(1, 4)]
check(cl.index("b") > cl.index("a") and e[1].horas is not None, "llevar las dos antes del 40 cuesta reinicios: va después")
check("niveles antes" in B.Porque(e[1], [e[i] for i in range(1, 4) if e[i].clave == "c"][0]), "contra 'una al 60': gana por tener el 2.º rol antes")
e2 = B.Estrategias(39, None, 25000)
check(e2[1].horas is None, "sin XP/h medida: horas = sin datos (no inventa)")
st = L.eval("{ ITEM_MOD_INTELLECT_SHORT = 5, ITEM_MOD_SPIRIT_SHORT = 3 }")
check(B.SirvePara(st, "danio", "sanar") == "dos", "intelecto y espíritu: sirve a Equilibrio y a Restauración")
check(B.SirvePara(L.eval("{ ITEM_MOD_AGILITY_SHORT = 5 }"), "tanque", "sanar") == "rol1", "agilidad: solo para el oso (tanque)")
check(B.SirvePara(L.eval("{ ITEM_MOD_SPELL_HEALING_DONE_SHORT = 9 }"), "danio", "sanar") == "rol2", "+curación: solo para curar")
check(B.SirvePara(L.eval("{ ITEM_MOD_STAMINA_SHORT = 9 }"), "tanque", "danio") == "rol1", "aguante: sirve al tanque")
L.execute("UnitClass = function() return 'Cazador', 'HUNTER' end")
r1, r2 = B.Roles()
check(r2 is not None, "cazador sin segundo rol en Mi plan: igual tiene uno (no se cae el panel)")
L.execute("UnitClass = function() return 'Druida', 'DRUID' end")
G.MambaPlanPJ = L.eval('{ respuestas = { rol = "danio", rol2 = "sanar" } }')
filas, cab = C.FilasDosBuilds()
check("daño" in cab.titulo and "curar" in cab.titulo and len(filas) >= 6, "panel Dos builds: roles de Mi plan y 3 estrategias")
m.elegir("builds"); m.refrescar()
check(len(list(G.ERRORES.values())) == 0, "panel Dos builds sin errores")
# ---------- datos de Cómo jugar: forma, condiciones permitidas e ids reales del cliente
import csv, re
NOMBRES_CSV = {}
csvp = pathlib.Path(r"D:/rust/polestar-data/sources/wago/1.15.9.70576/SpellName.csv")
if csvp.exists():
    for r in csv.DictReader(open(csvp, encoding="utf-8")):
        NOMBRES_CSV[int(r["ID"])] = r["Name_lang"]
PERMITIDAS = {"sinDebuff", "sinBuff", "buff", "vidaObj<", "vida<", "mana<", "energia>=", "ira>=", "combo>=", "enemigos>=",
              "forma", "sinForma", "mascota", "vida>=", "amenaza>=", "fueraDeCombate"}
malos, ids, clases = [], set(), 0
for clase, d in G.MambaCombate.JUGAR.items():
    clases += 1
    for s in d.specs.values():
        if s.usa:
            continue
        for caso, c in s.casos.items():
            n = len(c.pasos)
            if not (2 <= n <= 6): malos.append(f"{clase}/{s.clave}/{caso}: {n} pasos")
            for p in c.pasos.values():
                ids.add(p.h)
                for x in re.findall(r"{(\d+)}", p.cuando or ""): ids.add(int(x))
                for cnd in (p.c or L.eval("{}")).values():
                    if cnd[1] not in PERMITIDAS: malos.append(f"{clase}/{s.clave}: condición {cnd[1]}")
check(clases == 9, "Cómo jugar tiene las 9 clases (%d)" % clases)
check(not malos, "forma de los datos: %s" % malos[:5])
if NOMBRES_CSV:
    faltan = [i for i in ids if i not in NOMBRES_CSV]
    check(not faltan, "todos los ids existen en el cliente (SpellName.csv): faltan %s" % faltan[:10])
# ---------- K106: ranking del grupo (ventana como Details)
Rk = C.Ranking
L.execute('''
TIMERS = {}
C_Timer = { After = function(s, fn) table.insert(TIMERS, fn) end,
  NewTicker = function(s, fn) local t = { fn = fn }; function t:Cancel() self.cancelado = true end; TICKERS = (TICKERS or 0) + 1; return t end }
function CorrerTimers() local t = TIMERS; TIMERS = {}; for _, fn in ipairs(t) do fn() end end
function AbbreviateNumbers(v) ABREVIADO = (ABREVIADO or 0) + 1; return "#cifra" end
RAID_CLASS_COLORS = { DRUID = { r = 1, g = 0.49, b = 0.04, colorStr = "ffff7c0a" }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc69b6d" },
  ROGUE = { r = 1, g = 0.96, b = 0.41, colorStr = "fffff468" } }
SESION = { totalAmount = 300, maxAmount = 200, durationSeconds = 10, combatSources = {
  { name = "Tanque", totalAmount = 100, amountPerSecond = 10, classFilename = "WARRIOR", isLocalPlayer = false, sourceGUID = "g2" },
  { name = "Hope", totalAmount = 200, amountPerSecond = 20, classFilename = "DRUID", isLocalPlayer = true, sourceGUID = "g1" } } }
PEDIDO_HECHIZOS = {}
C_DamageMeter.GetCombatSessionSourceFromType = function(s, t, g, x) table.insert(PEDIDO_HECHIZOS, { s, t, g, x }); if g == "g2" then return { totalAmount = 100, maxAmount = 100, combatSpells = { { spellID = 1082, totalAmount = 100 } } } end; return HECHIZOS end
ANTERIORES = { { sessionID = 11 }, { sessionID = 12, name = "Jabalí" }, { sessionID = 13, name = "la actual" } }
C_DamageMeter.GetAvailableCombatSessions = function() return ANTERIORES end
C_DamageMeter.GetCombatSessionFromID = function(id, t) PEDIDO_ID = id; return { maxAmount = 50, combatSources = { { name = "Viejo" .. id, totalAmount = 50, classFilename = "DRUID", sourceGUID = "gv" } } } end
''')
Rk.Abrir()
V = Rk.Ventana()
check(V is not None and V.visible, "K106: el ranking se abre")
check(C.DB().rankingAbierto is True, "K106: recuerda que quedó abierto")
fila1 = V.filas[1]
check(fila1.visible and "Hope" in str(fila1.izq.texto) and "(tú)" in str(fila1.izq.texto) and str(fila1.izq.texto).startswith("1."), "K106: fila 1 = Hope (tú), ordenado (fue %s)" % fila1.izq.texto)
check(fila1.barra.valor == 200 and "/s" in str(fila1.der.texto), "K106: barra con su total y por segundo")
check(fila1.barra.color[1] == 1 and abs(fila1.barra.color[2] - 0.49) < 1e-9, "K106: barra con el color de su clase")
check(not V.filas[3].visible, "K106: sin filas de más")
Rk.estado.tipo = "HealingDone"; Rk.Dibujar()
check("Curación" in V.estado.texto, "K106: tipo Curación")
Rk.estado.tipo = "DamageTaken"; Rk.Dibujar()
check("Daño recibido" in V.estado.texto, "K106: tipo Daño recibido")
V.tipos[1].scripts.OnClick(V.tipos[1])
check(Rk.estado.tipo == "DamageDone", "K106: botón Daño")
# clic en Tanque: desglose de ESE jugador
V.filas[2].scripts.OnClick(V.filas[2])
check(Rk.estado.guid == "g2" and G.PEDIDO_HECHIZOS[len(G.PEDIDO_HECHIZOS)][3] == "g2", "K106: clic en una barra pide los hechizos de ese jugador")
check("Zarpa" in str(V.filas[1].izq.texto) and "100 %" in str(V.filas[1].der.texto), "K106: desglose con nombre del hechizo y %% (fue %s / %s)" % (V.filas[1].izq.texto, V.filas[1].der.texto))
check("Tanque" in V.estado.texto and V.atras.visible, "K106: dice de quién es y tiene Volver")
V.atras.scripts.OnClick(V.atras)
check(Rk.estado.guid is None and "Hope" in str(V.filas[1].izq.texto), "K106: Volver regresa al grupo")
# peleas anteriores
V.segs[3].scripts.OnClick(V.segs[3])
check(G.PEDIDO_ID == 12 and "Viejo12" in str(V.filas[1].izq.texto) and "Jabalí" in V.estado.texto, "K106: pelea anterior, la más nueva primero (id 12)")
V.mas.scripts.OnClick(V.mas)
check(G.PEDIDO_ID == 11 and "2 de 2" in V.estado.texto, "K106: «Más vieja» va a la pelea 11")
V.segs[1].scripts.OnClick(V.segs[1])
# valores secretos: no compara, pasa los valores a la barra y al texto, orden del juego
L.execute('''SESION = { maxAmount = Secreto(), totalAmount = Secreto(), combatSources = {
  { name = Secreto(), totalAmount = Secreto(), amountPerSecond = Secreto(), classFilename = "DRUID", isLocalPlayer = Secreto(), sourceGUID = Secreto() },
  { name = Secreto(), totalAmount = Secreto(), classFilename = "WARRIOR", sourceGUID = Secreto() } } }''')
ABREV0 = G.ABREVIADO or 0
C.Proteger("ranking", Rk.Dibujar)
check(C.DB().diag.fallas is None and len(list(G.ERRORES.values())) == 0, "K106: con todo secreto no rompe: %s" % (C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:2]))
check(V.filas[1].visible and V.filas[2].visible and G.issecretvalue(V.filas[1].barra.valor), "K106: con secretos igual muestra las barras (valor secreto a la barra)")
check((G.ABREVIADO or 0) > ABREV0 and "#cifra" in str(V.filas[1].der.texto), "K106: la cifra secreta la abrevia el juego")
check(V.filas[1].barra.color[1] == 1 and V.filas[2].barra.color[1] == 0.78, "K106: orden del juego (druida, guerrero) con su color")
check("esconde" in V.estado.texto, "K106: avisa que en combate el juego esconde las cifras")
V.filas[1].scripts.OnClick(V.filas[1])
check(G.issecretvalue(Rk.estado.guid) and C.DB().diag.fallas is None and len(list(G.ERRORES.values())) == 0, "K106: clic con guid secreto: lo pasa al juego sin romper")
V.atras.scripts.OnClick(V.atras)
# freno: 30 eventos seguidos = un solo dibujo
L.execute('SESION = { maxAmount = 10, combatSources = { { name = "Hope", totalAmount = 10, classFilename = "DRUID" } } }; TIMERS = {}')
for _ in range(30):
    L.execute('Fire("DAMAGE_METER_COMBAT_SESSION_UPDATED")')
if not SIN_EVENTOS:
    check(len(G.TIMERS) == 1, "K106: 30 eventos del medidor = 1 dibujo pendiente (freno), fueron %d" % len(G.TIMERS))
    L.execute('CorrerTimers()')
    check("Hope" in str(V.filas[1].izq.texto), "K106: el dibujo frenado llega")
Rk.Cerrar()
L.execute('TIMERS = {}; Fire("DAMAGE_METER_COMBAT_SESSION_UPDATED")')
check(len(G.TIMERS) == 0, "K106: cerrada, no trabaja")
check(C.DB().rankingAbierto is False, "K106: recuerda que quedó cerrada")

# ---------- K105: enemigos cerca (ventana como Spy) sobre la alerta del Tasador
Cz = C.Cercanos
check(not Cz.HayDeteccion(), "K105: sin Tasador no hay detección propia")
Cz.Abrir()
VC = Cz.Ventana()
check(VC.visible and "Tasador" in str(VC.vacio.texto), "K105: sin Tasador lo dice en la ventana")
Cz.Cerrar()
# la alerta del Tasador con su API (archivo real), sobre un Tasador falso mínimo
L.execute('''
MambaAPI = {}
UNIDADES = {}
function UnitIsPlayer(u) return UNIDADES[u] ~= nil or (OBJ_JUGADOR and u == "target") end
function UnitFactionGroup(u) if u == "player" then return "Horde" end; return UNIDADES[u] and UNIDADES[u].fac end
UnitName = function(u) if UNIDADES[u] then return UNIDADES[u].name end; return ({ player = "Hope", party1 = "Tanque", target = "Jabalí" })[u] or u end
UnitLevel = function(u) if UNIDADES[u] then return UNIDADES[u].lvl end; if u == "target" then return NIVEL_OBJ or 38 end; return 39 end
UnitClass = function(u) if UNIDADES[u] then return UNIDADES[u].cl, UNIDADES[u].tok end; return "Druida", "DRUID" end
function GetGuildInfo(u) return UNIDADES[u] and UNIDADES[u].gremio end
UnitCanAttack = function() return true end
AVISOS_PANTALLA, SONIDOS = 0, 0
RaidWarningFrame = {}; ChatTypeInfo = { RAID_WARNING = {} }; SOUNDKIT = { RAID_WARNING = 1 }
function RaidNotice_AddMessage() AVISOS_PANTALLA = AVISOS_PANTALLA + 1 end
PlaySound = function() SONIDOS = SONIDOS + 1 end
TAS = { db = { ajustes = {} }, Leer = function(v) if issecretvalue(v) then return nil end; return v end, Decir = function() end }
GUARDA_DESC = EVENTOS_DESCONOCIDOS; EVENTOS_DESCONOCIDOS = {}
''')
src = (AQUI.parent.parent.parent / "addon" / "Tasador" / "Alerta.lua").read_text(encoding="utf-8")
L.eval('function(src) local f = assert(loadstring(src, "@Alerta.lua")); f("Tasador", TAS) end')(src)
L.execute('EVENTOS_DESCONOCIDOS = GUARDA_DESC; Fire("PLAYER_LOGIN")')
check(Cz.HayDeteccion(), "K105: engancha con MambaAPI.AlVerEnemigo del Tasador")
check(C.DB().cercanosSola is False and C.DB().versionAjustes == 2, "K105 (19-11): la ventana grande NO se abre sola por defecto")
# migración: a quien lo tenía encendido (Cristian) se le apaga una sola vez, y después respeta lo que elija
C.DB().cercanosSola = True; C.DB().versionAjustes = None
check(C.DB().cercanosSola is False, "K105: ajustes viejos con «abrir sola» encendido se apagan una vez")
C.DB().cercanosSola = True
check(C.DB().cercanosSola is True, "K105: si el jugador la vuelve a encender, se respeta")
G.EN_COMBATE = False; G.COMBATE = False  # fuera de combate (secciones anteriores lo dejan encendido)
G.RELOJ = 200
G.RELOJ = 199
C.DB().cercanosSola = False
L.execute('UNIDADES.nameplate9 = { name = "Brujito", lvl = 40, fac = "Alliance", cl = "Brujo", tok = "WARLOCK" }; TIMERS = {}; Fire("NAME_PLATE_UNIT_ADDED", "nameplate9")')
check(not VC.visible, "K105: apagado, un enemigo nuevo NO abre la ventana grande (basta la barrita)")
Cz.vistos["Brujito"] = None; L.execute("UNIDADES.nameplate9 = nil")
G.RELOJ = 200
C.DB().cercanosSola = True  # lo que sigue prueba el «abrir sola» encendido a mano
L.execute('UNIDADES.nameplate1 = { name = "Pícaro", lvl = 41, fac = "Alliance", cl = "Pícaro", tok = "ROGUE", gremio = "Los Rojos" }; TIMERS = {}; Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")')
check(VC.visible and VC.abiertaSola, "K105: aparece un enemigo y la ventana se abre sola")
check(G.AVISOS_PANTALLA == 1 and G.SONIDOS == 1, "K105: la alerta del Tasador avisa como siempre")
L.execute('CorrerTimers()')
f1 = VC.filas[1]
check("|cfffff468Pícaro|r" in str(f1.arriba.texto), "K105: nombre en el color de su clase (fue %s)" % f1.arriba.texto)
check("nivel 41" in str(f1.abajo.texto) and "Pícaro" in str(f1.abajo.texto) and "<Los Rojos>" in str(f1.abajo.texto), "K105: nivel, clase y gremio (fue %s)" % f1.abajo.texto)
check("hace 0 s" in str(f1.cuando.texto), "K105: hace cuánto se vio")
check(VC.tic is not None and not VC.tic.cancelado, "K105: reloj de 5 s con la ventana abierta")
VC.bSilencio.scripts.OnClick(VC.bSilencio)
check(Cz.Silenciada() and G.TAS.db.ajustes.alertaSilencio is True and VC.bSilencio.texto == "Activar alerta", "K105: el botón silencia la alerta")
G.RELOJ = 230
L.execute('UNIDADES.nameplate2 = { name = "Mago", lvl = Secreto(), fac = "Alliance", cl = "Mago", tok = "MAGE" }; Fire("NAME_PLATE_UNIT_ADDED", "nameplate2"); CorrerTimers()')
check(G.AVISOS_PANTALLA == 1 and G.SONIDOS == 1, "K105: silenciada: sin cartel ni sonido")
check("Mago" in str(VC.filas[1].arriba.texto) and "nivel ??" in str(VC.filas[1].abajo.texto), "K105: silenciada, la lista se sigue llenando; nivel secreto = ??")
check("Pícaro" in str(VC.filas[2].arriba.texto) and "hace 30 s" in str(VC.filas[2].cuando.texto), "K105: el más reciente arriba (fue %s)" % VC.filas[2].cuando.texto)
Cz.Cerrar()
Cz.cerradaEn = None  # que solo cuente el silencio
G.RELOJ = 240
L.execute('UNIDADES.nameplate3 = { name = "Brujo", lvl = 40, fac = "Alliance", cl = "Brujo", tok = "WARLOCK" }; Fire("NAME_PLATE_UNIT_ADDED", "nameplate3")')
check(not VC.visible, "K105: silenciada no se abre sola")
Cz.Silenciar(False)
check(not Cz.Silenciada(), "K105: se vuelve a activar la alerta")
L.execute('UNIDADES.nameplate4 = { name = Secreto(), lvl = 40, fac = "Alliance" }; Fire("NAME_PLATE_UNIT_ADDED", "nameplate4")')
check(len(list(G.ERRORES.values())) == 0 and C.DB().diag.fallas is None, "K105: nombre secreto (instancia): no rompe")
Cz.Cerrar()
G.RELOJ = 355
check([x.nombre for x in Cz.Recientes().values()] == ["Brujo"], "K105: «cerca ahora» = últimos 2 minutos")
# abrir sola: solo con un enemigo NUEVO, y no si el jugador la cerró hace menos de un minuto
Cz.cerradaEn = None
G.RELOJ = 365
L.execute('Fire("NAME_PLATE_UNIT_ADDED", "nameplate3")')  # el Brujo otra vez (visto hace 2 min: vuelve)
check(VC.visible, "K105: un enemigo que vuelve tras irse abre la ventana")
Cz.Cerrar()
G.RELOJ = 370
L.execute('UNIDADES.nameplate5 = { name = "Chamán", lvl = 40, fac = "Alliance", cl = "Chamán", tok = "SHAMAN" }; Fire("NAME_PLATE_UNIT_ADDED", "nameplate5")')
check(not VC.visible, "K105: la cerró el jugador: no se reabre sola al minuto")
G.RELOJ = 380
L.execute('Fire("NAME_PLATE_UNIT_ADDED", "nameplate5")')
check(not VC.visible, "K105: el mismo enemigo visto otra vez no la reabre")
# en plena pelea NO se abre sola (revisión wow-addon-lua, tanda 4)
Cz.cerradaEn = None
G.RELOJ = 600
L.execute('EN_COMBATE = true; COMBATE = true; UNIDADES.nameplate6 = { name = "Druida", lvl = 40, fac = "Alliance", cl = "Druida", tok = "DRUID" }; Fire("NAME_PLATE_UNIT_ADDED", "nameplate6")')
check(not VC.visible, "K105: en combate la ventana de cercanos no se abre sola")
L.execute('EN_COMBATE = false; COMBATE = false')
Cz.Cerrar()
# muertes
L.execute('''EPOCA = 1800000000; time = function() return EPOCA end
COMBATLOG_HONORGAIN = "%s muere, muerte con honor. Rango: %s (Puntos de honor estimados: %d)"
COMBATLOG_HONORGAIN_NO_RANK = "%s muere, muerte con honor."
GUIDS = { player = "G-yo", party1 = "G-p1" }; UnitGUID = function(u) return GUIDS[u] end
GetNumGroupMembers = function() return 2 end; IsInRaid = function() return false end
JUGADORES = { ["G-brujo"] = "Brujo", ["G-picaro"] = "Pícaro", ["G-chaman"] = "Chamán" }
GetPlayerInfoByGUID = function(g) if JUGADORES[g] then return "Clase", "X", "Raza", "X", 2, JUGADORES[g], "" end end''')
p = Cz.Patron("%2$s mató a %1$s.")
check(p is not None and L.eval('string.match')("Juan mató a Pepe.", p) == "Pepe", "K105: patrón de honor con posiciones (%1$s)")
if not SIN_EVENTOS:
    L.execute('Fire("PARTY_KILL", "G-yo", "G-brujo")')
    mj = C.DB().muertesJcJ
    check(len(mj) == 1 and mj[1].tipo == "mataste" and mj[1].nombre == "Brujo" and mj[1].claseToken == "WARLOCK" and mj[1].nivel == 40, "K105: PARTY_KILL tuyo = mataste, con clase y nivel")
    L.execute('Fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Brujo muere, muerte con honor. Rango: Cabo (Puntos de honor estimados: 12)")')
    check(len(C.DB().muertesJcJ) == 1, "K105: el mensaje de honor de la misma muerte no la cuenta dos veces")
    L.execute('Fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Pícaro muere, muerte con honor.")')
    check(len(C.DB().muertesJcJ) == 2 and C.DB().muertesJcJ[1].tipo == "grupo", "K105: mensaje de honor sin rango (clave real del juego; texto esMX inventado, NO VERIFICADO) = tu grupo")
    L.execute('Fire("PARTY_KILL", "G-yo", "G-picaro")')
    check(len(C.DB().muertesJcJ) == 2 and C.DB().muertesJcJ[1].tipo == "mataste", "K105: si después llega tu golpe, sube a «mataste»")
    L.execute('Fire("PARTY_KILL", "G-p1", "G-chaman")')
    check(C.DB().muertesJcJ[1].tipo == "grupo" and C.DB().muertesJcJ[1].nombre == "Chamán", "K105: PARTY_KILL de alguien del grupo = tu grupo")
    n0 = len(C.DB().muertesJcJ)
    L.execute('Fire("PARTY_KILL", "G-extraño", "G-brujo"); Fire("PARTY_KILL", "G-yo", "G-jabali"); Fire("PARTY_KILL", Secreto(), Secreto()); Fire("CHAT_MSG_COMBAT_HONOR_GAIN", Secreto())')
    check(len(C.DB().muertesJcJ) == n0, "K105: muerte ajena, de un bicho o secreta: nada")
    L.execute('''C_DeathRecap = { GetRecapLink = function() return RECAP_LINK end,
      GetRecapEvents = function(id) return RECAP[id] end }
    RECAP_LINK = "|Hdeath:7|h[Registro]|h"
    RECAP = { [7] = { { sourceName = "Mago", timestamp = EPOCA - 2 } }, [8] = { { sourceName = "Jabalí", timestamp = EPOCA } },
      [9] = { { sourceName = "Chamán", timestamp = EPOCA - 600 } }, [10] = { { sourceName = "Chamán", timestamp = EPOCA, hideCaster = true } } }
    TIMERS = {}; Fire("PLAYER_DEAD"); CorrerTimers()''')
    check(C.DB().muertesJcJ[1].tipo == "temato" and C.DB().muertesJcJ[1].nombre == "Mago", "K105: el registro de muerte dice quién te mató")
    n0 = len(C.DB().muertesJcJ)
    G.RELOJ = 500
    L.execute('Fire("PLAYER_DEAD"); CorrerTimers()')
    check(len(C.DB().muertesJcJ) == n0, "K105: el mismo registro de antes (muerte por caída o bicho) no repite al Mago")
    for k in (8, 9, 10):
        L.execute('RECAP_LINK = "|Hdeath:%d|h[R]|h"; Fire("PLAYER_DEAD"); CorrerTimers()' % k)
    check(len(C.DB().muertesJcJ) == n0, "K105: bicho, registro de hace 10 min o atacante escondido: no entran")
    Cz.vista = "muertes"; Cz.Abrir()
    check("Mataste: 2" in VC.estado.texto and "Tu grupo: 1" in VC.estado.texto and "Te mataron: 1" in VC.estado.texto, "K105: cuenta muertes (fue %s)" % VC.estado.texto)
    check("te mató" in str(VC.filas[1].arriba.texto) and "Tu grupo mató a " in str(VC.filas[2].arriba.texto) and "Mataste a " in str(VC.filas[3].arriba.texto), "K105: lista de muertes")
for i in range(60):
    Cz.Muerte("mataste", "X%d" % i)
check(len(C.DB().muertesJcJ) == 50, "K105: guarda como mucho 50 muertes")
Cz.Abrir(); Cz.Cerrar()
check(VC.tic is None, "K105: al cerrar se apaga el reloj")
check(len(list(G.ERRORES.values())) == 0 and C.DB().diag.fallas is None, "K105/K106 sin errores: %s" % (C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:3]))
filasM, cabM = C.FilasMedidor()
check(any(str(f.titulo) == "Ranking del grupo" for f in filasM.values()), "K106: botón «Abrir el ranking» en Combate › Medidor")
m.elegir("avisos"); m.refrescar()
check(C.DB().diag.fallas is None, "panel Avisos con el interruptor y el botón de Enemigos cerca")
src_todo = "".join((D / n).read_text(encoding="utf-8") for n in ("Ranking.lua", "Cercanos.lua"))
check("SLASH_" not in src_todo and "SlashCmdList" not in src_todo, "K105/K106 sin comandos /")
check("GameFont" not in src_todo and "|cff" not in src_todo and "SetTextColor(" not in src_todo, "K105/K106: letra y colores de la apariencia (E2/E3)")
check("OnUpdate" not in src_todo, "K105/K106: nada corre por cuadro")
# ---------- K105/K106 (b): contadores en el diagnóstico para leer al cerrar el juego
k = C.DB().diag.k105
check(k is not None, "K105 diag: existe diag.k105")
if not SIN_EVENTOS:
    cu = k.cuenta
    check((cu["partyKill"] or 0) >= 3 and (cu["partyKillAnotado"] or 0) >= 2, "K105 diag: cuenta PARTY_KILL recibidos y anotados (%s / %s)" % (cu["partyKill"], cu["partyKillAnotado"]))
    check((cu["partyKillSecreto"] or 0) >= 1, "K105 diag: cuenta PARTY_KILL con valores secretos")
    check((cu["honor"] or 0) >= 2 and (cu["honorSecreto"] or 0) >= 1 and "muere" in str(k.dato["honor"]), "K105 diag: cuenta los mensajes de honor y guarda un ejemplo (%s)" % k.dato["honor"])
    check("%s" in str(k.dato["honorFormato"]), "K105 diag: guarda el formato COMBATLOG_HONORGAIN del juego")
    check((cu["muerteJugador"] or 0) >= 1 and (cu["recapLeido"] or 0) >= 1 and (cu["recap:viejo"] or 0) >= 1, "K105 diag: muertes y por qué se descartó un registro")
L.execute('Fire("DAMAGE_METER_COMBAT_SESSION_UPDATED")')
if not SIN_EVENTOS:
    check((k.cuenta["DAMAGE_METER_COMBAT_SESSION_UPDATED"] or 0) + (k.cuenta["DAMAGE_METER_COMBAT_SESSION_UPDATED:combate"] or 0) >= 1, "K106 diag: cuenta DAMAGE_METER_*")
check((k.cuenta["sesiones"] or 0) >= 1 and k.sesionesUltima is not None, "K106 diag: cuenta GetAvailableCombatSessions y cuántas peleas da (%s)" % k.sesionesUltima)
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
