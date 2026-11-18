"""Pruebas de Mamba_Plan con Lua 5.1 (lupa). Uso: python test_plan.py [carpeta de Mamba_Plan]

Reusa la simulación de mock_barras.lua (eventos desconocidos, combate) y le suma lo que lee el plan: nivel,
oro, profesiones, bolsas, hechizos conocidos y macros. Lo que NO prueba: cómo se ve (eso, en el juego).
"""
import sys, pathlib, re
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent.parent.parent / "addon" / "Mamba_Plan"
toc = (D / "Mamba_Plan.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


# Hope el 18-11: druida tauren 39, Herboristería 212/225 y Alquimia 190/225, 84 o, 4 bolsas (una de 6).
HOPE = '''
NIVEL = 39; ORO = 84 * 10000 + 1200; CLASE = "DRUID"
CONOCE = { [774] = true, [8936] = true, [5185] = true, [783] = true, [768] = true, [5487] = true, [9005] = true,
  [1082] = true, [339] = true, [8921] = true }
NOMBRES = { [774] = "Rejuvenecimiento", [8936] = "Recrecimiento", [5185] = "Toque de sanación", [783] = "Forma de viaje",
  [768] = "Forma felina", [5487] = "Forma de oso", [9005] = "Abalanzarse", [1082] = "Zarpa", [339] = "Raíces enredadoras",
  [8921] = "Fuego lunar" }
PROFS = { { "Herboristería", 212, 225 }, { "Alquimia", 190, 225 } }
BOLSAS = { [0] = { 16, 2 }, [1] = { 14, 1, 1 }, [2] = { 14, 1, 2 }, [3] = { 14, 1, 3 }, [4] = { 6, 1, 4 } }
MACROS = {}
'''
MOCK = '''
function UnitLevel() return NIVEL end
function UnitRace() return "Tauren", "Tauren" end
function UnitFactionGroup() return "Horde" end
function UnitClass() return "Druida", CLASE end
function UnitName() return "Hope" end
function GetMoney() return ORO end
function UnitXP() return 100 end
function UnitXPMax() return 1000 end
function GetProfessions() return 1, 2, nil, nil, nil, nil end
function GetProfessionInfo(i) local p = PROFS[i]; return p[1], 0, p[2], p[3], 0, 0, 100 + i end
C_Container = {
  GetContainerNumSlots = function(b) return BOLSAS[b] and BOLSAS[b][1] or 0 end,
  GetContainerNumFreeSlots = function(b) return BOLSAS[b] and BOLSAS[b][2] or 0 end,
  ContainerIDToInventoryID = function(b) return 30 + b end,
}
function GetInventoryItemID(_, inv) local b = BOLSAS[inv - 30]; return b and b[3] and (4000 + b[3]) or nil end
function GetNumTalentTabs() return 3 end
function GetTalentTabInfo(t) return t, ({ "Equilibrio", "Combate feral", "Restauración" })[t], 0, 0, ({ 19, 0, 8 })[t] end
function IsPlayerSpell(id) return CONOCE[id] or false end
C_Spell = { GetSpellName = function(id) return NOMBRES[id] end }
function GetMacroIndexByName(n) for i, m in ipairs(MACROS) do if m[1] == n then return i end end return 0 end
function CreateMacro(n, icono, cuerpo, pj) table.insert(MACROS, { n, cuerpo }); return #MACROS end
CURSOR = nil
function PickupMacro(i) CURSOR = i end
C_Map = { GetMapInfo = function(id) return { name = "Zona " .. id } end, GetBestMapForUnit = function() return 1412 end }
'''


def nuevo(antes=""):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(HOPE + MOCK)
    if antes:
        L.execute(antes)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Plan", M) end')
    for n in ARCHIVOS:
        cargar((D / n).read_text(encoding="utf-8"), n, M)
    return L, M


# ---------- 0. toc y fuente única de las profesiones ----------
check("## Interface: 16001" in toc and "SavedVariablesPerCharacter: MambaPlanPJ" in toc, "toc")
orig = pathlib.Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER\addon\Asistente_Clase\Datos_Profesiones.lua")
if orig.exists():
    check((D / "DatosProfesiones.lua").read_bytes() == orig.read_bytes(), "DatosProfesiones.lua es copia exacta de Asistente_Clase (fuente única)")

L, M = nuevo()
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(not list(G.ERRORES.values()), "errores al entrar: %s" % list(G.ERRORES.values()))

# ---------- 1. Estado ----------
e = M.Estado()
check(e.nivel == 39 and e.clase == "DRUID" and e.raza == "Tauren" and e.oro == 841200, "estado básico")
check(len(list(e.profesiones.values())) == 2 and e.profesiones[1].nombre == "Herboristería" and e.profesiones[2].rango == 190, "profesiones")
check(e.bolsas.total == 16 + 14 * 3 + 6 and e.bolsas.libres == 6 and e.bolsas.vacias == 0, "bolsas: %s %s" % (e.bolsas.total, e.bolsas.libres))
check(e.talentos[1].puntos == 19 and e.talentos[3].puntos == 8, "talentos 19/0/8")

# ---------- 2. Datos ----------
check(M.EQUITACION[33388][1] == 40 and M.EQUITACION[33388][2] == 900000, "equitación al 40: 90 o (ForeverTDB)")
kodo = M.MonturaDeRaza("Tauren", 40)
check(kodo is not None and "Kodo" in kodo.nombre and kodo.precio == 200000 and kodo.forever, "kodo de Forever: 20 o")
check(M.RANGOS["Alquimia"][4].tope == 300 and M.RANGOS["Alquimia"][4].nivel == 35, "Artesano de Alquimia: nivel 35")
check(M.LUGAR[1386][1] == "H", "instructor Artesano de Alquimia de la Horda")
n = sum(1 for _ in M.CONOCIDAS.values())
check(n >= 50 and all(b.url.startswith("http") for b in M.CONOCIDAS.values()), "builds conocidas con enlace: %d" % n)

# ---------- 3. Metas ----------
metas = list(M.Metas(e).values())
claves = [m.clave for m in metas]
check("entrenar40" in claves and "montura40" in claves, "metas: entrenar 40 y montura 40: %s" % claves)
mont = [m for m in metas if m.clave == "montura40"][0]
check(mont.costo == 900000 + 200000 + M.ENTRENAR.DRUID[40], "montura 40 = 90 o + 20 o + hechizos del 40")
check(mont.falta == max(0, mont.acumulado - 841200), "lo que falta, pagando en orden")
check("rangoAlquimia300" in claves and "rangoHerboristería300" in claves, "Artesano de las dos profesiones")
check([m.nivel for m in metas] == sorted(m.nivel for m in metas), "en orden de nivel")

# ---------- 4. Bolsas ----------
b = M.Bolsas(e)
check(b.menor == 6, "la más chica: 6")
check(b.recomendada is None or (b.recomendada.familia == "bolsa" and b.recomendada.casillas > 6), "recomendada: común y más grande")
especiales = [o.familia for o in b.opciones.values() if o.familia != "bolsa"]
check("hierbas" in especiales and "carcaj" not in especiales and "almas" not in especiales, "especiales: hierbas sí (Herboristería), carcaj y almas no: %s" % set(especiales))

# ---------- 5. Profesiones recomendadas ----------
G.MambaPlanPJ.respuestas = L.eval('{ rol = "sanar", estilo = "jce" }')
recs = list(M.ProfesionesRecomendadas(e, G.MambaPlanPJ.respuestas).values())
pares = [" + ".join(r.par.values()) for r in recs]
check("Desuello + Peletería" in pares and "Herboristería + Alquimia" in pares, "druida: subir y mazmorra: %s" % pares)
hierba = [r for r in recs if "Herboristería" in list(r.par.values())]
check(any(r.raza for r in hierba), "tauren: Cultivo junto a Herboristería")
check(all(len(list(r.fuentes.values())) > 0 for r in recs if r.uso != "ya"), "cada recomendación con fuente")

# ---------- 6. Pasos de Ahora ----------
pasos = list(M.Pasos(e, G.MambaPlanPJ.respuestas).values())
check(pasos[0].clave == "guia", "la guía primero")
check(any(p.clave == "rango:Herboristería300" for p in pasos), "Herboristería 212/225: aprende Artesano")
check(not any(p.clave == "rango:Alquimia300" for p in pasos), "Alquimia 190/225 todavía no")
check(any(p.clave.startswith("macro:dru") for p in pasos), "macros sugeridas de sanar")
G.MambaPlanPJ.descartados["rango:Herboristería300"] = True
check(not any(p.clave == "rango:Herboristería300" for p in M.Pasos(e, G.MambaPlanPJ.respuestas).values()), "No me interesa lo saca")

# ---------- 7. Macros ----------
okm, motivo = M.CrearMacro("druRejuRaton")
check(okm and G.MACROS[1][1] == "M·druRejuRaton" and "Rejuvenecimiento" in G.MACROS[1][2] and G.CURSOR == 1, "macro creada con el nombre del juego y en el cursor")
check("{" not in G.MACROS[1][2], "sin marcas {id} sin reemplazar")
okm2, _ = M.CrearMacro("druRejuRaton")
check(okm2 and len(list(G.MACROS.values())) == 1, "no se duplica")
L.execute('COMBATE = true')
okm3, motivo3 = M.CrearMacro("druOso")
check(not okm3 and "combate" in motivo3, "en combate no se crea")
L.execute('COMBATE = false')
for clase, lista in M.MACROS.items():
    for m in lista.values():
        for id_ in re.findall(r"\{(\d+)\}", m.cuerpo):
            check(int(id_) in list(m.usa.values()) or int(id_) == 20252, "%s %s: {%s} está en usa" % (clase, m.clave, id_))

# ---------- 8. Inicio y sección ----------
L2, M2 = nuevo('Polestar = { UI = { Picker = {} } }; function Polestar.UI.RegisterSection(s) SECCION = s; return true end; '
               'function Polestar.UI.ShowPicker() ABIERTO = true end; function Polestar.UI.Picker.ShowSection(k) VISTA = k end; '
               'function Polestar.UI.Picker.Render() end')
G2 = L2.globals()
L2.execute('Fire("PLAYER_LOGIN")')
check(G2.MambaPlanInicio is not None and G2.MambaPlanInicio.visible, "primera vez: el asistente se abre solo")
S = G2.SECCION
check(S is not None and S.key == "MambaPlan" and S.order == 21, "sección Mi plan en el riel, lugar 20")
items, activa = S.nav()
check(len(list(items.values())) == 10 and activa == "ahora", "índice de Mi plan")
padre = L2.eval('function() local f = CreateFrame("Frame", nil, UIParent); f.w, f.h = 700, 500; return f end')()
S.build(padre)
for v in ["ahora", "metas", "talentos", "equipo", "profesiones", "farmeo", "bolsas", "dinero", "macros", "builds"]:
    S.onNav(v)
    S.render()
check(not list(G2.ERRORES.values()), "todas las vistas sin errores: %s" % list(G2.ERRORES.values())[:3])
check(not list(G2.MambaPlanPJ.diag.fallas.values()) if G2.MambaPlanPJ.diag.fallas else True, "sin fallas anotadas")

# ---------- 8b. Corrección de Cristian (18-11): "Como juego ahora", mixto, especialización y varias metas ----------
ahora = M.ComoJuegaAhora(M.Estado())
check(ahora.nombre == "Equilibrio" and ahora.rol == "danio", "Hope 19/0/8: Equilibrio, daño")
r3 = L.eval('{ rol = "sanar", rol2 = "danio", estilos = { jce = 1, jcj = 2, oro = 2 } }')
usos = [x.uso for x in M.ProfesionesRecomendadas(M.Estado(), r3).values()]
check("mazmorra" in usos and "jcj" in usos and "oro" in usos and usos.index("mazmorra") < usos.index("jcj"),
      "varias metas a la vez, la principal primero: %s" % usos)
L2.execute('MambaPlan.AbrirInicio(); local v = MambaPlanInicio; for i = 1, 4 do v.siguiente.scripts.OnClick(v.siguiente) end')
check(G2.MambaPlanPJ.respondido and not G2.MambaPlanInicio.visible, "los 4 pasos con Siguiente/Listo guardan las respuestas")
check(G2.MambaPlanPJ.respuestas.estilos is not None, "las metas de juego se guardan (varias)")
check(not list(G2.ERRORES.values()), "asistente de 4 pasos sin errores: %s" % list(G2.ERRORES.values())[:2])

# ---------- 8c. Paso "Tu build" (captura de Cristian, 18-11): sin claves internas, UNA recomendada, puntos con nombre ----------
L.execute('''MambaAPI = { Clase = function() return { Builds = function(clase) return {
  { clave = "balance_fdb", rol = "danio", uso = "mazmorra", spec = 1, reparto = "41/0/10", fuente = { nombre = "ForeverDB", fecha = "2026-11-16" } },
  { clave = "gato_fdb", rol = "danio", uso = "mazmorra", spec = 2, reparto = "0/41/10", fuente = { nombre = "ForeverDB" } },
  { clave = "feral_subir_fdb", rol = "danio", uso = "subir", spec = 2, reparto = "0/35/16", fuente = { nombre = "ForeverDB" } },
  { clave = "balance_subir_fdb", rol = "danio", uso = "subir", spec = 1, reparto = "35/0/16", fuente = { nombre = "ForeverDB" } },
  { clave = "resto_lepre", rol = "sanar", uso = "mazmorra", spec = 3, reparto = "11/0/40", fuente = { nombre = "Leprestore" } },
} end } end }''')
grupos, rec = M.BuildsDe(M.Estado(), L.eval('{ rol = "danio", estilo = "jce" }'))
gl = list(grupos.values())
nombres = [b.nombre for g in gl for b in g.lista.values()]
lineas = [b.linea for g in gl for b in g.lista.values()]
check(not any("_fdb" in n or "_lepre" in n for n in nombres), "sin claves internas: %s" % nombres[:5])
check(sum(1 for g in gl for b in g.lista.values() if b.tag == "recomendada") == 1, "UNA sola recomendada")
check(rec is not None and rec.uso == "subir" and rec.rol == "danio", "nivel 39 + daño: la recomendada es para subir")
check(gl[0].grupo == "La que tienes" and "puntos: Equilibrio 19" in gl[0].lista[1].linea, "primero: la que tengo ahora, con puntos por árbol")
check([g.grupo for g in gl][1:3] == ["Para subir de nivel", "Al 60"], "agrupadas: subir y al 60")
check(any("puntos: Equilibrio 41 · Combate feral 0 · Restauración 10" in l for l in lineas), "41/0/10 con nombres de árbol")
check(any("Equilibrio · mazmorras al 60" in n for n in nombres), "nombre en español: Equilibrio · mazmorras al 60")
check("Es la de daño para subir de nivel" in rec.linea, "la recomendada dice por qué")
L2.execute('''MambaAPI = { Clase = function() return { Builds = function() return {
  { clave = "balance_fdb", rol = "danio", uso = "mazmorra", spec = 1, reparto = "41/0/10", fuente = { nombre = "ForeverDB" } } } end } end }
MambaPlanPJ.respondido = nil
MambaPlan.AbrirInicio(); local v = MambaPlanInicio; for i = 1, 4 do v.siguiente.scripts.OnClick(v.siguiente) end''')
check(not list(G2.ERRORES.values()) and G2.MambaPlanPJ.respuestas.build is not None and G2.MambaPlanPJ.respuestas.profesiones is not None,
      "con builds: los 4 pasos sin errores, y la recomendada queda elegida si no tocas nada")
if len(gl) > 3:
    con = list(gl[3].lista.values())
    check(gl[3].grupo == "De jugadores conocidos" and all(c.tag == "de un jugador conocido" for c in con), "conocidas con autor, aparte")

# ---------- 8d. "Ahora" = el próximo paso de la guía (prueba de la coordinadora en el juego, 18-11) ----------
L.execute('''Polestar = Polestar or {}
Polestar.Engine = { GetGuide = function() return { title = "Mulgore 1-12", steps = {
  { goals = { { text = "Entrega La caza del jabalí", status = "done" }, { text = "Entrega 2 misiones en Orgrimmar" } } },
  { goals = { { text = "Vuela a Molino Tarren" } } } } } end,
  GetLiveStep = function() return 1 end, StepNumber = function(i) return i end, StepTotal = function() return 2 end }
Polestar.UI = Polestar.UI or {}; Polestar.UI.PlainGoalText = function(g) return g.text end''')
pasos = list(M.Pasos(M.Estado(), G.MambaPlanPJ.respuestas).values())
check(pasos[0].tipo == "Ahora" and pasos[0].titulo == "Entrega 2 misiones en Orgrimmar  →  Vuela a Molino Tarren",
      "Ahora: el próximo paso de la guía, sin lo ya hecho: %s" % pasos[0].titulo)
check("Mulgore 1-12 · paso 1 de 2" in pasos[0].detalle, "guía y número de paso")
check(any(p.clave == "meta:entrenar40" or p.clave == "meta:montura40" for p in pasos), "al 39: entrenar y montura del 40 en Ahora")

# ---------- 8e. Cambiar de vista aunque Polestar llame a render con la sección todavía oculta ----------
S.onNav("equipo"); S.render()
padre.visible = False
S.onNav("ahora"); S.render()
check(M2.ultimaVista == "ahora", "Ahora se dibuja aunque la sección esté oculta al llamar a render (visto en el juego: quedaba Equipo)")
padre.visible = True

# ---------- 9. Prueba estática ----------
for n in ARCHIVOS:
    src = (D / n).read_text(encoding="utf-8")
    check(not re.search(r"\b(CastSpell\w*|UseAction|RunMacroText|TargetUnit|PlaceAuctionBid|PostAuction|BuyMerchantItem)\b", src),
          n + ": nada que juegue, compre o venda por el jugador")
    if n not in ("Piezas.lua",):
        check("|cff" not in src.lower() and not re.search(r"GameFont\w+", src), n + ": sin colores ni letras fijas (E2/E3)")

print(f"{ok} OK, {fail} FALLAN")
sys.exit(1 if fail else 0)
