# Licencias de terceros que no vienen escritas en su archivo

Algunos addons incluidos (ver `MAMBA.md`, "Addons incluidos") traen librerías cuyo archivo no lleva el texto de su licencia. Aquí va ese texto, para cumplir lo que piden. Este archivo **va en cada zip de Mamba**.

## CallbackHandler-1.0 (dentro de `addon/WhatsTraining/libs/`)

Es parte de Ace3. Su licencia es la misma de Ace3, que WhatsTraining trae escrita para LibDBIcon-1.0 (`addon/WhatsTraining/libs/LibDBIcon-1.0-LICENSE.txt`). Se repite aquí, porque pide conservar el aviso de copyright. Va dentro de WhatsTraining, como lo publica su autor; nunca suelto ("Redistribution of a stand alone version is strictly prohibited").

```
Copyright (c) 2007, Ace3 Development Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Redistribution of a stand alone version is strictly prohibited without
  prior written authorization from the Lead of the Ace3 Development Team.
* Neither the name of the Ace3 Development Team nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

## LibDataBroker-1.1 y LibStub (dentro de `addon/WhatsTraining/libs/`)

- LibStub: "LibStub is hereby placed in the Public Domain" (lo dice su propio archivo).
- LibDataBroker-1.1: su archivo no dice licencia. Se publica como dominio público (tekkub). **NO VERIFICADO** en la fuente.

## FusionIgnoreStore (dentro de `addon/WhatsTraining/libs/`)

Es del autor de WhatsTraining (fusionpit): sus commits están en https://github.com/fusionpit/WhatsTraining, que es MIT (verificado el 16-11 con la API de GitHub).

## ForeverTDB (solo para construir los datos; no va en ningún zip)

- Base de datos del servidor de Forever: https://github.com/advocaite/TrinityCore/tree/forever (fork de TrinityCore), **GPL-2.0**. Release `forever-tdb-2026-10-14`, asset `TDB_full_forever_2026_10_14.7z`, SHA-256 `373cdca7…4f41` (igual al `digest` del release), commit `f2b20d1863`.
- Autorizada por Cristian el 17-11-2026. Se usa **como hechos** (costos y niveles de entrenador, recompensas), igual que Polestar: forge la lee desde `data/local/forever-tdb/world.sqlite` (ignorado por git) y lo que llega al addon son valores derivados, que se acreditan en los `LICENSE-DATA.txt` / `NOTICE` de los datos.
- El SQLite se arma con `tools/asistente/tdb_a_sqlite.py`; el procedimiento está en la cabecera del script.

## forever-db (misiones propias de Forever en los datos; parche P7)

- Es el conjunto de datos público de Polestar, dentro del repositorio (`forever-db/`, versión `2026.11.1`): tablas de juego **GPL-3.0-only**; `mechanic` y `step`, **CC BY 4.0**. Su `NOTICE.md` (créditos: EG Link CC BY 4.0, CMaNGOS classic-db, VMaNGOS/Factoruide, ForeverTDB, pfQuest MIT, tablas del cliente y QuestieDB) va junto a los datos que se reparten.
- Sin QuestieDB, `forge data build` toma de forever-db las misiones que pfQuest no tiene y sus PNJ, objetos y objetos de inventario (`POLESTAR_FOREVER_DB_QUESTS=1`, `rust/crates/forge-data/src/mamba_foreverdb.rs`). Cada valor de forever-db está respaldado por al menos una fuente independiente (su `NOTICE.md`). Las filas llevan `source: "forever-db"`.
- Las ~126 misiones que ni forever-db tiene **salen de las guías** (`tools/asistente/guias_sin_fuente.py`, informe en `D:\rust\guias-mamba_SIN_FUENTE.md`): NO VERIFICADO, no se inventan títulos ni objetivos.
- Las líneas de guía que forge rechaza porque estos datos difieren de QuestieDB se corrigen con el arreglo que da el propio mensaje de forge (`tools/asistente/arreglar_guias.py`, informe en `D:\rust\guias-mamba_ARREGLOS.md`). Los nombres de hechizo que agrega salen de `SpellName.csv` y el bando de los PNJ nuevos de `FactionTemplate.csv`: tablas del cliente del juego bajadas de wago.tools (fuente ya autorizada, hechos del juego).
