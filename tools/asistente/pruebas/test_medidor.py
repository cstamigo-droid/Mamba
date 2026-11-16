"""Pruebas del Medidor con Lua 5.1 (lupa). Uso: python test_medidor.py ../Medidor"""
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).parent.parent / "Medidor"
ARCHIVOS = ["Nucleo.lua", "Juego.lua", "Comandos.lua"]

# El .toc debe pedir Interface 16001, guardar MedidorDB y cargar los archivos en orden
toc = (D / "Medidor.toc").read_text(encoding="utf-8")
assert "## Interface: 16001" in toc and "## SavedVariables: MedidorDB" in toc, "toc"
assert [l for l in toc.splitlines() if l.endswith(".lua")] == ARCHIVOS, "orden del toc"

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((pathlib.Path(__file__).parent / "mock_medidor.lua").read_text(encoding="utf-8"))
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Medidor", M) end')
    for n in ARCHIVOS:
        cargar((D / n).read_text(encoding="utf-8"), n, M)
    return L, M


# ---------- 1. Cálculos puros ----------
L, M = nuevo()
check(M.Dinero(12345) == "1o 23p 45c", M.Dinero(12345))
check(M.Dinero(-250) == "-2p 50c", M.Dinero(-250))
check(M.Dinero(0) == "0c", "dinero 0")
check(M.Miles(1234567) == "1.234.567" and M.Miles(-1500) == "-1.500" and M.Miles(12) == "12", "miles")
check(M.DeltaXP(1000, 5000, 1800, 5000) == 800, "xp normal")
check(M.DeltaXP(4800, 5000, 300, 5600) == 500, "xp con subida de nivel: 200 que faltaban + 300")
check(M.DeltaXP(None, None, 300, 5600) == 0, "sin lectura previa no suma")
check(M.Actividad(True, "party", "farmeo") == "mazmorra", "mazmorra automática")
check(M.Actividad(True, "pvp", "farmeo") == "jcj", "campo de batalla automático")
check(M.Actividad(False, "none", "farmeo") == "farmeo", "afuera manda la elegida")
check(M.Actividad(False, "none", None) == "misiones", "por defecto misiones")

info = L.eval('function(id) local t = {[1]={100,0},[2]={50,1}}; local i=t[id]; if i then return i[1], i[2] end end')
sub = L.eval('function(id) return ({[1]=1000,[2]=99999})[id] end')
check(M.PrecioUnidad(1, info, sub) == 950, "subasta menos 5% de comisión")
check(M.PrecioUnidad(2, info, sub) == 50, "ligado al recoger: solo vendedor")
check(M.PrecioUnidad(3, info, sub) is None, "sin datos del objeto: nil")

prev = L.eval('{[1]=2, [5]=1}')
act = L.eval('{[1]=5, [7]=3}')
precio = L.eval('function(id) if id == 7 then return nil end return 10 end')
check(M.DiffValor(prev, act, precio) == 30 - 10, "diff: +3 del 1, -1 del 5, el 7 sin precio")
check(prev[1] == 5 and prev[5] is None and prev[7] is None, "el 7 queda pendiente para reintentar")
precio2 = L.eval('function(id) return 4 end')
check(M.DiffValor(prev, act, precio2) == 12 and prev[7] == 3, "reintento del 7 suma 3x4")

pp = L.eval('{[171]={nombre="Alquimia",rango=100}}')
up = M.DiffProf(pp, L.eval('{[171]={nombre="Alquimia",rango=103},[185]={nombre="Cocina",rango=50}}'))
check(up["Alquimia"] == 3 and up["Cocina"] is None, "profesión: +3, la nueva no suma")
check(pp[185].rango == 50, "la nueva queda como punto de partida")

# ---------- 2. Juego simulado de punta a punta ----------
L, M = nuevo()
L.execute('''
ITEMS[2447] = {10, 0}      -- Hojaplata: vendedor 10c
ITEMS[3820] = {25, 0}      -- Raíz de sangre
ITEMS[118] = {5, 0}        -- poción menor
PRECIOS[2447] = 2000       -- subasta 20p -> neto 19p
PROF[1] = {"Alquimia", 120, 171}; PROF[2] = {"Herboristería", 130, 182}; PROF[5] = {"Cocina", 80, 185}
BOLSA[1] = {itemID=2447, stackCount=2}
PUESTO[1] = 9999; ITEMS[9999] = {300, 1}
Fire("ADDON_LOADED", "Medidor")
Fire("PLAYER_ENTERING_WORLD")
''')
check(L.eval('MedidorDB.version') == 1 and L.eval('MedidorDB.pj["Hope-Reino"].act') == "misiones", "guardado inicial")

# 10 minutos de misiones en Mil Agujas
L.execute('''
for i = 1, 600 do Tick(1) end
P.xp = 3000; Fire("PLAYER_XP_UPDATE")
P.dinero = P.dinero + 5000; Fire("PLAYER_MONEY")       -- recompensa 50p
P.dinero = P.dinero - 1000; Fire("PLAYER_MONEY")       -- reparar 10p
BOLSA[1].stackCount = 7; BOLSA[2] = {itemID=3820, stackCount=1}; Fire("BAG_UPDATE_DELAYED")
PROF[2][2] = 134; Fire("SKILL_LINES_CHANGED")
''')
k = 'MedidorDB.pj["Hope-Reino"].cubos["Mil Agujas|misiones|37"]'
check(abs(L.eval(k + '.seg') - 600) < 1e-6, "600 s contados")
check(L.eval(k + '.xp') == 2000, "2000 exp")
check(L.eval(k + '.ganado') == 5000 and L.eval(k + '.gastado') == 1000, "dinero ganado/gastado")
check(L.eval(k + '.valor') == 5 * 1900 + 25, f"botín: 5 hojaplata a 19p + raíz 25c = {L.eval(k + '.valor')}")
check(L.eval(k + '.prof["Herboristería"]') == 4, "herboristería +4")

# Cambio de actividad y zona: cubos separados
L.execute('SlashCmdList.MEDIDOR("act farmeo"); P.zona = "Tierras Inhóspitas"; Fire("ZONE_CHANGED_NEW_AREA"); for i=1,300 do Tick(1) end')
k2 = 'MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|37"]'
check(abs(L.eval(k2 + '.seg') - 300) < 1e-6, "cubo nuevo por zona+actividad")
check(abs(L.eval(k + '.seg') - 600) < 1e-6, "el cubo viejo no cambia")

# Actividad desconocida no se acepta
L.execute('chat = {}; SlashCmdList.MEDIDOR("act bailar")')
check(L.eval('MedidorDB.pj["Hope-Reino"].act') == "farmeo" and "desconocida" in L.eval('chat[1]'), "actividad inválida rechazada")

# Pausa y ausente: el reloj no corre. Un cuadro largo (pantalla de carga) se recorta a 5 s.
L.execute('SlashCmdList.MEDIDOR("pausa"); Tick(100); SlashCmdList.MEDIDOR("pausa"); P.afk = true; Tick(100); P.afk = false; Tick(60)')
check(abs(L.eval(k2 + '.seg') - 305) < 1e-6, f"pausa/AFK/recorte: {L.eval(k2 + '.seg')}")

# Subir de nivel: UnitLevel se atrasa (sigue en 37) pero el evento trae 38: manda el evento
L.execute('P.xp = 4900; Fire("PLAYER_XP_UPDATE"); P.xp = 100; P.max = 6000; Fire("PLAYER_LEVEL_UP", 38); Fire("PLAYER_XP_UPDATE"); Tick(3)')
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].xp') == 200, "exp del salto (100 + 100) va al cubo del nivel 38 aunque UnitLevel se atrase")
L.execute('P.nivel = 38')
check(L.eval(k2 + '.xp') + L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].xp') == 1900 + 100 + 100, f"exp: 1900, luego 100 que faltaban + 100 del nivel nuevo: {L.eval(k2 + '.xp')}")
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].seg') == 3, "cubo del nivel 38")

# Vender al vendedor: dinero sube, botín baja; el total (dinero+botín) refleja la pérdida frente a la subasta
L.execute('''
local c = MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"]
v0, g0 = c.valor, c.ganado
BOLSA[1].stackCount = 6; P.dinero = P.dinero + 10; Fire("PLAYER_MONEY"); Fire("BAG_UPDATE_DELAYED")
v1, g1 = c.valor, c.ganado
''')
check(L.eval('g1 - g0') == 10 and L.eval('v1 - v0') == -1900, "venta a vendedor: +10c dinero, -19p botín")

# Precio fijo mientras tengas unidades: si la subasta sube, el botín no se "revaloriza"
L.execute('PRECIOS[2447] = 99999; v0 = MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].valor; BOLSA[1].stackCount = 7; Fire("BAG_UPDATE_DELAYED")')
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].valor - v0') == 1900, "usa el precio con que entró")

# Objeto que el juego todavía no carga: se pide y se cuenta después
L.execute('''
local c = MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"]
v0 = c.valor
BOLSA[3] = {itemID=4444, stackCount=2}; Fire("BAG_UPDATE_DELAYED")
v1 = c.valor
ITEMS[4444] = {7, 0}; Fire("BAG_UPDATE_DELAYED")
v2 = c.valor
''')
check(L.eval('v1 - v0') == 0 and L.eval('PEDIDOS[4444]') is True, "sin datos: no suma y lo pide")
check(L.eval('v2 - v1') == 14, "cuando llega el dato suma 2x7")

# Banco: guardar cosas en el banco no es pérdida
L.execute('''
local c = MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"]
v0 = c.valor
Fire("BANKFRAME_OPENED"); BOLSA[1] = nil; Fire("BAG_UPDATE_DELAYED"); Fire("BANKFRAME_CLOSED"); Fire("BAG_UPDATE_DELAYED")
''')
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].valor - v0') == 0, "banco no cuenta")

# Equiparse algo de las bolsas no cambia el valor (se cuentan bolsas + puesto)
L.execute('''
local c = MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"]
v0 = c.valor
ITEMS[777] = {500, 2}; BOLSA[4] = {itemID=777, stackCount=1}; Fire("BAG_UPDATE_DELAYED")
v1 = c.valor
BOLSA[4] = nil; PUESTO[5] = 777; Fire("PLAYER_EQUIPMENT_CHANGED"); Fire("BAG_UPDATE_DELAYED")
''')
check(L.eval('v1 - v0') == 500 and L.eval('MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"].valor - v1') == 0, "equiparse es neutro")

# ---- Correcciones del revisor externo ----
C38 = 'MedidorDB.pj["Hope-Reino"].cubos["Tierras Inhóspitas|farmeo|38"]'
# G1: en pausa no se suma exp, dinero ni botín (y no se suma después)
L.execute('x0, g0, v0 = %s.xp, %s.ganado, %s.valor' % (C38, C38, C38))
L.execute('SlashCmdList.MEDIDOR("pausa"); P.xp = P.xp + 1000; Fire("PLAYER_XP_UPDATE"); P.dinero = P.dinero + 50000; Fire("PLAYER_MONEY"); BOLSA[9] = {itemID=118, stackCount=4}; Fire("BAG_UPDATE_DELAYED"); SlashCmdList.MEDIDOR("pausa"); Fire("PLAYER_XP_UPDATE"); Fire("PLAYER_MONEY"); Fire("BAG_UPDATE_DELAYED")')
check(L.eval('%s.xp - x0' % C38) == 0 and L.eval('%s.ganado - g0' % C38) == 0 and L.eval('%s.valor - v0' % C38) == 0, "pausa: nada se suma, ni al reanudar")
# G2: sacar un objeto y volver a tenerlo con otro precio de subasta no es ganancia
L.execute('ITEMS[778] = {100, 2}; PRECIOS[778] = 1000; BOLSA[10] = {itemID=778, stackCount=1}; Fire("BAG_UPDATE_DELAYED"); v0 = %s.valor' % C38)
L.execute('BOLSA[10] = nil; Fire("BAG_UPDATE_DELAYED"); PRECIOS[778] = 100000; RELOJ = RELOJ + 3600; BOLSA[10] = {itemID=778, stackCount=1}; Fire("BAG_UPDATE_DELAYED")')
check(L.eval('%s.valor - v0' % C38) == 0, "sale y vuelve el mismo día: mismo precio, neto 0")
L.execute('BOLSA[10] = nil; Fire("BAG_UPDATE_DELAYED"); RELOJ = RELOJ + 4 * 86400; BOLSA[11] = {itemID=1, stackCount=0}; ITEMS[1] = {1,0}; Fire("BAG_UPDATE_DELAYED")')
check(L.eval('MedidorDB.pj["Hope-Reino"].precios[778]') is None, "tras 3 días sin tenerlo, el precio se olvida")
L.execute('BOLSA[11] = nil; Fire("BAG_UPDATE_DELAYED")')
# M1: una pantalla de carga no borra el botín que esperaba precio
L.execute('v0 = %s.valor; BOLSA[12] = {itemID=5555, stackCount=3}; Fire("BAG_UPDATE_DELAYED"); Fire("PLAYER_ENTERING_WORLD"); ITEMS[5555] = {100, 0}; Fire("BAG_UPDATE_DELAYED")' % C38)
check(L.eval('%s.valor - v0' % C38) == 300, "pantalla de carga conserva lo pendiente")
# M1b: lo pendiente que se guarda en el banco igual se cuenta cuando llega el precio
L.execute('v0 = %s.valor; BOLSA[13] = {itemID=6666, stackCount=2}; Fire("BAG_UPDATE_DELAYED"); Fire("BANKFRAME_OPENED"); BOLSA[13] = nil; Fire("BAG_UPDATE_DELAYED"); Fire("BANKFRAME_CLOSED"); ITEMS[6666] = {50, 0}; Fire("BAG_UPDATE_DELAYED")' % C38)
check(L.eval('%s.valor - v0' % C38) == 100, "pendiente guardado en el banco igual cuenta 2x50")
# M3: la bolsa 5 (componentes) se lee: mover algo entre bolsas es neutro
L.execute('v0 = %s.valor; COMPONENTES[1] = BOLSA[12]; BOLSA[12] = nil; Fire("BAG_UPDATE_DELAYED")' % C38)
check(L.eval('%s.valor - v0' % C38) == 0, "mover a la bolsa de componentes es neutro")
# Valores secretos: no rompe y la exp se cuenta en la siguiente lectura legible
L.execute('x0 = %s.xp; P.secreto = true; P.xp = P.xp + 500; Fire("PLAYER_XP_UPDATE"); P.secreto = false; Fire("PLAYER_XP_UPDATE")' % C38)
check(L.eval('%s.xp - x0' % C38) == 500, "exp secreta en combate se cuenta después")

# Mazmorra: la actividad se pone sola
L.execute('P.inst = true; P.tipo = "party"; P.zona = "Horado Rajacieno"; Fire("ZONE_CHANGED_NEW_AREA"); Tick(4)')
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Horado Rajacieno|mazmorra|38"].seg') == 4, "mazmorra automática en el juego")
HR = 'MedidorDB.pj["Hope-Reino"].cubos["Horado Rajacieno|mazmorra|38"]'
check(L.eval(HR + '.pasadas') == 1, "entrar a una mazmorra cuenta 1 pasada")
# Morir y volver corriendo antes de 15 min: misma pasada. Volver 20 min después: pasada nueva.
SALIR = 'P.inst = false; P.tipo = "none"; P.zona = "Tierras Inhóspitas"; Fire("ZONE_CHANGED_NEW_AREA")'
ENTRAR = 'P.inst = true; P.tipo = "party"; P.zona = "Horado Rajacieno"; Fire("ZONE_CHANGED_NEW_AREA")'
L.execute(SALIR + '; RELOJ = RELOJ + 120; ' + ENTRAR)
check(L.eval(HR + '.pasadas') == 1, "volver a la misma mazmorra antes de 15 min no es otra pasada")
L.execute(SALIR + '; RELOJ = RELOJ + 1200; ' + ENTRAR)
check(L.eval(HR + '.pasadas') == 2, "volver 20 min después es otra pasada")
# B1: reiniciar la mazmorra y volver enseguida es pasada nueva (mensaje del sistema)
L.execute(SALIR + '; RELOJ = RELOJ + 30; Fire("CHAT_MSG_SYSTEM", "Horado Rajacieno has been reset."); ' + ENTRAR)
check(L.eval(HR + '.pasadas') == 3, "reiniciar la mazmorra cuenta pasada nueva")
L.execute(SALIR + '; RELOJ = RELOJ + 30; Fire("CHAT_MSG_SYSTEM", "Hope se une al grupo."); ' + ENTRAR)
check(L.eval(HR + '.pasadas') == 3, "otro mensaje del sistema no cuenta pasada")
# B2: entrar en pausa igual cuenta la pasada
L.execute(SALIR + '; RELOJ = RELOJ + 1200; SlashCmdList.MEDIDOR("pausa"); ' + ENTRAR + '; SlashCmdList.MEDIDOR("pausa")')
check(L.eval(HR + '.pasadas') == 4, "entrar en pausa igual cuenta la pasada")
# B4: en la pantalla de carga la zona viene atrasada: manda el nombre de la instancia
L.execute(SALIR + '; RELOJ = RELOJ + 1200; P.inst = true; P.tipo = "party"; P.instNombre = "Horado Rajacieno"; P.zona = "Los Baldíos"; Fire("ZONE_CHANGED_NEW_AREA"); P.instNombre = nil')
check(L.eval(HR + '.pasadas') == 5, "nombre de la instancia aunque la zona venga atrasada")
check(L.eval('MedidorDB.pj["Hope-Reino"].cubos["Los Baldíos|mazmorra|38"]') is None, "no crea un cubo con la zona de afuera")
L.execute('P.zona = "Horado Rajacieno"')
L.execute(SALIR)

# Informes en el chat
L.execute('chat = {}; SlashCmdList.MEDIDOR(""); SlashCmdList.MEDIDOR("todo")')
chat = [str(x) for x in L.eval('chat').values()]
print("\n".join(chat))
check(any("Mil Agujas · misiones (nv 37): 10 min" in c and "12.000 exp/h" in c for c in chat), "exp por hora: 2000 en 10 min = 12.000/h")
check(any("Herboristería +24.0/h" in c for c in chat), "profesión por hora: 4 en 10 min = 24/h")
check(any("dinero 2o 40p/h" in c for c in chat), "dinero por hora: 40p en 10 min = 2o 40p/h")
check(any("poco tiempo" in c for c in chat), "menos de 5 min avisa poco tiempo")
check(any("Tierras Inhóspitas · farmeo (nv 37-38)" in c for c in chat), "agrupa niveles por zona+actividad")
check(any("Ahora: Tierras Inhóspitas · farmeo · nivel 38" in c for c in chat), "dice dónde estás")
check(any("Horado Rajacieno · mazmorra" in c and "5 pasadas" in c and "por pasada" in c for c in chat), "informe muestra pasadas")

# /medidor mejor: ordena por total por hora y deja fuera lo de menos de 5 min
L.execute('chat = {}; SlashCmdList.MEDIDOR("mejor")')
mejor = [str(x) for x in L.eval('chat').values()]
print("\n".join(mejor))
check(any(c.startswith("|cff66ccff[Medidor]|r 1. ") for c in mejor), "mejor numera")
check(not any("Horado Rajacieno" in c for c in mejor), "mejor deja fuera lo de menos de 5 min")

# Sesión nueva (recarga): lo guardado sigue, la sesión empieza en cero
# Se escribe MedidorDB como texto Lua (como hace el juego en SavedVariables) y se carga en otro Lua
DUMP = '''function(v)
  local function d(x)
    if type(x) == "table" then
      local t = {}
      for k, val in pairs(x) do t[#t+1] = "[" .. d(k) .. "]=" .. d(val) end
      return "{" .. table.concat(t, ",") .. "}"
    elseif type(x) == "string" then return string.format("%q", x)
    else return tostring(x) end
  end
  return "MedidorDB = " .. d(v)
end'''
texto = L.eval(DUMP)(L.eval('MedidorDB'))
L2, M2 = nuevo()
L2.execute(texto)  # el juego restaura SavedVariables antes de ADDON_LOADED
L2.execute('Fire("ADDON_LOADED", "Medidor"); Fire("PLAYER_ENTERING_WORLD")')
check(L2.eval('MedidorDB.pj["Hope-Reino"].act') == "farmeo", "actividad recordada")
check(L2.eval('next(MedidorDB.pj["Hope-Reino"].cubos)') is not None, "cubos guardados siguen")
L2.execute('chat = {}; SlashCmdList.MEDIDOR("")')
check("nada medido" in str(L2.eval('chat[1]')), "sesión nueva vacía")

# Antes de PLAYER_ENTERING_WORLD no mide (evita contar el login como ganancia)
L3, M3 = nuevo()
L3.execute('Fire("ADDON_LOADED", "Medidor"); P.dinero = 999999; Fire("PLAYER_MONEY"); Tick(3)')
check(L3.eval('next(MedidorDB.pj["Hope-Reino"].cubos)') is None, "nada antes de entrar al mundo")

# Ranking puro: ordena por total/h; cubos viejos sin "pasadas" no rompen
rk = L.eval('''function(M)
  local c = {
    a = {zona="A", act="farmeo", nivel=40, seg=3600, xp=0, ganado=10000, gastado=0, valor=0, prof={}},
    b = {zona="B", act="mazmorra", nivel=40, seg=1800, xp=0, ganado=10000, gastado=0, valor=5000, pasadas=2, prof={}},
    c = {zona="C", act="misiones", nivel=40, seg=60, xp=0, ganado=999999, gastado=0, valor=0, prof={}},
  }
  local r = M.Ranking(c)
  return #r, r[1].zona, r[1].totalHora, r[2].zona
end''')(M)
check(tuple(rk) == (2, "B", 30000, "A"), "ranking: B 3o/h antes que A 1o/h, C fuera por poco tiempo: %r" % (tuple(rk),))
check("por pasada" in L.eval('function(M) return M.Linea(M.Agrupar({x={zona="B", act="mazmorra", nivel=40, seg=1800, xp=0, ganado=10000, gastado=0, valor=5000, pasadas=2, prof={}}})[1]) end')(M), "línea con pasadas")

# /reload dentro de una mazmorra: no cuenta una pasada nueva
L4, M4 = nuevo()
L4.execute('P.inst = true; P.tipo = "party"; P.zona = "Uldaman"; Fire("ADDON_LOADED", "Medidor"); Fire("PLAYER_ENTERING_WORLD"); Tick(2)')
check((L4.eval('MedidorDB.pj["Hope-Reino"].cubos["Uldaman|mazmorra|37"].pasadas') or 0) == 0, "recargar dentro de la mazmorra no cuenta pasada")

# Borrar pide confirmación
L.execute('chat = {}; SlashCmdList.MEDIDOR("borrar")')
check(L.eval('next(MedidorDB.pj["Hope-Reino"].cubos)') is not None, "borrar sin 'si' no borra")
L.execute('SlashCmdList.MEDIDOR("borrar si")')
check(L.eval('next(MedidorDB.pj["Hope-Reino"].cubos)') is None, "borrar si")

print(f"\n{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
