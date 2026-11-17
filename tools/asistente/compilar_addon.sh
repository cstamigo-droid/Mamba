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
# 2. Datos que salen de data/forever.
paso "base de misiones" "$F" data questdb
paso "misiones nuevas" "$F" data newquests --offline
paso "niveles de zona" "$F" data maps build
paso "codex" "$F" data codex
# 3. Mapas a pie de nuestra grilla (formato 3, sin --leffe) y los nombres de subzona.
paso "mapas a pie" "$F" nav pack --dir "$OUT\\grid" --layers "$RAIZ/data/local/nav-layers"
paso "subzonas" "$F" data subzones
# 4. Nombres por idioma sin QuestieDB ni DingDB, y las guías compiladas.
paso "nombres" "$F" data names --no-questie
paso "compilar guías" "$F" guide compile
echo "[$(date '+%H:%M:%S')] LISTO" | tee -a "$LOG"
