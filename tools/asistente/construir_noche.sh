#!/usr/bin/env bash
# Construcción nocturna de los datos de Mamba SIN QuestieDB, DingDB, forever-vo ni los mapas de Leffe
# (ARQUITECTURA §13c/§13f). Corre sola de punta a punta y se detiene en el primer fallo.
# No toca el juego: solo LEE sus archivos. Uso (Git Bash), con el juego CERRADO:
#     bash tools/asistente/construir_noche.sh
# Registro: D:\rust\noche\registro.log · Estado final: D:\rust\noche\ESTADO.txt
# Requisitos ya preparados: D:\rust\entorno.sh (Rust gnullvm + llvm-mingw), forge.exe compilado,
# data/sources y data/forever enlazados a D:\rust\polestar-data (uniones de Windows).
set -u -o pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
NOCHE=/d/rust/noche
LOG="$NOCHE/registro.log"
ESTADO="$NOCHE/ESTADO.txt"
OUT='D:\rust\forge-out'
WOW='C:\Program Files (x86)\World of Warcraft'
F=/d/rust/target/release/forge.exe
mkdir -p "$NOCHE"
source /d/rust/entorno.sh
cd "$RAIZ"
# El cliente de Cristian tiene los textos en español (esMX), no en inglés: las tablas que forge pide en
# enUS al cliente (Map, para la geometría de la grilla) se leen de la copia esMX (PARCHES.md P5).
# Las tablas con nombres para los datos se leen de wago.tools en inglés (--forever-tables wago).
export POLESTAR_TEXT_LOCALE_FALLBACK=esMX

ahora() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ahora)] $*" | tee -a "$LOG"; }
fin() { echo "$1" > "$ESTADO"; log "ESTADO: $1"; exit "${2:-0}"; }
paso() {
	local nombre="$1"; shift
	log "=== $nombre: $*"
	"$@" >> "$LOG" 2>&1
	local r=$?
	if [ $r -ne 0 ]; then fin "FALLÓ en «$nombre» (salida $r). Nada más corrió. Ver $LOG" 1; fi
	log "--- $nombre OK"
}

: > "$LOG"
log "Mamba: construcción nocturna. Repo $RAIZ, commit $(git rev-parse --short HEAD)"

# 0. Controles previos: juego cerrado y espacio en D:
if tasklist //FI "IMAGENAME eq Wow.exe" 2>/dev/null | grep -qi "wow.exe"; then
	fin "NO CORRIÓ: el juego (Wow.exe) está abierto. Ciérralo y vuelve a correr el script." 1
fi
libre=$(df -BG /d | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "${libre:-0}" -lt 40 ]; then fin "NO CORRIÓ: D: tiene ${libre} GB libres (hacen falta 40)." 1; fi
log "D: libre ${libre} GB; juego cerrado"

# 0b. forge del commit actual: tras fusionar una versión nueva de Polestar su código Rust cambia.
#     Si ya está al día, cargo no recompila nada (segundos).
paso "compilar forge" cargo build --release --locked -p forge --manifest-path "$RAIZ/rust/Cargo.toml"
log "forge: $("$F" version 2>&1 | head -1)"

# 1. Fuentes autorizadas por Cristian (16-11): tablas del juego (wago.tools), pfQuest (MIT),
#    CMaNGOS classic-db (GPL-3.0) y WoWDBDefs. NO: eglink, forever-vo, webxp, QuestieDB.
paso "fuentes" "$F" data sources --only wago,builders,pfquest,cmangos,wowdbdefs

# 2. ¿Se pueden crear enlaces simbólicos? forge build los usa (Modo de desarrollador o administrador).
prueba="D:\\rust\\tmp\\prueba_enlace_$$"
if cmd //c "mklink $prueba D:\\rust\\entorno.sh" >/dev/null 2>&1; then
	rm -f "/d/rust/tmp/prueba_enlace_$$"; ENLACES=1
else
	ENLACES=0
fi
log "enlaces simbólicos: $([ $ENLACES = 1 ] && echo sí || echo NO)"

if [ $ENLACES = 1 ]; then
	# 3a. La construcción completa: datos, grilla, caminatas, rutas, guías y su informe.
	#     La grilla lee data/forever/map-frames.json: en un checkout nuevo hay que hacer antes los datos.
	paso "datos" "$F" data build --no-questie --forever-tables wago
	paso "forge build" "$F" build --wow "$WOW" --no-questie --nav grid --accept-fewer-quests \
		--forever-tables wago --allow-build-mismatch --out "$OUT" --threads 8
else
	# 3b. Sin enlaces: lo que no los necesita (datos y grilla). Las guías quedan para la mañana.
	paso "datos" "$F" data build --no-questie
	paso "grilla" "$F" nav grid --out 'D:\rust\forge-out\grid' --wow "$WOW" --threads 8
	fin "PARCIAL: datos (--no-questie) y grilla listos en D:. forge build no corrió porque Windows no deja crear enlaces simbólicos (activar Modo de desarrollador: Configuración › Sistema › Para desarrolladores). Ver $LOG" 0
fi

# 4. Nombres en cada idioma sin QuestieDB ni DingDB (escribe addon/Polestar_<idioma>; se revisa con git diff).
paso "nombres" "$F" data names --no-questie

fin "LISTO: datos, grilla, rutas, guías (en $OUT) y nombres sin QuestieDB, DingDB, forever-vo ni Leffe. Falta (mañana, con Claude): compilar las guías al addon, nav pack sin --leffe, manifiesto y control_zip --estricto. Ver $LOG" 0
