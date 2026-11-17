#!/usr/bin/env bash
# Sigue a Polestar: cada versión nueva publicada se fusiona, se prueba y se deja lista, sin tocar la
# carpeta de trabajo C:\Users\<usuario>\Mamba (otras sesiones trabajan ahí). ARQUITECTURA §13b/§13f,
# HOJA_DE_RUTA_MAMBA §7, WOW_FOREVER/TAREA_SEGUIR_POLESTAR.md. Lo corre la tarea programada de Claude
# «mamba-seguir-polestar»; también se puede correr a mano (Git Bash):
#
#   bash seguir_polestar.sh                 vigía; si hay versión nueva: fusión + pruebas + lista de chequeo
#   bash seguir_polestar.sh --construir     reconstruye los datos CON CACHÉ en la copia de fusión (~1,5 h)
#   bash seguir_polestar.sh --seco vX.Y.Z   prueba en seco: fusiona vX.Y.Z en una rama prueba/, sin construir
#
# La fusión va en una copia aparte (git worktree) C:\Users\<usuario>\Mamba-fusion, rama fusion/vX.Y.Z, que sale de
# `asistente`. Nunca hace push ni pasa nada a `asistente`: eso lo decide Cristian (publicar = afuera).
# Última línea = estado, también en D:\rust\seguir\ESTADO.txt. Salida: 0 al día o listo · 1 falló · 3 ocupado.
set -u -o pipefail
REPO=/c/Users/<usuario>/Mamba
FUSION=/c/Users/<usuario>/Mamba-fusion
INFORMES=/c/Users/<usuario>/OneDrive/Escritorio/WOW_FOREVER/polestar_versiones
DIR=/d/rust/seguir
ESTADO="$DIR/ESTADO.txt"
CERROJO="$DIR/EN_CURSO"
mkdir -p "$DIR" "$INFORMES"
export PYTHONIOENCODING=utf-8
# Rama con la regla de estética y estas herramientas, mientras no esté dentro de asistente.
EXTRA_RAMA=mamba/estetica-y-polestar

fin() { echo "$(date '+%Y-%m-%d %H:%M') $1" > "$ESTADO"; echo "ESTADO: $1"; exit "${2:-0}"; }
forge_corriendo() { tasklist //FI "IMAGENAME eq forge.exe" 2>/dev/null | grep -qi "forge.exe"; }

# Argumentos ANTES del cerrojo (un error aquí no deja el cerrojo puesto).
MODO=fusion; TAG=""
case "${1:-}" in
	--construir) MODO=construir ;;
	--seco) MODO=seco; TAG="${2:-}"; [[ "$TAG" =~ ^v[0-9] ]] || { echo "uso: seguir_polestar.sh --seco vX.Y.Z"; exit 1; } ;;
	# --preparar vX.Y.Z: fusión + pruebas en fusion/vX.Y.Z aunque asistente ya la tenga (lo usa actualizar_mamba.py,
	# que compara con lo INSTALADO, no con asistente).
	--preparar) MODO=preparar; TAG="${2:-}"; [[ "$TAG" =~ ^v[0-9] ]] || { echo "uso: seguir_polestar.sh --preparar vX.Y.Z"; exit 1; } ;;
	"") ;;
	*) echo "uso: seguir_polestar.sh [--construir | --seco vX.Y.Z | --preparar vX.Y.Z]"; exit 1 ;;
esac

# Una sola corrida a la vez (un cerrojo de más de 6 h es de una corrida que murió). El nuestro se quita al
# salir por cualquier camino (fin, error, Ctrl+C); el de otra corrida no se toca.
if [ -f "$CERROJO" ] && [ -n "$(find "$CERROJO" -mmin -360 2>/dev/null)" ]; then
	echo "ESTADO: OCUPADO: otra corrida empezó $(cat "$CERROJO")"; exit 3
fi
date '+%Y-%m-%d %H:%M' > "$CERROJO"
trap 'rm -f "$CERROJO"' EXIT
HECHAS="$DIR/hechas" # una marca por etiqueta fusionada y probada con éxito (la rama sola no prueba nada)
mkdir -p "$HECHAS"

# Copia aparte con las uniones a los datos y cachés compartidos (no están en git).
preparar_copia() {
	local rama="$1"
	git -C "$REPO" fetch upstream --tags -q || return 1
	if [ -d "$FUSION/.git" ] || [ -f "$FUSION/.git" ]; then
		if [ -n "$(git -C "$FUSION" status --porcelain)" ]; then
			# La copia es desechable: lo que quedó de una corrida que se detuvo a medias (en una rama fusion/
			# o prueba/) se descarta. Otra rama ahí = alguien la usa a mano: no se toca.
			case "$(git -C "$FUSION" branch --show-current)" in
				fusion/*|prueba/*) git -C "$FUSION" reset -q --hard && git -C "$FUSION" clean -qfd || return 1 ;;
				*) echo "la copia $FUSION tiene cambios sin commitear en otra rama"; return 1 ;;
			esac
		fi
		git -C "$FUSION" checkout -q -B "$rama" asistente || return 1
	else
		git -C "$REPO" worktree add -q -B "$rama" "$FUSION" asistente || return 1
	fi
	# Herramientas y regla de estética, si todavía no están en asistente.
	if git -C "$REPO" rev-parse -q --verify "refs/heads/$EXTRA_RAMA" >/dev/null \
		&& ! git -C "$FUSION" merge-base --is-ancestor "$EXTRA_RAMA" HEAD; then
		git -C "$FUSION" merge -q --no-edit "$EXTRA_RAMA" || { echo "no pude sumar $EXTRA_RAMA"; return 1; }
	fi
	local w
	w="$(cygpath -w "$FUSION")"
	# data/local es carpeta PROPIA de la copia (forge escribe ahí): nunca una unión a la carpeta de trabajo.
	# Solo ForeverTDB (de lectura) se enlaza; kb y nav-layers se copian una vez, como caché.
	mkdir -p "$FUSION/data/local"
	for c in kb nav-layers; do
		[ -e "$FUSION/data/local/$c" ] || [ ! -d "$REPO/data/local/$c" ] || cp -r "$REPO/data/local/$c" "$FUSION/data/local/" || return 1
	done
	for par in "data\\forever|D:\\rust\\polestar-data\\forever" "data\\sources|D:\\rust\\polestar-data\\sources" \
		"data\\local\\forever-tdb|D:\\rust\\forever-tdb"; do
		local en="${par%%|*}" a="${par##*|}"
		# unión de Windows con PowerShell (mklink por cmd pierde las comillas que le pasa Git Bash)
		[ -e "$FUSION/${en//\\//}" ] || powershell -NoProfile -Command \
			"New-Item -ItemType Junction -Path '$w\\$en' -Target '$a' | Out-Null" || return 1
	done
}

fusionar() {
	local tag="$1" rama="$2" log="$DIR/fusion_$1.log"
	preparar_copia "$rama" > "$log" 2>&1 || fin "FALLÓ preparando la copia aparte para $tag. Ver $log" 1
	local antes
	antes="$(git -C "$FUSION" describe --tags --abbrev=0 --match 'v*' HEAD)"
	# fusionar_polestar.sh pide el árbol limpio: lo está (rama recién salida de asistente).
	if ! bash "$FUSION/tools/asistente/fusionar_polestar.sh" "$tag" >> "$log" 2>&1; then
		python -I "$FUSION/tools/asistente/informe_polestar.py" "$antes" "$tag" "$INFORMES/$tag.md" >> "$log" 2>&1
		fin "FALLÓ la fusión o una prueba de $tag: $(grep -a '^ALTO' "$log" | tail -1). Rama $rama en $FUSION. Lista: $INFORMES/$tag.md. Registro: $log" 1
	fi
	python -I "$FUSION/tools/asistente/informe_polestar.py" "$antes" "$tag" "$INFORMES/$tag.md" >> "$log" 2>&1 \
		|| fin "FALLÓ el informe de $tag. Ver $log" 1
	[[ "$rama" == fusion/* ]] || return 0 # la prueba en seco no deja marcas
	echo "$tag" > "$DIR/ULTIMA_FUSION"
	date '+%Y-%m-%d %H:%M' > "$HECHAS/$tag"
}

case "$MODO" in
preparar)
	fusionar "$TAG" "fusion/$TAG"
	fin "FUSIONADA Y PROBADA: $TAG en la rama fusion/$TAG ($FUSION). Lista: $INFORMES/$TAG.md" 0
	;;
seco)
	fusionar "$TAG" "prueba/$TAG"
	fin "PRUEBA EN SECO OK: $TAG fusionado y probado en la rama prueba/$TAG ($FUSION), sin construir. Lista: $INFORMES/$TAG.md" 0
	;;
fusion)
	# Una sola llamada, a la vigía que viaja con este script (la de asistente puede no conocer --fork).
	SALIDA="$(python -I "$(cd "$(dirname "$0")" && pwd)/generador/polestar_al_dia.py" --fork "$REPO" 2>&1)"
	r=$?
	SALIDA="$(echo "$SALIDA" | head -1)"
	echo "$SALIDA"
	case "$SALIDA" in
		"AL DÍA"*) fin "$SALIDA" 0 ;;
		FUSIONAR*) TAG="$(echo "$SALIDA" | awk '{print $2}')" ;;
		*) fin "NO SE PUDO REVISAR (salida $r): $SALIDA" 1 ;;
	esac
	# Preparada = marca de éxito + rama. Una rama sin marca es de una corrida que falló: se rehace.
	if [ -f "$HECHAS/$TAG" ] && git -C "$REPO" rev-parse -q --verify "refs/heads/fusion/$TAG" >/dev/null; then
		fin "YA PREPARADA: $TAG espera en la rama fusion/$TAG (falta construir o que Cristian la pase a asistente). Lista: $INFORMES/$TAG.md" 0
	fi
	fusionar "$TAG" "fusion/$TAG"
	fin "FUSIONADA Y PROBADA: $TAG en la rama fusion/$TAG ($FUSION). Falta: --construir. Lista: $INFORMES/$TAG.md" 0
	;;
construir)
	TAG="$(cat "$DIR/ULTIMA_FUSION" 2>/dev/null)"
	[ -n "$TAG" ] && [ "$(git -C "$FUSION" branch --show-current)" = "fusion/$TAG" ] || fin "NADA QUE CONSTRUIR: no hay una fusión preparada" 0
	forge_corriendo && { echo "ESTADO: OCUPADO: forge.exe corre (otra construcción)"; exit 3; }
	[ -f "$FUSION/tools/asistente/compilar_addon.sh" ] || fin "BLOQUEADA: falta tools/asistente/compilar_addon.sh en asistente (la sesión de construcción todavía no lo commiteó)" 1
	log="$DIR/construir_$TAG.log"
	# construir_noche.sh se niega con el juego abierto: entonces queda para la próxima corrida.
	bash "$FUSION/tools/asistente/construir_noche.sh" > "$log" 2>&1
	grep -q "^LISTO" /d/rust/noche/ESTADO.txt || fin "NO CONSTRUIDA: $(cat /d/rust/noche/ESTADO.txt). Ver $log" 1
	bash "$FUSION/tools/asistente/compilar_addon.sh" >> "$log" 2>&1 || fin "FALLÓ compilar_addon.sh. Ver $log" 1
	(cd "$FUSION" && LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-reemplazos.test.js tests/mamba-estetica.test.js) >> "$log" 2>&1 \
		|| fin "FALLARON las pruebas después de construir. Ver $log" 1
	(cd "$FUSION" && git add -A addon guides GENERADOS.txt && { git diff --cached --quiet || git commit -q -m "Mamba: datos reconstruidos sobre Polestar $TAG"; }) >> "$log" 2>&1 		|| fin "FALLÓ el commit de la construcción. Ver $log" 1
	fin "LISTA PARA INSTALAR: $TAG construido y probado en $FUSION (rama fusion/$TAG). Lista: $INFORMES/$TAG.md" 0
	;;
esac
