#!/usr/bin/env bash
# Pasa la construcción de forge (D:\rust\forge-out, hecha con construir_noche.sh) al addon: guías,
# piernas, base de misiones, Codex, nombres, mapas a pie SIN Leffe y los datos que salen de
# data/forever. Sin QuestieDB, DingDB, forever-vo ni Leffe (ARQUITECTURA §13c/§13f).
# Uso (Git Bash), desde cualquier carpeta:  bash tools/asistente/compilar_addon.sh
# Se detiene en el primer fallo. Registro: D:\rust\noche\compilar.log
set -u -o pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
LOG=/d/rust/noche/compilar.log
OUT='D:\rust\forge-out'
F=/d/rust/target/release/forge.exe
source /d/rust/entorno.sh
cd "$RAIZ"
export POLESTAR_FOREVER_DB_QUESTS=1
: > "$LOG"
paso() {
	local nombre="$1"; shift
	echo "[$(date '+%H:%M:%S')] === $nombre: $*" | tee -a "$LOG"
	"$@" >> "$LOG" 2>&1
	local r=$?
	if [ $r -ne 0 ]; then echo "FALLÓ en «$nombre» (salida $r). Ver $LOG" | tee -a "$LOG"; exit 1; fi
}
# 1. Las guías de cada salida, al diseño publicado (guides/ y guides/legs.json, con las piernas de
#    nuestra grilla).
paso "publicar guías" "$F" guide publish --from "$OUT\\guides" --data data/forever
# professions.json/travel.json los escribe forge build: se ponen solo mientras dura este script (18-11).
puestos=()
for n in professions.json travel.json; do
	[ -f "data/forever/$n" ] || { cp "/d/rust/forge-out/data/forever/$n" "data/forever/$n"; puestos+=("data/forever/$n"); }
done
trap 'rm -f "${puestos[@]}"' EXIT
# 2. Datos que salen de data/forever.
paso "base de misiones" "$F" data questdb
paso "misiones nuevas" "$F" data newquests --offline
paso "niveles de zona" "$F" data maps build
paso "codex" "$F" data codex
# 2b. Lo que el addon traía hecho con los datos de Polestar (con QuestieDB) se rehace con los de Mamba
#     (revisión de los 7 agentes, 18-11). QoL/Data.lua NO: declara pfQuest y rehacerlo perdía 80 sanadores.
paso "topes de entrenador (ForeverTDB)" python -I "$RAIZ/tools/asistente/topes_entrenadores.py"
paso "entrenadores de clase" "$F" data trainers
paso "viajes" "$F" data travel --grid "$OUT\grid"
paso "recompensas de clase" node tools/polestar.js classrewards build
paso "puntos de recolección" node tools/polestar.js profession gathering spots
paso "nombres esMX del cliente y ForeverTDB" python -I "$RAIZ/tools/asistente/nombres_wdb.py" esMX
# 3. Mapas a pie de nuestra grilla (formato 3, sin --leffe) y los nombres de subzona.
# Nombres de área en inglés (el addon los compara con GetSubZoneText en inglés) y los puntos de paso
# (cuevas, pasos, edificios, portones: aids.json, que nav pack trata como opcional). 18-11.
paso "áreas de la grilla en inglés" python -I "$RAIZ/tools/asistente/areas_en_ingles.py" "$OUT\\grid"
paso "puntos de paso de la grilla" node tools/polestar.js nav aids --dir "$OUT\\grid"
paso "mapas a pie" "$F" nav pack --dir "$OUT\\grid" --layers "$RAIZ/data/local/nav-layers"
# Subzonas: NO se rehacen. forge exige la misma build del cliente que los datos (70532, tablas de
# wago) y su tabla fija está en 70888 (18-11 03:02). Quedan las que trae Polestar, sin cambios.
# 4. Nombres por idioma sin QuestieDB ni DingDB, y las guías compiladas.
paso "nombres" "$F" data names --no-questie
# guides/ trae las guías de Polestar sin los filtros de Mamba: se compila una copia con las de la ruta
# y el resto en su versión filtrada (la que aprobó forge build), con piernas horneadas en NUESTRA grilla.
C='D:\rust\guias-compilar'
paso "guías para compilar" python -I "$RAIZ/tools/asistente/guias_para_compilar.py" 'D:\rust\guias-mamba' "$C"
for vuelta in 1 2 3 4 5; do
	paso "hornear piernas ($vuelta)" "$F" guide bake --guides "$C" --grid "$OUT\\grid" --threads 8
	if "$F" guide compile --guides "$C" --force > /d/rust/noche/compilar_guias.txt 2>&1; then
		echo "[$(date '+%H:%M:%S')] --- compilar guías OK" | tee -a "$LOG"; break
	fi
	[ $vuelta = 5 ] && { echo "FALLÓ en «compilar guías». Ver /d/rust/noche/compilar_guias.txt" | tee -a "$LOG"; exit 1; }
	paso "arreglos de compilar ($vuelta)" python -I "$RAIZ/tools/asistente/guias_para_compilar.py" --arreglar "$C" 'D:\rust\noche\compilar_guias.txt'
done
# 5. forge reescribe los .toc de las carpetas que genera y borra la marca X-Mamba (aviso de fork
#    modificado, GPL-3.0 §5a): los parches de Mamba se vuelven a aplicar al final (18-11).
paso "parches de Mamba" python -I "$RAIZ/tools/asistente/parches.py"
paso "avisos de fuentes autorizadas" python -I "$RAIZ/tools/asistente/avisos_mamba.py"
echo "[$(date '+%H:%M:%S')] LISTO" | tee -a "$LOG"
