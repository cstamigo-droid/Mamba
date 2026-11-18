# PARCHES.md: cambios de Mamba dentro de archivos de Polestar

Regla (ARQUITECTURA §13b): lo de Mamba va en carpetas propias. Dentro de los archivos de Polestar solo se hacen **estos** cambios, mínimos y anotados. Todos los aplica `tools/asistente/parches.py`, que se puede correr las veces que haga falta: si un parche ya está, no hace nada, y si Polestar cambió el texto original, falla y avisa.

**Después de cada fusión con una versión nueva de Polestar:**
```
python -I tools/asistente/parches.py            # vuelve a aplicar todo
python -I tools/asistente/parches.py --revisar  # 0 pendientes = listo
python -I tools/asistente/generados.py          # rehace GENERADOS.txt
```

| Id | Archivo | Qué cambia | Por qué |
|---|---|---|---|
| P1 | `addon/Polestar/Core/Init.lua` | `IssueURL` y `DiscordURL` apuntan a los issues de Mamba. Se agrega `ns.mamba`, que lee el campo `X-Mamba` del `.toc` | §13f.4: los errores del fork no deben llegarle al autor de Polestar. Mamba no tiene Discord: el enlace "Discord" de la ventana de errores abre los issues de Mamba |
| P2 | `addon/Polestar/Core/Update.lua`, `addon/Polestar/Quests/Party.lua` | `mine()` devuelve `nil` si es Mamba y `ReleaseURL` apunta a los releases de Mamba. En el grupo sigue diciendo "your guides can differ", pero sin "A newer version is out" | §13f.4: sin esto, Polestar compara su versión con la de otros jugadores y con Polestar Client, y pide "actualiza Polestar". Si el jugador hace caso, CurseForge **reemplaza el fork por el oficial**. Con `mine() = nil`, Mamba no avisa ni manda su versión por el canal de la hermandad ni por susurro. En el grupo sí la manda (`Party.EncodeHello`), porque es parte del protocolo de grupo de Polestar; lo que manda es la versión base ("0.4.0"). Las versiones nuevas de Polestar las vigila `polestar_al_dia.py` |
| P3 | `addon/Polestar/Nav/Journey.lua` | `nav.answerTomTom` pasa a `true` por defecto | §16, fila TomTom: con TomTom apagado, Polestar responde `/way` y la API de puntos de TomTom (`AddWaypoint`, etc.). Polestar lo trae apagado porque el reemplazo no tiene `TomTom.db`. Revisado el 16-11 con grep sobre **todos** los addons instalados en el juego de Cristian: fuera del propio TomTom, ninguno lee `TomTom.db` ni `TomTom.profile`. El jugador lo puede apagar en Opciones › Navegación |
| P4 | todos los `addon/Polestar*/Polestar*.toc` (41) | `## Title…` termina en "· Mamba" y se agrega `## X-Mamba: fork de Polestar, modificado AAAA-MM-DD (repo). No es el Polestar oficial.` | GPL-3.0 §5a: aviso de modificación con fecha, visible en la lista de addons del juego |
| P5 | `rust/crates/forge-gamedata/src/lib.rs` (herramienta `forge`, no el addon) | Si una tabla del cliente no está en el idioma pedido (enUS) y existe `POLESTAR_TEXT_LOCALE_FALLBACK=esMX`, lee esa copia y lo avisa. Sin la variable, todo queda como en Polestar | El juego de Cristian tiene los textos en español, y forge pide `Map`, `AreaTable` y `WMOAreaTable` en inglés para la grilla de caminatas (falló así el 17-11, "is the enUS text locale installed?"). La geometría es la misma en todos los idiomas. Las tablas con nombres para los datos se leen en inglés desde wago.tools (`--forever-tables wago`). Ojo: los nombres de zona de la grilla pueden salir en español. Se revisa al compilar las guías |
| P6 | `rust/crates/forge-data/src/kb.rs` (herramienta `forge`) | Si una corrección pública de mecánicas apunta a un paso de misión que no existe y está `POLESTAR_KB_SKIP_MISSING_STEPS=1`, lo avisa y sigue. Sin la variable, todo queda como en Polestar | Sin QuestieDB, EG Link ni forever-vo, 3 correcciones (pasos 1, 1 y 2) apuntan a pasos que nuestros datos no tienen, y `data build --kb` se detenía (17-11). Esa base de conocimiento la exige la etapa de rutas de `forge build` |
| P7 | `rust/crates/forge-data/src/lib.rs` y `build.rs` (herramienta `forge`); archivo propio `mamba_foreverdb.rs` | Con `POLESTAR_FOREVER_DB_QUESTS=1` y sin QuestieDB, después de leer pfQuest se agregan desde `forever-db/data/*.jsonl` las misiones que faltan (con sus PNJ, objetos e ítems, y los puntos pasados a % del mapa con los marcos de forever-db), y los objetivos que lista forever-db pasan adelante en su orden (el del juego, con el que numeran las guías); los que solo tiene pfQuest quedan detrás. También entran los ítems, PNJ y objetos que nombran las guías (`data/local/forever-db-need.txt`, de `guias_sin_fuente.py --necesita`) y los entrenadores de clase de forever-db; el bando de cada PNJ nuevo (A/H/AH) sale de su plantilla de facción en la tabla FactionTemplate del juego (wago). Sin la variable, todo queda como en Polestar | Sin QuestieDB faltaban 811 misiones propias de Forever y las guías no se podían escribir (17-11). Con P7 entran 967 misiones, 420 PNJ, 50 objetos y 771 ítems, y 539 misiones toman el orden de objetivos de forever-db; los errores de compilación de las guías en los datos bajan de 1102 a 646 (el resto: profesiones, que escribe forge build). Quedan 126 misiones sin fuente, que `guias_sin_fuente.py` saca de las guías, y unas decenas de líneas que `arreglar_guias.py` corrige con el arreglo que da el mensaje de forge |
| P8 | `addon/Polestar/Nav/Travel.lua` | `Nav.EstimateTravel` acepta un quinto argumento `noFlights` (planear sin vuelos, con su propia clave en la caché) y devuelve un tercer valor: los tramos del plan que ya armaba (`legs`, solo lectura; también desde la caché) | Fila K58 («Ir a…» tramo por tramo): el planificador ya calcula los tramos para estimar y los tiraba. Mamba (`Asistente/Llevame.lua`) los muestra con su tiempo, compara la ruta sin piedra de hogar (`noHearth`, ya existía) y sin pagar vuelos (`noFlights`). Sin P8 Mamba da solo el total (`Nav.API.Estimate`). Probado con el planificador real en `tools/asistente/pruebas/test_llevame.py` (su `--romper` quita P8 y las pruebas de tramos fallan) |

Pruebas de Polestar que fijan esos mismos valores y se ajustan junto con el parche (las aplica el mismo script):

| Id | Archivo | Qué cambia |
|---|---|---|
| P1 | `tests/ui-report.test.js` | `INVITE` y la URL del issue esperan los de Mamba |
| P1 | `rust/crates/forge-addontest/tests/addontest/ui-welcome.rs` | el texto del enlace es el de Mamba |
| P2 | `rust/crates/forge-addontest/tests/addontest/ui-update.rs` | el enlace del release es el de Mamba |
| P3 | `rust/crates/forge-addontest/tests/addontest/nav-journey.rs` | la prueba "off by default" espera encendido |

**No verificado:** las pruebas en Rust (`forge-addontest`), porque en este PC no hay Rust. Las de Node sí se corrieron (ver `MAMBA.md`, "Pruebas").

**Para proponerle a Polestar** (si los acepta, dejan de ser parches nuestros): P1 y P2 como un campo del `.toc` (por ejemplo `X-Fork`) que Polestar respete. P3 no, porque es una decisión de Mamba.
