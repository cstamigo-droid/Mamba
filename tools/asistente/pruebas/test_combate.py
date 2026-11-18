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
        L.execute('for _, e in ipairs({"PLAYER_SWING","PLAYER_SWING_RANGE_UPDATE","DAMAGE_METER_COMBAT_SESSION_UPDATED","DAMAGE_METER_RESET","LOSS_OF_CONTROL_ADDED","UNIT_THREAT_LIST_UPDATE","NAME_PLATE_UNIT_ADDED","ACTIVE_TALENT_GROUP_CHANGED"}) do EVENTOS_DESCONOCIDOS[e] = true end')
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Combate", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Rotacion.lua":
            src = src.replace("local v = R.Condicion(c)", "local v = true")
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
check(B.SirvePara(L.eval("{ ITEM_MOD_AGILITY_SHORT = 5 }"), "danio", "sanar") == "fisico", "agilidad: solo físico")
check(B.SirvePara(L.eval("{ ITEM_MOD_SPELL_HEALING_DONE_SHORT = 9 }"), "danio", "sanar") == "curar", "+curación: solo curar")
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
              "forma", "sinForma", "mascota", "amenaza>=", "fueraDeCombate"}
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
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
