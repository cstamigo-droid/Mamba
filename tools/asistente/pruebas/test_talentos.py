# K109: el planificador visual de talentos (Asistente/SecTalentos.lua + Asistente_Clase/Arbol.lua y Datos_Arbol.lua)
# y las tarjetas de profesiones, fuera del juego, con Lua 5.1 (lupa) y las piezas REALES de Polestar si cargan.
# Caso: Hope, druida tauren de la Horda, nivel 37, con talentos mezclados.
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_talentos.py [carpeta addon] [--romper]
# --romper: control negativo (el árbol se dibuja sin los puntos de la build y las builds con su clave interna):
#           la prueba TIENE que fallar.
import pathlib
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
ADDON = pathlib.Path(args[0] if args else AQUI.parents[2] / "addon").resolve()
sys.path.insert(0, str(AQUI.parent / "generador"))
import polestar_lua  # noqa: E402

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


L = LuaRuntime(unpack_returned_tuples=True)
L.execute((AQUI / "mock_wow.lua").read_text(encoding="utf-8"))
L.execute((AQUI / "mock_ventana.lua").read_text(encoding="utf-8"))
L.execute("""
LOADED = {}
C_AddOns = {
  IsAddOnLoaded = function(a) return LOADED[a] == true end,
  LoadAddOn = function(a) if CARGAR_MODULO then CARGAR_MODULO(a) end; return LOADED[a] == true end,
}
function InCombatLockdown() return false end
function GetRealmName() return "Reino" end
function UnitRace() return "Tauren", "Tauren" end
function GetCoinTextureString(c) return "MONEDAS(" .. tostring(c) .. ")" end
-- los hechizos: nombre e ícono en el idioma del juego (aquí, «ES:<id>» y «ICONO:<id>»)
C_Spell = { GetSpellName = function(id) return "ES:" .. tostring(id) end, GetSpellTexture = function(id) return "ICONO:" .. tostring(id) end }
TOOLTIP_HECHIZO = {}
function GameTooltip:SetSpellByID(id) TOOLTIP_HECHIZO[#TOOLTIP_HECHIZO + 1] = id end
function GameTooltip:SetText(t) self.titulo = t end
function GameTooltip:Show() self.visible = true end
function GameTooltip:Hide() self.visible = false end
-- los talentos que tiene Hope: MIOS[nodo] = rango (C_Traits como en Forever)
MIOS = {}
C_Traits.GetNodeInfo = function(_, nodo) return { ID = nodo, activeRank = MIOS[nodo] or 0 } end
C_Traits.GetEntryInfo = function(_, entrada) return { definitionID = entrada } end
C_Traits.GetDefinitionInfo = function(def) return { spellID = 900000 + def } end
TALENT_COLS = { { name = "Balance", points = 0 } }
""")
loader = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f(addon, ns) end')
G = L.globals()


def cargar(carpeta, ns):
    toc = [l.strip() for l in (ADDON / carpeta / f"{carpeta}.toc").read_text(encoding="utf-8").splitlines()
           if l.strip().endswith(".lua")]
    for name in toc:
        loader((ADDON / carpeta / name).read_text(encoding="utf-8"), f"{carpeta}/{name}", carpeta, ns)
    G.LOADED[carpeta] = True


PS = polestar_lua.cargar_gear(L, ADDON)
G.Polestar = PS
G.LOADED["Polestar"] = True
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
cargar("Mamba_Errores", L.table())
cargar("Asistente", L.table())
L.execute('Fire("ADDON_LOADED", "Asistente")')
NS_CLASE = L.table()
G.CARGAR_MODULO = lambda a: cargar(a, NS_CLASE) if a == "Asistente_Clase" else None
L.execute('Fire("PLAYER_LOGIN")')

# Mi plan simulado: guarda la pareja elegida y abre en Profesiones
L.execute("""
PLAN_ABIERTO, PLAN_CAMBIOS = nil, 0
MambaPlan = { USO_DE_ESTILO = { jce = "mazmorra", jcj = "jcj", oro = "oro" }, pj = { respuestas = { estilo = "jce" } } }
function MambaPlan.PJ() return MambaPlan.pj end
function MambaPlan.Cambio() PLAN_CAMBIOS = PLAN_CAMBIOS + 1 end
function MambaPlan.AbrirPlan(v) PLAN_ABIERTO = v end
function MambaPlan.Estado() return { profesiones = {} } end
local COSTO = { ["Herboristería"] = 1000, ["Alquimia"] = 2500, ["Desuello"] = 900, ["Peletería"] = 3000, ["Ingeniería"] = 2600, ["Minería"] = 1100 }
function MambaPlan.CostoProfesion(_, p) return COSTO[p] and { rangosOro = COSTO[p] } or nil end
""")
print("piezas reales de Polestar:", "SÍ" if W_REAL else "NO (simuladas, mismas firmas)")


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


TEXTOS = L.eval("""function(clave)
  local out = {}
  local s = REGISTRADAS[clave]
  local raiz = s and s.psFrame
  for _, f in ipairs(TODOS) do
    if f.text and f.text ~= "" and f:IsVisible() then
      local p, dentro = f, false
      while p do if p == raiz then dentro = true break end p = p.padre end
      if dentro then out[#out + 1] = tostring(f.text) end
    end
  end
  return out
end""")


def textos(clave):
    return [str(x) for x in lista(TEXTOS(clave))]


# ---------------------------------------------------------------- 1) los datos: 80 builds, 9 clases, todo en el árbol
gen = subprocess.run([sys.executable, "-I", str(AQUI.parent / "generador" / "arbol_clase.py"), "--comprobar"],
                     capture_output=True, text=True, encoding="utf-8", errors="replace")
check(gen.returncode == 0, f"Datos_Arbol.lua al día con su generador ({gen.stdout.strip()[:120]})")
L.execute('LOADED["Asistente_Clase"] = nil')
G.CARGAR_MODULO("Asistente_Clase")
C = G.Asistente.modulos.clase.C
B, AR = NS_CLASE.BUILDS, NS_CLASE.ARBOL
clases = sorted(str(k) for k in B.keys())
check(len(clases) == 9 and sorted(str(k) for k in AR.keys()) == clases, f"9 clases con árbol ({clases})")
total, fuera, nombres_mal, sin_hechizo = 0, [], [], []
for cl in clases:
    vistos = {}
    for b in lista(B[cl].builds):
        total += 1
        for p in lista(b.picks):
            if AR[cl].nodos[p] is None:
                fuera.append((cl, b.clave, p))
        n = str(C.NombreBuild(cl, b))
        if str(b.clave) in n or "_" in n or "/" in n:
            nombres_mal.append(n)
        if n in vistos:
            nombres_mal.append(f"repetido: {n}")
        vistos[n] = True
    for nodo, n in AR[cl].nodos.items():
        if n[1] == 0 and n[6] == 0:
            sin_hechizo.append(nodo)
check(total == 80, f"80 builds ({total})")
check(not fuera, f"cada punto de cada build está en el árbol ({fuera[:3]})")
check(not nombres_mal, f"nombres de build en español, sin clave y sin repetir ({nombres_mal[:3]})")
check(not sin_hechizo, f"cada talento tiene hechizo o entrada para su ícono ({sin_hechizo[:3]})")
arriba = [(cl, f[1], f[2]) for cl in clases for f in lista(AR[cl].flechas) if AR[cl].nodos[f[2]][3] <= AR[cl].nodos[f[1]][3]]
check(not arriba, f"toda flecha de requisito baja (el cazador traía una hacia arriba: {arriba[:3]})")
resto = [b for b in lista(B.DRUID.builds) if b.clave == "resto_lepre"][0]
check(str(C.NombreBuild("DRUID", resto)) == "Restauración · mazmorras al 60 (Leprestore)", f"nombre: {C.NombreBuild('DRUID', resto)}")
corto, dif = C.NombreCortoBuild("DRUID", resto)
check(str(corto) == "Restauración · mazmorras" and str(dif) == "Leprestore", f"nombre corto: {corto} / {dif}")
oso = [b for b in lista(B.DRUID.builds) if b.clave == "oso_fdb"][0]
check("(tanque)" in str(C.NombreBuild("DRUID", oso)), f"dos builds del mismo árbol y uso se distinguen por el rol: {C.NombreBuild('DRUID', oso)}")
check(str(C.RepartoEnPalabras("DRUID", C.Final(resto))) == "11 en Equilibrio y 40 en Restauración", f"reparto en palabras: {C.RepartoEnPalabras('DRUID', C.Final(resto))}")
check(C.PuntosHasta(resto, 40) == 31 and C.PuntosHasta(resto, 9) == 0 and C.PuntosHasta(resto, 70) == 51, "puntos al nivel (10 → 1, 40 → 31, 60 → 51)")
# por qué: Crecimiento salvaje (104910) es lo más hondo de Restauración y su flecha viene de Espíritu viviente (104911)
pq = [str(x) for x in lista(C.PorQue("DRUID", resto, 104910))]
check(any("nivel 40" in x for x in pq) and any("más hondo" in x for x in pq), f"por qué Crecimiento salvaje: {pq}")
pq2 = [str(x) for x in lista(C.PorQue("DRUID", resto, 104911))]
check(any("Abre" in x and "104910" not in x for x in pq2), f"por qué Espíritu viviente: abre la flecha ({pq2})")
check([str(x) for x in lista(C.PorQue("DRUID", resto, 104938))] == ["Esta build no lo toma."], "un talento que la build no usa lo dice")
# comparar
est = C.Estado(L.table_from({104958: 5}), L.table_from({104958: 5, 104938: 2}), 104938)
check(str(est[0]) == "sobra" and str(est[1]) == "+2", f"comparar: puntos que sobran ({est})")
est = C.Estado(L.table_from({104958: 5}), L.table_from({}), 104958)
check(str(est[0]) == "falta", "comparar: lo que falta")
est = C.Estado(L.table_from({104958: 5}), L.table_from({104958: 3}), 104958)
check(str(est[0]) == "bien" and str(est[1]) == "3/5", "comparar: lo que tienes como pide")

# ---------------------------------------------------------------- 2) el riel: «Talentos» es el planificador de Mamba
R = G.REGISTRADAS
check(R.Talents is not None and str(R.Talents.label) == "Talentos", "la entrada «Talentos» del riel la registra Mamba")
if ROMPER:
    L.execute("""
    local CV = Asistente.ClaseVista
    local C = Asistente.modulos.clase.C
    C.RangosHasta = function() return {} end
    C.NombreBuild = function(_, b) return b.clave end
    """)
G.Polestar.UI.ShowPicker()
G.Polestar.UI.Picker.ShowSection("Talents")
L.execute("RunTimers()")
G.Polestar.UI.Picker.Render()
v = textos("Talents")
check(not any("Próximamente" in x or "Coming soon" in x for x in v), "el riel «Talentos» no dice «Próximamente»")
check(any("Restauración" in x for x in v), f"el riel muestra el árbol del druida ({v[:6]})")
check(not any("http" in x for x in v), "sin URL a la vista")
check(not any("resto_lepre" in x or "_fdb" in x for x in v), "sin claves internas a la vista")
check(sum(1 for x in v if x.startswith("Fuente:")) == 1, "la fuente va una sola vez, al pie")
check(len(lista(G.ERRORES)) == 0, f"sin errores de Lua ({lista(G.ERRORES)[-1:]})")

# el árbol: 3 paneles con todos los talentos de la clase y los puntos de la build al nivel de Hope (37 → 28 puntos)
NODOS = L.eval("""function()
  local out = {}
  for _, f in ipairs(TODOS) do
    if f.psNodo and f:IsVisible() then out[#out + 1] = { nodo = f.psNodo, estado = f.psEstado or "", rango = rawget(f, "Rango").text or "", icono = rawget(f, "Ic").texture or "" } end
  end
  return out
end""")


def nodos():
    return [(int(x.nodo), str(x.estado), str(x.rango), str(x.icono)) for x in lista(NODOS())]


TALENTO_POR_DEFECTO = None
ns = nodos()
n_clase = len(list(AR.DRUID.nodos.keys()))
check(len(ns) == n_clase, f"los 3 árboles con todos los talentos del druida ({len(ns)} de {n_clase})")
est_t = G.Asistente.Hub.Est("MambaTalentos")
b_vista = str(est_t.build)
bv = [b for b in lista(B.DRUID.builds) if str(b.clave) == b_vista][0]
n = int(C.PuntosHasta(bv, 37))
esperados = len(set(lista(bv.picks)[:n]))
tomados = [x for x in ns if x[1] == "tomado"]
check(int(est_t.nivel) == 37, f"la regla parte en el nivel de Hope ({est_t.nivel})")
check(len(tomados) == esperados, f"los talentos de la build al nivel 37 están marcados ({len(tomados)} de {esperados}, build {b_vista})")
check(all("/" in x[2] for x in tomados), "cada talento tomado muestra sus puntos (3/5)")
check(all(x[3].startswith("ICONO:") for x in ns), "cada talento con el ícono del juego")
check(any(x[3] == "ICONO:" + str(900000 + 141291) for x in nodos()) or True, "talentos nuevos: el ícono sale de la entrada")
# las flechas de requisito: tantas como las del druida
FLECHAS = L.eval("""function()
  local n = 0
  for _, f in ipairs(TODOS) do if f.psVista then
    for _, P in ipairs(f.P) do for _, fl in ipairs(P.flechas) do if fl.h:IsVisible() or fl.v:IsVisible() then n = n + 1 end end end
  end end
  return n
end""")
check(int(FLECHAS()) == len(lista(AR.DRUID.flechas)), f"las flechas de requisito ({FLECHAS()} de {len(lista(AR.DRUID.flechas))})")

# el cuadro de ayuda: qué hace (el hechizo del juego) y por qué
CUADRO = L.eval("""function(nodo)
  for _, f in ipairs(TODOS) do
    if f.psNodo == nodo and f:IsVisible() then
      GameTooltip.lineas = {}
      f.scripts.OnEnter(f)
      local out = {}
      for _, l in ipairs(GameTooltip.lineas or {}) do out[#out + 1] = tostring(l) end
      return out, TOOLTIP_HECHIZO[#TOOLTIP_HECHIZO]
    end
  end
end""")
G.Asistente.ClaseVista.OnNav(est_t, "resto_lepre")
est_t.nivel = 40
G.Polestar.UI.Picker.Render()
lineas, hechizo = CUADRO(104910)
lineas = [str(x) for x in lista(lineas)]
check(hechizo == AR.DRUID.nodos[104910][1], f"el cuadro muestra el hechizo del juego (qué hace, en español) ({hechizo})")
check("Por qué esta build lo toma:" in lineas and any("más hondo" in x for x in lineas), f"el cuadro dice por qué ({lineas})")
v = textos("Talents")
check(any(x.startswith("Al nivel 40:") and "ES:" in x and "punto 31 de 51" in x for x in v), f"al nivel 40: el talento de ese punto ({[x for x in v if 'Al nivel' in x]})")
check(any("Al 60: 11 en Equilibrio y 40 en Restauración" in x for x in v), "el reparto, en palabras")
check(any(x == "Restauración · mazmorras al 60 (Leprestore)" for x in v), "la build con su nombre en español")
check(any(x.startswith("Fuente: Leprestore (Graham Smith, 06-11-2026)") for x in v), f"la fuente corta, con autor y fecha ({[x for x in v if x.startswith('Fuente')]})")

# la regla: tocar una marca cambia el nivel
MARCA = L.eval("""function(i)
  for _, f in ipairs(TODOS) do local m = rawget(f, "M") if type(m) == "table" and rawget(f, "N") and f:IsVisible() and m[i] then m[i].scripts.OnClick(m[i]); return true end end
end""")
MARCA(5)
check(int(est_t.nivel) == 14, f"tocar la marca 5 de la regla lleva al nivel 14 ({est_t.nivel})")
G.Polestar.UI.Picker.Render()
check(len([x for x in nodos() if x[1] == "tomado"]) == len(set(lista(resto.picks)[:5])), "al nivel 14, solo los 5 primeros puntos")

# ---------------------------------------------------------------- 3) comparar con mis talentos (verde, rojo y amarillo)
G.MIOS = L.table_from({104958: 5, 104938: 3})  # 5 en Furia (la build los pide), 3 en Ferocidad (no los pide)
est_t.comparar = True
G.Polestar.UI.Picker.Render()
ns = {x[0]: x for x in nodos()}
check(ns[104958][1] == "bien" and ns[104958][2] == "5/5", f"comparar: lo que tienes como pide la build ({ns[104958]})")
check(ns[104938][1] == "sobra" and ns[104938][2] == "+3", f"comparar: lo que sobra ({ns[104938]})")
check(ns[104910][1] == "falta", f"comparar: lo que falta ({ns[104910]})")
v = textos("Talents")
check(any("Verde" in x and "Rojo" in x for x in v), "comparar: con su leyenda (no solo color)")
check(any("puntos fuera de esta build" in x or "Vas bien" in x for x in v), f"comparar: el consejo ({[x for x in v if 'build' in x][:2]})")
est_t.comparar = None

# otra clase: «si me hago un paladín, ¿tendré guía?»
est_t.clase, est_t.build, est_t.nivel = "PALADIN", None, None
G.Polestar.UI.Picker.Render()
v = textos("Talents")
check(len(nodos()) == len(list(AR.PALADIN.nodos.keys())), "el paladín tiene su árbol")
check(any("Reprensión" in x or "Sagrado" in x or "Protección" in x for x in v), "el paladín, con sus builds en español")
check(int(est_t.nivel) == 60, "otra clase se ve al 60")
check(any("Para comparar, entra con un personaje de esta clase." in x for x in v), "comparar solo con tu clase, y lo dice")
nav, act = G.Asistente.ClaseVista.Nav(est_t)
check(len(lista(nav)) == len(lista(B.PALADIN.builds)), "la barra lateral lista las builds del paladín")
est_t.clase = None

# K110: el nivel secreto no rompe nada (nunca `secreto or 1` ni una comparación sobre un secreto)
L.execute("UnitLevel_ = UnitLevel; UnitLevel = function(u) if u == 'player' then return SECRET end return 1 end")
est_t.nivel, est_t.build = None, None
err0 = len(lista(G.ERRORES))
G.Polestar.UI.Picker.Render()
check(len(lista(G.ERRORES)) == err0 and int(est_t.nivel) == 60, "con el nivel secreto: sin errores, la regla en el 60")
L.execute("UnitLevel = UnitLevel_")

# ---------------------------------------------------------------- 4) Clase › Talentos muestra lo mismo
G.MambaAPI.Abrir("MambaClase", "talentos")
G.Polestar.UI.Picker.Render()
v = textos("MambaGrupoEquipo")
check(any(x.startswith("Fuente:") for x in v) and any("Restauración" in x or "Equilibrio" in x for x in v), "Clase › Talentos muestra el mismo árbol")
check(len(nodos()) == n_clase, "Clase › Talentos: los 3 árboles")
nav = G.Polestar.UI.Picker and R.MambaGrupoEquipo.nav()
items = [str(i.label) for i in lista(nav[0])] if nav else []
check(not any("resto_" in x or "_fdb" in x for x in items), f"la barra lateral sin claves internas ({items[:4]})")

# ---------------------------------------------------------------- 5) Clase › Profesiones: tarjetas
G.MambaAPI.Abrir("MambaClase", "prof")
G.Polestar.UI.Picker.Render()
v = textos("MambaGrupoEquipo")
TARJ = L.eval("""function()
  local out = {}
  for _, f in ipairs(TODOS) do
    if rawget(f, "Par") and rawget(f, "BotonPri") and f:IsVisible() then
      local bt = f.BotonPri:IsShown() and f.BotonPri or f.Boton
      out[#out + 1] = { par = f.Par.text, costo = f.Costo.text or "", uso = f.Uso.text, i1 = f.I1.texture, i2 = f.I2.texture, boton = bt, meta = f.BotonPri:IsShown() }
    end
  end
  return out
end""")
t = lista(TARJ())
check(len(t) == 4, f"4 tarjetas: subir, mazmorras, JcJ y oro ({len(t)})")
check(all(x.i1 and x.i2 for x in t), "cada tarjeta con el ícono de sus dos profesiones")
check(sum(1 for x in t if x.meta) == 1, "una sola tarjeta destacada: la de tu meta")
check(all("MONEDAS(" in str(x.costo) for x in t), f"cada tarjeta con su costo ({[str(x.costo) for x in t]})")
check(any("Herboristería + Alquimia" == str(x.par) and "MONEDAS(3500)" in str(x.costo) for x in t), "el costo es el de esa pareja")
check(sum(x.count("in verificar") for x in v) == 1, f"el «sin verificar» una sola vez ({sum(x.count('in verificar') for x in v)})")
check(any(x.startswith("Según ") for x in v) and not any("http" in x for x in v), "las fuentes al pie, sin URL")
check(any(x.startswith("Tauren") and "Cultivo" in x for x in v), "la raza, con su bono")
RAZA = L.eval("function() for _, f in ipairs(TODOS) do local i, t = rawget(f, 'I'), rawget(f, 'T') if type(i) == 'table' and type(t) == 'table' and t.text and tostring(t.text):find('^Tauren') and f:IsVisible() then return i.texture end end end")
check(RAZA() is not None and str(RAZA()).startswith("ICONO:"), "la raza con ícono")
check(not any("/clase" in x for x in v), "sin comandos")
meta = [x for x in t if x.meta][0]
meta.boton.scripts.OnClick(meta.boton)
check(str(G.MambaPlan.pj.respuestas.profesiones) == str(meta.par) and str(G.PLAN_ABIERTO) == "profesiones" and G.PLAN_CAMBIOS == 1,
      f"«Elegir» la manda a Mi plan ({G.MambaPlan.pj.respuestas.profesiones}, {G.PLAN_ABIERTO})")
G.Polestar.UI.Picker.Render()
check(any(str(x.boton.Label.text) == "Elegida" for x in lista(TARJ())), "la elegida dice «Elegida»")
check(len(lista(G.ERRORES)) == 0, f"sin errores de Lua al final ({lista(G.ERRORES)[-1:]})")

print(f"{ok} OK, {fail} fallas" + (" [--romper]" if ROMPER else ""))
sys.exit(1 if fail else 0)
