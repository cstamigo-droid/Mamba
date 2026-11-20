"""Pruebas de Mamba_Comodidades (raros K70 y comodidades K71/K83) con Lua 5.1 (lupa).
Uso: python test_comodidades.py [carpeta de Mamba_Comodidades]"""
import sys, pathlib, re, itertools
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent.parent.parent / "addon" / "Mamba_Comodidades"
toc = (D / "Mamba_Comodidades.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


# Polestar falso: ajustes, bus de mensajes, raros del Codex en la zona 1429 (y uno en otra zona y uno de
# mazmorra), distancia en el plano (1 unidad de mapa = 10 m), flecha y tarjeta de aviso.
MOCK = r'''
local cf = CreateFrame
function CreateFrame(...) local f = cf(...); f.SetCreature = function(s, id) s.criatura = id end; f.SetPortraitZoom = function() end; return f end
CVARS = { autoLootDefault = "0" }
C_CVar = { GetCVar = function(k) return CVARS[k] end, SetCVar = function(k, v) CVARS[k] = v end }
MUDOS = {}
function MuteSoundFile(id) MUDOS[id] = true end
function UnmuteSoundFile(id) MUDOS[id] = nil end
NIVEL = 30
function UnitLevel() return NIVEL end
ZONA = 1429
C_Map = {
  GetBestMapForUnit = function() return 9999 end,
  GetMapInfo = function(id)
    if id == 9999 then return { mapType = 5, parentMapID = ZONA, name = "Cueva" } end
    return { mapType = 3, parentMapID = 13, name = "Bosque de Elwynn" }
  end,
}
Enum = { UIMapType = { Zone = 3 } }
MACROS = {}
function GetMacroIndexByName(n) for i, m in ipairs(MACROS) do if m.n == n then return i end end return 0 end
function CreateMacro(n, icono, cuerpo, porPj) if COMBATE then error("combate") end; table.insert(MACROS, { n = n, cuerpo = cuerpo, pj = porPj }); return #MACROS end
function EditMacro(i, n, icono, cuerpo) if COMBATE then error("combate") end; MACROS[i].cuerpo = cuerpo end
CURSOR = nil
function PickupMacro(n) CURSOR = n end
function GetTime() return RELOJ or 100 end
TICKERS = {}
C_Timer.NewTicker = function(_, fn) local t = { fn = fn }; function t:Cancel() self.muerto = true end; table.insert(TICKERS, t); return t end
function Tic() for _, t in ipairs(TICKERS) do if not t.muerto then t.fn() end end end
CHAT = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, t) table.insert(CHAT, t) end }

AJUSTES = { ["qol.autoReleasePvP"] = false, ["qol.acceptSummon"] = false, ["qol.acceptResurrect"] = false,
  ["qol.fastLoot"] = true, ["maps.flightTimer"] = true, ["qol.hideErrors"] = false }
YO = { map = 1429, x = 50, y = 50 }
FLECHA = nil
local bus = {}
local function rec(id, nombre, nivel, spawns, extra)
  local r = { kind = "rare", id = id, name = nombre, level = nivel, spawns = spawns, loot = {} }
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end
RAROS = {
  rec(1, "Lejos", 25, { { map = 1429, x = 90, y = 90 } }),
  rec(2, "Cerca", 25, { { map = 1429, x = 52, y = 50 } }),
  rec(3, "Medio", 26, { { map = 1429, x = 70, y = 50 }, { map = 1426, x = 10, y = 10 } }),
  rec(4, "Otra zona", 25, { { map = 1426, x = 50, y = 50 } }),
  rec(5, "Gris", 10, { { map = 1429, x = 51, y = 51 } }),
  rec(6, "De mazmorra", 25, { { map = 1429, x = 40, y = 40 } }, { instance = 34 }),
}
TESOROS = { { kind = "treasure", id = 77, name = "Cofre", spawns = { { map = 1429, x = 60, y = 60 } }, loot = {} } }
CODEX = true
CERCA = {}
TARJETA = CreateFrame("Frame", "PolestarRareToast", UIParent)
Polestar = {
  Get = function(k) return AJUSTES[k] end,
  Set = function(k, v) AJUSTES[k] = v end,
  On = function(m, fn) bus[m] = bus[m] or {}; table.insert(bus[m], fn) end,
  PlayerPoint = function() return YO end,
  Compat = { CreatureCached = function() return true end },
  Theme = { Approx = function() return "≈" end },
  Nav = { SetTarget = function(map, x, y, nombre) FLECHA = { map = map, x = x, y = y, nombre = nombre }; return true end,
          ClearTarget = function() FLECHA = nil end },
  QoL = { Buttons = { MarkLine = function() return "/tm [@target,exists] 8" end } },
  Rares = {
    Codex = function() return CODEX end,
    ListOf = function(k) return k == "treasure" and TESOROS or RAROS end,
    GreyLevel = function(l) return l - 5 - math.floor(l / 10) end,
    Nearby = function() return CERCA end,
    Toast = { frame = TARJETA },
  },
}
function Avisar(m, ...) for _, fn in ipairs(bus[m] or {}) do fn(...) end end
'''


def nuevo(extra=""):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    L.execute(extra)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Comodidades", M) end')
    for n in ARCHIVOS:
        cargar((D / n).read_text(encoding="utf-8"), n, M)
    return L, M


def lista_lua(t):
    return [t[i] for i in range(1, len(t) + 1)]


L, M = nuevo()
G = L.globals()
L.execute('Fire("PLAYER_LOGIN"); Fire("PLAYER_ENTERING_WORLD")')
check(not lista_lua(G.ERRORES), "errores al entrar: %s" % lista_lua(G.ERRORES))
R = M.Raros

# --- K70: los raros de la zona
lst, motivo, zona = R.Lista()
nombres = [p.rec.name for p in lista_lua(lst)]
check(zona == 1429, "zona: sube de la cueva al mapa de la zona (%s)" % zona)
check(nombres == ["Cerca", "Medio", "Lejos"], "raros de la zona, el más cercano primero, sin grises, sin mazmorra, sin otra zona: %s" % nombres)
G.MambaComodidadesDB.raros.grises = True
check("Gris" in [p.rec.name for p in lista_lua(R.Lista()[0])], "con 'incluir grises' entra el gris")
G.MambaComodidadesDB.raros.grises = False
G.MambaComodidadesDB.raros.tesoros = True
check("Cofre" in [p.rec.name for p in lista_lua(R.Lista()[0])], "con 'sumar tesoros' entra el cofre")
G.MambaComodidadesDB.raros.tesoros = False
# control negativo: sin base de datos, dice por qué (R0: "sin datos aún")
G.CODEX = False
l2, mot2 = R.Lista()[:2]
check(l2 is None and "Sin datos" in mot2, "sin Codex: 'Sin datos aún' (%s)" % mot2)
G.CODEX = True

# --- la ruta: la más corta de verdad (fuerza bruta sobre 6 puntos) y nunca peor que ir al más cercano
L.execute('''PUNTOS = {}
for i, xy in ipairs({ {10,10}, {90,12}, {12,88}, {88,90}, {50,52}, {30,70} }) do
  PUNTOS[i] = { rec = { name = "R" .. i }, spawn = { map = 1, x = xy[1], y = xy[2] } }
end
DESDE = { map = 1, x = 0, y = 0 }''')
orden, total = R.Ruta(G.PUNTOS, G.DESDE)
pts = lista_lua(G.PUNTOS)
def largo(seq):
    d, prev = 0.0, (0, 0)
    for p in seq:
        x, y = p.spawn.x, p.spawn.y
        d += ((x - prev[0]) ** 2 + (y - prev[1]) ** 2) ** 0.5 * 10
        prev = (x, y)
    return d
optimo = min(largo(s) for s in itertools.permutations(pts))
check(len(lista_lua(orden)) == 6, "la ruta pasa por todos")
check(total <= optimo * 1.05, "ruta casi óptima: %.0f m contra el óptimo %.0f m" % (total, optimo))
cercano = R.Largo(G.DESDE, G.PUNTOS)  # en el orden dado
check(total <= cercano + 0.5, "la ruta no es peor que el orden de la lista")

# --- el macro: el más cercano gana (va al final), cabe en 255, con la marca si cabe
L.execute('Fire("ZONE_CHANGED_NEW_AREA")')
i = G.GetMacroIndexByName("MambaRaros")
check(i == 1, "macro MambaRaros creado al cambiar de zona")
cuerpo = G.MACROS[1].cuerpo
lineas = cuerpo.split("\n")
check(lineas[-2] == "/targetexact Cerca" and lineas[-1].startswith("/tm"), "el más cercano al final y la marca de Polestar: %r" % cuerpo)
check("Otra zona" not in cuerpo and "De mazmorra" not in cuerpo, "solo los de la zona")
# un raro a la vista va primero (al final del macro)
L.execute('CERCA = { "Visto Ahora" }; RELOJ = 200; Avisar("RARE_NEARBY")')
check(G.MACROS[1].cuerpo.split("\n")[-2] == "/targetexact Visto Ahora", "el raro a la vista gana: %r" % G.MACROS[1].cuerpo)
check(len(lista_lua(G.MACROS)) == 1, "lo reescribe, no crea otro")
L.execute('CERCA = {}')
# 255 letras: con 40 nombres largos, corta y avisa cuántos entraron
L.execute('NOMBRES = {} for i = 1, 40 do NOMBRES[i] = "Raro de nombre bastante largo " .. i end')
texto, n = R.Macro(G.NOMBRES, "/tm 8")
check(len(texto.encode("utf-8")) <= 255 and 0 < n < 40, "macro cortado a 255 (%d letras, %d nombres)" % (len(texto), n))
check([l for l in texto.split("\n") if l.startswith("/targetexact")][-1] == "/targetexact Raro de nombre bastante largo 1", "aun cortado, el primero de la lista gana")
check(R.Macro(L.eval('{ "Malo\\nlinea", "" }'), None)[0] is None, "control negativo: nombres con salto de línea o vacíos no entran")
# en combate: no toca el macro y lo hace al salir
L.execute('COMBATE = true; CERCA = { "En Combate" }')
r_ok, r_mot = R.ActualizarMacro()
check(not r_ok and r_mot == "combate" and "En Combate" not in G.MACROS[1].cuerpo, "en combate no se escribe")
L.execute('COMBATE = false; Fire("PLAYER_REGEN_ENABLED")')
check("En Combate" in G.MACROS[1].cuerpo, "al salir de combate se escribe lo pendiente")
L.execute('CERCA = {}')
check(not lista_lua(G.BLOQUEOS), "ninguna acción bloqueada")
# poner en la barra
check(R.AlCursor() and G.CURSOR == "MambaRaros", "Ponerlo en mi barra: el macro queda en el cursor")
# macros de la cuenta llenos: va al personaje
L2, M2 = nuevo('local cm = CreateMacro; LLENA = true; CreateMacro = function(n, i, c, pj) if LLENA and not pj then error("llena") end; return cm(n, i, c, pj) end')
L2.execute('Fire("PLAYER_LOGIN"); Fire("ZONE_CHANGED_NEW_AREA")')
check(L2.globals().MACROS[1] is not None and L2.globals().MACROS[1].pj == True, "macros de la cuenta llenos: lo crea en el personaje")

# --- ruta en marcha: flecha al primero y avanza sola al llegar
check(R.Empezar(), "empezar ruta")
check(G.FLECHA is not None and G.FLECHA.nombre == "Cerca", "la flecha apunta al primero (%s)" % (G.FLECHA and G.FLECHA.nombre))
check(any("≈" in t and "min" in t for t in lista_lua(G.CHAT)), "R0: dice metros y minutos aproximados")
L.execute('YO = { map = 1429, x = 52, y = 50 }; Tic()')
check(G.FLECHA.nombre != "Cerca" and R.ruta.i == 2, "al llegar pasa solo al siguiente (%s)" % G.FLECHA.nombre)
R.Detener()
check(G.FLECHA is None and not R.ruta.activa, "detener apaga la flecha")
L.execute('YO = { map = 1429, x = 50, y = 50 }')

# --- la miniatura en la tarjeta de aviso
L.execute('Avisar("RARE_SPOTTED", { kind = "rare", id = 61, name = "Thuros" })')
mini = G.MambaRaroMiniatura
check(mini is not None and mini.visible and L.eval('MambaRaroMiniatura.punto[2] == TARJETA'), "miniatura al lado de la tarjeta")
check(mini.modelo is not None, "con su modelo 3D")
check(L.eval('MambaRaroMiniatura.padre == TARJETA'), "cuelga de la tarjeta: hereda escala, opacidad, entrada y se va con ella")
check(L.eval('MambaRaroMiniatura.h') == 104, "alto de la tarjeta (104, BAND_H + ROW_H)")
check(L.eval('MambaRaroMiniatura.psLight') == True, "marco claro de los avisos (psLight)")
check(L.eval('MambaRaroMiniatura.modelo.criatura') == 61, "dibuja la criatura del aviso")
L.execute('Avisar("RARE_SPOTTED", { kind = "treasure", id = 9 })')
check(not mini.visible, "control negativo: un tesoro no tiene cara")
G.MambaComodidadesDB.raros.miniatura = False
check(not R.Miniatura(L.eval('{ kind = "rare", id = 61 }')), "con el interruptor apagado no sale")
G.MambaComodidadesDB.raros.miniatura = True

# --- K71: comodidades = los ajustes de Polestar, sin duplicar
C = M.Comodidades
items = {it.titulo: it for it in lista_lua(C.LISTA)}
for t in ["Liberar el espíritu solo en campos de batalla", "Aceptar invocaciones", "Aceptar resurrecciones",
          "Botín rápido", "Tiempo de vuelo restante", "Ocultar los errores rojos de combate", "Brillo en los objetos de misión"]:
    check(t in items, "interruptor: " + t)
it = items["Aceptar invocaciones"]
C.Poner(it, True)
check(G.AJUSTES["qol.acceptSummon"] == True and C.Valor(it) == True, "aceptar invocaciones escribe el ajuste de Polestar")
C.Poner(it, False)
check(G.AJUSTES["qol.acceptSummon"] == False, "y lo apaga")
C.Poner(items["Botín automático"], True)
check(G.CVARS.autoLootDefault == "1", "botín automático = la opción del juego")
# brillo: sin ForeverLootSparkles, no disponible; con él, su propio ajuste
check(not C.Disponible(items["Brillo en los objetos de misión"]), "sin ForeverLootSparkles: 'no disponible'")
L.execute('VALOR_BRILLO = true; Settings = { GetSetting = function(k) if k == "FOREVER_LOOT_SPARKLES_ENABLED" then return { GetValue = function() return VALOR_BRILLO end, SetValue = function(_, v) VALOR_BRILLO = v end } end end }')
C.Poner(items["Brillo en los objetos de misión"], False)
check(G.VALOR_BRILLO == False and C.Valor(items["Brillo en los objetos de misión"]) == False, "brillo: usa el ajuste de ForeverLootSparkles")
# sonidos
son = {s.clave: s for s in lista_lua(C.Sonidos())}
C.Poner(son["trenes"], True)
check(G.MUDOS[539802] and G.MUDOS[7744513], "silenciar el tren")
C.Poner(son["trenes"], False)
check(not G.MUDOS[539802], "y vuelve a sonar")
C.Poner(son["bostezo"], True)
L3, M3 = nuevo('MambaComodidadesDB = { sonidos = { bostezo = true } }')
L3.execute('Fire("PLAYER_LOGIN")')
check(L3.globals().MUDOS[562388], "el silencio se vuelve a poner al entrar")
check(not L3.globals().MUDOS[569773], "control negativo: lo apagado no se silencia")

# --- el panel en Interfaz (ventana de Mamba)
L4, M4 = nuevo('Polestar.UI = { Picker = {} }; function Polestar.UI.RegisterSection(s) SECCION = s; return true end; '
               'function Polestar.UI.ShowPicker() end; function Polestar.UI.Picker.ShowSection() end; function Polestar.UI.Picker.Render() end')
G4 = L4.globals()
L4.execute('Fire("PLAYER_LOGIN")')
S = G4.SECCION
check(S is not None and S.key == "MambaInterfaz", "cuelga de la ventana de Mamba (Interfaz)")
nav, _ = S.nav()
etiquetas = [i.label for i in lista_lua(nav)]
check("Raros y tesoros" in etiquetas and "Comodidades" in etiquetas, "títulos en el índice: %s" % etiquetas)
padre = L4.eval('function() local f = CreateFrame("Frame", nil, UIParent); f.w, f.h = 640, 480; return f end')()
S.build(padre)
for k in ["raros:ruta", "raros:macro", "raros:opciones", "comodidades:interruptores", "comodidades:sonidos"]:
    S.onNav(k); S.render()
check(not lista_lua(G4.ERRORES), "panel sin errores: %s" % lista_lua(G4.ERRORES)[:3])

# --- K124: cada automatismo y aviso se apaga desde Ajustes › Mamba › Qué se muestra (MambaAPI.Interruptor)
L5, M5 = nuevo('INTER = {}; MambaAPI = { Interruptor = function(s) INTER[s.id] = s; return true end }')
G5 = L5.globals()
L5.execute('Fire("PLAYER_LOGIN")')
inter = {k: G5.INTER[k] for k in G5.INTER.keys()}
for k in ["comodidades.raro_cara", "comodidades.macro_raros", "comodidades.qol_autoReleasePvP", "comodidades.qol_acceptSummon",
          "comodidades.qol_acceptResurrect", "comodidades.qol_fastLoot", "comodidades.maps_flightTimer", "comodidades.qol_hideErrors",
          "comodidades.autoLootDefault", "comodidades.trenes", "comodidades.fallido", "comodidades.bostezo"]:
    check(k in inter and inter[k].addon == "Mamba_Comodidades", "interruptor publicado: " + k)
check("comodidades.brillo" not in inter, "sin ForeverLootSparkles no se publica un interruptor que no haría nada")
for k, s in inter.items():
    v0 = bool(s.get())
    s.set(not v0)
    check(bool(s.get()) == (not v0), "set aplica en el momento: " + k)
    s.set(v0)
    check(bool(s.get()) == v0, "y vuelve: " + k)
L5.execute('INTER["comodidades.trenes"].set(true)')
check(G5.MUDOS[539802], "apagar desde Opciones silencia de verdad (no solo guarda)")
L5.execute('INTER["comodidades.raro_cara"].set(false)')
check(not M5.Raros.Miniatura(L5.eval('{ kind = "rare", id = 61 }')), "la cara apagada desde Opciones no sale")
L6, M6 = nuevo()
L6.execute('Fire("PLAYER_LOGIN")')
check(L6.globals().MambaInterruptoresPendientes is not None and len(lista_lua(L6.globals().MambaInterruptoresPendientes)) >= 5,
      "sin Asistente cargado, quedan en MambaInterruptoresPendientes")

# --- reglas del código (estética E1-E4, sin comandos, de cero)
for n in ARCHIVOS:
    src = (D / n).read_text(encoding="utf-8")
    sin_coment = "\n".join(l for l in src.splitlines() if not l.strip().startswith("--"))
    check(not re.search(r"SLASH_|SlashCmdList", sin_coment), n + ": sin comandos de chat")
    check(not re.search(r"\|c[fF]{2}[0-9a-fA-F]{6}", sin_coment), n + ": sin colores fijos (E3)")
    if n != "Piezas.lua":
        check(not re.search(r"GameFont|SetFont\(|Template\"", sin_coment), n + ": sin letras ni plantillas propias (E2, E4)")
    check(not re.search(r"LeaPlus|Leatrix_Plus|RSConfig|RSGeneralDB|RSConstants", sin_coment), n + ": código propio, nada de Leatrix ni RareScanner")
print(f"{ok} OK, {fail} FALLAN")
sys.exit(1 if fail else 0)
