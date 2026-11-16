# Mamba: un fork de Polestar

**Mamba no es el Polestar oficial.** Es un fork de [fitzforge/polestar](https://github.com/fitzforge/polestar) (GPL-3.0), hecho por Cristian Amigo para *World of Warcraft: Forever*. Parte del código fuente de Polestar 0.4.0 y le suma módulos propios: la base (guía paso a paso, GPS, rutas y viajes) es la de Polestar.

- Creado: 2026-11-16, desde la etiqueta `v0.4.0` de Polestar (commit `59071e2`).
- Rama de trabajo: `asistente`. Las versiones nuevas de Polestar se traen **fusionando** sus etiquetas `vX.Y.Z`.
- Licencia: **GPL-3.0-only**, igual que Polestar (`LICENSE`, con sus permisos extra en `LICENSE-EXCEPTION.md`). Gratis, sin publicidad.
- Para errores o dudas de Mamba, abre un issue **aquí**, no en Polestar.

## Qué agrega Mamba (16-11-2026)
| Carpeta | Qué hace |
|---|---|
| `addon/Asistente` | Núcleo de los módulos de Mamba: ajustes comunes, estilo del juego, `/asis` |
| `addon/Asistente_Servicios` | "¿Qué hay en esta ciudad?": banco, subasta, buzón, posada, vuelo, establos, reparar, instructores y vendedores, con búsqueda en español. El viaje lo hace la flecha de Polestar (`Polestar.Nav.API`). `/servicios` |
| `addon/Asistente_Datos` | Qué material juntar en cada zona mientras haces misiones, para qué receta sirve, y qué misiones regalan bolsas |
| `addon/Tasador` | Qué hacer con cada objeto (vender, subastar, guardar) y un escaneo propio de la subasta, que solo lee precios |
| `addon/Medidor` | Experiencia, oro, botín y profesión por hora, por zona y actividad |
| `tools/asistente/` | Generadores de datos (Python, desde `forever-db`) y pruebas (Lua 5.1 con `lupa`). Guías: `*_LEEME.md` |

Todo lo de Polestar sigue **sin cambios** en este primer paso. No se editó ningún archivo suyo.

## Lo que todavía NO está listo (léelo antes de repartir un zip)
Este repositorio hereda el historial y los archivos de Polestar. Algunos de sus archivos generados usan datos cuyo permiso es **solo para Polestar**:
- las caminatas y los mapas a pie hechos con los mapas privados de Leffe (`Legs.lua`, `Polestar_Nav_*`, "`--leffe`");
- los nombres y hechos que vienen de QuestieDB y DingDB (`Polestar_<idioma>/Names.lua`, guías);
- quién da y recibe cada misión, de forever-vo (sin licencia declarada).

Mamba **no reparte un zip** hasta reconstruir esos datos con la herramienta de Polestar sin esas fuentes (`forge ... --no-questie --nav grid`) y pasar un control que rechace cualquier archivo generado con ellas. El plan completo está en `ARQUITECTURA.md` §13-§15 del proyecto. Mientras tanto, para jugar, instala **Polestar oficial** y agrega las carpetas `addon/Asistente*`, `addon/Tasador` y `addon/Medidor`.

## Créditos
- **Polestar**, de "The Polestar authors" (Fitz y colaboradores): todo lo que no está en la tabla de arriba. Ver `LICENSE`, `THIRD_PARTY.md`, los `LICENSE-DATA.txt` y los `CREDITS.md` de cada carpeta, que se conservan intactos.
- Shortest Path Forever, de Cillian Berragan (rutas a pie, dentro de Polestar).
- **forever-db** (de Polestar, GPL-3.0) para los datos de los módulos de Mamba. Sus fuentes están en `forever-db/NOTICE.md` y en `addon/Asistente_Servicios/NOTICE-forever-db.md`.
- World of Warcraft y Blizzard Entertainment son marcas de Blizzard Entertainment, Inc. Ni Mamba ni Polestar están hechos ni respaldados por Blizzard.
