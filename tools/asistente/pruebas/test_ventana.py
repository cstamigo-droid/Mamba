# Pruebas de la ventana de Mamba (Asistente/Ventana.lua) con la pestaña Equipo, fuera del juego, con Lua 5.1
# (lupa) y el módulo Gear REAL de Polestar. Caso: Hope, druida tauren de la Horda, nivel 39 (Restauración).
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_ventana.py [carpeta addon] [carpeta Asistente_Clase]
# Revisa: /equipo abre la ventana; se navega con clic (pestañas, secciones, mazmorra -> ficha -> Volver);
# cuadro del objeto al pasar el ratón; flecha a la entrada; nada en el chat; nombres en español; sin la
# palabra "Polestar"; en combate se abre igual; pestañas Clase y Subasta; botón del minimapa; 0 errores.
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
ADDON = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else AQUI.parents[2] / "addon").resolve()
CLASE = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else pathlib.Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER\addon")
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
G.LOADED["Polestar"] = True
GUIAS = []
PS.Dungeons = L.table_from({
    "Load": L.eval("function() return true end"),
    "GuideTo": lambda clave: GUIAS.append(clave) or True,
})
cargar(ADDON, "Asistente", L.table())
L.execute('Fire("ADDON_LOADED", "Asistente")')
T = L.table()
cargar(ADDON, "Tasador", T)
L.execute('Fire("ADDON_LOADED", "Tasador")')
E = L.table()
NS_CLASE = L.table()
HAY_CLASE = (CLASE / "Asistente_Clase" / "Asistente_Clase.toc").exists()


def modulo(a):
    if a == "Asistente_Equipo":
        cargar(ADDON, a, E)
    elif a == "Asistente_Clase" and HAY_CLASE:
        cargar(CLASE, a, NS_CLASE)


G.CARGAR_MODULO = modulo
L.execute('Fire("PLAYER_LOGIN")')

# Hope: druida tauren, nivel 39, Restauración por talentos.
polestar_lua.fijar_personaje(L, PS, "DRUID", 39, "restoration")
GEAR = PS.Gear
G.TALENT_COLS = L.eval('{ { name = "Balance", points = 0 }, { name = "Feral Combat", points = 5 }, { name = "Restoration", points = 31 } }')
GEAR.RefreshPlayer()

ventana = lambda: G.MambaVentana  # noqa: E731
FILAS = L.eval("""function()
  local out = {}
  for _, b in ipairs(MambaVentana.filas) do
    if b:IsShown() and b.o then out[#out + 1] = b end
  end
  return out
end""")
TEXTOS_VISIBLES = L.eval("""function()
  local out = {}
  for _, f in ipairs(TODOS) do
    local p, dentro = f, false
    while p do if p == MambaVentana then dentro = true break end p = p.padre end
    if dentro and f.text and f:IsVisible() then out[#out + 1] = f.text end
  end
  return out
end""")


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


def filas():
    return lista(FILAS())


def textos():
    return [str(b.o.texto) for b in filas()]


def visibles():
    return [str(x) for x in lista(TEXTOS_VISIBLES())]


def boton(lst, nombre):
    for b in lista(lst):
        if b.nombre == nombre and b.IsShown(b):
            return b
    return None


INGLES = ("Razorfen Downs", "Scarlet Library", "Scarlet Cathedral", "The Barrens", "Tirisfal Glades",
          "Mordresh Fire Eye", "Arcanist Doan", "Whitemane", "Fairbanks", "Library Walkers")


def revisar_vista(nombre):
    v = visibles()
    check(len(v) > 3, f"{nombre}: la ventana muestra algo ({len(v)} textos)")
    check(not any("Polestar" in x for x in v), f"{nombre}: sin la palabra Polestar ({[x for x in v if 'Polestar' in x][:1]})")
    for ingles in INGLES:
        check(not any(ingles in x for x in v), f"{nombre}: sin {ingles!r}")
    check(not any(x.startswith("Algo falló") for x in v), f"{nombre}: sin fallas al armarla")


# --- 1. /equipo abre la ventana, no escribe en el chat ---
n_chat = len(G.chat)
L.execute('Slash("/equipo")')
check(ventana() is not None and ventana().IsShown(ventana()), "/equipo abre la ventana de Mamba")
check(G.LOADED["Asistente_Equipo"] is True, "carga el módulo de equipo")
check(len(G.chat) == n_chat, f"/equipo no escribe en el chat ({[G.chat[i] for i in range(n_chat + 1, len(G.chat) + 1)][:2]})")
check(str(ventana().titulo.text) == "Mamba", "el título es Mamba")
t = textos()
check(any("Pesos de Mamba" in x and "nivel 39" in x for x in t), f"Mi equipo: cabecera de Hope ({t[:1]})")
check(any(x.startswith("Cabeza:") for x in t) and any(x.startswith("Mano derecha:") for x in t), "Mi equipo: ranura por ranura")
check(any("Qué mazmorra repetir" in x for x in t), "Mi equipo: qué mazmorra repetir")
revisar_vista("Mi equipo")
secciones = [str(b.nombre) for b in lista(ventana().botonesSeccion) if b.IsShown(b)]
check(secciones == ["Mi equipo", "Mazmorras", "Al 60 (JcE)", "JcJ", "Rol", "Fuentes"], f"6 secciones con clic: {secciones}")
pestanas = [str(b.nombre) for b in lista(ventana().botonesPestana)]
check(pestanas == ["Equipo", "Clase", "Subasta"], f"pestañas de Mamba: {pestanas}")

# --- 2. Se navega con clic entre las secciones ---
for nombre, debe in (("Mazmorras", "Mazmorras para"), ("Al 60 (JcE)", "PROVISIONAL"), ("JcJ", "Rango 14"),
                     ("Rol", "Lo decide Mamba"), ("Fuentes", "ForeverLevelingBiS"), ("Mi equipo", "Pesos de Mamba")):
    b = boton(ventana().botonesSeccion, nombre)
    check(b is not None, f"botón de la sección {nombre}")
    if b is None:
        continue
    b.Click(b)
    check(any(debe in x for x in textos()), f"clic en {nombre}: muestra {debe!r}")
    revisar_vista(nombre)
check(len(G.chat) == n_chat, "navegar no escribe en el chat")

# --- 3. Mazmorras: clic en una -> su ficha (jefes, piezas, %, pasadas) y la flecha a su entrada ---
boton(ventana().botonesSeccion, "Mazmorras").Click(boton(ventana().botonesSeccion, "Mazmorras"))
check(any("Zahúrda Rajacieno" in x for x in textos()), "lista Zahúrda Rajacieno (nivel 37-46) en español")
fila_rfd = next((b for b in filas() if "Zahúrda Rajacieno" in str(b.o.texto) and b.o.ir), None)
check(fila_rfd is not None, "Zahúrda Rajacieno se puede abrir con clic")
GUIAS.clear()
fila_rfd.scripts.OnClick(fila_rfd)
check(GUIAS == ["razorfen-downs"], f"la flecha va a la entrada de Zahúrda Rajacieno ({GUIAS})")
t = textos()
check(t and "Zahúrda Rajacieno" in t[0], f"ficha de la mazmorra ({t[:1]})")
check(any("La flecha te lleva a la entrada" in x for x in t), "la ficha dice que la flecha está puesta")
check(any("Jefes y lo que te mejora" in x for x in t), "la ficha muestra los jefes")
check(any("Mordresh Ojo de Fuego" in x for x in t), "jefe en español: Mordresh Ojo de Fuego")
check(any("pasadas" in x for x in t) and any("%" in x for x in t), "piezas con % y pasadas")
items = [b for b in filas() if b.o.item]
check(len(items) > 0, "hay piezas con objeto")
revisar_vista("Ficha de Zahúrda Rajacieno")
check(ventana().volver.IsShown(ventana().volver), "aparece «Volver»")
# Cuadro del objeto al pasar el ratón
if items:
    b = items[0]
    b.scripts.OnEnter(b)
    check(str(G.GameTooltip.enlace) == f"item:{b.o.item}", f"cuadro del objeto al pasar el ratón ({G.GameTooltip.enlace})")
# Volver
ventana().volver.Click(ventana().volver)
check(any("Mazmorras para" in x for x in textos()), "«Volver» regresa a la lista de mazmorras")
# Biblioteca y Catedral Escarlata (las de la captura de Cristian), desde "todas"
L.execute('Asistente.AbrirVentana("equipo", "mazmorras:todas", true)')
t = textos()
check(any("Biblioteca Escarlata" in x for x in t) and any("Catedral Escarlata" in x for x in t), "Biblioteca y Catedral Escarlata en español")
check(any("Claros de Tirisfal" in x for x in t) and any("Los Baldíos" in x for x in t), "zonas en español")
revisar_vista("Todas las mazmorras")
cat = next(b for b in filas() if "Catedral Escarlata" in str(b.o.texto))
GUIAS.clear()
cat.scripts.OnClick(cat)
check(GUIAS == ["scarlet-monastery"], "la Catedral guía al Monasterio Escarlata")
t = textos()
check(any("Alta inquisidora Melenablanca" in x for x in t), f"jefa en español en la ficha: {[x for x in t if 'inquisi' in x.lower()][:2]}")
revisar_vista("Ficha de la Catedral Escarlata")
# Una nueva de Forever sin entrada conocida: lo dice, sin error
L.execute('Asistente.AbrirVentana("equipo", "mazmorras:todas", true)')
kd = next(b for b in filas() if "Krol" in str(b.o.texto))
GUIAS.clear()
kd.scripts.OnClick(kd)
check(GUIAS == [] and any("todavía no conoce la entrada" in x for x in textos()), "Krol'dok: dice que no conoce la entrada")

# --- 4. Subcomandos: abren su sección ---
for arg, debe in (("mazmorras", "Mazmorras para"), ("60", "PROVISIONAL"), ("jcj", "Rango 14"), ("rol", "Lo decide Mamba"), ("fuentes", "ForeverLevelingBiS"), ("", "Pesos de Mamba")):
    L.execute(f'Slash("/equipo", "{arg}")')
    check(any(debe in x for x in textos()), f"/equipo {arg}: abre su sección")
# Escape: la ventana se cierra con Escape (UISpecialFrames) o con la cruz
check("MambaVentana" in [str(x) for x in lista(G.UISpecialFrames)], "se cierra con Escape")

# --- 5. En combate: la ventana se abre y se navega igual; la flecha espera ---
ventana().Hide(ventana())
G.COMBATE = True
L.execute('Slash("/equipo", "mazmorras")')
check(ventana().IsShown(ventana()), "en combate la ventana se abre (marcos normales, nada protegido)")
fila = next((b for b in filas() if b.o.ir), None)
GUIAS.clear()
fila.scripts.OnClick(fila)
check(GUIAS == [] and any("sal de combate" in x.lower() for x in textos()), "en combate la flecha no se pone y lo dice")
G.COMBATE = False

# --- 6. Pestañas Clase y Subasta: lo que iba al chat va a la ventana ---
n_chat = len(G.chat)
pc = boton(ventana().botonesPestana, "Clase")
pc.Click(pc)
if HAY_CLASE:
    check(len(textos()) > 0, f"Clase: muestra el resumen ({textos()[:1]})")
    check(len(G.chat) == n_chat, "Clase: nada en el chat")
    for nombre in ("Profesiones", "Builds"):
        b = boton(ventana().botonesSeccion, nombre)
        b.Click(b)
        check(len(textos()) > 0 and len(G.chat) == n_chat, f"Clase/{nombre}: en la ventana")
    b = next((b for b in filas() if b.o.ir and str(b.o.ir).startswith("build:")), None)
    check(b is not None, "Clase/Builds: cada build se abre con clic")
    if b:
        b.scripts.OnClick(b)
        check(any("Comparar mis talentos" in x for x in textos()), "Clase: ficha de una build")
else:
    print("(sin Asistente_Clase en", CLASE, "— se salta)")
ps = boton(ventana().botonesPestana, "Subasta")
decir_orig = G.Tasador.Decir
ps.Click(ps)
b = boton(ventana().botonesSeccion, "Qué vender")
b.Click(b)
check(any("Qué vender" in x for x in textos()), f"Subasta/Qué vender en la ventana ({textos()[:1]})")
check(len(G.chat) == n_chat, "Subasta: nada en el chat")
pe = boton(ventana().botonesPestana, "Equipo")
pe.Click(pe)
check(L.eval("function(a, b) return rawequal(a, b) end")(G.Tasador.Decir, decir_orig), "al salir de Subasta, el Tasador vuelve a hablar en el chat")
L.execute('Slash("/tasador", "op")') if False else None

# --- 7. Botón del minimapa y /mamba ---
bm = G.MambaBotonMinimapa
check(bm is not None and bm.IsShown(bm), "botón de Mamba en el minimapa")
ventana().Hide(ventana())
bm.scripts.OnClick(bm)
check(ventana().IsShown(ventana()), "clic en el botón del minimapa abre la ventana")
bm.scripts.OnClick(bm)
check(not ventana().IsShown(ventana()), "otro clic la cierra")
bm.scripts.OnEnter(bm)
L.execute('Slash("/mamba")')
check(ventana().IsShown(ventana()), "/mamba abre la ventana")
L.execute('Slash("/mamba", "boton")')
check(not bm.IsShown(bm), "/mamba boton oculta el botón")
L.execute('Slash("/mamba", "boton")')
check(bm.IsShown(bm), "/mamba boton lo vuelve a mostrar")

# --- 8. Sin errores de Lua ---
errores = [str(x) for x in lista(G.ERRORES)]
check(errores == [], f"0 errores de Lua: {errores[:3]}")
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
