"""Pruebas de Mamba_Barras con Lua 5.1 (lupa). Uso: python test_barras.py [carpeta de Mamba_Barras]

Simula lo que ya rompió cosas en el juego (eventos que Forever no conoce, marcos protegidos en combate).
Lo que NO prueba: que se vea bien ni que LibActionButton haga su parte; eso se prueba en el juego.
"""
import sys, pathlib, re, subprocess, tempfile
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent.parent.parent / "addon" / "Mamba_Barras"
toc = (D / "Mamba_Barras.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua") and not l.startswith("libs")]
ARCHIVOS = [a for a in ARCHIVOS if a != "Teclas_cortas.lua"]

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


# Copia de Bartender de ejemplo: el perfil real de Hope (18-11), escrito por el generador.
HOPE_BT = '''
Bartender4DB = { ["profileKeys"] = { ["Hope Fé"] = "Hope Fé" }, ["namespaces"] = {
 ["ActionBars"] = { ["profiles"] = { ["Hope Fé"] = { ["actionbars"] = {
   { ["position"] = { ["y"] = 49.02, ["x"] = -302.58, ["point"] = "BOTTOM", ["scale"] = 0.75 }, ["padding"] = 1.9 },
   { ["enabled"] = false, ["position"] = { ["y"] = -224, ["x"] = -284.5, ["point"] = "CENTER" } },
   { ["rows"] = 12, ["position"] = { ["y"] = 200, ["x"] = -96, ["point"] = "RIGHT", ["scale"] = 0.75 } },
   { ["rows"] = 12, ["position"] = { ["y"] = 202.4, ["x"] = -143, ["point"] = "RIGHT", ["scale"] = 0.75 } },
   { ["position"] = { ["y"] = 119.45, ["x"] = -303.41, ["point"] = "BOTTOM", ["scale"] = 0.75 } },
   { ["position"] = { ["y"] = 84.2, ["x"] = -303.41, ["point"] = "BOTTOM", ["scale"] = 0.75 } },
   {}, {}, {}, {}, [14] = {}, [13] = { ["enabled"] = true, ["position"] = { ["y"] = 154.7, ["x"] = -303.74, ["point"] = "BOTTOM", ["scale"] = 0.75 } },
   [15] = { ["position"] = { ["y"] = -224, ["x"] = -284.5, ["point"] = "CENTER" } } } } } },
 ["StanceBar"] = { ["profiles"] = { ["Hope Fé"] = { ["position"] = { ["y"] = 192.65, ["x"] = -305.8, ["point"] = "BOTTOM", ["scale"] = 1.2 } } } },
 ["PetBar"] = { ["profiles"] = { ["Hope Fé"] = { ["enabled"] = false, ["position"] = { ["y"] = 97.4, ["x"] = 118.2, ["point"] = "BOTTOM" } } } },
} }
'''


def generar_copia():
    """Corre el generador real sobre el perfil de ejemplo y devuelve el DeBartender.lua que escribe."""
    with tempfile.TemporaryDirectory() as t:
        t = pathlib.Path(t)
        sv = t / "Cuenta" / "SavedVariables"
        sv.mkdir(parents=True)
        (sv / "Bartender4.lua").write_text(HOPE_BT, encoding="utf-8")
        out = t / "DeBartender.lua"
        out.write_text((D / "DeBartender.lua").read_text(encoding="utf-8"), encoding="utf-8")
        gen = AQUI.parent / "barras" / "copiar_bartender.py"
        r = subprocess.run([sys.executable, str(gen), str(t), str(out)], capture_output=True, text=True, encoding="utf-8")
        check(r.returncode == 0, "generador: " + r.stderr[-300:])
        return out.read_text(encoding="utf-8")


COPIA = generar_copia()


def nuevo(antes="", con_copia=True):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    if antes:
        L.execute(antes)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Barras", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if n == "DeBartender.lua" and con_copia:
            src = COPIA
        cargar(src, n, M)
    return L, M


# ---------- 0. Todo compila y el .toc carga cada archivo ----------
check("## Interface: 16001" in toc, "toc 16001")
check("SavedVariablesPerCharacter: MambaBarrasPJ" in toc, "toc PJ")
for n in ARCHIVOS:
    check((D / n).exists(), "falta " + n)
for lib in ["LibStub", "CallbackHandler-1.0", "LibButtonGlow-1.0", "LibActionButton-1.0"]:
    check(("libs\\%s\\%s.lua" % (lib, lib)) in toc and (D / "libs" / lib / (lib + ".lua")).exists(), "lib " + lib)

# ---------- 1. Cálculos puros ----------
L, M = nuevo()
pag = L.eval("function(M) return M.PaginasFormas('DRUID', nil, function(c) return c == 97 or c == 73 end) end")(M)
check(pag.oso == 9 and pag.felina == 7 and pag.sigilo == 7 and pag.lechucico == 0,
      "druida: oso 9, felina 7, sigilo como felina, lechúcico vacío -> no cambia: %s %s %s %s" % (pag.oso, pag.felina, pag.sigilo, pag.lechucico))
pag2 = L.eval("function(M) return M.PaginasFormas('DRUID', nil, function(c) return c == 85 or c == 73 end) end")(M)
check(pag2.sigilo == 8, "si la página de sigilo (85-96) tiene algo, el sigilo la usa")
pag3 = L.eval("function(M) return M.PaginasFormas('DRUID', {oso = 0}, function() return true end) end")(M)
check(pag3.oso == 0, "lo que elige el jugador manda sobre lo por defecto")
cond = L.eval("function(M) return M.Conductor('DRUID', {sigilo = 7, felina = 7, oso = 9, lechucico = 0}, {anular = 18, vehiculo = 16}) end")(M)
check(cond == "[overridebar]18;[vehicleui][possessbar]16;[bonusbar:5]11;[bar:2]2;[bar:3]3;[bar:4]4;[bar:5]5;[bar:6]6;"
             "[bonusbar:1,stealth]7;[bonusbar:1]7;[bonusbar:3]9;1", "conductor druida: " + cond)
check(L.eval("function(M) return M.Conductor('HUNTER', {}, {}) end")(M).endswith("[bar:6]6;1"), "cazador: sin formas")
check(L.eval("function(M) return M.Conductor('WARRIOR', {batalla=7, defensiva=8, rabiosa=9}, {}) end")(M).count("bonusbar") == 4,
      "guerrero: tres actitudes + bonusbar:5")
c, f = L.eval("function(M) return M.Rejilla(12, 1) end")(M)
check((c, f) == (12, 1), "rejilla 12x1")
c, f = L.eval("function(M) return M.Rejilla(12, 5) end")(M)
check((c, f) == (3, 4), "12 en 5 filas -> 3 columnas, 4 filas: %s %s" % (c, f))
check(L.eval("function(M) return M.BotonDeBT('CLICK BT4Button13:Keybind') end")(M) == 13, "BT4Button13 -> 13")
check(L.eval("function(M) return M.BotonDeBT('CLICK BT4Button146:LeftButton') end")(M) == 146, "BT bar 13 -> casilla 146")
check(L.eval("function(M) return M.BotonDeBT('CLICK BT4Button80:Keybind') end")(M) is None, "BT bar 7 (sin barra en Mamba) -> nada")
check(L.eval("function(M) return M.BotonDeBT('ACTIONBUTTON1') end")(M) is None, "no es de Bartender")

# ---------- 2. Arranque: barras, formas, mascota, copia de Bartender, barras del juego ----------
PREVIO = '''
ACCIONES[97] = true; ACCIONES[73] = true
for i = 1, 12 do
  CreateFrame("CheckButton", "ActionButton"..i, UIParent, "SecureActionButtonTemplate")
  CreateFrame("CheckButton", "MultiBarRightButton"..i, UIParent, "SecureActionButtonTemplate")
end
CreateFrame("Frame", "MainActionBar", UIParent)
CreateFrame("Frame", "MultiBarRight", UIParent)
CreateFrame("Frame", "StanceBar", UIParent)
BINDINGS["ACTIONBUTTON1"] = {"1"}
BINDINGS["MULTIACTIONBAR3BUTTON2"] = {"F2"}
BINDINGS["CLICK BT4Button13:Keybind"] = {"SHIFT-1", "CTRL-1"}
BINDINGS["SHAPESHIFTBUTTON2"] = {"X"}
'''
L, M = nuevo(PREVIO)
L.execute('Fire("PLAYER_LOGIN"); Fire("PLAYER_ENTERING_WORLD")')
G = L.globals()
check(not list(G.ERRORES.values()), "errores al entrar: %s" % list(G.ERRORES.values()))
check(M.listo, "listo")
for i in range(1, 10):
    check(G["MambaBarra%d" % i] is not None, "barra %d creada" % i)
check(G.MambaBarraFormas is not None and G.MambaBarraMascota is not None, "formas y mascota")
check(G.MambaBoton145 is not None and G.MambaBoton1.estados["7"][2] == 73, "barra 1, página 7 -> casilla 73")
check(G.MambaBoton1.estados["1"][2] == 1 and G.MambaBoton13.estados["0"][2] == 13, "casillas por estado")
cond = G.DRIVERS["MambaBarra1:page"]
check("[bonusbar:3]9" in cond and "[bonusbar:1]7" in cond and "[bonusbar:4]" not in cond, "conductor real: " + str(cond))
check(G.MambaBoton1.config.actionButtonUI and G.MambaBoton1.config.assistedHighlight, "resaltado de Blizzard encendido")
check(G.MambaBoton1.config.keyBoundTarget == "ACTIONBUTTON1" and G.MambaBoton13.config.keyBoundTarget == False,
      "tecla: barra 1 usa la del juego; barra 2 su clic")
# copia de Bartender
c1, c2, c3, c7, c9 = (M.Config(i) for i in (1, 2, 3, 7, 9))
check(c1.punto == "BOTTOM" and abs(c1.x + 302.58) < 0.01 and c1.escala == 0.75 and c1.separacion == 1.9, "barra 1 como en Bartender")
check(c2.mostrar is False and c3.filas == 12 and c7.mostrar is True and c9.mostrar is False, "barras 2 oculta, 3 vertical, 7 (BT13) visible, 9 oculta")
check(M.Config("formas").escala == 1.2 and M.Config("mascota").mostrar is False, "formas y mascota de Bartender")
check(G.MambaBarrasPJ.copiadoDe == "instalación", "origen de la copia")
check(G.MambaBarra1.punto[0 + 1] == "BOTTOM" and abs(G.MambaBarra1.punto[4] - (-302.58 / 0.75)) < 0.01, "SetPoint en unidades de la barra")
# barras del juego escondidas
check(G.ActionButton1.attr["statehidden"] is True and G.ActionButton1.visible is False, "ActionButton1 escondido")
check(L.eval("function(M) return MainActionBar.padre == M.oculto and MultiBarRight.padre == M.oculto and StanceBar.padre == M.oculto end")(M), "marcos del juego bajo el oculto")
# teclas
O = G.OVERRIDES
check(O["1"] == "MambaBoton1" and O["F2"] == "MambaBoton26", "teclas del juego -> Mamba: %s" % dict(O))
check(O["SHIFT-1"] == "MambaBoton13" and O["CTRL-1"] == "MambaBoton13", "teclas de Bartender -> Mamba")
check(O["X"] == "MambaForma2", "tecla de forma")
check(G.MambaBarrasDB.diag.teclas.bartender == 2, "diag teclas")
# evento desconocido: no corta nada y queda anotado
check(G.MambaBarrasDB.diag.eventosNo["PET_BAR_UPDATE_USABLE"], "evento desconocido anotado")
check(G.MambaBarrasDB.diag.rotacion.C_AssistedCombat is False, "diag rotación")
# formas
check(G.MambaForma1.estados["0"][2] == 5487 and G.MambaForma3.estados["0"][1] == "empty", "formas llenas")
check(G.MambaForma2.marcado is True, "forma activa marcada")

# K99: las barras van en MEDIUM (en LOW la barra del juego mal escondida se comía los clics)
check(G.MambaBarra1.estrato == "MEDIUM" and G.MambaBarraFormas.estrato == "MEDIUM" and G.MambaBarraMascota.estrato == "MEDIUM", "barras en MEDIUM")
# K99: cada clic y cada hechizo soltado se cuentan en el diag
G.MambaBoton1.scripts.PostClick(G.MambaBoton1, "LeftButton"); G.MambaBoton1.scripts.OnReceiveDrag(G.MambaBoton1)
check(G.MambaBarrasDB.diag.cuenta.clics == 1 and G.MambaBarrasDB.diag.cuenta.soltados == 1, "diag cuenta clics y soltados")
# K99: un tamaño y una separación para todas las barras
M.TamanoTodas(0.6); M.SeparacionTodas(4)
check(all(M.Config(i).escala == 0.6 and M.Config(i).separacion == 4 for i in range(1, 10)) and M.Config("formas").escala == 0.6, "tamaño y separación de todas")
check(G.MambaBarra1.escala == 0.6 and G.MambaBarrasPJ.escalaTodas == 0.6, "aplicado a la barra")
M.TamanoTodas(0.1)
check(M.Config(2).escala == 0.3, "tamaño mínimo 30 %")
M.TamanoTodas(0.75); M.SeparacionTodas(1.9)
L.eval("function(M) M.Config(1).separacion = 1.9 end")(M)

# ---------- 3. Combate: nada protegido se toca; se aplica al salir ----------
L.execute('COMBATE = true')
L.eval("function(M) local c = M.Config(1); c.escala = 1; c.botones = 6; M.FueraDeCombate('disponer1', function() M.Disponer(1) end) end")(M)
L.execute('Fire("UPDATE_BINDINGS"); Fire("UPDATE_SHAPESHIFT_FORMS")')
check(not list(G.BLOQUEOS.values()), "en combate no se tocó nada protegido: %s" % list(G.BLOQUEOS.values()))
check(G.MambaBarra1.escala == 0.75, "todavía no se aplicó")
L.execute('COMBATE = false; Fire("PLAYER_REGEN_ENABLED")')
check(G.MambaBarra1.escala == 1 and G.MambaBoton7.visible is False and G.MambaBoton6.visible is True, "aplicado al salir de combate")

# ---------- 4. Asignar teclas ----------
check(M.EmpezarTeclas(), "empieza asignar teclas")
M.bajoRaton = G.MambaBoton2
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "Q")
check(list(G.BINDINGS["ACTIONBUTTON2"].values()) == ["Q"] and G.GUARDADO == 1, "Q -> ACTIONBUTTON2 guardada en el juego")
check(G.OVERRIDES["Q"] == "MambaBoton2", "Q aprieta el botón de Mamba")
M.bajoRaton = G.MambaBoton14
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "G")
check(list(G.BINDINGS["CLICK MambaBoton14:LeftButton"].values()) == ["G"], "barra 2: tecla al clic del botón")
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "BACKSPACE")
check(not list((G.BINDINGS["CLICK MambaBoton14:LeftButton"] or L.table()).values()), "Retroceso borra")
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "LSHIFT")
check(G.GUARDADO == 3, "una tecla sola de Mayús no se asigna")
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "ESCAPE")
check(not M.asignando, "Esc termina")
# la pelea empieza antes de que llegue PLAYER_REGEN_DISABLED: no se llama a SetBinding (protegida)
check(M.EmpezarTeclas(), "vuelve a asignar")
M.bajoRaton = G.MambaBoton3
L.execute('COMBATE = true')
G.MambaBarrasCaptura.scripts.OnKeyDown(G.MambaBarrasCaptura, "R")
check(G.GUARDADO == 3 and not (G.BINDINGS["ACTIONBUTTON3"] and list(G.BINDINGS["ACTIONBUTTON3"].values())), "en combate no asigna teclas")
check(not list(G.BLOQUEOS.values()), "en combate no se toca nada protegido al apretar una tecla")
L.execute('COMBATE = false; Fire("PLAYER_REGEN_ENABLED")')
check(not M.asignando, "al salir de combate se cierra el modo de teclas")

# ---------- 5. Mover ----------
check(M.EmpezarMover(), "empieza mover")
check(G.MambaBarrasMover is not None and G.MambaBarrasMover.visible, "panel Listo a la vista")
L.execute('COMBATE = false')
M.TerminarMover()
check(not M.moviendoBarras, "Listo termina")
L.execute('COMBATE = true')
check(not M.EmpezarMover(), "en combate no se mueve")
L.execute('COMBATE = false')

# ---------- 6. Opciones (sin Polestar: plantillas del juego) ----------
M.AbrirOpciones(3)
check(G.MambaBarrasVentana is not None and G.MambaBarrasVentana.visible, "ventana de barras")
check(not list(G.ERRORES.values()), "errores al abrir opciones: %s" % list(G.ERRORES.values()))

# ---------- 7. Entrar en combate (recarga en pelea) ----------
L, M = nuevo('COMBATE = true')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(not M.listo and not list(G.BLOQUEOS.values()), "en combate espera: %s" % list(G.BLOQUEOS.values()))
L.execute('COMBATE = false; Fire("PLAYER_REGEN_ENABLED")')
check(M.listo and G.MambaBarra1 is not None, "al salir de combate arma las barras")

# ---------- 8. Otro addon de barras encendido: Mamba no pone las suyas ----------
L, M = nuevo('CARGADOS = { Bartender4 = true }; CreateFrame("Frame", "MainActionBar", UIParent)')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaBarra1 is None and M.bloqueadoPor == "Bartender4" and L.eval("function(M) return MainActionBar.padre ~= M.oculto end")(M), "con Bartender4: no pisa")
check(G.MambaBarrasCambio is not None and G.MambaBarrasCambio.visible, "ofrece cambiar a las barras de Mamba (una vez)")
check(G.MambaBarrasPJ.ofrecido is True, "no se vuelve a ofrecer")
M.AbrirOpciones()
check(G.MambaBarrasVentana.visible, "la pestaña ofrece apagar Bartender4")

# ---------- 9. Sin copia de Bartender: lugar por defecto ----------
L, M = nuevo(con_copia=False)
L.execute('Fire("PLAYER_LOGIN")')
check(M.Config(1).punto == "BOTTOM" and M.Config(1).y == 40 and M.Config(2).mostrar is False, "por defecto")

# ---------- 9b. K99: personaje que entró antes de que la instalación trajera la copia de Bartender ----------
L, M = nuevo('MambaBarrasPJ = { version = 1, barras = { { mostrar = true, botones = 12, filas = 1, escala = 0.8, separacion = 2, alfa = 1, ver = "siempre", punto = "BOTTOMLEFT", x = 736, y = 0 } } }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaBarrasPJ.version == 2 and G.MambaBarrasPJ.copiadoDe == "instalación" and M.Config(1).punto == "BOTTOM", "v1 sin copia: copia una vez")
check(G.MambaBarrasPJ.anterior is not None and G.MambaBarrasPJ.anterior[1].x == 736, "lo de antes queda para Deshacer")
check(L.eval("function(M) return M.avisoCopia end")(M) is True, "avisa en el chat que copió (y cómo deshacer)")
L, M = nuevo('MambaBarrasPJ = { version = 2, copiadoDe = "instalación", barras = { { mostrar = true, botones = 12, filas = 1, escala = 0.8, separacion = 2, alfa = 1, ver = "siempre", punto = "BOTTOMLEFT", x = 736, y = 0 } } }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(M.Config(1).x == 736, "ya copiado: no vuelve a pisar lo del jugador")
L, M = nuevo('MambaBarrasPJ = { version = 1, barras = {} }', con_copia=False)
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaBarrasPJ.anterior is None and G.MambaBarrasPJ.copiadoDe is None, "sin copia disponible: queda igual")
# revisión wow-addon-lua (tanda 3): sin copia NO se gasta la oportunidad; cuando llega la copia, se copia
L, M = nuevo('MambaBarrasPJ = { version = 2, barras = { { mostrar = true, botones = 12, filas = 1, escala = 0.8, separacion = 2, alfa = 1, ver = "siempre", punto = "BOTTOMLEFT", x = 736, y = 0 } } }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MambaBarrasPJ.copiadoDe == "instalación" and G.MambaBarrasPJ.anterior[1].x == 736, "entró antes sin copia: copia cuando aparece")

# ---------- 10. Prueba estática: nada decide ni lanza por el jugador ----------
PROHIBIDO = re.compile(r"\b(CastSpell\w*|UseAction|RunMacroText|TargetUnit|CastShapeshiftForm|SpellStopCasting|"
                       r"C_AssistedCombat\.\w+\s*\(\s*\)\s*;?\s*-- usar)")
for n in ARCHIVOS:
    src = (D / n).read_text(encoding="utf-8")
    m = PROHIBIDO.search(src)
    check(not m, "%s llama a %s" % (n, m.group(0) if m else ""))
    check("|cff" not in src.lower(), n + ": color fijo en el texto (E3)")
    check(not re.search(r"GameFont\w+", src) or n == "Piezas.lua", n + ": letra fija (E2), solo permitida en el respaldo sin Polestar")

# ---------- 11. Sección "Barras" en el menú de Polestar (riel izquierdo del hub) ----------
L, M = nuevo('Polestar = { UI = { Picker = {} } }; function Polestar.UI.RegisterSection(s) SECCION = s; return true end; '
             'function Polestar.UI.ShowPicker() ABIERTO = true end; function Polestar.UI.Picker.ShowSection(k) SECCION_VISTA = k end; '
             'function Polestar.UI.Picker.Render() end')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
S = G.SECCION
check(S is not None and S.key == "MambaInterfaz" and S.label == "Interfaz", "sección Interfaz registrada en el hub")
items, activa = S.nav()
check(len(list(items.values())) == 12 and items[1].heading and activa == "barras:1", "índice: título Barras + 9 barras + formas + mascota, la 1 elegida")
padre = L.eval('function() local f = CreateFrame("Frame", nil, UIParent); f.w, f.h = 640, 480; return f end')()
S.build(padre)
S.onNav("barras:3"); S.render()
check(not list(G.ERRORES.values()), "build/render sin errores: %s" % list(G.ERRORES.values()))
M.AbrirOpciones(5)
check(G.ABIERTO and G.SECCION_VISTA == "MambaInterfaz", "abrir opciones lleva a la sección del hub")

# ---------- 12. Defectos vistos en el juego el 18-11 ----------
L, M = nuevo('CreateFrame("Frame", "MainActionBar", UIParent); MainActionBar.HideBase = function(self) self.escondidaBase = true end')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MainActionBar.escondidaBase is True, "la barra principal del juego se esconde con su Hide original (HideBase)")
K = LuaRuntime(unpack_returned_tuples=True)
K.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
K.execute((D / "Teclas_cortas.lua").read_text(encoding="utf-8"))
kb = K.eval('LibStub("LibKeyBound-1.0")')
check(kb.ToShortKey(kb, "CTRL-1") == "c1" and kb.ToShortKey(kb, "SHIFT-MOUSEWHEELUP") == "sRuA" and kb.ToShortKey(kb, "Q") == "Q", "teclas cortas")
# ---------- 13. K55: ventanas movibles y "Restablecer posiciones" ----------
L, M = nuevo('MambaAPI = { Movible = function(f, n, asa, op) MOVIBLES = MOVIBLES or {}; MOVIBLES[n] = op and op.yaArrastra; return true end, '
             'AlRestablecer = function(fn) RESTABLECER = fn end }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
M.AbrirOpciones()
check(G.MOVIBLES is not None and G.MOVIBLES["MambaBarrasVentana"] is True, "la ventana de barras pasa por MambaAPI.Movible")
c1 = M.Config(1); c1.punto, c1.x, c1.y = "CENTER", 5, 5
G.RESTABLECER()
check(M.Config(1).punto == "BOTTOM" and abs(M.Config(1).x + 302.58) < 0.01, "Restablecer: la barra vuelve al lugar de Bartender")
# K55 ampliado: el modo «Mover elementos» de Mamba pone las barras en su modo de mover
L, M = nuevo('MambaAPI = { AlModoMover = function(fn) MODO_MOVER = fn end }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(G.MODO_MOVER is not None, "Barras se enganchan al modo Mover de Mamba")
if G.MODO_MOVER is not None:
    G.MODO_MOVER(True); check(M.moviendoBarras, "modo Mover: las barras muestran sus recuadros")
    G.MODO_MOVER(False); check(not M.moviendoBarras, "al salir: las barras salen de su modo")
print(f"{ok} OK, {fail} FALLAN")
sys.exit(1 if fail else 0)
