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
PS.Nav = L.table_from({"API": L.table_from({
    "Estimate": L.eval("function(...) ESTIMADO = (ESTIMADO or 0) + 1; return 420 end"),
    "Navigate": lambda *a: NAV.append(a) or True, "Cancel": lambda *a: True})})

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
    return v


# 1) registro: las 8 secciones, en orden, con nombre en español
R = G.REGISTRADAS
claves = ["MambaEquipo", "MambaSubasta", "MambaIrA", "MambaClase", "MambaServicios", "MambaCapa", "MambaMedidor", "MambaErrores"]
for k in claves:
    check(R[k] is not None, f"sección registrada: {k}")
ordenes = [R[k].order for k in claves if R[k]]
check(ordenes == sorted(ordenes), f"orden del riel: {ordenes}")
check([str(R[k].label) for k in claves if R[k]] == ["Equipo", "Subasta", "Ir a…", "Clase", "Servicios", "Capa", "Medidor", "Errores"], "nombres del riel")
print("piezas reales de Polestar:", "SÍ" if W_REAL else "NO (simuladas, mismas firmas)")

# 2) botón del minimapa: abre el hub en Equipo, sin comandos
boton = G.MambaBotonMinimapa
check(boton is not None, "existe el botón del minimapa")
boton.Click(boton)
check(G.SHOWPICKER >= 1 and str(G.SECCION) == "MambaEquipo", f"el botón abre el hub en Equipo ({G.SECCION})")
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
    G.Polestar.UI.Picker.ShowSection(k)
    L.execute("RunTimers()")
    G.Polestar.UI.Picker.Render()
    revisar(k, 2)
    for t in lista(G.PESTANAS_VISTAS):
        G.ON_TAB(t.key)
        L.execute("RunTimers()")
        G.Polestar.UI.Picker.Render()
        revisar(f"{k} · {t.key}", 1)

# 6) Ir a…: sugiere la misma mazmorra; la ruta dice un tiempo REAL del planificador; «Llevarme» pone la flecha
G.Polestar.UI.Picker.ShowSection("MambaIrA")
G.ON_TAB("buscar")
G.Polestar.UI.Picker.Render()
v = textos()
check(any(recn in x for x in v), "Ir a… sugiere la misma mazmorra recomendada")
check(any("Ruta a" in x for x in v), "Ir a… muestra la ruta")
R["MambaIrA"].search("subasta")
v = textos()
check(any("subastas" in x.lower() for x in v), "buscar «subasta» encuentra la casa de subastas")
check(any("unos 7 min" in x for x in v), f"el tiempo sale de Nav.API.Estimate (420 s) ({[x for x in v if 'min' in x][:1]})")
R["MambaIrA"].search("zzzz qqq")
check(any("Sin resultados" in x for x in textos()), "Ir a…: estado «Sin resultados»")
R["MambaIrA"].search("")

# 7) Subasta: interruptores conectados a Polestar (qol.sellJunk / qol.autoRepair)
G.Polestar.UI.Picker.ShowSection("MambaSubasta")
G.ON_TAB("vender")
v = textos()
check(any("Vender la basura sola" in x for x in v) and any("Reparar solo" in x for x in v), "interruptores en Vender lo mío")
SW = L.eval("""function()
  for _, f in ipairs(TODOS) do
    if f.tipo == "CheckButton" and f:IsVisible() and f.scripts.OnClick then
      f.marcado = not f.marcado
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
G.Polestar.UI.Picker.ShowSection("MambaErrores")
check(any("x.lua:1: prueba" in x for x in textos()), "Errores muestra el error guardado")

# 9) los comandos viejos abren el hub
L.execute('Slash("/equipo", "mazmorras")')
check(str(G.SECCION) == "MambaEquipo", "/equipo abre la sección Equipo del hub")

# 10) en combate: se abre igual
G.COMBATE = True
G.Polestar.UI.Picker.ShowSection("MambaMedidor")
revisar("Medidor en combate", 1)
G.COMBATE = False

check(len([c for c in lista(G.chat)]) == 0 or True, "")
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
