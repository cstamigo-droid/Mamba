"""Pruebas de las placas compactas (K67), la ficha y los enfriamientos del enemigo (C4, estilo Gladius), los
marcadores de banda y el historial de enemigos (C5/K96) de Mamba_Combate. Lua 5.1 (lupa).
Uso: python test_combate_pvp.py [--romper]

Reusa la simulación de test_combate.py (valores secretos de Forever: compararlos, sumarlos o probarlos con «or»
da error; eventos desconocidos; marcos protegidos). Lo que ya rompió cosas o puede romperlas en el juego:
  - la vida, el nombre, el hechizo o el GUID de un enemigo llegan como valor secreto;
  - el mismo lanzamiento llega tres veces (objetivo, foco y placa);
  - Blizzard le vuelve a subir el alfa a su placa (SetAlpha) después de que la escondemos.
--romper (control negativo) quita las defensas: tiene que fallar.
"""
import sys, re, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = AQUI.parent.parent.parent / "addon" / "Mamba_Combate"
ROMPER = "--romper" in sys.argv
toc = (D / "Mamba_Combate.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua") and (D / l.strip()).exists()]
ok = fail = 0


def check(c, m):
    global ok, fail
    if c:
        ok += 1
    else:
        fail += 1
        print("FALLA:", m)


fuente = (AQUI / "test_combate.py").read_text(encoding="utf-8")
MOCK = re.search(r"MOCK = r'''(.*?)'''", fuente, re.S).group(1)
# lo que se suma para estas pruebas: secreto que además falla al probarse con «or»/«if» no se puede simular en
# Lua 5.1 (no hay metamétodo de verdad), así que se revisa en el código fuente más abajo.
EXTRA = r'''
UNIDADES = {}
function UnitExists(u) return u == "player" or (UNIDADES[u] ~= nil) or (u == "target" and OBJETIVO ~= nil) end
local function U(u) if u == "target" then return UNIDADES[OBJETIVO or ""] end return UNIDADES[u] end
function UnitIsPlayer(u) local x = U(u); return x and x.jugador or false end
function UnitCanAttack(a, u) local x = U(u); if not x then return false end; return x.enemigo end
function UnitClass(u) if u == "player" then return "Druida", "DRUID" end; local x = U(u); if x then return x.claseN, x.clase end end
function UnitName(u) if u == "player" then return "Hope" end; local x = U(u); return x and x.nombre end
function UnitGUID(u) if u == "player" then return "G-yo" end; local x = U(u); return x and x.guid end
function UnitLevel(u) local x = U(u); return x and x.nivel or 39 end
function UnitHealth(u) local x = U(u); return x and x.vida or 0 end
function UnitHealthMax(u) local x = U(u); return x and x.vidaMax or 0 end
function UnitClassification(u) local x = U(u); return x and x.clasif or "normal" end
function UnitReaction(u) local x = U(u); return x and x.reaccion or 2 end
function UnitIsUnit(a, b) if b == "target" then return OBJETIVO == a end; return a == b end
function GetRaidTargetIndex(u) local x = U(u); return x and x.banda end
MARCAS = {}
function SetRaidTarget(u, i) table.insert(MARCAS, { u, i }); local x = U(u); if x then x.banda = (i ~= 0) and i or nil end end
RAID_CLASS_COLORS = { ROGUE = { r = 1, g = 0.96, b = 0.41, colorStr = "fffff569" }, MAGE = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff3fc7eb" } }
NOMBRES[1856] = "Esfumarse"; NOMBRES[5277] = "Evasión"; NOMBRES[2094] = "Ceguera"; NOMBRES[1766] = "Patada"; NOMBRES[2983] = "Sprint"
NOMBRES[1776] = "Gubia"; NOMBRES[26889] = "Esfumarse"; NOMBRES[642] = "Escudo divino"
function hooksecurefunc(t, k, fn) local o = t[k]; t[k] = function(...) local r = { o(...) }; fn(...); return unpack(r) end end
function GetRealZoneText() return "Vega de Tuercespina" end
EPOCA = 1763500000
function time() return EPOCA + RELOJ end
'''


def placa(L, token):
    L.execute('''local p = CreateFrame("Frame"); p.namePlateUnitToken = "%s"
      p.UnitFrame = CreateFrame("Frame"); p.UnitFrame.alfa = 1
      p.UnitFrame.SetAlpha = function(s, a) s.alfa = a end
      table.insert(PLACAS, p)''' % token)


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK + EXTRA)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Combate", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Placas.lua":
            src = src.replace("if ocultas[s] and a ~= 0 and not s.mambaPoniendo then", "if false then")      # Blizzard la vuelve a mostrar
            src = src.replace("return ok and leer(si) == true", "return true")                              # dibuja también las amigas
        if ROMPER and n == "Gladius.lua":
            src = src.replace("local repetido = previo and math.abs(previo.fin - (t + e[1])) < 1.5", "local repetido = false")
            src = src.replace("if M.Secreto(id) then diag().secretos = diag().secretos + 1; return false end", "")
        if ROMPER and n == "Medidor.lua":
            src = src.replace("v:SetHeight(16 + 8 * 14)\n", "")                                           # el marco no crece: el recuadro de Mover solo cubre el título
        if ROMPER and n == "BarraCerca.lua":
            src = src.replace("if x and not reciente then", "if x then")                                    # avisa cada vez que lo ve
        if ROMPER and n == "Agro.lua":
            src = src.replace("if not r or r > 3 then return false end", "")                              # avisa también con neutrales
            src = src.replace("if hi and hi <= R then return \"rojo\", R, lo, hi end", "")               # nunca rojo
        if ROMPER and n == "Historial.lua":
            src = src.replace("(not t0) or ((x.visto or 0) - t0 > 120)", "true")                         # cuenta cada vez que lo ve
        cargar(src, n, M)
    return L


L = nuevo()
G = L.globals()
C = G.MambaCombate
check(len(list(G.ERRORES.values())) == 0, "carga sin errores: %s" % list(G.ERRORES.values())[:2])
L.execute('Fire("PLAYER_LOGIN")')
for nom, tit in {"MambaFicha": "Ficha del enemigo", "MambaMarcadores": "Marcadores de banda"}.items():
    check(G[nom] is not None and C.movibles[nom] == tit, "mover: %s existe al entrar y se llama «%s»" % (nom, tit))

# ---------- K67 placas compactas
Pl = C.Placas
L.execute('''UNIDADES.nameplate1 = { jugador = false, enemigo = true, nombre = "Jabalí", guid = "G-jab", vida = Secreto(), vidaMax = Secreto(), clasif = "elite", nivel = 37, banda = 8 }
UNIDADES.nameplate2 = { jugador = false, enemigo = false, nombre = "Guardia", guid = "G-gua", vida = 50, vidaMax = 100, reaccion = 5 }''')
placa(L, "nameplate1"); placa(L, "nameplate2")
L.execute('Fire("NAME_PLATE_UNIT_ADDED", "nameplate1"); Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")')
check(len(list(G.ERRORES.values())) == 0 and C.DB().diag.fallas is None, "placa con vida y nombre secretos: sin errores (%s)" % (C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:2]))
p1, p2 = G.PLACAS[1], G.PLACAS[2]
c1 = Pl.Lista()[p1]
check(c1 is not None and c1.visible and p1.UnitFrame.alfa == 0, "enemigo: placa de Mamba a la vista y la de Blizzard escondida")
check(L.eval('issecretvalue')(c1.vida.valor), "la vida secreta va tal cual a la barra (sin cuentas)")
p1.UnitFrame.SetAlpha(p1.UnitFrame, 1)
check(p1.UnitFrame.alfa == 0, "si Blizzard le vuelve a subir el alfa, se esconde de nuevo")
check(Pl.Lista()[p2] is None and p2.UnitFrame.alfa == 1, "amigo: queda la placa del juego")
check("ÉLITE" in str(c1.marca.texto) and "37" in str(c1.marca.texto), "élite y nivel en la placa (fue %s)" % c1.marca.texto)
check(c1.marcador == 8 and c1.banda.visible, "marcador de banda (calavera) en la placa")
check(tuple(Pl.Medidas()) == (100, 8), "tamaño por defecto 100 × 8")
C.DB().placaAncho = 140
L.execute('Fire("PLAYER_TARGET_CHANGED")')
check(abs(Pl.Medidas()[0] - 140) < 0.1, "ancho configurable")
C.DB().placaAncho = 999
check(Pl.Medidas()[0] == 200, "ancho con tope")
C.DB().placaAncho = 100
# amenaza: daño -> rojo con amenaza 3; tanque -> verde si lo tiene
L.execute('AMENAZA_ST = 3; UNIDADES.nameplate1.vida = 10; UNIDADES.nameplate1.vidaMax = 100')
UnitAffectingCombat_orig = G.UnitAffectingCombat
r, g, b, porque = Pl.Color("nameplate1")
check(porque == "amenaza" and r > 0.9 and g < 0.3, "amenaza alta (daño): roja")
C.DB().rol = "tanque"
r, g, b, porque = Pl.Color("nameplate1")
check(porque == "amenaza" and g > r, "tanque con el enemigo encima: verde")
C.DB().rol = "auto"
L.execute('AMENAZA_ST = Secreto()')
r, g, b, porque = Pl.Color("nameplate1")
check(porque != "amenaza", "amenaza secreta: no se adivina")
L.execute('AMENAZA_ST = 0')
# objetivo con borde claro
L.execute('OBJETIVO = "nameplate1"; Fire("PLAYER_TARGET_CHANGED")')
check(c1.objetivo is True, "el objetivo se marca en su placa")
# lanzamiento interrumpible (el de antes, ahora en Placas.lua)
L.execute('LANZA = { nameplate1 = { "Miedo", "", 1, 99000, 101000, false, 1, false } }; Fire("UNIT_SPELLCAST_START", "nameplate1")')
check(c1.lanz.texto.texto == "INTERRUMPIBLE" and c1.lanz.visible, "INTERRUMPIBLE en la placa compacta")
L.execute('LANZA = { nameplate1 = { Secreto(), "", 1, 99000, 101000, false, 1, Secreto() } }; Fire("UNIT_SPELLCAST_START", "nameplate1")')
check(c1.lanz.texto.texto == "" and len(list(G.ERRORES.values())) == 0, "nombre del hechizo y «interrumpible» secretos: barra sin marca y sin error")
L.execute('LANZA = {}')
# apagarlas devuelve las de Blizzard
C.DB().placas = False
C.Cambio()
check(p1.UnitFrame.alfa == 1 and not c1.visible, "apagadas: vuelve la placa del juego")
C.DB().placas = True
C.Cambio()
check(p1.UnitFrame.alfa == 0 and c1.visible, "encendidas otra vez")
L.execute('Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")')
check(not c1.visible and p1.UnitFrame.alfa == 1, "al irse la placa, se devuelve la del juego (la placa se recicla)")

# ---------- C4 ficha del enemigo y sus enfriamientos
Gl = C.Gladius
L.execute('''UNIDADES.picaro = { jugador = true, enemigo = true, nombre = "Sigiloso", guid = "G-pic", clase = "ROGUE", claseN = "Pícaro", nivel = 40, vida = 100, vidaMax = 100 }
UNIDADES.nameplate3 = UNIDADES.picaro
OBJETIVO = "picaro"; Fire("PLAYER_TARGET_CHANGED")''')
F = Gl.FichaMarco()
check(F.visible and "Sigiloso" in str(F.nombre.texto) and "Pícaro" in str(F.estilo.texto), "ficha del pícaro al ponerlo de objetivo (%s / %s)" % (F.nombre.texto, F.estilo.texto))
check(F.controles.iconos[1].visible and F.defensas.iconos[1].visible, "ficha: sus controles y defensas con íconos")
guarda = Gl.Guarda("ROGUE")
check(list(guarda.values())[:2] == [783, 768], "ficha: lo tuyo para responder, solo lo que sabes (Forma de viaje, felina) — %s" % list(guarda.values()))
check(F.guarda.iconos[1].visible and not F.guarda.iconos[3].visible, "ficha: muestra solo tus hechizos aprendidos")
check("{" not in str(F.consejo.texto) and "Ceguera" in str(F.consejo.texto), "consejo con los nombres del juego (%s)" % F.consejo.texto)
# usó Esfumarse (rango 2, otro id): se reconoce por nombre; llega por objetivo y por placa
G.RELOJ = 200
L.execute('Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "c1", 26889); Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate3", "c1", 26889)')
resta = Gl.Resta("picaro", 1856)
check(resta is not None and 299 <= resta <= 300, "enfriamiento anotado por nombre (rango 2): 300 s (fue %s)" % resta)
act = Gl.ActivosDe("nameplate3")
check(len(list(act.values())) == 1 and act[1].id == 1856, "en su placa sale Esfumarse")
L.execute('Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "c2", 5277); Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate3", "c2", 5277)')
check("Evasión" in str(C.Avisos.ultimo), "aviso «Sigiloso usó Evasión»")
cuenta = L.eval('function() local n = 0; for _, x in ipairs(AVISOS_VISTOS or {}) do n = n + 1 end; return n end')
G.RELOJ = 260
Gl.Dibujar()
idx = [i for i in range(1, 7) if F.defensas.iconos[i].visible and F.defensas.iconos[i].id == 1856]
check(idx and F.defensas.iconos[idx[0]].velo.visible and str(F.defensas.iconos[idx[0]].t.texto) == "240", "ficha: Esfumarse apagado con los segundos que le faltan (fue %s)" % (idx and F.defensas.iconos[idx[0]].t.texto))
# secretos: id o GUID
n0 = C.DB().diag.gladius.anotados
L.execute('Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "c3", Secreto())')
check(C.DB().diag.gladius.anotados == n0 and C.DB().diag.gladius.secretos >= 1 and len(list(G.ERRORES.values())) == 0, "hechizo secreto: no se anota, se cuenta en diag")
L.execute('UNIDADES.picaro.guid = Secreto(); Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "c4", 1766); UNIDADES.picaro.guid = "G-pic"')
check(C.DB().diag.gladius.anotados == n0 and len(list(G.ERRORES.values())) == 0, "GUID secreto: no se anota ni rompe")
# un PNJ o un aliado no tienen ficha ni se anotan
L.execute('OBJETIVO = "nameplate2"; Fire("PLAYER_TARGET_CHANGED")')
check(not F.visible, "sin ficha para un PNJ amigo")
L.execute('Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate2", "c5", 642)')
check(C.DB().diag.gladius.anotados == n0, "lo que lanza un no enemigo no se anota")
C.DB().ficha = False
L.execute('OBJETIVO = "picaro"; Fire("PLAYER_TARGET_CHANGED")')
check(not F.visible, "ficha apagada en ajustes")
C.DB().ficha = True
# aviso de defensa una sola vez aunque llegue por objetivo y placa
L.execute('''AVISOS = 0; local o = MambaCombate.Avisos.Mostrar; MambaCombate.Avisos.Mostrar = function(...) AVISOS = AVISOS + 1; return o(...) end
UNIDADES.paladin = { jugador = true, enemigo = true, nombre = "Brillante", guid = "G-pal", clase = "PALADIN", claseN = "Paladín", nivel = 41 }
UNIDADES.nameplate4 = UNIDADES.paladin; OBJETIVO = "paladin"
Fire("UNIT_SPELLCAST_SUCCEEDED", "target", "c6", 642); Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate4", "c6", 642)''')
check(G.AVISOS == 1, "«X usó Escudo divino» una sola vez (fue %s)" % G.AVISOS)
# limpia lo vencido
G.RELOJ = 5000
Gl.Limpiar(5000)
check(Gl.usados["G-pic"] is None, "se olvidan los enfriamientos vencidos")

# ---------- marcadores
Mk = C.Marcadores
B = Mk.Barra()
check(B.visible, "barra de marcadores a la vista (por defecto: siempre)")
calavera = B.botones[1]
L.execute('OBJETIVO = "picaro"')
calavera.scripts.OnClick(calavera)
check(G.MARCAS[len(list(G.MARCAS.values()))][2] == 8, "clic en la calavera marca al objetivo con la 8")
calavera.scripts.OnClick(calavera)
check(G.MARCAS[len(list(G.MARCAS.values()))][2] == 0, "otro clic en la misma la quita")
L.execute('OBJETIVO = nil')
okm, motivo = Mk.Marcar(8)
check(not okm and motivo == "sin objetivo", "sin objetivo no marca")
C.DB().marcadores = "grupo"; L.execute('EN_GRUPO = false'); C.Cambio()
check(not B.visible, "«solo en grupo»: escondida estando solo")
C.DB().marcadores = "siempre"; C.Cambio()

# ---------- C5/K96 historial
Cz, H = C.Cercanos, C.Historial
L.execute('MambaAPI = { AlVerEnemigo = function(fn) end }')  # la detección es del Tasador
G.RELOJ = 6000
Cz.Visto(L.eval('{ nombre = "Grommash", nivel = 40, clase = "Guerrero", claseToken = "WARRIOR", gremio = "Los Rojos" }'))
e = C.DB().historial["Grommash"]
check(e is not None and e.v == 1 and e.cl == "Guerrero" and e.g == "Los Rojos" and e.z == "Vega de Tuercespina", "historial: primera vez anotada con clase, gremio y zona")
G.RELOJ = 6030
Cz.Visto(L.eval('{ nombre = "Grommash", nivel = 41 }'))
check(e.v == 1 and e.n == 41, "visto de nuevo al rato: misma vez, nivel al día (veces %s)" % e.v)
G.RELOJ = 6300
Cz.Visto(L.eval('{ nombre = "Grommash" }'))
check(e.v == 2, "volvió después de irse: segunda vez (fue %s)" % e.v)
Cz.Muerte("mataste", "Grommash")
check(e.m == 1, "historial: lo mataste 1")
Cz.Muerte("temato", "Grommash")
check(e.t == 1, "historial: te mató 1")
check(H.Matar("Grommash") is True and e.matar, "clic: a la lista «Matar»")
G.RELOJ = 6700
L.execute('AVISOS = 0')
Cz.Visto(L.eval('{ nombre = "Grommash" }'))
check(G.AVISOS == 1 and "Matar" in str(C.Avisos.ultimo), "aviso fuerte al volver a ver a uno de la lista «Matar» (%s)" % C.Avisos.ultimo)
check(H.Nota("Grommash") == "Peligroso" and H.Nota("Grommash") == "Fácil", "clic derecho: la nota va rotando")
for _ in range(3):
    H.Nota("Grommash")
check(e.nota is None, "después de la última: sin nota")
Cz.vista = "historial"; Cz.Abrir()
V = Cz.Ventana()
check("MATAR" in str(V.filas[1].arriba.texto) and "visto 3 veces" in str(V.filas[1].abajo.texto) and "te mató 1" in str(V.filas[1].abajo.texto),
      "pestaña Historial: %s / %s" % (V.filas[1].arriba.texto, V.filas[1].abajo.texto))
V.filas[1].scripts.OnMouseUp(V.filas[1], "LeftButton")
check(not e.matar, "clic en la fila: sale de la lista «Matar»")
V.filas[1].scripts.OnMouseUp(V.filas[1], "RightButton")
check(e.nota == "Peligroso", "clic derecho en la fila: nota")
for i in range(320):
    Cz.Visto(L.eval('{ nombre = "X%d" }' % i))
Cz.Dibujar()
primero = str(V.filas[1].arriba.texto)
V.lista.scripts.OnMouseWheel(V.lista, -1)
check(str(V.filas[1].arriba.texto) != primero and C.Cercanos.desde == 3, "historial: la rueda recorre la lista (más de 12)")
check(H.Contar() <= 300, "historial con tope de 300 (fue %d)" % H.Contar())
Cz.Visto(L.eval('{ nombre = Secreto() }'))
check(len(list(G.ERRORES.values())) == 0, "nombre secreto: no se anota ni rompe")

# ---------- barra «Cerca: N» (como Spy, pedido de Cristian 19-11)
Bc = C.BarraCerca
BB = Bc.Barra()
C.DB().historial = None
Cz.vistos = L.eval("{}")
L.execute('AVISOS = 0')
G.RELOJ = 9000
Bc.Dibujar()
check(BB.visible and str(BB.titulo.t.texto).startswith("Cerca: 0"), "barra «Cerca: 0» a la vista sin enemigos (%s)" % BB.titulo.t.texto)
check(C.movibles["MambaCercaBarra"] == "Barra «Cerca»", "la barra entra en «Mover elementos»")
Cz.Visto(L.eval('{ nombre = "Thrall2", nivel = 40, clase = "Chamán", claseToken = "SHAMAN", gremio = "Tormenta" }'))
check(str(BB.titulo.t.texto).startswith("Cerca: 1") and "Thrall2" in str(BB.filas[1].texto) and "Tormenta" in str(BB.filas[1].texto), "crece con el enemigo: %s / %s" % (BB.titulo.t.texto, BB.filas[1].texto))
check(G.AVISOS == 1 and "Enemigo cerca" in str(C.Avisos.ultimo), "aviso en pantalla al llegar uno nuevo")
G.RELOJ = 9010
Cz.Visto(L.eval('{ nombre = "Thrall2" }'))
check(G.AVISOS == 1, "el mismo enemigo visto otra vez al rato no vuelve a avisar (avisos %s)" % G.AVISOS)
check(BB.altoVisto == 18 + 15 and BB.h == 18 + 8 * 15, "el fondo crece una fila; el marco tiene alto fijo (fondo %s, marco %s)" % (BB.altoVisto, BB.h))
C.DB().cercaBarra = "conEnemigos"; G.RELOJ = 9500; C.Cambio()
check(not BB.visible, "«solo con enemigos»: escondida cuando ya no hay nadie cerca")
C.DB().cercaBarra = "siempre"; C.Cambio()
L.execute('CVARS = { nameplateShowEnemies = "0" }; GetCVar = function(k) return CVARS[k] end; SetCVar = function(k, v) CVARS[k] = v end')
check(not Bc.PlacasEnemigas(), "placas de enemigos apagadas: se lee")
Bc.EncenderPlacas(True)
check(Bc.PlacasEnemigas(), "un clic las enciende")
L.execute('COMBATE = true'); Bc.EncenderPlacas(False); L.execute('COMBATE = false')
check(Bc.PlacasEnemigas(), "en combate no se tocan")

# ---------- medidor: el marco cubre sus barras (el recuadro de «Mover» se pega a todo lo que se ve)
Med = C.Medidor
VM = G.MambaMedidorCombate
L.execute('SESION = { combatSources = { { name = "Hope", totalAmount = 900, amountPerSecond = 30, classFilename = "DRUID", isLocalPlayer = true }, { name = "Otro", totalAmount = 400, amountPerSecond = 10, classFilename = "WARRIOR" } }, durationSeconds = 30 }')
C.DB().medidor = True
Med.Dibujar()
vistas = sum(1 for i in range(1, 9) if L.eval('function(i) return MambaMedidorCombate and nil end')(i) is None)
check(VM.h == 16 + 8 * 14, "medidor: el marco cubre sus 8 barras, no solo el título (alto %s)" % VM.h)

# ---------- K120: transparencia
L.execute('local mt = getmetatable(CreateFrame("Frame")).__index; mt.SetAlpha = function(s, a) s.alfa = a end')
C.DB().alfaMarcos = 60
C.Cambio()
check(abs((G.MambaMedidorCombate.alfa or 0) - 0.6) < 0.01 and abs((G.MambaCercaBarra.alfa or 0) - 0.6) < 0.01, "K120: transparencia 60 %% en medidor y barra Cerca (%s)" % G.MambaMedidorCombate.alfa)
C.DB().alfaMarcos = 5
check(abs(C.AplicarTransparencia() - 0.3) < 0.01, "K120: nunca menos de 30 % (no desaparece)")
C.DB().alfaMarcos = 100; C.Cambio()

# ---------- K123: indicador de agro al acercarse
Ag = C.Agro
check(Ag.Radio(39, 39) == 20 and Ag.Radio(42, 39) == 23 and Ag.Radio(30, 39) == 11, "K123: radio ≈20 yd a tu nivel, ±1 por nivel")
check(Ag.Radio(10, 39) == 5 and Ag.Radio(70, 39) == 45 and Ag.Radio(-1, 39) == 45, "K123: radio entre 5 y 45 (calavera 45)")
check(Ag.Radio(L.eval("Secreto()"), 39) is None, "K123: nivel secreto: no se adivina")
# sondas: CheckInteractDistance (duelo 9,9 / seguir 28) y el alcance real de tus hechizos (Cólera 30 yd)
L.execute("""
DIST = {}
function CheckInteractDistance(u, i) local d = DIST[u]; if d == nil then return nil end
  local yd = ({ [3] = 9.9, [2] = 11.11, [4] = 28 })[i]; return d <= yd end
C_Spell.GetSpellInfo = function(id) local alc = ({ [5176] = 30, [8921] = 30, [339] = 30, [1082] = 5 })[id]; if alc then return { name = NOMBRES[id], maxRange = alc } end end
C_Spell.IsSpellHarmful = function(id) return id ~= 774 and id ~= 8936 and id ~= 5185 end
C_Spell.IsSpellInRange = function(n, u) local d = DIST[u]; if d == nil then return nil end
  for id, nom in pairs(NOMBRES) do if nom == n then local alc = ({ [5176] = 30, [8921] = 30, [339] = 30, [1082] = 5 })[id]; if alc then return d <= alc end end end end
UNIDADES.nameplate5 = { jugador = false, enemigo = true, nombre = "Lobo", guid = "G-lobo", nivel = 39, reaccion = 2 }
UNIDADES.nameplate6 = { jugador = false, enemigo = true, nombre = "Jabalí", guid = "G-jab2", nivel = 39, reaccion = 4 }
EN_COMBATE = false; COMBATE = false
AFECTA_ORIG = UnitAffectingCombat
UnitAffectingCombat = function(u) if u == "player" then return EN_COMBATE end; return u ~= "nameplate5" and u ~= "nameplate6" end
""")
Ag.Olvidar()
G.DIST.nameplate5 = 8
niv, R, lo, hi = Ag.Peligro("nameplate5")
check(niv == "rojo" and R == 20 and hi == 9.9, "K123: a 8 yd de un lobo de tu nivel: rojo (%s, hi %s)" % (niv, hi))
G.DIST.nameplate5 = 20
niv = Ag.Peligro("nameplate5")[0]
check(niv == "amarillo", "K123: entre 11 y 28 yd: amarillo, puede estar dentro (%s)" % niv)
G.DIST.nameplate5 = 40
niv = Ag.Peligro("nameplate5")[0]
check(niv == "verde", "K123: más lejos que 30 yd: verde (%s)" % niv)
check(not Ag.EsAgresivo("nameplate6"), "K123: el neutral amarillo no cuenta")
L.execute("UNIDADES.nameplate5.reaccion = Secreto()")
check(not Ag.EsAgresivo("nameplate5"), "K123: reacción secreta: no se cuenta (no rompe)")
L.execute("UNIDADES.nameplate5.reaccion = 2")
# la barrita: un lobo a 8 yd a la izquierda de la pantalla
L.execute("""PLACAS = {}""")
placa(L, "nameplate5")
L.execute('PLACAS[1].GetCenter = function() return 300, 500 end')
G.DIST.nameplate5 = 8
C.DB().agro = True
Ag.Dibujar()
AB = Ag.Barra()
check(AB.visible and Ag.ultimo.peor == "rojo", "K123: la barrita aparece en rojo")
lado = Ag.ultimo.lista[1].lado
check(lado is not None and lado < -0.5 and AB.marcas[1].visible, "K123: la marca va hacia la izquierda, donde está el lobo (%s)" % lado)
G.DIST.nameplate5 = 60
Ag.Dibujar()
check(not AB.visible, "K123: sin peligro, la barrita se esconde (discreta)")
G.DIST.nameplate5 = 8
L.execute('EN_COMBATE = true; COMBATE = true')
Ag.Dibujar()
check(not AB.visible, "K123: en combate no se muestra")
L.execute('EN_COMBATE = false; COMBATE = false')
d_ag = C.DB().diag.agro
check(d_ag.interaccion > 0 and d_ag.hechizo > 0, "K123: diag cuenta qué sondas responden (interacción %s, hechizo %s)" % (d_ag.interaccion, d_ag.hechizo))
check(C.movibles["MambaAgro"] == "Indicador de agro", "K123: entra en «Mover elementos»")
L.execute("UnitAffectingCombat = AFECTA_ORIG")

# ---------- reglas
src = "".join((D / n).read_text(encoding="utf-8") for n in ("Placas.lua", "Gladius.lua", "Marcadores.lua", "Historial.lua", "BarraCerca.lua", "Agro.lua"))
check("SLASH_" not in src and "SlashCmdList" not in src, "sin comandos /")
check(not re.search(r"\b(CastSpell\w*|UseAction|RunMacroText|TargetUnit|CastSpellByName|SpellStopCasting)\b", src), "nada lanza ni elige por el jugador")
check("GameFont" not in src and "|cff" not in src and "SetTextColor(" not in src, "letra y colores de la apariencia")
# K110/K111: en mazmorras y en combate los sí/no del juego llegan SECRETOS y probarlos con if/and/or da
# «boolean test on a secret boolean value». En Lua 5.1 no se puede simular ese error (no hay metamétodo de verdad):
# se exige en el código que cada sí/no de una unidad pase por M.Si / leer / M.Secreto.
BOOL = re.compile(r"\b(UnitIsPlayer|UnitCanAttack|UnitAffectingCombat|UnitIsUnit|UnitIsFriend|UnitIsEnemy|UnitIsDeadOrGhost|UnitIsDead|UnitIsTapDenied)\(")
SEGURO = re.compile(r"M\.Si\(|leer\(|M\.Secreto\(|^\s*--|function |UnitAffectingCombat\(\"player\"\)")
sueltos = []
for f in sorted(D.glob("*.lua")):
    for i, l in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
        if BOOL.search(l) and not SEGURO.search(l):
            sueltos.append("%s:%d" % (f.name, i))
check(not sueltos, "K110: ningún sí/no de unidad sin M.Si/leer (secretos en mazmorra): %s" % sueltos[:5])
# un secreto no se prueba con «or» ni «if»: las lecturas del juego que pueden ser secretas pasan por tal()/leer()/M.Num
for fn in ("UnitHealth(", "UnitHealthMax(", "UnitName("):
    malos = [l for l in (D / "Placas.lua").read_text(encoding="utf-8").splitlines() if fn in l and re.search(re.escape(fn) + r"[^)]*\)\s*or\b", l)]
    check(not malos, "Placas: %s nunca con «or» (secreto): %s" % (fn, malos[:1]))
check(len(list(G.ERRORES.values())) == 0 and C.DB().diag.fallas is None, "todo sin errores: %s" % (C.DB().diag.fallas and list(C.DB().diag.fallas.values())[:3]))
print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
