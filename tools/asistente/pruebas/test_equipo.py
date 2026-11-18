# Pruebas del asesor de equipo (Asistente_Equipo) fuera del juego, con Lua 5.1 (lupa), contra el módulo
# Gear REAL de Polestar instalado (no una copia): así se prueba también el contrato con Polestar.
# Uso (desde el repositorio Mamba): python -I tools/asistente/pruebas/test_equipo.py [carpeta addon]
# (por defecto Mamba/addon: el mismo Polestar y Asistente que se instalan)
# Caso principal: Hope, druida tauren de la Horda, nivel 37, Restauración por talentos.
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
ADDON = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else AQUI.parents[2] / "addon").resolve()
sys.path.insert(0, str(AQUI.parent / "generador"))
import polestar_lua  # noqa: E402

L = LuaRuntime(unpack_returned_tuples=True)
L.execute((pathlib.Path(__file__).parent / "mock_wow.lua").read_text(encoding="utf-8"))
L.execute("""
LOADED = {}
C_AddOns = {
  IsAddOnLoaded = function(a) return LOADED[a] == true end,
  LoadAddOn = function(a) if CARGAR_MODULO then CARGAR_MODULO(a) end; return LOADED[a] == true end,
}
function InCombatLockdown() return false end
""")
loader = L.eval('function(src, name, addon, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f(addon, ns) end')


def cargar(carpeta, ns):
    toc = [l.strip() for l in (ADDON / carpeta / f"{carpeta}.toc").read_text(encoding="utf-8").splitlines()
           if l.strip().endswith(".lua")]
    for name in toc:
        loader((ADDON / carpeta / name).read_text(encoding="utf-8"), f"{carpeta}/{name}", carpeta, ns)
    L.globals().LOADED[carpeta] = True


G_ = L.globals()
PS = polestar_lua.cargar_gear(L, ADDON)  # deja Polestar como global, como en el juego
G_.LOADED["Polestar"] = True
cargar("Asistente", L.table())
T = L.table()
cargar("Tasador", T)
L.execute('Fire("ADDON_LOADED", "Tasador")')
E = L.table()
G_.CARGAR_MODULO = lambda a: cargar(a, E) if a == "Asistente_Equipo" else None
GEAR = PS.Gear
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


def comando(texto):
    # /equipo abre la ventana de Mamba (Asistente/Ventana.lua, 18-11). La prueba lee las filas que la ventana
    # dibuja para esa sección (E.Seccion), como texto. La ventana misma se prueba en test_ventana.py.
    if G_.LOADED["Asistente_Equipo"] is not True:
        G_.C_AddOns.LoadAddOn("Asistente_Equipo")
    lst = G_.Asistente.NuevaLista()
    try:
        E.Seccion(E.Alias(texto), lst)
    except Exception as e:  # noqa: BLE001  la ventana lo atrapa y lo muestra (test_ventana.py)
        return ["ERROR " + str(e)]
    return [str(lst.filas[i].texto) for i in range(1, len(lst.filas) + 1)]


def refrescar():
    GEAR.Invalidate("equipment")
    GEAR.Invalidate("spec")


# --- 1. Talentos de Hope: el rol lo decide Polestar ---
G_.TALENT_COLS = L.eval('{ { name = "Balance", points = 0 }, { name = "Feral Combat", points = 5 }, { name = "Restoration", points = 31 } }')
GEAR.RefreshPlayer()
salida = comando("")
check(G_.LOADED["Asistente_Equipo"] is True, "el módulo se carga con /equipo")
check(any("Restauración" in s and "nivel 37" in s and "tus talentos" in s for s in salida), f"cabecera con rol de Polestar: {salida[:2]}")
check(L.eval("function(a, b) return rawequal(a, b) end")(E.Gear(), GEAR), "usa Polestar.Gear real")
for f in lista(E.CONTRATO):
    check(GEAR[f] is not None, f"Polestar trae Gear.{f}")

# Sin Polestar: aviso, sin error.
guardado = G_.Polestar
G_.Polestar = None
salida = comando("")
check(any("necesito mamba" in s.lower() for s in salida), "sin Polestar avisa (con el nombre Mamba)")
G_.Polestar = L.table_from({"Gear": L.table()})
salida = comando("")
check(any("falta Gear." in s for s in salida), "Polestar sin el contrato: avisa qué falta")
G_.Polestar = guardado
# Polestar sin ItemDB.Get: avisa una vez y sigue.
db_get = PS.ItemDB.Get
PS.ItemDB.Get = None
salida = comando("")
check(any("ItemDB.Get" in x for x in salida) and any("Tu equipo" in x for x in salida), "sin ItemDB.Get: avisa y sigue")
salida = comando("")
check("ItemDB.Get" in salida[0] and sum("ItemDB.Get" in x for x in salida) == 1, "el aviso de ItemDB sale una vez, arriba de la sección (en la ventana no hace ruido en el chat)")
PS.ItemDB.Get = db_get

# --- 2. Equipo de Hope (ids reales de los datos; Polestar los conoce por su ItemDB) ---
mapa = {"str": "ITEM_MOD_STRENGTH_SHORT", "agi": "ITEM_MOD_AGILITY_SHORT", "sta": "ITEM_MOD_STAMINA_SHORT",
        "int": "ITEM_MOD_INTELLECT_SHORT", "spi": "ITEM_MOD_SPIRIT_SHORT", "armor": "RESISTANCE0_NAME"}
LOC = {1: "INVTYPE_HEAD", 3: "INVTYPE_SHOULDER", 5: "INVTYPE_CHEST", 20: "INVTYPE_ROBE", 6: "INVTYPE_WAIST", 7: "INVTYPE_LEGS",
       8: "INVTYPE_FEET", 10: "INVTYPE_HAND", 16: "INVTYPE_CLOAK", 17: "INVTYPE_2HWEAPON", 11: "INVTYPE_FINGER"}
w37 = GEAR.GetWeights()


def poner_en_juego(iid, ranura):
    info = GEAR.GetItemInfo(iid)
    base = {mapa[k]: v for k, v in info.stats.items() if k in mapa}  # el cliente NO da los "Equipar:"
    tip = []
    for k, v in info.stats.items():
        if k == "heal":
            tip.append(f"Equipar: Aumenta la sanación realizada por hechizos y efectos hasta en {v}.")
    G_.ITEMS[iid] = L.table_from({"name": f"pieza{iid}", "q": 2, "loc": LOC[info.inv], "cls": info["class"], "sub": info.subclass,
                                  "req": info.req, "stats": L.table_from(base), "tip": L.table_from(dict(enumerate(tip, 1)))})
    G_.EQUIP[ranura] = iid


# Piezas de nivel bajo (de Las Cuevas de los Lamentos y otras) que sirven a Restauración: la MÁS DÉBIL por ranura,
# para que haya mejoras que encontrar.
candidatos = {}
for clave in ("wc", "rfc", "sfk", "bfd", "vc"):
    for f in lista(E.BOTIN[clave]):
        info = GEAR.GetItemInfo(f.id)
        if not info or info.req > 30 or info.inv not in (1, 3, 5, 20, 6, 7, 8, 10, 16, 17):
            continue
        if not GEAR.Usability(info)[0] or not E.Aporta(info.stats, w37):
            continue
        ranura = {20: 5, 16: 15, 17: 16}.get(info.inv, info.inv)
        s = GEAR.ScoreWith(info, w37, False)
        if s > 0 and (ranura not in candidatos or s < candidatos[ranura][1]):
            candidatos[ranura] = (f.id, s)
for ranura, (iid, _) in candidatos.items():
    poner_en_juego(iid, ranura)
check(len(candidatos) >= 5, f"Hope lleva al menos 5 piezas ({sorted(candidatos)})")
check(16 in candidatos and G_.ITEMS[candidatos[16][0]].loc == "INVTYPE_2HWEAPON", "Hope lleva un arma de dos manos")
# Un anillo que Polestar NO conoce (no está en su ItemDB), con un "Equipar:" en el cuadro: debe quedar dudoso.
G_.ITEMS[999001] = L.table_from({"name": "Anillo raro", "q": 2, "loc": "INVTYPE_FINGER", "cls": 4, "sub": 0, "req": 30,
                                 "stats": L.table_from({"ITEM_MOD_INTELLECT_SHORT": 3}),
                                 "tip": L.table_from({1: "Equipar: Aumenta la sanación realizada por hechizos y efectos hasta en 9."})})
G_.EQUIP[11] = 999001
# Otro anillo nuevo sin "Equipar:": se puede medir aunque Polestar no lo conozca.
G_.ITEMS[999003] = L.table_from({"name": "Anillo simple", "q": 2, "loc": "INVTYPE_FINGER", "cls": 4, "sub": 0, "req": 30,
                                 "stats": L.table_from({"ITEM_MOD_INTELLECT_SHORT": 4}), "tip": L.table_from({})})
G_.EQUIP[12] = 999003
refrescar()

puestos = E.EquipoPuesto()
rev = E.Revisar(GEAR, puestos, E.SabeEquipar)
filas = {f.ranura: f for f in lista(rev.ranuras)}
check(filas[11].sabe is False, "anillo desconocido con 'Equipar:' queda dudoso")
check(filas[12].sabe is True, "anillo desconocido sin 'Equipar:' queda bien")
r0 = sorted(candidatos)[0]
check(filas[r0].sabe is True, "pieza que Polestar conoce queda bien")
check(rev.desconocidas == 1, f"una ranura dudosa ({rev.desconocidas})")
check(rev.vacias >= 4, f"cuenta ranuras vacías ({rev.vacias})")
check(filas[17].vacia is False and filas[17].dosManos, "con dos manos, la mano izquierda no cuenta como vacía")
for ranura, (iid, s) in candidatos.items():
    if ranura != 16:
        check(abs(filas[ranura].puntaje - s) < 1e-6, f"el puntaje de la ranura {ranura} es el de Polestar (con su 'Equipar:')")

# --- 3. Mazmorras para Hope (37, Horda) ---
con, sin = E.MejorasMazmorras(GEAR, 37, "H")
claves = [x.m.clave for x in lista(con)] + [m.clave for m in lista(sin)]
check({"rfd", "smbib", "rfk", "gnomer"} <= set(claves), f"mazmorras de su nivel: {claves}")
check("stocks" not in claves, "Las Mazmorras (Ventormenta) no salen para la Horda")
check("kroldok" not in claves and "vc" not in claves and "sfk" not in claves, "fuera de rango: Krol'Dok, Minas, Colmillo Oscuro")
check("ahogada" in [m.clave for m in lista(sin)], "La Ciudad Ahogada sale como 'sin datos'")
valores = [x.valor for x in lista(con)]
check(valores == sorted(valores, reverse=True) and valores[0] > 0, "ordenadas por valor, y alguna mejora")
n_piezas = 0
for x in lista(con):
    for p in lista(x.piezas):
        n_piezas += 1
        r = GEAR.CompareToEquipped(f"item:{p.id}")
        check(r.usable and abs(r.delta - p.ganancia) < 1e-9, f"{p.id}: ganancia = la de Polestar.CompareToEquipped")
        check(p.nivelMin <= 39, f"{p.id}: nivel {p.nivelMin} <= 39")
check(n_piezas > 5, f"varias piezas propuestas ({n_piezas})")
# Una pieza mejor que todo en la cabeza: ya no se proponen cascos.
check(any(p.ranura == 1 for x in lista(con) for p in lista(x.piezas)), "hay cascos propuestos (antes)")
G_.ITEMS[999002] = L.table_from({"name": "Casco enorme", "q": 4, "loc": "INVTYPE_HEAD", "cls": 4, "sub": 2, "req": 30,
                                 "stats": L.table_from({"ITEM_MOD_INTELLECT_SHORT": 300, "ITEM_MOD_SPIRIT_SHORT": 300}), "tip": L.table_from({})})
antes = G_.EQUIP[1]
G_.EQUIP[1] = 999002
refrescar()
con2 = E.MejorasMazmorras(GEAR, 37, "H")[0]
check(not any(p.ranura == 1 for x in lista(con2) for p in lista(x.piezas)), "con un casco mejor ya no propone cascos")
G_.EQUIP[1] = antes
refrescar()
n, h = E.Pasadas(20)
check(abs(n - 5) < 1e-9 and abs(h - 1) < 1e-9, "20 % = 5 pasadas = 1 hora como mínimo")
check(E.Pasadas(0) is None, "0 % = sin dato")
# Facción: cada una ve las de su capital y no las de la otra.
check("stocks" in [m.clave for m in lista(E.MazmorrasParaNivel(30, "A"))], "la Alianza ve Las Mazmorras")
check("rfc" not in [m.clave for m in lista(E.MazmorrasParaNivel(15, "A"))], "la Alianza no recibe Sima Ígnea (Orgrimmar)")
check("rfc" in [m.clave for m in lista(E.MazmorrasParaNivel(15, "H"))], "la Horda sí recibe Sima Ígnea")
check("thanes" not in [m.clave for m in lista(E.MazmorrasParaNivel(15, "H"))], "la Horda no recibe Hall of Thanes (Forjaz)")

# Misiones y bichos: se muestran, pero no suman al valor de "qué mazmorra repetir".
L.execute("""
function PRUEBA_BOTIN(E, filas)
  local viejo = E.BOTIN.rfd
  E.BOTIN.rfd = filas
  local con = E.MejorasMazmorras(Polestar.Gear, 37, "H", MISION_HECHA)
  E.BOTIN.rfd = viejo
  for _, x in ipairs(con) do if x.m.clave == "rfd" then return x end end
end
""")
fila = lista(E.BOTIN.rfd)[0]
x = G_.PRUEBA_BOTIN(E, L.table_from({1: L.table_from({"id": fila.id, "jefe": "Misión X", "pct": 100, "mision": 99999})}))
check(x is not None and len(lista(x.piezas)) == 1 and x.valor == 0, "una misión se muestra pero no suma al valor")
G_.MISION_HECHA = L.eval("function(q) return q == 99999 end")
x = G_.PRUEBA_BOTIN(E, L.table_from({1: L.table_from({"id": fila.id, "jefe": "Misión X", "pct": 100, "mision": 99999})}))
check(x is not None and len(lista(x.piezas)) == 0, "una misión ya hecha no se propone")
G_.MISION_HECHA = None
x = G_.PRUEBA_BOTIN(E, L.table_from({1: L.table_from({"id": fila.id, "jefe": "", "pct": 30, "bichos": True})}))
check(x is not None and len(lista(x.piezas)) == 1 and x.valor == 0, "el botín de bichos se muestra pero no suma")
x = G_.PRUEBA_BOTIN(E, L.table_from({1: L.table_from({"id": fila.id, "jefe": "Jefe", "pct": 30, "rc": 8})}))
check(x is not None and len(lista(x.piezas)) == 0, "una misión solo para pícaros no se le propone a un druida")

# Piezas dudosas: sin el Tasador, una pieza desconocida con "Equipar:" sigue siendo dudosa.
tas = G_.Tasador
G_.Tasador = None
check(E.SabeEquipar("|Hitem:999001|h[x]|h", 999001) is False, "sin Tasador: desconocida con 'Equipar:' = dudosa")
check(E.SabeEquipar("|Hitem:999003|h[x]|h", 999003) is True, "sin Tasador: desconocida sin 'Equipar:' = bien")
G_.Tasador = tas
# Pieza que Polestar conoce, pero con un efecto por probabilidad: dudosa (lo ve el Tasador).
conocida = candidatos[r0][0]
G_.ITEMS[conocida].tip = L.table_from({1: "Equipar: Tus hechizos tienen un 5% de probabilidad de hacer algo."})
check(E.SabeEquipar(f"|Hitem:{conocida}|h[x]|h", conocida) is False, "conocida con efecto por probabilidad = dudosa")
# Sin el Tasador, una pieza conocida con "Equipar:" también queda dudosa (no se sabe si es por probabilidad).
G_.Tasador = None
G_.ITEMS[conocida].tip = L.table_from({1: "Equipar: Tus hechizos tienen un 5% de probabilidad de hacer algo."})
check(E.SabeEquipar(f"|Hitem:{conocida}|h[x]|h", conocida) is False, "sin Tasador: conocida con 'Equipar:' = dudosa")
G_.Tasador = tas
G_.ITEMS[conocida].tip = L.table_from({})

# Base de objetos de Polestar sin cargar (addon desactivado o en combate): no aconseja, avisa (revisor 2, ALTA).
cargada, carga = PS.ItemDB.IsLoaded, PS.ItemDB.Load
PS.ItemDB.IsLoaded = L.eval("function() return false end")
PS.ItemDB.Load = L.eval("function() return false end")
salida = comando("")
check(any("Polestar_ItemDB" in x for x in salida) and not any(" 1. " in x for x in salida), "sin la base de objetos: avisa y no aconseja")
PS.ItemDB.IsLoaded, PS.ItemDB.Load = cargada, carga
# Un error dentro (Polestar cambió la forma de algo): aviso en el chat, no error en rojo.
cmp_ = GEAR.CompareToEquipped
GEAR.CompareToEquipped = L.eval("function() error('forma nueva') end")
salida = comando("")
check(any(x.startswith("ERROR") and "forma nueva" in x for x in salida), "un error de Polestar llega a la ventana, que lo muestra sin cortar nada")
GEAR.CompareToEquipped = cmp_

# --- 4. Comandos ---
salida = comando("")
check(any(s.startswith("1. ") for s in salida), "la revisión muestra la mazmorra n.º 1")
check(any("Anillo 1" in s for s in salida), "avisa la ranura dudosa (Anillo 1)")
check(any("5 entradas" in s for s in salida), "menciona el tope de 5 por hora")
salida = comando("mazmorras")
check(any("Zahúrda Rajacieno" in s for s in salida), "lista Zahúrda Rajacieno (Razorfen Downs en esMX)")
salida = comando("60")
check(any("PROVISIONAL" in s for s in salida) and len(salida) > 8, f"guía al 60 provisional ({len(salida)} líneas)")
salida = comando("jcj")
check(any("Refugio de Campeón" in s for s in salida), "JcJ: conjunto azul de Restauración de la Horda (esMX)")
check(any("Refugio de Señor de la Guerra" in s for s in salida), "JcJ: conjunto épico (esMX)")
check(any("14: Armas épicas" in s for s in salida), "JcJ: tabla de rangos")
salida = comando("rol")
check(any("Restauración" in s for s in salida) and any("Lo decide Mamba" in s for s in salida), "rol: explica que lo decide Mamba")
salida = comando("fuentes")
check(any("ForeverLevelingBiS" in s for s in salida), "créditos")
# Rol elegido en Polestar: el Asistente lo sigue.
PS.AJUSTES["gear.spec.DRUID"] = "feral"
refrescar()
salida = comando("rol")
check(any("Feral" in s and "ajustes de Mamba" in s for s in salida), "sigue el rol elegido en Mamba")
PS.AJUSTES["gear.spec.DRUID"] = "auto"
refrescar()

# --- 5. Tabla fija y guías al 60: 9 clases x 3 especializaciones (personaje simulado por Polestar) ---
CLASES = ("WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID")
sin_nada = []
for clase in CLASES:
    for rr in lista(E.Roles(GEAR, clase)):
        for nivel in (15, 20, 25, 30, 35, 40, 45, 50, 55, 60):
            polestar_lua.fijar_personaje(L, PS, clase, nivel, rr.clave, raza=None)
            check(GEAR.GetSpec()[0] == rr.clave, f"{clase} {rr.clave}: Polestar usa ese rol")
            c2, s2 = E.MejorasMazmorras(GEAR, nivel, "H")
            check(len(lista(c2)) + len(lista(s2)) > 0, f"{clase} {rr.clave} {nivel}: hay mazmorras en rango")
            for x in lista(c2):
                for p in lista(x.piezas):
                    info = GEAR.GetItemInfo(p.id)
                    if not GEAR.Usability(info)[0]:
                        check(False, f"{clase} {rr.clave}: {p.id} no la puede usar")
            if not any(x.valor > 0 for x in lista(c2)):
                sin_nada.append((clase, rr.clave, nivel))
        filas60, faltan = E.BiS60(GEAR, clase, rr.clave, "H")
        filas60, faltan = lista(filas60), lista(faltan)
        dos_manos = any(f.ranura == 16 and not f.alternativa and GEAR.GetItemInfo(f.id).inv == 17 for f in filas60)
        if GEAR.PROFICIENCY[clase].dualWield is not None:
            # Mano izquierda: una pieza que se consigue, o si no hay ninguna, la ranura sale en "sin datos" (con la fabricada como alternativa).
            check(dos_manos or any(f.ranura == 17 for f in filas60) or 17 in faltan,
                  f"BiS {clase} {rr.clave}: quien usa dos armas tiene mano izquierda, dos manos o la ranura en 'sin datos'")
        izq = {f.id for f in filas60 if f.ranura == 17 and f.alternativa != True}
        der = {f.id for f in filas60 if f.ranura == 16 and f.alternativa != True}
        check(not (izq & der), f"BiS {clase} {rr.clave}: la misma arma no va en las dos manos")
        hay = {f.ranura for f in filas60 if not f.alternativa}
        check(all(r not in hay for r in faltan), f"BiS {clase} {rr.clave}: 'sin datos' solo nombra ranuras vacías")
        check(len(filas60) >= 8, f"BiS {clase} {rr.clave}: {len(filas60)} filas")
        principales = [f.ranura for f in filas60 if not f.alternativa]
        check(len(principales) == len(set(principales)), f"BiS {clase} {rr.clave}: una pieza por ranura")
        for f in filas60:
            info = GEAR.GetItemInfo(f.id)
            u = GEAR.Usability(info)
            check(u[0] or u[1] in ("dualwield", "skill"), f"BiS {clase} {rr.clave}: {f.id} usable ({u[1]})")
            check(info.req <= 60, "BiS: nivel <= 60")
        j = E.JcJ(clase, rr.clave, "H")
        check(j is not None and j.azul is not None and j.epico is not None, f"JcJ {clase} {rr.clave}")
print("tramos sin pieza con datos:", len(sin_nada), sin_nada[:12])
# Hueco conocido de los datos: al 55, para lanzadores de tela, ninguna mazmorra con datos trae algo útil.
check(all(n == 55 for _, _, n in sin_nada), f"solo el tramo 55 queda sin piezas: {sin_nada}")
polestar_lua.fijar_personaje(L, PS, "DRUID", 60, "restoration", raza=None)
orden = lista(E.OrdenBiS(E.BiS60(GEAR, "DRUID", "restoration", "H")[0]))
cert = [f.certeza for f in orden]
check(cert == sorted(cert, reverse=True), "orden del BiS: primero lo seguro")
polestar_lua.fijar_personaje(L, PS, "ROGUE", 60, "combat", raza=None)
pic = [f for f in lista(E.BiS60(GEAR, "ROGUE", "combat", "H")[0]) if not f.alternativa]
for clase in CLASES:
    for rr in lista(E.Roles(GEAR, clase)):
        polestar_lua.fijar_personaje(L, PS, clase, 60, rr.clave, raza=None)
        for f in lista(E.BiS60(GEAR, clase, rr.clave, "H")[0]):
            tipos = {x.tipo for x in lista(f.fuentes)}
            if not f.alternativa:
                check(tipos & {"mision", "botin"}, f"BiS {clase} {rr.clave}: la principal {f.id} se puede conseguir (no solo fabricada)")
            if f.alternativa == "fabricado":
                check(tipos == {"profesion"}, "alternativa fabricada = solo fabricada")
polestar_lua.fijar_personaje(L, PS, "ROGUE", 60, "combat", raza=None)
pic_todo = lista(E.BiS60(GEAR, "ROGUE", "combat", "H")[0])
check(any(f.ranura == 17 for f in pic_todo), "pícaro al 60: se le propone mano izquierda (revisor, hallazgo 1)")


# --- esMX y Mamba (18-11): Hope, druida tauren nivel 39, escribe /equipo ---
import re  # noqa: E402

DATOS = (ADDON / "Asistente_Equipo" / "Datos_Mazmorras.lua").read_text(encoding="utf-8")
# Los nombres que Cristian vio en inglés en el juego: ya no están en los datos (salvo marcados con "*").
for ingles, espanol in (("Razorfen Downs", "Zahúrda Rajacieno"), ("Scarlet Library", "Biblioteca Escarlata"),
                        ("Scarlet Cathedral", "Catedral Escarlata"), ("The Barrens", "Los Baldíos"),
                        ("Tirisfal Glades", "Claros de Tirisfal"), ("Mordresh Fire Eye", "Mordresh Ojo de Fuego"),
                        ("Arcanist Doan", "Arcanista Doan"), ("High Inquisitor Whitemane", "Alta inquisidora Melenablanca"),
                        ("High Inquisitor Fairbanks", "Alto inquisidor Ribalimpia"), ("Library Walkers", "Botos de biblioteca"),
                        ("The Drowned City", "La Ciudad Anegada"), ("Krol'Dok Stronghold", "Bastión de Krol'dok")):
    check(f'"{ingles}"' not in DATOS, f"datos sin el nombre inglés {ingles!r}")
    check(f'"{espanol}"' in DATOS, f"datos con {espanol!r}")
# Todo nombre que siga en inglés lleva "*" y está en la lista conocida (nada inglés sin marcar a la vista).
marcados = set(re.findall(r'"([^"]+)\*"', DATOS))
check(marcados <= {"Magmatus", "Stone Watcher"}, f"solo los jefes nuevos sin esMX quedan marcados: {sorted(marcados)}")

polestar_lua.fijar_personaje(L, PS, "DRUID", 39, "restoration")  # Hope: druida tauren de la Horda, nivel 39
refrescar()
for cmd in ("", "mazmorras", "60", "jcj", "rol"):
    salida = comando(cmd)
    check(len(salida) > 0, f"/equipo {cmd}: escribe algo")
    check(not any("Polestar" in x for x in salida), f"/equipo {cmd}: sin la palabra Polestar ({[x for x in salida if 'Polestar' in x][:1]})")
    for ingles in ("Razorfen Downs", "Scarlet Library", "Scarlet Cathedral", "The Barrens", "Tirisfal Glades",
                   "Mordresh Fire Eye", "Arcanist Doan", "Whitemane", "Fairbanks", "Library Walkers"):
        check(not any(ingles in x for x in salida), f"/equipo {cmd}: sin {ingles!r}")
salida = comando("")
check(any("Pesos de Mamba" in x for x in salida), "cabecera: Pesos de Mamba")
check(any("nivel 39" in x for x in salida), "Hope nivel 39")

# Objeto que el cliente aún no cargó: sale el esMX de los datos, y se le pide al juego.
pedidos = []
G_.C_Item = L.table_from({"GetItemInfo": L.eval("function() return nil end"),
                          "RequestLoadItemDataByID": lambda i: pedidos.append(i)})
check(E.NombreObjeto(274294) == "Botos de biblioteca", f"Library Walkers sin caché -> esMX ({E.NombreObjeto(274294)})")
check(274294 in pedidos, "pide al juego cargar el objeto")
# Uno que no está en los datos: el inglés de Polestar con "*" (marcado como sin traducción).
G_.Polestar.ItemDB.ItemName = lambda i: "Unknown Thing"
check(E.NombreObjeto(1) == "Unknown Thing*", "sin esMX: inglés con *")
# La leyenda del "*" sale una vez cuando algo marcado se mostró, y no cuando no.
m1 = E.MAZMORRAS[1]
nombre1 = m1.nombre
m1.nombre = "Magmatus*"
salida = comando("mazmorras:todas")
check(sum("NO VERIFICADO" in x and "sin traducción" in x for x in salida) == 1, f"leyenda del *: {[x for x in salida if 'traducción' in x]}")
m1.nombre = nombre1
salida = comando("rol")
check(not any("sin traducción" in x for x in salida), "sin marcas no hay leyenda")
G_.C_Item = None
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
