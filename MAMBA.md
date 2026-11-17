# Mamba: un fork de Polestar

**Mamba no es el Polestar oficial.** Es un fork de [fitzforge/polestar](https://github.com/fitzforge/polestar) (GPL-3.0), hecho por Cristian Amigo para *World of Warcraft: Forever*. Parte del código fuente de Polestar (hoy v0.4.1) y le suma módulos propios. La base (guía paso a paso, GPS, rutas y viajes) es la de Polestar.

- Creado el 2026-11-16 desde la etiqueta `v0.4.0` de Polestar (commit `59071e2`).
- Rama de trabajo: `asistente`. Las versiones nuevas de Polestar se traen **fusionando** sus etiquetas `vX.Y.Z`.
- Licencia: **GPL-3.0-only**, igual que Polestar (`LICENSE`, con sus permisos extra en `LICENSE-EXCEPTION.md`). Es gratis y no tiene publicidad. Los addons de otros autores que Mamba lleva dentro conservan su propia licencia (ver "Addons incluidos").
- Para errores o dudas de Mamba, abre un issue **aquí**, no en Polestar.
- **Ojo:** si la app de CurseForge o Polestar Client actualizan Polestar, **reemplazan las carpetas del fork por las oficiales**. Hay que desactivar las actualizaciones automáticas de Polestar.

## La meta
Que Mamba reemplace **todos** los addons que usa Cristian, igual o mejor. La tabla de cada addon, con su versión y su "hecho cuando", está en `ARQUITECTURA.md` §16 del proyecto. Versiones: **1.0** cubre lo que Polestar ya hace, más los addons libres y el fork limpio; **1.5** profesiones, subasta, recolección y JcJ; **2.0** bolsas, barras, botín, mazmorras, sanación, medidor y mapa; **3.0** la interfaz completa.

## Mamba 1.0: qué reemplaza
| Addon que se apaga | Qué hace Mamba en su lugar | Probado con |
|---|---|---|
| TomTom | Polestar responde `/way` y la API de puntos de TomTom, y Mamba lo deja **encendido por defecto** (parche P3) | `tests/mamba-reemplazos.test.js`: `/way x y`, `reset` y `AddWaypoint` de otro addon. `/way <zona> x y` y `#mapa` los prueba Polestar (`nav-journey.rs`, sin correr aquí) |
| Pawn | La línea del cuadro del objeto: "Polestar \| +12% upgrade · Head" (`Gear` de Polestar, encendido por defecto) | ídem |
| GearQuestForever | La recompensa recomendada sale marcada al entregar, y nunca se elige sola (`QoL/Rewards.lua`) | ídem: prueba que viene encendido y que marca la mejora. La comparación de equipo se simula; la real la prueba la fila Pawn |
| SkillUpForever (+ ForeverCore) | Se incluyen **sin cambios de código** (GPL-3.0-or-later, de cjber) | `incluidos.py revisar`: licencia, versión y que el código es idéntico al de su autor. Que cargan bien se ve en el juego (ya los usa Cristian) |
| WhatsTraining | Se incluye **sin cambios de código** (MIT, de Sveng/fusionpit) | ídem |
| ForeverLootSparkles | Se incluye **sin cambios de código** (GPL-3.0-or-later, de Ashtar Senior). Estaba en la 2.0; entra antes porque es un solo archivo | ídem |
| MyLayerTracker | `Asistente/Capa.lua`, **implementación propia del mismo método** (MyLayerTracker no tiene licencia y no se copió su archivo; comparte lo funcional: qué campo del GUID se lee): la capa del PNJ en el objetivo **o bajo el ratón**, aviso al cambiar, `/capa` y `/layer`. Estaba en la 2.0 | `tools/asistente/pruebas/test_capa.py` |

## Qué agrega Mamba
| Carpeta | Qué hace |
|---|---|
| `addon/Asistente` | Núcleo de los módulos de Mamba: ajustes comunes, estilo del juego, `/asis`, y la capa del servidor (`/capa`) |
| `addon/Asistente_Servicios` | "¿Qué hay en esta ciudad?": banco, subasta, buzón, posada, vuelo, establos, reparar, instructores y vendedores, con búsqueda en español. El viaje lo hace la flecha de Polestar (`Polestar.Nav.API`). `/servicios` |
| `addon/Asistente_Datos` | Qué material juntar en cada zona mientras haces misiones, para qué receta sirve y qué misiones regalan bolsas |
| `addon/Tasador` | Qué hacer con cada objeto (vender, subastar o guardar) y un escaneo propio de la subasta, que solo lee precios |
| `addon/Medidor` | Experiencia, oro, botín y profesión por hora, por zona y actividad |
| `tools/asistente/` | Generadores de datos (Python, desde `forever-db`), pruebas (Lua 5.1 con `lupa`) y los controles del fork (abajo) |

## Addons incluidos (de otros autores)
Van en `addon/` con su carpeta, su `LICENSE` y sus créditos **tal como los publicó su autor**. El único cambio está en su `.toc`: el título dice "· Mamba" y hay una línea `X-Mamba` que avisa de la modificación (GPL-3.0 §5a). `tools/asistente/incluidos.json` guarda la versión, la fuente y la huella de cada archivo, y `incluidos.py revisar` falla si alguien les cambió el código.

| Carpeta | Autor | Licencia | Versión | Código fuente |
|---|---|---|---|---|
| `ForeverCore` | cjber | GPL-3.0-or-later | v1.12.0 | https://github.com/cjber/forever-core |
| `SkillUpForever` | cjber | GPL-3.0-or-later | v1.10.1 | https://github.com/cjber/skillup-forever |
| `WhatsTraining` | Sveng (fusionpit) | MIT | 11.4.8 | https://github.com/fusionpit/WhatsTraining |
| `ForeverLootSparkles` | Ashtar Senior | GPL-3.0-or-later | v2.0.0 | CurseForge, proyecto 1729017 (el código es el del zip) |

Los textos de licencia que faltan en los archivos de esas librerías están en `LICENCIAS_TERCEROS.md`, que va en cada zip. WhatsTraining trae librerías de terceros: LibStub, LibBabble-3.0 y LibDataBroker-1.1 (dominio público); LibBabble-CreatureType-3.0 (MIT); CallbackHandler-1.0 y LibDBIcon-1.0 (Ace3, licencia BSD que prohíbe repartirlas sueltas; aquí van dentro de WhatsTraining, como las publica su autor); y FusionIgnoreStore (del autor de WhatsTraining, MIT, verificado en su repositorio). WhatsTraining es un addon aparte dentro del paquete (GPL-3.0 §5, "agregado"): su licencia MIT y la de sus librerías no cambian.

## Cambios dentro de Polestar
Son solo los de `PARCHES.md` (P1-P4): los errores van a este repositorio, no hay aviso de "actualiza Polestar" (ni en la tarjeta ni en el grupo), TomTom viene encendido y cada `.toc` lleva el aviso de modificación. Los aplica `tools/asistente/parches.py`. Conocido y aceptado: el botón "Discord" de la ventana de errores conserva su texto y su logo, pero abre los issues de Mamba.

## Cada versión nueva de Polestar (pasa seguido: v0.3.7.2 el 12-11, v0.4.0.1 el 16-11, v0.4.1 el 17-11)
Base actual: **Polestar v0.4.1** (fusionada el 17-11; trae Polestar_Arcade: Freedoom Arcade GPL-2.0-or-later y arte Freedoom BSD-3-Clause). Para traer la siguiente, desde Git Bash:
```
bash tools/asistente/fusionar_polestar.sh vX.Y.Z      # la etiqueta nueva de fitzforge/polestar
```
El script, en orden, y se detiene en el primer problema:
1. Muestra si cambiaron las licencias o los permisos de datos de Polestar. Si sale algo, hay que releer ARQUITECTURA §5b antes de repartir.
2. Fusiona la etiqueta (nunca la rama `next`). Si hay choques, los archivos generados se toman de Polestar (`GENERADOS.txt`). Los de `PARCHES.md` se resuelven a mano.
3. Vuelve a aplicar los parches P1-P4.
4. Rehace `GENERADOS.txt`, revisa los addons incluidos y compara las funciones internas que usa `Asistente_Equipo` (`internas_entre.py`). Si cambió alguna, avisa a la sesión de equipo.
5. Corre todas las pruebas y commitea. **Sin push.**

Después: la siguiente construcción de datos (`construir_noche.sh`) recompila `forge` con el código nuevo y usa esta base. Y hay que avisarle a Cristian que no actualice Polestar desde CurseForge, porque eso reemplaza las carpetas del fork.

## Lo que todavía NO está listo (léelo antes de repartir un zip)
Este repositorio hereda el historial y los archivos de Polestar. `GENERADOS.txt` lista los archivos generados que están en git:
- **[AJENO] (146):** hechos con fuentes cuyo permiso es **solo para Polestar**. Son las caminatas y mapas a pie hechos con los mapas privados de Leffe (`Legs.lua`, `Polestar_Nav*`); los nombres de QuestieDB y DingDB (`Polestar_<idioma>/Names.lua`); y las guías, con hechos de QuestieDB y de forever-vo, que no declara licencia.
- **[REGENERAR] (5):** salen de `data/forever`, que en la máquina de Polestar lleva la capa de QuestieDB.

Mamba **no reparte un zip** hasta reconstruir esos archivos con la herramienta de Polestar sin esas fuentes (`forge data build --no-questie`, `forge build --nav grid`, sin `--kb` para dejar fuera forever-vo) y hasta que `tools/asistente/control_zip.py --estricto --manifiesto <construcción>` dé 0 rechazos. Hoy, sobre `addon/`, da **272 rechazos** (lo esperado). Construir `forge` requiere Rust (ya instalado en `D:\rust`) y un compilador de C (pendiente de permiso).

Los datos **propios** de Mamba (Servicios, Datos, Tasador, Medidor) salen de `forever-db` (GPL-3.0). Su `NOTICE.md` dice: "Every value in its tables is held by at least one of the independent sources below" (EG Link CC BY 4.0, CMaNGOS GPL-3.0, VMaNGOS, ForeverTDB, pfQuest MIT, el cliente). Las tablas que usamos (`quest`, `quest_start`, `quest_end`, `quest_objective`, `quest_reward`, `npc`, `object`, `item`, `item_source`, `spawn`, `ui_map`) son GPL-3.0-only en su `datapackage.json`. De ellas Mamba toma ids y números, no textos de objetivos.

**Criterio, uno solo (lo aplican `control_zip.py` y `generados.py`):** forever-db se acepta porque Polestar lo publica como conjunto de datos GPL-3.0 y declara que cada valor lo tiene al menos una fuente independiente. QuestieDB figura entre sus créditos, no como única fuente. Lo que se rechaza son los archivos de Polestar que declaran llevar hechos de QuestieDB "with the Questie maintainers' agreement" (guías, nombres) o caminatas de Leffe. Si Questie o Polestar dicen otra cosa de forever-db, este criterio cae y los datos de Mamba se regeneran.

Mientras tanto, para jugar: **Polestar oficial** + las carpetas de Mamba (`Asistente*`, `Tasador`, `Medidor` y las de "Addons incluidos").

## Pruebas
```
# módulos de Mamba (Python + lupa)
cd tools/asistente/pruebas
python test_capa.py ../../../addon
python test_servicios.py ../../../addon ../../..
python test_tasador.py ../../../addon/Tasador
python test_escaneo.py ../../../addon/Tasador
python test_medidor.py ../../../addon/Medidor
# filas de la 1.0 que cubre Polestar, con el Polestar del fork (Node 24 + Lua 5.1)
LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-reemplazos.test.js
# controles del fork
python -I tools/asistente/parches.py --revisar
python -I tools/asistente/incluidos.py revisar
python -I tools/asistente/generados.py --revisar
python -I tools/asistente/control_zip.py addon
```
`tools/asistente/lua51/` es un intérprete Lua 5.1 mínimo sobre `lupa`, para correr las pruebas de Polestar en Windows sin instalar Lua. Con él, `tests/ui-report.test.js` falla 4 de 43 **igual con y sin los parches**: son diferencias de este intérprete, no de Mamba.

## Créditos
- **Polestar**, de "The Polestar authors" (Fitz y colaboradores): todo lo que no está en las tablas de arriba. Ver `LICENSE`, `THIRD_PARTY.md`, los `LICENSE-DATA.txt` y los `CREDITS.md` de cada carpeta, que se conservan intactos.
- Shortest Path Forever, de Cillian Berragan (rutas a pie, dentro de Polestar).
- Los autores de los addons incluidos (tabla de arriba).
- **forever-db** (de Polestar, GPL-3.0) para los datos de los módulos de Mamba. Sus fuentes están en `forever-db/NOTICE.md` y en `addon/Asistente_Servicios/NOTICE-forever-db.md`.
- World of Warcraft y Blizzard Entertainment son marcas de Blizzard Entertainment, Inc. Ni Mamba ni Polestar están hechos ni respaldados por Blizzard.
