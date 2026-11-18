# -*- coding: utf-8 -*-
"""Escribe WOW_FOREVER/EQUIPO.md (mazmorras por nivel para las 9 clases, guías al 60 de JcE y JcJ)
corriendo la MISMA lógica Lua del addon (addon/Asistente_Equipo/Logica.lua) con lupa.
Así el documento y el addon nunca dicen cosas distintas.

Uso: python -I equipo_tablas.py   (después de python -I equipo.py)
"""
import datetime
import pathlib
import sys

from lupa.lua51 import LuaRuntime

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import polestar_lua  # noqa: E402  (el Gear REAL de Polestar, el mismo que corre en el juego)

AQUI = pathlib.Path(__file__).resolve().parent
MAMBA = pathlib.Path(r"C:\Users\<usuario>\Mamba")  # absoluta: este archivo también se copia a WOW_FOREVER/generador
ADDON = MAMBA / "addon" / "Asistente_Equipo"
SALIDA = pathlib.Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER") / "EQUIPO.md"

CLASES = [("WARRIOR", "Guerrero"), ("PALADIN", "Paladín"), ("HUNTER", "Cazador"), ("ROGUE", "Pícaro"),
          ("PRIEST", "Sacerdote"), ("SHAMAN", "Chamán"), ("MAGE", "Mago"), ("WARLOCK", "Brujo"), ("DRUID", "Druida")]
TRAMOS = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
RANURA = {1: "Cabeza", 2: "Cuello", 3: "Hombros", 5: "Pecho", 6: "Cintura", 7: "Piernas", 8: "Pies", 9: "Muñecas",
          10: "Manos", 11: "Anillo", 12: "Anillo", 13: "Abalorio", 14: "Abalorio", 15: "Espalda", 16: "Mano derecha",
          17: "Mano izquierda", 18: "A distancia / reliquia"}


def cargar():
    L = LuaRuntime(unpack_returned_tuples=True)
    PS = polestar_lua.cargar_gear(L)
    E = L.table()
    loader = L.eval('function(src, name, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Asistente_Equipo", ns) end')
    for f in ("Datos_Mazmorras.lua", "Datos_JcJ.lua", "Logica.lua"):
        loader((ADDON / f).read_text(encoding="utf-8"), f, E)
    return L, E, PS


def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


def pct(p):
    if not p or p <= 0:
        return "% sin dato"
    if p >= 100:
        return "misión"
    return f"{p:.1f}".rstrip("0").rstrip(".").replace(".", ",") + " %"


def fuente(f):
    if f.tipo == "mision":
        return f"misión «{f.n}»" + (f" ({f.zona})" if f.zona else "")
    if f.tipo == "botin":
        if not f.jefe:
            return f"bichos, {f.zona} ({pct(f.pct)} por bicho, NO VERIFICADO)"
        return f"{f.jefe}, {f.zona} ({pct(f.pct)})"
    if f.tipo == "profesion":
        return f"fabricado ({f.prof} {f['nivel'] or ''}; NO VERIFICADO: la receta puede pedir materiales de banda)"
    return "?"


def main():
    L, E, PS = cargar()
    GEAR = PS.Gear
    nombre_de = lambda i: PS.ItemDB.ItemName(i) or f"objeto {i}"
    hoy = datetime.date.today().strftime("%d-%m-%Y")
    o = []
    w = o.append
    w("# Equipo: mazmorras por nivel y guías al 60 (todas las clases)")
    w("")
    w(f"Generado el {hoy} por `generador/equipo_tablas.py` con la misma lógica del addon `Asistente_Equipo` (`/equipo`). **No editar a mano.**")
    w("")
    w("## Cómo leer esto")
    w("- **En el juego manda `/equipo`**: compara contra lo que **llevas puesto** (con el módulo de equipo de Polestar). Estas tablas suponen que no llevas nada, así que muestran la pieza que más suma a tu rol en cada mazmorra.")
    w("- **% de caída** = probabilidad de que el jefe la suelte en una pasada. Pasadas promedio = 100 / %. Con el tope de **5 entradas por hora**, 10 pasadas son 2 horas como mínimo.")
    w("- Para los **bichos** (no jefes) el % es por bicho, no por pasada (NO VERIFICADO); por eso no suman al orden. Las **recompensas de misión** son seguras pero se ganan una vez: tampoco suman al orden de «qué mazmorra repetir».")
    w("- Los nombres de objetos y jefes están en inglés (así vienen en los datos). En el juego, `/equipo` los muestra en español.")
    w("- Rol = especialización de talentos. Los talentos y el cambio de rol están en la otra tarjeta: «Asesor de clase: profesiones, builds y cambio de rol».")
    w("")
    w("## Fuentes (con fecha)")
    w("| Dato | Fuente | Fecha | Confianza |")
    w("|---|---|---|---|")
    w("| Niveles de cada mazmorra y tope de 5 entradas por hora | Warcraft Tavern, https://www.warcrafttavern.com/forever/guides/dungeons/ (dice que coincide con el buscador de grupo del juego) | leída el 16-11-2026 | buena; no es Blizzard |")
    w("| Botín de cada jefe y su % de caída, recompensas de misión | ForeverLevelingBiS v0.12.0-beta de Thunder (MIT), vía Polestar_ItemDB/Forever.lua | datos del 13-10-2026 (**beta**, antes del lanzamiento del 4-11) | **provisional**: Blizzard rehízo el botín de las mazmorras para Forever |")
    w("| Pesos, rol, «¿lo puede usar?» y comparación con lo puesto | El módulo Gear de Polestar 0.3.7.2 (GPL-3.0), con simulaciones de wowsims (MIT). El Asistente lo llama, no lo copia | Polestar del 12-11-2026 | buena para comparar piezas; no es un simulador de Forever |")
    w("| Conjuntos JcJ (qué conjunto es de qué rol, ids de las piezas) | Tablas del cliente de Forever 1.60.1.70532 (beta) vía wago.tools | 22-10-2026 | **provisional** (beta) |")
    w("| Qué da cada rango JcJ, honor, sellos | Blizzard, https://worldofwarcraft.blizzard.com/en-us/news/24303316 | 7-10-2026 | oficial, pero anterior al lanzamiento |")
    w("| Bandas: Barrow Deeps, Hyjal Summit y Onyxia abren el 9-12 | Blizzard, https://worldofwarcraft.blizzard.com/news/24303009 | 20-10-2026 | oficial |")
    w("| Botín rehecho: «hundreds of new items» y moneda Tarnished Undermine Real | Warcraft Tavern (misma página) | 16-11-2026 | buena; no es Blizzard |")
    w("")
    w("**Fuentes que NO coinciden:** los rangos de nivel del buscador de grupo que trae Polestar (tablas del cliente de la beta) son más amplios que los de Warcraft Tavern (ej.: Zul'Farrak 39-60 contra 44-54). Aquí se usa Warcraft Tavern, que es posterior al lanzamiento. Otra lista (method.gg, 14-11) también da rangos distintos y dice basarse en la beta (ver `ORO.md`).")
    w("")
    w("**No se usó:** AtlasLoot Forever (GPL-2.0 solo: no se mezcla con nuestro paquete GPL-3.0 sin permiso del autor), Wowhead, Icy Veins ni Warcraft Tavern para el botín (prohíben copiar).")
    w("")
    w("## Las 35 mazmorras")
    w("| Mazmorra | Niveles | Dónde | ¿Datos de botín? |")
    w("|---|---|---|---|")
    for m in lista(E.MAZMORRAS):
        nota = " (nueva de Forever)" if m.nueva else ""
        lado = {"A": " · capital de la Alianza", "H": " · capital de la Horda"}.get(m.lado, "")
        datos = "sí" if E.BOTIN[m.clave] else "**NO** (sin datos abiertos)"
        w(f"| {m.nombre}{nota} | {m.min}-{m.max} | {m.donde}{lado} | {datos} |")
    w("")
    w("Sin datos abiertos de botín: hay que mirarlas en el diario de mazmorras del juego. AtlasLoot las tiene, pero solo se puede usar como referencia a mano (licencia).")
    w("")
    w("## Mazmorras por nivel, para cada clase y especialización")
    w("Para cada tramo: las 2 mazmorras que más suman a tu rol y su mejor pieza de jefe. Calculado para la Horda (las de una capital de la Alianza no salen). «sin datos» = ninguna mazmorra del tramo tiene datos de botín; «nada útil» = hay datos, pero ningún jefe suelta algo para este rol.")
    w("")
    w("Regla propia: los bichos de Cumbre de Roca Negra se cuentan en la Superior (los datos no dicen el ala). Las mazmorras dentro de una capital no se le aconsejan a la otra facción (NO VERIFICADO si el buscador de grupo te lleva igual).")
    for clase, nombre in CLASES:
        w("")
        w(f"### {nombre}")
        for r in lista(E.Roles(GEAR, clase)):
            w("")
            w(f"**{nombre} {r.nombre}**")
            w("")
            w("| Nivel | 1.ª mazmorra: mejor pieza | 2.ª mazmorra: mejor pieza | Sin datos en el tramo |")
            w("|---|---|---|---|")
            for nivel in TRAMOS:
                polestar_lua.fijar_personaje(L, PS, clase, nivel, r.clave, raza=None)
                con, sin = E.MejorasMazmorras(GEAR, nivel, "H")
                celdas = []
                for x in [x for x in lista(con) if x.valor > 0][:2]:
                    p = lista(x.piezas)[0]
                    quien = p.jefe if (p.jefe and not p.bichos) else "bichos"
                    cuanto = pct(p.pct) + (" por bicho, NO VERIFICADO" if p.bichos else "") if not p.mision else "misión, una vez"
                    celdas.append(f"{x.m.nombre}: {p.nombre} ({RANURA.get(p.ranura, '?')}, {quien}, {cuanto})")
                vacio = "nada útil" if lista(con) else "sin datos"
                while len(celdas) < 2:
                    celdas.append(vacio)
                s = ", ".join(m.nombre for m in lista(sin)) or "—"
                w(f"| {nivel} | {celdas[0]} | {celdas[1]} | {s} |")
    w("")
    w("## Guía al 60 de JcE — PROVISIONAL")
    w("- **Provisional** porque: (1) las bandas abren el 9-12-2026 y no hay datos de su botín; (2) los datos son de la beta; (3) faltan las mazmorras sin datos abiertos (Profundidades de Roca Negra, La Masacre, Maraudon, Templo Sumergido, Blackmaw Hold, Shaper's Terrace, Alcaz Prison, Krol'Dok).")
    w("- **Regla propia** (no viene de una fuente): se quitan las piezas de nivel de objeto mayor a 66 (equipo de bandas de Vanilla como Naxxramas o Ahn'Qiraj, que no están anunciadas para Forever), el botín de esas bandas y las misiones que dependen de Ahn'Qiraj o de la Feria de la Luna Negra (NO VERIFICADO que existan en Forever).")
    w("- **Orden sugerido para juntarlas:** primero lo seguro (misiones), después lo que más cae de un jefe y al final lo de bichos. Lo fabricado no entra al orden: solo sale como alternativa (la receta puede pedir materiales de banda: NO VERIFICADO receta por receta).")
    w("- La pieza principal siempre se puede conseguir (misión o mazmorra). Si hay una **fabricada** mejor, sale como alternativa («o fabricada», NO VERIFICADO: la receta puede pedir materiales de banda). Si la principal no sale de una mazmorra, se muestra también la mejor que **sí** sale de una («o de mazmorra»).")
    w("- Calculado para la **Horda** (las misiones de una sola facción cambian para la Alianza; en el juego, `/equipo 60` usa tu facción).")
    for clase, nombre in CLASES:
        w("")
        w(f"### {nombre}")
        for r in lista(E.Roles(GEAR, clase)):
            polestar_lua.fijar_personaje(L, PS, clase, 60, r.clave, raza=None)
            filas, faltan = E.BiS60(GEAR, clase, r.clave, "H")
            filas, faltan = lista(filas), lista(faltan)
            w("")
            w(f"**{nombre} {r.nombre}** — en orden para juntarlas")
            w("")
            w("| # | Ranura | Pieza | Dónde | Alternativa |")
            w("|---|---|---|---|---|")
            for i, f in enumerate(lista(E.OrdenBiS(L.table_from(dict(enumerate(filas, 1))))), 1):
                alts = [a for a in filas if a.ranura == f.ranura and a.alternativa in ("mazmorra", "fabricado")]
                alt = "; ".join(("fabricada: " if a.alternativa == "fabricado" else "de mazmorra: ") + f"{nombre_de(a.id)}: {fuente(lista(a.fuentes)[0])}" for a in alts) or "—"
                w(f"| {i} | {RANURA.get(f.ranura, '?')} | {nombre_de(f.id)} | {fuente(lista(f.fuentes)[0])} | {alt} |")
            if faltan:
                w("")
                w("Sin pieza de misión o mazmorra en los datos para: " + ", ".join(sorted({RANURA.get(x, '?') for x in faltan})) + ".")
                for x in faltan:
                    for a in [a for a in filas if a.ranura == x and a.alternativa == "fabricado"]:
                        w(f"- {RANURA.get(x, '?')}, fabricada: {nombre_de(a.id)}: {fuente(lista(a.fuentes)[0])}")
    w("")
    w("## Guía al 60 de JcJ — PROVISIONAL")
    w("Sistema (Blizzard, 7-10-2026, https://worldofwarcraft.blizzard.com/en-us/news/24303316):")
    w("- El **honor** se gana matando jugadores, en campos de batalla y con misiones JcJ. Más honor en el campo destacado de la semana festiva.")
    w("- Los **puntos de rango** salen de campos de batalla y misiones JcJ, con **tope semanal**. El artículo no habla de que bajen con el tiempo.")
    w("- Con honor se compran **dos conjuntos**: uno azul y uno épico. La pieza épica = la azul + un **Sello Envalentonado** (cada sello pide un rango).")
    w("- Temporadas con tareas semanales: dan honor y puntos de rango; 3 tareas por temporada dan un Punto de Legado.")
    w("- Arenas: el artículo no las menciona (NO VERIFICADO que existan).")
    w("")
    w("| Rango | Qué abre |")
    w("|---|---|")
    for x in lista(E.RANGOS_JCJ):
        w(f"| {x[1]} | {x[2]} |")
    w("")
    w("**Orden sugerido** (regla propia a partir de la tabla oficial): abalorio JcJ (rango 2), capa (3) y collar (4); después el conjunto azul con honor; luego cada ficha épica cuando llegues a su rango (8 a 14).")
    w("")
    w("Conjunto de cada especialización (tablas del cliente de la beta, 22-10-2026). El rol de cada conjunto se dedujo de sus estadísticas (sanación → sanador; poder de hechizo → lanzador; fuerza o agilidad → físico):")
    w("")
    w("| Clase | Especialización | Horda: azul / épico | Alianza: azul / épico | Nota |")
    w("|---|---|---|---|---|")
    for clase, nombre in CLASES:
        for r in lista(E.Roles(GEAR, clase)):
            h, a = E.JcJ(clase, r.clave, "H"), E.JcJ(clase, r.clave, "A")
            nota = (h and h.azul and h.azul.nota) or ""
            hh = f"{h.azul.nombre} / {h.epico.nombre}" if h else "—"
            aa = f"{a.azul.nombre} / {a.epico.nombre}" if a else "—"
            w(f"| {nombre} | {r.nombre} | {hh} | {aa} | {nota} |")
    w("")
    w("Las piezas de cada conjunto (ids) están en `addon/Asistente_Equipo/Datos_JcJ.lua`; en el juego, `/equipo jcj` las nombra en español.")
    w("")
    w("## Licencia de los datos")
    w("Este documento usa datos de ForeverLevelingBiS (Copyright (c) 2026 Thunder, licencia MIT), leídos desde Polestar (GPL-3.0). El aviso MIT completo está en `addon/Asistente_Equipo/LICENSE-DATA.txt` y debe ir junto a este documento si se publica aparte.")
    w("")
    SALIDA.write_text("\n".join(o) + "\n", encoding="utf-8")
    print("escrito", SALIDA, len(o), "líneas")


if __name__ == "__main__":
    main()
