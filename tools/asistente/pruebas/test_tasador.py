import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

D = pathlib.Path(sys.argv[1])
L = LuaRuntime(unpack_returned_tuples=True)
L.execute((pathlib.Path(__file__).parent / "mock_wow.lua").read_text(encoding="utf-8"))
T = L.table()
loader = L.eval('function(src, name, T) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Tasador", T) end')
# Mismo orden que Tasador.toc
toc = [l.strip() for l in (D / "Tasador.toc").read_text(encoding="utf-8").splitlines() if l.strip().endswith(".lua")]
for name in toc:
    loader((D / name).read_text(encoding="utf-8"), name, T)
print("CARGA OK", toc)
L.execute('Fire("ADDON_LOADED", "Tasador")')
ok = 0
fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def E(**kw):
    return T.Evaluar(L.table_from(kw))


def rol():
    r = T.RolActual()
    return r[0] if isinstance(r, tuple) else r


def lines_of(lua_table):
    return [str(x) for x in lua_table.values()]


A = T.ACCION

# --- Reglas básicas ---
check(T.Dinero(12345) == "1o 23p 45c", T.Dinero(12345))
check(T.Dinero(0) == "0c", "dinero 0")
check(E(calidad=0, vendedor=50).accion == A.VENDEDOR, "gris")
check(E(calidad=0, vendedor=0).accion == A.BOTAR, "gris sin valor")
check(E(calidad=1, clase=12, vendedor=0).accion == A.GUARDAR, "mision")
check(E(calidad=2, liga=1, vendedor=500, clase=4).accion == A.VENDEDOR, "BoP")
check(E(calidad=1, liga=1, vendedor=0, reactivo=True).accion == A.GUARDAR, "BoP reactivo")
check(E(calidad=1, liga=1, vendedor=0, clase=4).accion == A.GUARDAR, "ligado sin valor nunca se bota")
r = E(calidad=2, liga=2, vendedor=1000, subasta=50000, clase=4)
check(r.accion == A.SUBASTA and r.nivel == "Caro", f"BoE caro {r.accion} {r.nivel}")
r = E(calidad=2, liga=2, vendedor=1000, subasta=1200, clase=4)
check(r.accion == A.VENDEDOR and r.nivel == "Barato", f"subasta no compensa {r.accion} {r.nivel}")
check(E(calidad=2, liga=2, vendedor=500, clase=2).accion == A.REVISAR, "equipo sin precio")
check(E(calidad=1, liga=0, vendedor=0, subasta=5000, clase=7).accion == A.SUBASTA, "sin vendedor con subasta")
check(E(calidad=1, liga=0, vendedor=10, subasta=30000, diasSubasta=10, clase=7).aviso is not None, "aviso viejo")

# --- ALTA 1: la ganancia mínima es POR MONTÓN, no por unidad ---
# (La prueba vieja de las líneas 42-43 decía "guardar" para un material que vale 9p 40c más por unidad en
#  montones de 20: eso son 18o 80p por montón, así que lo correcto es SUBASTAR.)
r = E(calidad=1, liga=0, vendedor=10, subasta=1000, reactivo=True, clase=7, pila=20)
check(r.accion == A.SUBASTA, f"ALTA1 material x20 que deja 18o por montón -> subastar ({r.accion})")
r = E(calidad=1, liga=0, vendedor=10, subasta=1000, reactivo=True, clase=7, pila=1)
check(r.accion == A.GUARDAR, f"ALTA1 material que no se apila y deja 9p -> guardar ({r.accion})")
r = E(calidad=1, liga=0, vendedor=100, subasta=300, clase=15, pila=20)
check(r.accion == A.SUBASTA, f"ALTA1 x20 con 1p85c más por unidad -> subastar ({r.accion})")
r = E(calidad=1, liga=0, vendedor=100, subasta=300, clase=15, pila=1)
check(r.accion == A.VENDEDOR, f"ALTA1 mismo objeto sin apilar -> vendedor ({r.accion})")
r = E(calidad=1, liga=0, vendedor=10, subasta=30000, reactivo=True, clase=7)
check(r.accion == A.SUBASTA, "reactivo caro -> subastar")

# --- 18: clases 7 y 5 son material aunque no traigan la marca de reactivo ---
check(E(calidad=1, liga=1, vendedor=0, clase=7).accion == A.GUARDAR, "18 clase 7 ligada sin precio -> guardar")
check(T.EsMaterial(L.table_from({"clase": 5})) and T.EsMaterial(L.table_from({"clase": 7})), "18 clases 5 y 7")
check(not T.EsMaterial(L.table_from({"clase": 4})), "18 armadura no es material")
r = E(calidad=1, liga=0, vendedor=10, subasta=40, clase=5, pila=1)
check(r.accion == A.GUARDAR, f"18 reactivo clase 5 barato -> guardar ({r.accion})")

# --- 7: un BoE que ya está ligado no se puede subastar ---
r = E(calidad=2, liga=2, ligado=True, vendedor=500, subasta=50000, clase=4)
check(r.accion == A.VENDEDOR, f"7 BoE ya ligado -> vendedor ({r.accion})")

# --- 8: herramientas y mejoras se guardan ---
check(E(calidad=1, liga=0, vendedor=50, herramienta=True, clase=2).accion == A.GUARDAR, "8 herramienta")
check(E(calidad=2, liga=2, vendedor=500, subasta=50000, mejora=True, clase=4).accion == A.GUARDAR, "8 mejora")
check(T.EsHerramienta(2901, 7, 0) and T.EsHerramienta(999999, 2, 20) and not T.EsHerramienta(999999, 2, 10), "8 pico y caña")

# --- 6: comparación cuando lo puesto suma 0 ---
check(T.Comparar(10, L.table_from([False])) == "vacia", "vacia")
check(abs(T.Comparar(12, L.table_from([10, 15])) - 20) < 1e-9, "anillo peor")
check(T.Comparar(5, L.table_from([0])) == "sinbase", "6 lo puesto suma 0 -> sin porcentaje")
pesos = T.PesosPara("DRUID", "sanacion", 37)
s = T.Puntaje(L.table_from({"ITEM_MOD_INTELLECT_SHORT": 10, "ITEM_MOD_SPELL_HEALING_DONE_SHORT": 10, "XX": 5}), pesos)
check(abs(s - 17) < 1e-9, f"puntaje {s}")
check(T.PesosPara("DRUID", "equilibrio", 37).int == 1 and T.PesosPara("DRUID", "equilibrio", 45).int == 0.577, "bandas")

# --- ALTA 4: bonificaciones "Equipar:" ---
def clas(t):
    c = T.ClasificarEquipar(t)
    return None if c is None else dict(c.items())

check(clas(" Restaura 4 p. de maná cada 5 s.") == {"mp5": 4}, "ALTA4 mp5")
check(clas(" Aumenta hasta 22 p. la sanación de los hechizos y efectos.") == {"heal": 22}, "ALTA4 sanación")
check(clas(" Aumenta hasta 12 p. el daño y la sanación de los hechizos y efectos mágicos.") == {"sp": 12, "heal": 12}, "ALTA4 daño y sanación")
check(clas(" Aumenta hasta 9 p. el daño que infligen los hechizos y efectos de Naturaleza.") == {"spNature": 9}, "ALTA4 naturaleza")
check(clas(" Mejora tu probabilidad de asestar un golpe crítico con hechizos un 1%.") == {"spellCrit": 1}, "ALTA4 crítico hechizos")
check(clas(" Mejora un 1% tu probabilidad de conseguir un golpe crítico.") == {"crit": 1}, "ALTA4 crítico")
check(clas(" +45 p. de poder de ataque solo en las formas felina, de oso y de oso temible.") == {"ap": 45}, "ALTA4 poder de ataque feral")
check(clas(" Increases healing done by spells and effects by up to 22.") == {"heal": 22}, "ALTA4 inglés")
check(clas(" Aumenta la velocidad de nado un 15%.") is None, "ALTA4 efecto desconocido")
extra, desc = T.LeerEquipar(L.table_from(["Peto", "Equipar: Restaura 4 p. de maná cada 5 s.", "Equipar: Algo raro.", "Uso: algo"]), "Equipar:")
check(extra.mp5 == 4 and desc == 1, f"ALTA4 LeerEquipar {desc}")
# No se suma dos veces si GetItemStats ya trae la sanación.
tot = T.PuntajeTotal(L.table_from({"ITEM_MOD_SPELL_HEALING_DONE_SHORT": 22}), L.table_from({"heal": 22}), pesos)
check(abs(tot - 22 * 0.7) < 1e-9, f"ALTA4 sin doble conteo {tot}")

# --- Historial / mercado (10: día real y cantidad disponible) ---
h = T.Historial(L.eval('{h={["100"]=1000,["99"]=2000,["98"]=2000,["97"]=2200},l={["100"]=600},a={["100"]=12}}'), None, 100)
check(h.hoy == 600 and abs(h.media - 2066.6667) < 0.01 and T.EsBarato(h), "historial barato")
check(h.esHoy and h.disponible == 12, "10 esHoy y disponible")
h = T.Historial(L.eval('{h={["100"]=1000,["99"]=2000,["98"]=2000},l={["100"]=600},a={["100"]=1}}'), None, 105)
check(not h.esHoy, "10 escaneo de hace 5 días no es hoy")
check(not T.EsBarato(h), "10 una sola subasta barata no cuenta")
check(T.Historial(L.eval('{h={["1"]=5,["2"]=5}}')) is None, "poca historia")
check(T.DiaHoy() == 1000, f"10 DiaHoy {T.DiaHoy()}")

# --- Cuadro del objeto: mejora, subasta, no usable ---
L.execute('''
ITEMS[100] = {name="Peto",q=2,sell=1000,cls=4,sub=2,bind=2,loc="INVTYPE_CHEST",stats={ITEM_MOD_INTELLECT_SHORT=10}}
ITEMS[101] = {name="Viejo",q=1,sell=100,cls=4,sub=2,bind=2,loc="INVTYPE_CHEST",stats={ITEM_MOD_INTELLECT_SHORT=5}}
ITEMS[102] = {name="Placas",q=2,sell=100,cls=4,sub=4,bind=2,loc="INVTYPE_CHEST",stats={}}
EQUIP[5] = 101; PRICES[100] = 40000
T_ = nil
''')
T.db.ajustes.rol = "equilibrio"
lines = lines_of(L.eval('ShowTip("|Hitem:100|h[Peto]|h")'))
print("\n".join(lines))
check(any("MEJORA" in x for x in lines), "mejora en tooltip")
check(any("Es mejora" in x for x in lines), "8 la mejora se guarda (no se manda a subastar)")
lines = lines_of(L.eval('ShowTip("|Hitem:102|h[P]|h")'))
check(any("No lo puedes usar" in x for x in lines), "placas no usable")
L.execute('ITEMS[103] = {name="Botas",q=2,sell=1000,cls=4,sub=2,bind=2,loc="INVTYPE_FEET",stats={ITEM_MOD_INTELLECT_SHORT=3}}; PRICES[103]=40000; EQUIP[8]=101')
lines = lines_of(L.eval('ShowTip("|Hitem:103|h[B]|h")'))
check(any("Subastar" in x for x in lines), f"subastar en tooltip {lines}")

# ALTA 4 en el cuadro: pieza de sanación con "Equipar:" que GetItemStats no trae.
T.db.ajustes.rol = "sanacion"
L.execute('''
ITEMS[300] = {name="Toga",q=2,sell=100,cls=4,sub=1,bind=2,loc="INVTYPE_LEGS",stats={ITEM_MOD_INTELLECT_SHORT=5},
  tip={"Equipar: Aumenta hasta 22 p. la sanación de los hechizos y efectos."}}
ITEMS[301] = {name="Calzas",q=2,sell=100,cls=4,sub=2,bind=2,loc="INVTYPE_LEGS",stats={ITEM_MOD_INTELLECT_SHORT=8}}
EQUIP[7] = 301
''')
lines = lines_of(L.eval('ShowTip("|Hitem:300|h[T]|h")'))
check(any("MEJORA" in x and "Restauración" in x for x in lines), f"ALTA4 sanación de Equipar cuenta {lines}")
L.execute('ITEMS[302] = {name="Raro",q=2,sell=100,cls=4,sub=1,bind=2,loc="INVTYPE_LEGS",stats={ITEM_MOD_INTELLECT_SHORT=50}, tip={"Equipar: Te hace brillar en la oscuridad."}}')
lines = lines_of(L.eval('ShowTip("|Hitem:302|h[R]|h")'))
check(any("no sé medir" in x for x in lines) and not any("MEJORA" in x for x in lines), f"ALTA4 efecto desconocido -> no afirma mejora {lines}")

# 6 en el cuadro: lo puesto suma 0 -> sin "100 %".
L.execute('ITEMS[310]={name="Capa",q=2,sell=10,cls=4,sub=1,bind=2,loc="INVTYPE_CLOAK",stats={ITEM_MOD_INTELLECT_SHORT=4}}; ITEMS[311]={name="Capa0",q=1,sell=1,cls=4,sub=1,bind=2,loc="INVTYPE_CLOAK",stats={}}; EQUIP[15]=311')
lines = lines_of(L.eval('ShowTip("|Hitem:310|h[C]|h")'))
check(any("no suma nada" in x for x in lines) and not any("100%" in x for x in lines), f"6 sin 100% {lines}")

# ALTA 5: mano izquierda con un arma de dos manos puesta.
L.execute('''
ITEMS[320] = {name="Baston",q=2,sell=100,cls=2,sub=10,bind=2,loc="INVTYPE_2HWEAPON",stats={ITEM_MOD_INTELLECT_SHORT=10}}
ITEMS[321] = {name="Orbe",q=2,sell=100,cls=4,sub=0,bind=2,loc="INVTYPE_HOLDABLE",stats={ITEM_MOD_INTELLECT_SHORT=6}}
ITEMS[322] = {name="Daga izq",q=2,sell=100,cls=2,sub=15,bind=2,loc="INVTYPE_WEAPONOFFHAND",stats={ITEM_MOD_AGILITY_SHORT=6}}
ITEMS[323] = {name="Maza",q=2,sell=100,cls=2,sub=4,bind=2,loc="INVTYPE_WEAPON",stats={ITEM_MOD_INTELLECT_SHORT=12}}
EQUIP[16] = 320; EQUIP[17] = nil
''')
lines = lines_of(L.eval('ShowTip("|Hitem:321|h[O]|h")'))
check(any("dos manos" in x for x in lines) and not any("póntelo" in x for x in lines), f"ALTA5 objeto de mano izquierda con 2M {lines}")
lines = lines_of(L.eval('ShowTip("|Hitem:322|h[D]|h")'))
check(any("No lo puedes usar" in x for x in lines), f"ALTA5 arma de mano izquierda: druida no la usa {lines}")
lines = lines_of(L.eval('ShowTip("|Hitem:323|h[M]|h")'))
check(any("MEJORA" in x and "mano izquierda libre" in x for x in lines), f"ALTA5 una mano contra 2M {lines}")

# 7 en el cuadro: la línea "Ligado" del cuadro.
L.execute('ITEMS[330] = {name="Anillo",q=2,sell=500,cls=4,sub=0,bind=2,loc="INVTYPE_FINGER",stats={}}; PRICES[330]=90000; EQUIP[11]=101; EQUIP[12]=101')
lines = lines_of(L.eval('ShowTip("|Hitem:330|h[A]|h", {"Anillo", "Ligado"})'))
check(any("Vender al vendedor" in x for x in lines) and not any("Subastar" in x for x in lines), f"7 ligado en el cuadro {lines}")

# 9: sufijo aleatorio sin precio propio -> no usar el del objeto base.
L.execute('ITEMS[340] = {name="Cinto",q=2,sell=500,cls=4,sub=2,bind=2,loc="INVTYPE_WAIST",stats={}}; PRICES[340]=50000; EQUIP[6]=101')
suf = "|Hitem:340::::::1234:0:37|h[Cinto del Oso]|h"
info = T.InfoDe(suf)
check(info.subasta is None and "sufijo" in str(info.avisoPrecio), f"9 sufijo sin precio propio {info.subasta}")
L.execute(f'PRICES_LINK["{suf}"] = 80000')
info = T.InfoDe(suf)
check(info.subasta == 80000, f"9 sufijo con precio propio {info.subasta}")
check(T.Sufijo(suf) == 1234 and T.Sufijo("|Hitem:340|h[x]|h") == 0, "9 leer sufijo")

# --- ALTA 3: rol desde los talentos de Forever (C_Traits) ---
T.db.ajustes.rol = "auto"
L.execute('TALENT_COLS = {{name="Equilibrio",points=5},{name="Combate feral",points=0},{name="Restauración",points=23}}')
check(rol() == "sanacion", f"ALTA3 Restauración con más puntos {rol()}")
L.execute('TALENT_COLS = {{name="Balance",points=0},{name="Feral Combat",points=20},{name="Restoration",points=3}}')
check(rol() == "feral", "ALTA3 nombres en inglés")
L.execute('TALENT_COLS = {{name=SECRET,points=2},{name=SECRET,points=1},{name=SECRET,points=SECRET}}')
check(rol() == "equilibrio", "ALTA3 nombres secretos: por posición, sin errores")
L.execute('TALENT_COLS = nil')
rol_, fuente = T.RolActual()
check(rol_ == "equilibrio" and fuente == "por defecto", f"ALTA3 sin talentos {rol_} {fuente}")
T.db.ajustes.rol = "feral"
check(rol() == "feral", "rol fijo")

# --- Bolsas: isBound, mejora, herramienta ---
T.db.ajustes.rol = "equilibrio"
L.execute('''
ITEMS[2901] = {name="Pico de minero",q=1,sell=40,cls=2,sub=1,bind=0}
ITEMS[350] = {name="Guantes",q=2,sell=500,cls=4,sub=2,bind=2,loc="INVTYPE_HAND",stats={}}; PRICES[350]=90000
BAG={100,101,102,2901,350}; STACK={1,3,1,1,1}; BOUND={false,false,false,false,true}
EQUIP[10]=101
chat = {}; SlashCmdList.TASADOR("")
''')
chat = lines_of(L.eval('chat'))
print("\n".join(chat))
check(any("Total:" in c for c in chat), "resumen bolsas")
txt = "\n".join(chat)
sec = lambda name: txt.split(name)[1].split("|cffffffff")[0] if name in txt else ""
check("Pico" in sec("Guardar"), "8 el pico va a Guardar")
check("Peto" in sec("Guardar"), "8 la mejora va a Guardar")
check("Guantes" not in sec("Subastar"), "7 guantes ligados no van a Subastar")

# --- Alerta (12 valores secretos, 13 UnitCanAttack y límite de sonido) ---
L.execute('UNITS["nameplate1"] = {name="Pepe", lvl=40, fac="Alliance", cl="Paladín", tok="PALADIN"}; NOW=10; Fire("NAME_PLATE_UNIT_ADDED","nameplate1")')
w = lines_of(L.eval('warnings'))
print(w)
check(len(w) == 1 and "Pepe" in w[0] and "40" in w[0] and "PELIGRO" in w[0], f"alerta {w}")
check(L.eval('sounds') == 1, "suena una vez")
L.execute('NOW=20; Fire("NAME_PLATE_UNIT_ADDED","nameplate1")')
check(len(L.eval('warnings')) == 1, "no repite antes de 60s")
L.execute('UNITS["nameplate2"] = {name="Amigo", lvl=30, fac="Horde"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate2")')
check(len(L.eval('warnings')) == 1, "no alerta a horda")
L.execute('INST=true; UNITS["nameplate3"] = {name="Otro", lvl=30, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate3"); INST=false')
check(len(L.eval('warnings')) == 1, "no alerta en instancia")
L.execute('UNITS["nameplate4"] = {name="Paz", lvl=30, fac="Alliance", atk=false}; Fire("NAME_PLATE_UNIT_ADDED","nameplate4")')
check(len(L.eval('warnings')) == 1, "13 no alerta si no se puede atacar")
L.execute('NOW=15; UNITS["nameplate5"] = {name="Juan", lvl=30, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate5")')
check(len(L.eval('warnings')) == 2 and L.eval('sounds') == 1, f"13 segundo enemigo avisa sin sonar otra vez (sonidos {L.eval('sounds')})")
L.execute('NOW=40; UNITS["nameplate6"] = {name="Ana", lvl=30, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate6")')
check(L.eval('sounds') == 2, "13 pasados 10 s vuelve a sonar")
L.execute('UNITS["nameplate7"] = {name=SECRET, lvl=30, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate7")')
check(len(L.eval('warnings')) == 3, "12 nombre secreto: sin aviso y sin error")
L.execute('NOW=100; UNITS["nameplate8"] = {name="Luz", lvl=SECRET, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","nameplate8")')
w = lines_of(L.eval('warnings'))
check(len(w) == 4 and "??" in w[-1], f"12 nivel secreto -> ?? {w[-1:]}")
check(T.Leer(L.eval('SECRET')) is None and T.Leer(5) == 5, "12 T.Leer")

# --- Alerta: API para «Enemigos cerca» de Mamba_Combate (K105) ---
check(L.eval('MambaAPI == nil or MambaAPI.AlVerEnemigo == nil'), "K105 sin Asistente (sin MambaAPI) no crea la API")
L.execute('MambaAPI = {}; Fire("PLAYER_LOGIN")')
check(L.eval('type(MambaAPI.AlVerEnemigo) == "function" and type(MambaAPI.SilenciarCercanos) == "function"'), "K105 cuelga la API en MambaAPI al entrar")
L.execute('''VISTAS = {}
MambaAPI.AlVerEnemigo(function() error("oyente roto") end)
MambaAPI.AlVerEnemigo(function(i) table.insert(VISTAS, i) end)
UNITS["nameplate9"] = {name="Vero", lvl=33, fac="Alliance", cl="Mago", tok="MAGE"}; NOW=200; Fire("NAME_PLATE_UNIT_ADDED","nameplate9")''')
v = L.eval('VISTAS[1]')
check(v is not None and v.nombre == "Vero" and v.nivel == 33 and v.claseToken == "MAGE" and v.gremio is None, "K105 AlVerEnemigo con nombre, nivel y clase; gremio nil sin romper")
check(len(L.eval('warnings')) == 5, "K105 un oyente roto no corta la alerta")
L.execute('NOW=210; Fire("NAME_PLATE_UNIT_ADDED","nameplate9")')
check(len(L.eval('VISTAS')) == 2 and len(L.eval('warnings')) == 5, "K105 el oyente ve cada vista; el aviso respeta los 60 s")
L.execute('MambaAPI.SilenciarCercanos(true); UNITS["nameplate10"] = {name="Sil", lvl=33, fac="Alliance"}; NOW=300; S0 = sounds; Fire("NAME_PLATE_UNIT_ADDED","nameplate10")')
check(L.eval('MambaAPI.CercanosSilenciados()') is True and len(L.eval('warnings')) == 5 and L.eval('sounds == S0') and len(L.eval('VISTAS')) == 3, "K105 silenciada: sin cartel ni sonido, el oyente sigue")
L.execute('MambaAPI.SilenciarCercanos(false); UNITS["nameplate11"] = {name="Vuelve", lvl=33, fac="Alliance"}; NOW=320; Fire("NAME_PLATE_UNIT_ADDED","nameplate11")')
check(L.eval('MambaAPI.CercanosSilenciados()') is False and len(L.eval('warnings')) == 6, "K105 sin silencio vuelve a avisar")

# --- Mercado: baratos y hierbas con día real, cantidad y tandas (11) ---
L.execute('''
ITEMS[200]={name="Hierba",q=1,sell=10,cls=7,sub=9}
ITEMS[201]={name="Vieja",q=1,sell=10,cls=7,sub=9}
ITEMS[202]={name="Espada",q=2,sell=10,cls=2,sub=7}
Auctionator.Database.db["200"] = {h={["1000"]=500,["999"]=1000,["998"]=1000},l={},a={["1000"]=8}}
Auctionator.Database.db["201"] = {h={["995"]=500,["994"]=1000,["993"]=1000},l={},a={["995"]=8}}
Auctionator.Database.db["202"] = {h={["1000"]=500,["999"]=1000,["998"]=1000},l={},a={["1000"]=8}}
Auctionator.Database.db["g:1:2"] = {h={}}
for i = 5000, 5900 do Auctionator.Database.db[tostring(i)] = {h={}} end
chat = {}; INFO_CALLS = 0; TIMER_CALLS = 0; INSTANT_CALLS = 0
SlashCmdList.TASADOR("baratos")
FIRST_BATCH = INSTANT_CALLS
RunTimers()
''')
chat = lines_of(L.eval('chat'))
print("\n".join(chat))
check(any("Hierba" in c and "50%" in c and "8 a la venta" in c for c in chat), "baratos con cantidad")
check(not any("Vieja" in c for c in chat), "10 precio de hace 5 días no sale como 'hoy'")
check(not any("Espada" in c for c in chat), "11 el filtro de clase deja fuera el equipo")
check(L.eval('INFO_CALLS') <= 2, f"11 GetItemInfo solo para lo que pasa el filtro ({L.eval('INFO_CALLS')})")
check(L.eval('INSTANT_CALLS') >= 3 and L.eval('TIMER_CALLS') >= 2, f"11 usa GetItemInfoInstant y reparte en tandas ({L.eval('TIMER_CALLS')})")
check(L.eval('FIRST_BATCH') <= 400 and L.eval('MAX_BATCH') <= 400, f"11 cada tanda revisa como mucho 400 ({L.eval('FIRST_BATCH')}, {L.eval('MAX_BATCH')})")
L.execute('chat = {}; SlashCmdList.TASADOR("hierbas"); RunTimers(); SlashCmdList.TASADOR("rol sanación"); SlashCmdList.TASADOR("comisión 6"); SlashCmdList.TASADOR("ayuda")')
chat = lines_of(L.eval('chat'))
check(any("Hierba" in c and "x20" in c for c in chat), "hierbas")
check(T.db.ajustes.rol == "sanacion" and abs(T.db.ajustes.comision - 0.06) < 1e-9, "comandos con tilde")
L.execute('for k in pairs(Auctionator.Database.db) do if k ~= "201" then Auctionator.Database.db[k] = nil end end; chat = {}; SlashCmdList.TASADOR("hierbas"); RunTimers()')
chat = lines_of(L.eval('chat'))
check(any("hace 5 días" in c for c in chat), f"10 avisa que el último escaneo es viejo {chat}")

# ================= Hallazgos de la 2.ª revisión externa =================
# H2: efectos que saltan por probabilidad NO son estadísticas fijas.
check(clas(" Tus golpes críticos tienen un 10% de probabilidad de aturdir al objetivo.") is None, "H2 proc de crítico")
check(clas(" Tienes un 2% de probabilidad al golpear cuerpo a cuerpo de ganar 100 p. de maná.") is None, "H2 proc al golpear")
check(clas(" Al golpear con hechizos tienes un 2% de probabilidad de recuperar maná.") is None, "H2 proc de hechizos")
check(clas(" Your critical strikes have a 10% chance to stun the target.") is None, "H2 proc inglés")
check(clas(" Mejora un 1% tu probabilidad de golpear con hechizos.") == {"spellHit": 1}, "H2 golpe con hechizos sigue bien")
# H5: escuelas en minúscula.
check(clas(" Aumenta hasta 10 p. el daño que infligen los hechizos y efectos de fuego.") == {"spFire": 10}, "H5 fuego en minúscula")
check(clas(" Aumenta hasta 10 p. el daño que infligen los hechizos y efectos arcanos.") == {"spArcane": 10}, "H5 arcanos")
# H6: DPS del arma cuenta (feral 14 x poder de ataque).
pf = T.PesosPara("DRUID", "feral", 37)
check(abs(pf.dps - 14 * pf.ap) < 1e-9 and T.PesosPara("DRUID", "equilibrio", 37).dps == 0.01, "H6 peso del DPS")
check(T.Puntaje(L.table_from({"ITEM_MOD_DAMAGE_PER_SECOND_SHORT": 10}), pf) > 60, "H6 DPS suma para feral")
# H3: en bolsas cuenta lo que tienes, no la pila máxima.
check(E(calidad=1, liga=0, vendedor=100, subasta=300, clase=15, pila=20, cantidad=1).accion == A.VENDEDOR, "H3 1 unidad de pila 20 -> vendedor")
check(E(calidad=1, liga=0, vendedor=100, subasta=300, clase=15, pila=20, cantidad=20).accion == A.SUBASTA, "H3 20 unidades -> subastar")
# H7: el vendedor paga más que la subasta -> vender, aunque sea material.
check(E(calidad=1, liga=0, vendedor=500, subasta=100, clase=7, pila=1).accion == A.VENDEDOR, "H7 material que el vendedor paga mejor")
# H8: el vendedor no lo compra y la subasta deja 3c -> no "Subastar".
check(E(calidad=1, liga=0, vendedor=0, subasta=3, clase=15, pila=1).accion == A.REVISAR, "H8 subasta de 3c")
# H1: ranura vacía con pieza inútil o con efecto desconocido -> NO es mejora y se puede subastar.
T.db.ajustes.rol = "equilibrio"
L.execute('''
EQUIP[13] = nil; EQUIP[14] = nil; EQUIP[2] = nil
ITEMS[400] = {name="Abalorio fuerza",q=3,sell=500,cls=4,sub=0,bind=2,loc="INVTYPE_TRINKET",stats={ITEM_MOD_STRENGTH_SHORT=8}}
ITEMS[401] = {name="Colgante raro",q=3,sell=500,cls=4,sub=0,bind=2,loc="INVTYPE_NECK",stats={ITEM_MOD_INTELLECT_SHORT=4}, tip={"Equipar: Te hace brillar."}}
PRICES[400] = 500000; PRICES[401] = 500000
''')
lines = lines_of(L.eval('ShowTip("|Hitem:400|h[A]|h")'))
check(any("Subastar" in x for x in lines) and any("no suma nada" in x for x in lines), f"H1 ranura vacía y no suma -> subastar {lines}")
lines = lines_of(L.eval('ShowTip("|Hitem:401|h[C]|h")'))
check(any("Subastar" in x for x in lines) and any("no sé medir" in x for x in lines), f"H1 ranura vacía con efecto desconocido -> subastar {lines}")
# H1: mejora que además vale: se dice cuánto daría en subasta.
L.execute('ITEMS[402] = {name="Colgante int",q=3,sell=500,cls=4,sub=0,bind=2,loc="INVTYPE_NECK",stats={ITEM_MOD_INTELLECT_SHORT=4}}; PRICES[402]=500000')
lines = lines_of(L.eval('ShowTip("|Hitem:402|h[C]|h")'))
check(any("Guardar" in x for x in lines) and any("en subasta te quedarían" in x for x in lines), f"H1 mejora valiosa avisa el oro {lines}")
# H4: objeto de nivel muy superior no se guarda como mejora.
L.execute('ITEMS[403] = {name="Cinto 58",q=3,sell=500,req=58,cls=4,sub=2,bind=2,loc="INVTYPE_WAIST",stats={ITEM_MOD_INTELLECT_SHORT=40}}; PRICES[403]=2000000; EQUIP[6]=101')
lines = lines_of(L.eval('ShowTip("|Hitem:403|h[C]|h")'))
check(any("Subastar" in x for x in lines) and any("nivel 58" in x for x in lines), f"H4 nivel 58 -> subastar y avisar {lines}")
# H11: la caña no dice "no lo puedes usar".
L.execute('ITEMS[6256] = {name="Caña",q=1,sell=10,cls=2,sub=20,bind=0,loc="INVTYPE_2HWEAPON",stats={}}')
lines = lines_of(L.eval('ShowTip("|Hitem:6256|h[C]|h")'))
check(any("Guardar" in x for x in lines) and not any("No lo puedes usar" in x for x in lines), f"H11 caña {lines}")
# H12: ligado a la cuenta (la lista se arma al cargar: se recarga Juego.lua con la cadena del cliente).
L.execute('ITEM_ACCOUNTBOUND = "Ligado a la cuenta"')
_db = T.db
loader((D / "Juego.lua").read_text(encoding="utf-8"), "Juego.lua", T)
T.db = _db
check(T.LigadoEnTextos(L.table_from(["x", "Ligado a la cuenta"])), "H12 ligado a la cuenta")
# H13: cuadro aún no cargado -> "aún cargando", no "no sé medir".
L.execute('ITEMS[404] = {name="Nuevo",q=2,sell=100,cls=4,sub=2,bind=2,loc="INVTYPE_WAIST",stats={ITEM_MOD_INTELLECT_SHORT=40}}; local g = C_TooltipInfo.GetHyperlink; C_TooltipInfo.GetHyperlink = function() return nil end; LINES_404 = ShowTip("|Hitem:404|h[N]|h"); C_TooltipInfo.GetHyperlink = g')
lines = lines_of(L.eval('LINES_404'))
check(any("cargando" in x for x in lines) and not any("no sé medir" in x for x in lines), f"H13 cargando {lines}")
# H14: muchos enemigos juntos -> un aviso grande, el resto solo en el chat.
L.execute('warnings = {}; chat = {}; NOW = 500; for i = 1, 5 do UNITS["np"..i] = {name="Grupo"..i, lvl=30, fac="Alliance"}; Fire("NAME_PLATE_UNIT_ADDED","np"..i) end')
check(len(L.eval('warnings')) == 1 and sum("Grupo" in c for c in lines_of(L.eval('chat'))) == 5, "H14 un aviso en pantalla, 5 en el chat")
# H9: /tasador rol auto no se rompe si los talentos fallan.
L.execute('TALENT_COLS = {}; C_Traits.GetConfigInfo = function() error("falla") end; chat = {}; SlashCmdList.TASADOR("rol auto")')
check(any("Comparo equipo" in c for c in lines_of(L.eval('chat'))), "H9 rol auto sin error")

# ================= 3.ª tanda (segunda revisión) =================
# R2: bonificación temporal no es fija.
check(clas(" Aumenta tu probabilidad de golpe crítico un 2% durante 10 s.") is None, "R2 temporal")
# N2: el motivo dice que el vendedor paga más.
check("vendedor paga más" in E(calidad=1, liga=0, vendedor=500, subasta=100, clase=15, pila=1).motivo, "N2 motivo")
# R1: capa con armadura pero sin nada útil para Equilibrio, ranura vacía -> subastar.
T.db.ajustes.rol = "equilibrio"
L.execute('EQUIP[15] = nil; ITEMS[410] = {name="Capa fuerza",q=3,sell=500,cls=4,sub=1,bind=2,loc="INVTYPE_CLOAK",stats={ITEM_MOD_STRENGTH_SHORT=12,RESISTANCE0_NAME=30}}; PRICES[410]=500000')
lines = lines_of(L.eval('ShowTip("|Hitem:410|h[C]|h")'))
check(any("Subastar" in x for x in lines) and not any("póntelo" in x for x in lines), f"R1 capa con armadura {lines}")
# R3: el objeto PUESTO aún no cargó -> "cargando".
L.execute('ITEMS[411] = {name="Botas2",q=2,sell=100,cls=4,sub=2,bind=2,loc="INVTYPE_FEET",stats={ITEM_MOD_INTELLECT_SHORT=9}}; EQUIP[8]=412; ITEMS[412]={name="Puestas",q=1,sell=1,cls=4,sub=2,bind=2,loc="INVTYPE_FEET",stats={ITEM_MOD_INTELLECT_SHORT=2}}')
L.execute('local g = C_TooltipInfo.GetHyperlink; C_TooltipInfo.GetHyperlink = function(l) if l:find("item:412") then return nil end return g(l) end; LINES_R3 = ShowTip("|Hitem:411|h[B]|h"); C_TooltipInfo.GetHyperlink = g')
lines = lines_of(L.eval('LINES_R3'))
check(any("cargando" in x for x in lines) and not any("no sé medir" in x for x in lines), f"R3 puesto cargando {lines}")
# N1: en la lista de bolsas, una pieza con efecto desconocido lleva aviso.
L.execute('EQUIP[7] = 301; BAG={302}; STACK={1}; BOUND={false}; chat = {}; SlashCmdList.TASADOR("")')
chat = lines_of(L.eval('chat'))
check(any("Raro" in c and "compáralo antes de vender" in c for c in chat), f"N1 aviso en bolsas {chat}")

print(f"\n{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
