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
# Sin QuestieDB faltan las misiones propias de Forever: forge las toma de forever-db (GPL-3.0, de
# Polestar) con sus PNJ, objetos y objetos de inventario (PARCHES.md P7). Vale para el paso de datos y
# para la etapa de datos de forge build.
export POLESTAR_FOREVER_DB_QUESTS=1

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
# MAMBA_JUEGO_ABIERTO_OK=1: correr igual con el juego abierto. forge solo LEE el cliente (nunca escribe), y
# con la grilla ya hecha casi no lo toca; el riesgo es que el lanzador lo actualice a mitad (se repite).
if [ -z "${MAMBA_JUEGO_ABIERTO_OK:-}" ] && tasklist //FI "IMAGENAME eq Wow.exe" 2>/dev/null | grep -qi "wow.exe"; then
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
# ForeverTDB (autorizada por Cristian el 17-11, GPL-2.0, solo como hechos, nunca va en un zip): el paso
# de profesiones de forge build exige sus listas de entrenador. La arma tools/asistente/tdb_a_sqlite.py.
if [ ! -f "$RAIZ/data/local/forever-tdb/world.sqlite" ]; then
	fin "FALLÓ antes de empezar: falta data/local/forever-tdb/world.sqlite (armarlo con tools/asistente/tdb_a_sqlite.py, ver su cabecera)." 1
fi

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
	# Con --kb (la base de conocimiento que pide la etapa routes, data/local/kb/forever-kb.sqlite):
	# --offline para NO bajar eglink ni forever-vo (no autorizados); sin el respaldo esMX, para que no
	# entren nombres en español desde el cliente (forge avisa y sigue sin ItemSparse/GameObjects; 17-11:
	# con el respaldo entraban 857 nombres en español). P6 deja seguir las correcciones públicas que
	# apuntan a pasos que sin QuestieDB no existen.
	# Los objetos de inventario, PNJ y objetos del mundo que nombran las guías: P7 agrega desde
	# forever-db los que faltan en los datos (17-11).
	paso "lo que nombran las guías" python -I "$RAIZ/tools/asistente/guias_sin_fuente.py" --necesita "$RAIZ/data/local/forever-db-need.txt"
	paso "datos" env -u POLESTAR_TEXT_LOCALE_FALLBACK POLESTAR_KB_SKIP_MISSING_STEPS=1 \
		"$F" data build --no-questie --forever-tables wago --kb --offline
	# Capas del suelo para las caminatas (preferir caminos, evitar pueblos enemigos), propias: los caminos
	# salen de las texturas del cliente instalado y los hubs de la grilla y los datos. Sin la capa de
	# caminos la etapa walks falla ("expected one road mask tag", 17-11). Si ya están, no se rehacen (para rehacerlas, borrar la carpeta).
	if [ ! -d "$RAIZ/data/local/nav-layers/roads" ]; then
		paso "capa caminos" "$F" nav layers roads --wow "$WOW" --root "$RAIZ"
	fi
	if [ ! -f "$RAIZ/data/local/nav-layers/hubs.json" ]; then
		# La capa de hubs pide FactionTemplate y AreaTable de la build EXACTA de la grilla (la del cliente),
		# que `data sources` no baja porque wago.tools no la lista; wago sí la sirve (17-11: 70938).
		gb=$(python -I -c "import json,sys;print(json.load(open(sys.argv[1]))['build'])" 'D:\rust\forge-out\grid\index.json')
		for t in FactionTemplate AreaTable; do
			c="$RAIZ/data/sources/wago/$gb/$t.csv"
			[ -s "$c" ] || paso "wago $t $gb" curl -sf --create-dirs -o "$c" "https://wago.tools/db2/$t/csv?build=$gb"
		done
		paso "capa hubs" "$F" nav layers hubs --dir 'D:\rust\forge-out\grid' --root "$RAIZ"
	fi
	# forge busca las capas en dos lugares: prepare usa <grilla>/../nav-layers y, si no existe,
	# data/local/nav-layers; legs (walker.rs hubs_file) solo <grilla>/../nav-layers. Sin esa carpeta,
	# legs carga sin hubs, la clave del grafo cambia y falla "no walk graph … for continent 1" (17-11, 23:30).
	# Copia idéntica junto a la salida: las dos etapas leen lo mismo.
	paso "capas junto a la salida" bash -c 'rm -rf /d/rust/forge-out/nav-layers && cp -r "$1/data/local/nav-layers" /d/rust/forge-out/nav-layers' _ "$RAIZ"
	# Una sola máscara de caminos en grid/walk (walks exige una; si no, "expected one road mask tag", 17-11):
	# se apartan las que no registró la prepare vigente y se quitan de la caché de la grilla (si no, forge
	# rehace la grilla, prepare crea otra máscara y vuelve a fallar).
	paso "máscaras de caminos" python -I "$RAIZ/tools/asistente/apartar_roads.py" D:/rust/forge-out
	# Sin QuestieDB no hay ninguna misión de Zephras Isle: Skyborne no tiene inicio ("no Alliance start for
	# race Skyborne", 17-11). Se construyen las 8 razas clásicas; Skyborne queda para la 1.1 (forever-db).
	STARTS="${MAMBA_STARTS:-Orc,Troll,Tauren,Undead,Human,Dwarf,Gnome,NightElf}"
	# Las ~126 misiones que ni forever-db tiene salen de las guías (NO VERIFICADO, informe en
	# D:\rust\guias-mamba_SIN_FUENTE.md); forge lee esa copia en vez de guides/ (17-11).
	GUIAS='D:\rust\guias-mamba'
	paso "guías sin fuente" python -I "$RAIZ/tools/asistente/guias_sin_fuente.py" "$RAIZ/data/forever/quests.json" "$GUIAS"
	# Lo que forge rechaza porque los datos sin QuestieDB difieren (índice de objetivo, élites, `direct`,
	# hechizos sin nombre…), con el arreglo que el propio mensaje de forge da; informe en
	# D:/rust/guias-mamba_ARREGLOS.md (17-11).
	paso "arreglos de guías" python -I "$RAIZ/tools/asistente/arreglar_guias.py" "$GUIAS"
	# Si forge rehace la grilla o prepare en esta misma corrida (forge nuevo, cliente actualizado), queda una
	# máscara de caminos nueva junto a la vieja y walks falla con "expected one road mask tag" (17-11, dos
	# veces). Entonces se aparta la vieja y forge build se repite una vez: grilla y prepare ya quedan en caché.
	if ! "$F" build --wow "$WOW" --no-questie --nav grid --accept-fewer-quests \
		--forever-tables wago --allow-build-mismatch --out "$OUT" --threads 8 \
		--starts "$STARTS" --guides "$GUIAS" >> "$LOG" 2>&1; then
		if tail -5 "$LOG" | grep -q "expected one road mask tag"; then
			log "walks: dos máscaras de caminos; se aparta la vieja y se repite forge build"
			paso "máscaras de caminos (2)" python -I "$RAIZ/tools/asistente/apartar_roads.py" D:/rust/forge-out
		else
			fin "FALLÓ en «forge build». Nada más corrió. Ver $LOG" 1
		fi
	else
		touch "$NOCHE/.build_ok"
	fi
	[ -f "$NOCHE/.build_ok" ] && rm -f "$NOCHE/.build_ok" || \
	paso "forge build" "$F" build --wow "$WOW" --no-questie --nav grid --accept-fewer-quests \
		--forever-tables wago --allow-build-mismatch --out "$OUT" --threads 8 \
		--starts "$STARTS" --guides "$GUIAS"
else
	# 3b. Sin enlaces: lo que no los necesita (datos y grilla). Las guías quedan para la mañana.
	paso "datos" "$F" data build --no-questie
	paso "grilla" "$F" nav grid --out 'D:\rust\forge-out\grid' --wow "$WOW" --threads 8
	fin "PARCIAL: datos (--no-questie) y grilla listos en D:. forge build no corrió porque Windows no deja crear enlaces simbólicos (activar Modo de desarrollador: Configuración › Sistema › Para desarrolladores). Ver $LOG" 0
fi

# 4. Nombres en cada idioma sin QuestieDB ni DingDB (escribe addon/Polestar_<idioma>; se revisa con git diff).
# (Los nombres van en compilar_addon.sh: `data names` necesita la base de misiones de `data questdb`,
# que se arma ahí; aquí fallaba "the quest database is not built", 18-11 02:59.)

fin "LISTO: datos, grilla, rutas y guías (en $OUT) sin QuestieDB, DingDB, forever-vo ni Leffe. Falta (mañana, con Claude): compilar las guías al addon, nav pack sin --leffe, manifiesto y control_zip --estricto. Ver $LOG" 0
