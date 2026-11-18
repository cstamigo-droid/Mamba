# Pruebas de las secciones de Mamba dentro del hub de Polestar (Asistente/Hub.lua + Sec*.lua), fuera del juego,
# con Lua 5.1 (lupa), el Gear REAL de Polestar y, si cargan, sus piezas REALES de interfaz (Theme/Widgets.lua).
# Caso: Hope, druida tauren de la Horda, nivel 39.
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_hub.py [carpeta addon] [--romper]
# --romper: control negativo (rompe una sección a propósito: la prueba TIENE que fallar).
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
ADDON = pathlib.Path(args[0] if args else AQUI.parents[2] / "addon").resolve()
sys.path.insert(0, str(AQUI.parent / "generador"))
import polestar_lua  # noqa: E402

L = LuaRuntime(unpack_returned_tuples=True)
L.execute((AQUI / "mock_wow.lua").read_text(encoding="utf-8"))
L.execute((AQUI / "mock_ventana.lua").read_text(encoding="utf-8"))
L.execute("""
LOADED = {}
COMBATE = false
C_AddOns = {
  IsAddOnLoaded = function(a) return LOADED[a] == true end,
  LoadAddOn = function(a) if CARGAR_MODULO then CARGAR_MODULO(a) end; return LOADED[a] == true end,
}
function InCombatLockdown() return COMBATE end
function GetRealmName() return "Reino" end
function UnitRace() return "Tauren", "Tauren" end
MAPA = 1456
function UnitXP() return 1000 end
function UnitXPMax() return 5000 end
function GetMoney() return 10000 end
function GetZoneText() return "Cima del Trueno" end
function GetRealZoneText() return "Cima del Trueno" end
function GetCoinTextureString(c) return "MONEDAS(" .. tostring(c) .. ")" end
function IsAltKeyDown() return ALT == true end
ITEM_QUALITY_COLORS = { [0] = { hex = "|cff9d9d9d" }, { hex = "|cffffffff" }, { hex = "|cff1eff00" }, { hex = "|cff0070dd" }, { hex = "|cffa335ee" } }
C_Map = { GetBestMapForUnit = function() return MAPA end, GetPlayerMapPosition = function() return { GetXY = function() return 0.5, 0.5 end } end,
  GetMapInfo = function(m) return ({ [1454] = { name = "Orgrimmar" }, [1456] = { name = "Cima del Trueno" }, [1458] = { name = "Entrañas" } })[m] end }
""")
loader = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f(addon, ns) end')
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def cargar(base, carpeta, ns):
    toc = [l.strip() for l in (base / carpeta / f"{carpeta}.toc").read_text(encoding="utf-8").splitlines()
           if l.strip().endswith(".lua")]
    for name in toc:
        loader((base / carpeta / name).read_text(encoding="utf-8"), f"{carpeta}/{name}", carpeta, ns)
    L.globals().LOADED[carpeta] = True


G = L.globals()
PS = polestar_lua.cargar_gear(L, ADDON)
G.Polestar = PS
G.LOADED["Polestar"] = True
GUIAS = []
PS.Dungeons = L.table_from({"Load": L.eval("function() return true end"), "GuideTo": lambda clave: GUIAS.append(clave) or True})
NAV = []
PS.Nav = L.table_from({"API": L.table_from({"version": 1, 
    "Estimate": L.eval("function(...) ESTIMADO = (ESTIMADO or 0) + 1; return 420 end"),
    "Navigate": L.eval("function(...) return NAVEGAR(...) end"), "Cancel": lambda *a: True})})
G.NAVEGAR = lambda *a: NAV.append(a) or True  # Navigate es una función de Lua, como en el juego (MambaAPI la exige)

# Las piezas REALES de interfaz de Polestar, si cargan con los marcos simulados.
W_REAL = False
try:
    ldr = L.eval('function(src, name, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Polestar", ns) end')
    for f in ("Theme/House.lua", "Theme/Theme.lua", "Theme/SkinApi.lua", "Theme/Anim.lua", "Theme/Widgets.lua"):
        ldr((ADDON / "Polestar" / f).read_text(encoding="utf-8"), "Polestar/" + f, PS)
    W_REAL = bool(PS.Widgets and PS.Widgets.Scroll)
except Exception as e:  # noqa: BLE001
    print("aviso: las piezas reales de Polestar no cargan fuera del juego:", str(e)[:160])
    PS.Widgets = None
    PS.Theme = None
G.USAR_W_REAL = W_REAL
L.execute((AQUI / "mock_hub.lua").read_text(encoding="utf-8"))

cargar(ADDON, "Mamba_Errores", L.table())
L.execute('Fire("ADDON_LOADED", "Mamba_Errores")')
cargar(ADDON, "Asistente", L.table())
L.execute('Fire("ADDON_LOADED", "Asistente")')
T = L.table()
cargar(ADDON, "Tasador", T)
L.execute('Fire("ADDON_LOADED", "Tasador")')
E, NS_CLASE, NS_SERV, NS_MED = L.table(), L.table(), L.table(), L.table()


def modulo(a):
    if a == "Asistente_Equipo":
        cargar(ADDON, a, E)
    elif a == "Asistente_Clase":
        cargar(ADDON, a, NS_CLASE)
    elif a == "Asistente_Servicios":
        cargar(ADDON, a, NS_SERV)


G.CARGAR_MODULO = modulo
cargar(ADDON, "Medidor", NS_MED)
L.execute('Fire("ADDON_LOADED", "Medidor")')
L.execute('Fire("PLAYER_LOGIN")')
polestar_lua.fijar_personaje(L, PS, "DRUID", 39, "balance")
G.TALENT_COLS = L.eval('{ { name = "Balance", points = 31 }, { name = "Feral Combat", points = 5 }, { name = "Restoration", points = 0 } }')
PS.Gear.RefreshPlayer()

if ROMPER:
    L.execute('Asistente.Hub.secciones.MambaEquipo.dibujar = function() error("roto a proposito") end')


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


TEXTOS = L.eval("""function()
  local out = {}
  local s = REGISTRADAS[SECCION]
  local raiz = s and s.psFrame
  for _, f in ipairs(TODOS) do
    if f.text and f.text ~= "" and f:IsVisible() then
      local p, dentro = f, false
      while p do if p == raiz then dentro = true break end p = p.padre end
      if dentro then out[#out + 1] = f.text end
    end
  end
  return out
end""")


def textos():
    return [str(x) for x in lista(TEXTOS())]


INGLES = ("Razorfen Downs", "Scarlet Library", "The Barrens", "Mordresh Fire Eye", "Arcanist Doan")
ERR0 = len(lista(G.ERRORES))


def revisar(nombre, minimo=3):
    v = textos()
    check(len(v) >= minimo, f"{nombre}: muestra algo ({len(v)} textos)")
    check(not any("Algo falló" in x for x in v), f"{nombre}: sin fallas al armarla ({[x for x in v if 'Algo falló' in x][:1]})")
    check(not any(c in x for x in v for c in ("/tasador", "/equipo", "/clase", "/medidor", "/capa", "/errores", "/mamba")),
          f"{nombre}: sin comandos en el texto ({[x for x in v if '/' in x and any(c in x for c in ('/tasador', '/clase', '/equipo'))][:1]})")
    for ing in INGLES:
        check(not any(ing in x for x in v), f"{nombre}: sin {ing!r}")
    check(len(lista(G.ERRORES)) == ERR0, f"{nombre}: sin errores de Lua ({lista(G.ERRORES)[-1:] if lista(G.ERRORES) else ''})")
    check(not any("muchomejor" in x.replace(" ", "") for x in v), f"{nombre}: nunca «mucho mejor»")
    check(not any("[" in x or "]" in x for x in v), f"{nombre}: nombres sin corchetes ({[x for x in v if '[' in x][:1]})")
    check(sum(x.count("NO VERIFICADO") for x in v) == 0, f"{nombre}: sin «NO VERIFICADO» repetido en las filas")
    check(not any(x.strip().startswith("0 %") for x in v), f"{nombre}: nunca «0 %» (sin dato)")
    check(not any("←" in x or "la tuya, sin datos" in x for x in v), f"{nombre}: sin símbolos que la fuente no tiene ni frases raras")
    return v


# 1) registro: 4 entradas en el riel (Equipo, Oro, Ciudad y Errores al pie) con las 8 partes dentro
R = G.REGISTRADAS
grupos = ["MambaGrupoEquipo", "MambaGrupoOro", "MambaGrupoIrA", "MambaGrupoCiudad", "MambaGrupoErrores"]
for k in grupos:
    check(R[k] is not None, f"entrada del riel registrada: {k}")
check([str(R[k].label) for k in grupos if R[k]] == ["Equipo", "Oro", "Ir a…", "Ciudad", "Errores"], "nombres del riel (Ir a… a la vista, con entrada propia)")
check(R["MambaGrupoErrores"] is not None and R["MambaGrupoErrores"].foot is True, "Errores va al pie del riel")
claves = ["MambaEquipo", "MambaSubasta", "MambaIrA", "MambaClase", "MambaServicios", "MambaCapa", "MambaMedidor", "MambaErrores"]
for k in claves:
    check(G.Asistente.Hub.grupoDe[k] is not None, f"parte dentro de un grupo: {k}")
check(G.MambaAPI is not None, "existe la API pública MambaAPI")
print("piezas reales de Polestar:", "SÍ" if W_REAL else "NO (simuladas, mismas firmas)")

# 2) botón del minimapa: abre el hub en Equipo, sin comandos
boton = G.MambaBotonMinimapa
check(boton is not None, "existe el botón del minimapa")
boton.Click(boton)
check(G.SHOWPICKER >= 1 and str(G.SECCION) == "MambaGrupoEquipo", f"el botón abre el hub en Equipo ({G.SECCION})")
L.execute("RunTimers()")
G.Polestar.UI.Picker.Render()
v = revisar("Equipo · Mejorar", 10)
check(any(x.startswith("Ve a ") for x in v), "Equipo: arriba «Ve a <mazmorra>»")
rec = G.Asistente.MazmorraRecomendada()
check(rec is not None, "hay mazmorra recomendada")
recn = str(rec.nombre) if rec else "?"
check(any(recn in x for x in v), f"la recomendada ({recn}) aparece en Mejorar")
check(any("%" in x for x in v), "Mejorar muestra % de mejora")
tabs = [str(t.label) for t in lista(G.PESTANAS_VISTAS)]
check(tabs[:3] == ["Mejorar", "Lo que llevas", "Mazmorras"], f"pestañas de Equipo: {tabs}")
check(str(G.TITULO_VISTO[1]) == "Mejorar mi equipo", "título de Equipo")

# 3) un «Ir» de una fila pone la flecha (GuideTo)
IR = L.eval("""function()
  for _, f in ipairs(TODOS) do
    local lb = rawget(f, "Label")
    if type(lb) == "table" and lb.text == "Ir" and f:IsVisible() and f.scripts.OnClick then f.scripts.OnClick(f); return true end
  end
end""")
n0 = len(GUIAS)
check(IR() is True, "hay un botón «Ir» visible en Mejorar")
check(len(GUIAS) == n0 + 1, f"«Ir» pone la flecha a la entrada ({GUIAS[-1:]})")

# 3b) pasar el ratón por una fila con líneas extra (cuadro del objeto) no da error (Widgets.lua:554, 18-11)
PASAR = L.eval("""function()
  local n = 0
  for _, f in ipairs(TODOS) do
    local d = rawget(f, "psDatos")
    if type(d) == "table" and d.tipExtra and f:IsVisible() and f.scripts.OnEnter then f.scripts.OnEnter(f); n = n + 1 end
  end
  return n
end""")
e0 = len(lista(G.ERRORES))
check(PASAR() > 0, "hay filas con cuadro del objeto")
check(len(lista(G.ERRORES)) == e0, f"pasar el ratón no da error ({lista(G.ERRORES)[-1:] if len(lista(G.ERRORES)) > e0 else ''})")
import re as _re
for _f in (ADDON).glob("Asistente*/*.lua"):
    _t = _f.read_text(encoding="utf-8", errors="replace")
    check(not _re.search(r"^\s*SlashCmdList\s*=", _t, _re.M), f"{_f.name}: no reasigna SlashCmdList (contamina el /run del juego)")

# 4) todas las pestañas de Equipo
for key in ("llevas", "mazmorras", "60", "jcj", "rol", "fuentes"):
    G.ON_TAB(key)
    v = revisar(f"Equipo · {key}")
G.ON_TAB("mazmorras")
v = textos()
check(any(recn in x for x in v), "la ficha abre la MISMA mazmorra recomendada")
check(any("Llevarme a la entrada" in x for x in v), "la ficha tiene «Llevarme a la entrada»")
check(any("Ver las misiones de esta mazmorra" in x for x in v), "enlace a las misiones de la mazmorra")
G.ON_TAB("mejorar")
L.execute('Asistente.Hub.Est("MambaEquipo").cuando = "luego"')
G.Polestar.UI.Picker.Render()
revisar("Equipo · Más adelante")
check(any(x.startswith("a nivel ") for x in textos()), "Más adelante dice «a nivel N»")

# 5) cada sección se abre desde el riel y se arma sin errores
for k in claves[1:]:
    G.MambaAPI.Abrir(k)
    L.execute("RunTimers()")
    G.Polestar.UI.Picker.Render()
    revisar(k, 2)
    for t in lista(G.PESTANAS_VISTAS):
        G.ON_TAB(t.key)
        L.execute("RunTimers()")
        G.Polestar.UI.Picker.Render()
        revisar(f"{k} · {t.key}", 1)

# 6) Ir a…: sugiere la misma mazmorra; la ruta dice un tiempo REAL del planificador; «Llevarme» pone la flecha
G.MambaAPI.Abrir("MambaIrA")
G.ON_TAB("buscar")
G.Polestar.UI.Picker.Render()
v = textos()
check(any(recn in x for x in v), "Ir a… sugiere la misma mazmorra recomendada")
check(any("Ruta a" in x for x in v), "Ir a… muestra la ruta")
R["MambaGrupoIrA"].search("subasta")
v = textos()
check(any("subastas" in x.lower() for x in v), "buscar «subasta» encuentra la casa de subastas")
check(any("≈ 7:00" in x for x in v), f"sin el parche P8 el tiempo total sale de Nav.API.Estimate (420 s = ≈ 7:00, R0) ({[x for x in v if 'otal' in x][:1]})")
# con el parche P8, los tramos: piedra, vuelo y a pie, cada uno con su tiempo, y las otras formas de llegar
L.execute("""
Asistente.Llevame.OlvidarCache()
Polestar.Nav.EstimateTravel = function(from, to, budgeted, noHearth, noFlights)
  local legs
  if noFlights then legs = { { kind = "walk", seconds = 900, label = "Camina", yards = 6000 } }
  elseif noHearth then legs = { { kind = "walk", seconds = 20, label = "Camina hasta el maestro de vuelo", yards = 130 }, { kind = "fly", seconds = 258, label = "Vuela a Cima del Trueno" }, { kind = "walk", seconds = 40, label = "Camina", yards = 280 } }
  else legs = { { kind = "hearth", seconds = 15, label = "Piedra de hogar a Cima del Trueno" }, { kind = "walk", seconds = 45, yards = 382 } } end
  local t = 0; for _, l in ipairs(legs) do t = t + l.seconds end
  return t, nil, legs
end
""")
R["MambaGrupoIrA"].search("banco")
v = textos()
tx = " | ".join(v)
check("1. Piedra de hogar a Cima del Trueno" in tx and "15 s" in tx, "Ir a…: tramo 1, la piedra con su tiempo")
check("Caminar 382 yd" in tx and "≈ 45 s" in tx, "Ir a…: tramo 2, a pie con sus yardas y su tiempo (≈)")
check("Total ≈ 1:00" in tx, "Ir a…: el total, estimado (R0)")
check("El más cercano en tiempo" in tx, "Ir a…: el banco elegido es el más cercano EN TIEMPO")
check("Otras formas de llegar" in tx and "Sin piedra de hogar" in tx and "Sin piedra ni vuelos" in tx, "Ir a…: las alternativas sin piedra y sin piedra ni vuelos (la más rápida no vuela)")
check("≈ 5:18" in tx, "la alternativa sin piedra da su total (20 + 258 + 40 s)")
L.execute("Polestar.Nav.EstimateTravel = nil; Asistente.Llevame.OlvidarCache()")
R["MambaGrupoIrA"].search("zzzz qqq")
check(any("Sin resultados" in x for x in textos()), "Ir a…: estado «Sin resultados»")
R["MambaGrupoIrA"].search("")

# 7) Subasta: interruptores conectados a Polestar (qol.sellJunk / qol.autoRepair)
G.MambaAPI.Abrir("MambaSubasta")
G.ON_TAB("vender")
v = textos()
check(any("Vender la basura sola" in x for x in v) and any("Reparar solo" in x for x in v), "interruptores en Vender lo mío")
SW = L.eval("""function()
  for _, f in ipairs(TODOS) do
    if f.tipo == "CheckButton" and f:IsVisible() and f.scripts.OnClick then
      f.marcado = not AJUSTES["qol.sellJunk"] -- el marco simulado no guarda SetChecked: se parte del ajuste
      if not rawget(f, "GetChecked") or type(f.GetChecked) ~= "function" then end
      f.GetChecked = function(self) return self.marcado end
      f.scripts.OnClick(f); return true
    end
  end
end""")
antes = G.AJUSTES["qol.sellJunk"]
SW()
check(G.AJUSTES["qol.sellJunk"] != antes, "el interruptor cambia qol.sellJunk de Polestar")

# 8) Errores: muestra lo guardado y se vacía con botón
L.execute('MambaErroresDB = MambaErroresDB or {}; MambaErroresDB.lista = { { msg = "x.lua:1: prueba", hora = "hoy", veces = 2, tipo = "lua" } }')
G.MambaAPI.Abrir("MambaErrores")
check(any("x.lua:1: prueba" in x for x in textos()), "Errores muestra el error guardado")

# 8b) Tu rol: se elige con un clic, sin mandar a los ajustes
G.MambaAPI.Abrir("MambaEquipo", "rol")
v = textos()
check(any("Elige tu rol" in x for x in v), "Tu rol: título «Elige tu rol»")
check(not any("ajustes de equipo" in x for x in v), "Tu rol: no manda a los ajustes de equipo")
ELEGIR = L.eval("""function()
  for _, f in ipairs(TODOS) do
    local lb = rawget(f, "Label")
    if type(lb) == "table" and lb.text == "Elegir" and f:IsVisible() and f.scripts.OnClick then f.scripts.OnClick(f); return true end
  end
end""")
check(ELEGIR() is True, "Tu rol: hay botones «Elegir»")
check(G.AJUSTES["gear.spec.DRUID"] is not None, f"«Elegir» fija el rol en Polestar (gear.spec.DRUID = {G.AJUSTES['gear.spec.DRUID']})")
G.AJUSTES["gear.spec.DRUID"] = None

# 9) los comandos viejos abren el hub
L.execute('Slash("/equipo", "mazmorras")')
check(str(G.SECCION) == "MambaGrupoEquipo", "/equipo abre la sección Equipo del hub")

# 9b) la API pública para «Mi plan»
m = G.MambaAPI.MejorasPorRanura()
check(m is not None and len(list(m.keys())) > 0, "MambaAPI.MejorasPorRanura devuelve piezas")
r = G.MambaAPI.MazmorraRecomendada()
check(r is not None and str(r.nombre) == recn, "MambaAPI.MazmorraRecomendada = la misma de la ventana")
check(G.MambaAPI.Clase() is not None and G.MambaAPI.Clase().Builds is not None, "MambaAPI.Clase expone la lógica de clase")
# navegar por la barra lateral del grupo: elegir la parte Clase
R["MambaGrupoEquipo"].onNav("p:MambaClase")
G.Polestar.UI.Picker.ShowSection("MambaGrupoEquipo")
check(str(G.TITULO_VISTO[1]) == "Tu clase", "la barra lateral del grupo cambia a la parte Clase")

# 10) en combate: se abre igual
G.COMBATE = True
G.MambaAPI.Abrir("MambaMedidor")
revisar("Medidor en combate", 1)
G.COMBATE = False

# 10b) el cuadro del objeto: UN solo bloque «Mamba» (fila E8), sin «Tasador:» ni la línea propia de Polestar
CUADRO = L.eval("""function(id, marca)
  local out = {}
  local tt = GameTooltip
  local a1, a2 = tt.AddLine, tt.AddDoubleLine
  tt.AddLine = function(_, t) out[#out + 1] = tostring(t) end
  tt.AddDoubleLine = function(_, l, r) out[#out + 1] = tostring(l) .. " | " .. tostring(r) end
  AsistenteDB.objetos = AsistenteDB.objetos or {}
  AsistenteDB.objetos[id] = marca
  MambaPlan = { MaterialDelPlan = function(x) if x == id then return { clase = "vital", texto = "VITAL: lo necesitas para subir Alquimia" } end end }
  local ok, err = pcall(TIP_HOOK, tt, { id = id, lines = {} })
  tt.AddLine, tt.AddDoubleLine = a1, a2
  MambaPlan = nil
  if not ok then out[#out + 1] = "ERROR " .. tostring(err) end
  return out
end""")
if G.TIP_HOOK is not None:
    G.ITEMS[9001] = L.eval('{name="Paño de prueba",q=1,sell=150,cls=7,sub=5,bind=0,loc="",stats={}}')
    c = [str(x) for x in lista(CUADRO(9001, None))]
    check(sum(1 for x in c if x == "Mamba") == 1, f"cuadro: un solo encabezado «Mamba» ({c})")
    check(not any(x.startswith("Tasador") or "Polestar" in x for x in c), f"cuadro: sin «Tasador:» ni «Polestar» sueltos ({c})")
    check(sum(1 for x in c if "Qué hacer:" in x) == 1, f"cuadro: UNA acción al final ({c})")
    check(c and "Qué hacer:" in c[-1], "cuadro: la acción va al final")
    check(any("VITAL: lo necesitas" in x for x in c), "cuadro: muestra lo que dice Mi plan (MaterialDelPlan)")
    c2 = [str(x) for x in lista(CUADRO(9001, "guardar"))]
    check(any("Qué hacer:" in x and "Guardar" in x and "lo elegiste tú" in x for x in c2), f"cuadro: respeta lo que marcaste ({c2[-1:]})")
    check(not any("ERROR" in x for x in c + c2), f"cuadro: sin errores ({[x for x in c + c2 if 'ERROR' in x]})")
    G.AsistenteDB.objetos[9001] = None
else:
    check(False, "el Tasador instaló su gancho del cuadro (TIP_HOOK)")

# 10b2) rol + árbol de Mi plan -> clave de pesos de Polestar (druida)
CL = L.eval("function(r, a) return Tasador.ClaveDeRol(r, a) end")
check(str(CL("danio", 1)) == "balance", f"danio + árbol 1 = balance ({CL('danio', 1)})")
check(str(CL("danio", 2)) == "feral", "danio + árbol 2 = feral")
check(str(CL("sanar", None)) == "restoration", "sanar = restoration")
check(str(CL("tanque", None)) == "feral", "tanque (druida) = feral")

# 10c) ventanas movibles: lugar por personaje, candado y «Restablecer posiciones»
VENT = L.eval("""function()
  local V = Asistente.Ventanas
  local f = CreateFrame("Frame", "MambaPruebaVentana", UIParent)
  f.GetLeft = function() return 500 end; f.GetBottom = function() return 300 end
  f.GetWidth = function() return 200 end; f.GetHeight = function() return 100 end
  f.GetEffectiveScale = function() return 1 end
  UIParent.GetEffectiveScale = function() return 1 end
  UIParent.GetWidth = function() return 1920 end; UIParent.GetHeight = function() return 1080 end
  local ok1 = MambaAPI.Movible(f, "prueba")
  f:Hide()
  local guardado = AsistenteDB.lugares[V.Personaje()]
  -- arrastrar y soltar: el onStop de DragWindow guarda (aquí, directo)
  local hay = V.marcos.prueba ~= nil
  V.Fijar(true)
  local llamado = false
  local orig = Polestar.StartDrag
  local fijada = MambaAPI.VentanasFijas()
  V.Fijar(false)
  V.Restablecer()
  local vacio = next(AsistenteDB.lugares[V.Personaje()]) == nil
  return ok1, hay, fijada, vacio
end""")
r = VENT()
check(r[0] is True and r[1] is True, "MambaAPI.Movible registra la ventana")
check(r[2] is True, "el candado fija las ventanas (VentanasFijas)")
check(r[3] is True, "«Restablecer posiciones» borra los lugares de este personaje")
# en combate no se mueve ni se restablece nada (un ancla de marcos seguros quedaría bloqueada: veto del revisor, 18-11)
COMB = L.eval("""function()
  COMBATE = true
  Asistente.Ventanas.Fijar(false)
  local bloqueo = false
  local orig = Polestar.StartDrag
  local llamo = false
  Polestar.StartDrag = Polestar.StartDrag
  AsistenteDB.lugares[Asistente.Ventanas.Personaje()] = { prueba = { x = 1, y = 1 } }
  Asistente.Ventanas.Restablecer()
  local sigue = AsistenteDB.lugares[Asistente.Ventanas.Personaje()].prueba ~= nil
  COMBATE = false
  return sigue
end""")
check(COMB() is True, "«Restablecer posiciones» en combate espera a que termine el combate")

# 10d) K108: la ventana de servicios cuando el jugador quiera
G.MAPA = 1456
check(G.MambaAPI.CiudadMasCercana() == 1456, "en Cima del Trueno, la ciudad más cercana es la misma")
check(G.MambaAPI.AbrirServicios() is True, "MambaAPI.AbrirServicios abre la ventana en una ciudad")
G.MAPA = 1413  # Los Baldíos: no es ciudad
CMAS = G.MambaAPI.CiudadMasCercana()
check(CMAS in (1454, 1456, 1458), f"fuera de una ciudad, CiudadMasCercana da una ciudad con lista ({CMAS})")
check(G.MambaAPI.AbrirServicios() is True, "fuera de una ciudad, AbrirServicios abre la más cercana (sin «Aquí no hay lista»)")
G.MAPA = 1456
G.MambaAPI.Abrir("MambaServicios")
v = textos()
check(any("Abrir la ventana de servicios" in x for x in v), "Ciudad › Servicios tiene el botón «Abrir la ventana de servicios»")
check(any("Abrirla sola al entrar a una ciudad" in x for x in v), "Ciudad › Servicios tiene el interruptor de abrirla sola")
# la columna Distancia con las yardas (antes salía vacía: "x, y = a and f()" cortaba a un valor)
L.execute("function UnitPosition() return -1280, 150, 0, 1 end")
G.Polestar.UI.Picker.Render()
v = textos()
check(any(x.endswith("yardas") or x == "aquí" for x in v), f"Ciudad › Servicios: la columna Distancia muestra las yardas ({[x for x in v if 'yard' in x][:2]})")
MED = L.eval("""function()
  local abierto = 0
  local orig = MambaAPI.AbrirServicios
  MambaAPI.AbrirServicios = function() abierto = abierto + 1; return true end
  MambaBotonMinimapa.scripts.OnClick(MambaBotonMinimapa, "MiddleButton")
  MambaAPI.AbrirServicios = orig
  return abierto
end""")
check(MED() == 1, "clic con la rueda en el botón del minimapa abre los servicios")

# 10e) MambaAPI.PonerEnSubasta: sin el subastador abierto no hace nada y dice por qué
PS_ = L.eval("function() return MambaAPI.PonerEnSubasta(9001, 100) end")
r = PS_()
check(r[0] is False and "subastador" in str(r[1]), f"PonerEnSubasta sin la subasta abierta: no hace nada y lo dice ({r[1]})")

# 10f) modo «Mover elementos» (K55 ampliado): marcos sin título, rueda = tamaño, nada en combate
MOV = L.eval("""function()
  local W = Asistente.Ventanas
  local f = CreateFrame("Frame", "MambaPruebaMedidor", UIParent)
  f.GetScale = function(self) return self.escala or 1 end
  f.SetScale = function(self, e) self.escala = e end
  local ok1 = MambaAPI.Movible(f, "pruebaMedidor", { etiqueta = "Medidor de daño", sinAsa = true })
  COMBATE = true
  local enCombate, motivo = MambaAPI.ModoMover(true)
  COMBATE = false
  local entra = MambaAPI.ModoMover(true)
  local visto = false
  for _, f2 in ipairs(TODOS) do
    if f2.nombre and type(f2.nombre) == "table" and tostring(f2.nombre.text or ""):find("Medidor de daño", 1, true) and f2:IsShown() then visto = f2 end
  end
  local escala
  if visto and visto.scripts.OnMouseWheel then visto.scripts.OnMouseWheel(visto, 1); escala = f.escala end
  Fire("PLAYER_REGEN_DISABLED")
  local salio = not W.moviendo
  return ok1, enCombate, tostring(motivo), entra, visto ~= false, escala, salio
end""")
r = MOV()
check(r[0] is True, "MambaAPI.Movible acepta un marco sin título con opciones (sinAsa, etiqueta)")
check(r[1] is False and "combate" in r[2], "en combate no se entra al modo Mover")
check(r[3] is True and r[4] is True, "el modo Mover muestra cada elemento con su nombre")
check(r[5] is not None and abs(r[5] - 1.05) < 0.001, f"la rueda cambia el tamaño del elemento ({r[5]})")
check(r[6] is True, "si empieza un combate, se sale solo del modo Mover")
check(G.REGISTRADAS["MambaGrupoMover"] is not None, "la entrada «Mover» está al pie del riel")

# 11) el riel de Polestar: con 12 secciones en 680 de alto, caben TODAS (antes cortaba las que no cabían)
if W_REAL:
    RIEL = L.eval("""function()
      local f = CreateFrame("Frame"); f.h = 680
      f.Rail = CreateFrame("Frame", nil, f); f.railButtons = {}; f.psRail = Polestar.Widgets.SHELL.rail; f.psNavTop = 150
      local items = {}
      for i = 1, 12 do items[i] = { key = "s" .. i, label = "S" .. i, icon = "compact" } end
      local bottom = { { key = "o", label = "Op" }, { key = "i", label = "Im" }, { key = "e", label = "Er" } }
      return Polestar.Widgets.ShellRail(f, items, bottom, "s1", function() end)
    end""")
    n = RIEL()
    check(n == 12, f"el riel muestra las 12 secciones ({n})")
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
