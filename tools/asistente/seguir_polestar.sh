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

fin() { echo "$(date '+%Y-%m-%d %H:%M') $1" > "$ESTADO"; echo "ESTADO: $1"; rm -f "$CERROJO"; exit "${2:-0}"; }
forge_corriendo() { tasklist //FI "IMAGENAME eq forge.exe" 2>/dev/null | grep -qi "forge.exe"; }

# Una sola corrida a la vez (un cerrojo de más de 6 h es de una corrida que murió).
if [ -f "$CERROJO" ] && [ -n "$(find "$CERROJO" -mmin -360 2>/dev/null)" ]; then
	echo "ESTADO: OCUPADO: otra corrida empezó $(cat "$CERROJO")"; exit 3
fi
date '+%Y-%m-%d %H:%M' > "$CERROJO"

MODO=fusion; TAG=""
case "${1:-}" in
	--construir) MODO=construir ;;
	--seco) MODO=seco; TAG="${2:?uso: --seco vX.Y.Z}" ;;
	"") ;;
	*) fin "uso: seguir_polestar.sh [--construir | --seco vX.Y.Z]" 1 ;;
esac

# Copia aparte con las uniones a los datos y cachés compartidos (no están en git).
preparar_copia() {
	local rama="$1"
	git -C "$REPO" fetch upstream --tags -q || return 1
	if [ -d "$FUSION/.git" ] || [ -f "$FUSION/.git" ]; then
		[ -z "$(git -C "$FUSION" status --porcelain)" ] || { echo "la copia $FUSION tiene cambios sin commitear"; return 1; }
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
	for par in "data\\forever|D:\\rust\\polestar-data\\forever" "data\\sources|D:\\rust\\polestar-data\\sources" \
		"data\\local|$(cygpath -w "$REPO")\\data\\local"; do
		local en="${par%%|*}" a="${par##*|}"
		[ -e "$FUSION/${en//\\//}" ] || cmd //c "mklink /J \"$w\\$en\" \"$a\"" >/dev/null || return 1
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
	echo "$tag" > "$DIR/ULTIMA_FUSION"
}

case "$MODO" in
seco)
	fusionar "$TAG" "prueba/$TAG"
	fin "PRUEBA EN SECO OK: $TAG fusionado y probado en la rama prueba/$TAG ($FUSION), sin construir. Lista: $INFORMES/$TAG.md" 0
	;;
fusion)
	SALIDA="$(python -I "$REPO/tools/asistente/generador/polestar_al_dia.py" --fork "$REPO" 2>&1 \
		|| python -I "$(dirname "$0")/generador/polestar_al_dia.py" --fork "$REPO" 2>&1)"
	r=$?
	echo "$SALIDA"
	case "$SALIDA" in
		"AL DÍA"*) fin "$SALIDA" 0 ;;
		FUSIONAR*) TAG="$(echo "$SALIDA" | awk '{print $2}')" ;;
		*) fin "NO SE PUDO REVISAR (salida $r): $SALIDA" 1 ;;
	esac
	if git -C "$REPO" rev-parse -q --verify "refs/heads/fusion/$TAG" >/dev/null; then
		fin "YA PREPARADA: $TAG espera en la rama fusion/$TAG (falta construir o que Cristian la pase a asistente). Lista: $INFORMES/$TAG.md" 0
	fi
	fusionar "$TAG" "fusion/$TAG"
	fin "FUSIONADA Y PROBADA: $TAG en la rama fusion/$TAG ($FUSION). Falta: --construir. Lista: $INFORMES/$TAG.md" 0
	;;
construir)
	TAG="$(cat "$DIR/ULTIMA_FUSION" 2>/dev/null)"
	[ -n "$TAG" ] && [ "$(git -C "$FUSION" branch --show-current)" = "fusion/$TAG" ] || fin "NADA QUE CONSTRUIR: no hay una fusión preparada" 0
	forge_corriendo && { rm -f "$CERROJO"; echo "ESTADO: OCUPADO: forge.exe corre (otra construcción)"; exit 3; }
	[ -f "$FUSION/tools/asistente/compilar_addon.sh" ] || fin "BLOQUEADA: falta tools/asistente/compilar_addon.sh en asistente (la sesión de construcción todavía no lo commiteó)" 1
	log="$DIR/construir_$TAG.log"
	# construir_noche.sh se niega con el juego abierto: entonces queda para la próxima corrida.
	bash "$FUSION/tools/asistente/construir_noche.sh" > "$log" 2>&1
	grep -q "^LISTO" /d/rust/noche/ESTADO.txt || fin "NO CONSTRUIDA: $(cat /d/rust/noche/ESTADO.txt). Ver $log" 1
	bash "$FUSION/tools/asistente/compilar_addon.sh" >> "$log" 2>&1 || fin "FALLÓ compilar_addon.sh. Ver $log" 1
	(cd "$FUSION" && LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-reemplazos.test.js tests/mamba-estetica.test.js) >> "$log" 2>&1 \
		|| fin "FALLARON las pruebas después de construir. Ver $log" 1
	(cd "$FUSION" && git add -A addon guides GENERADOS.txt && git commit -q -m "Mamba: datos reconstruidos sobre Polestar $TAG") >> "$log" 2>&1
	fin "LISTA PARA INSTALAR: $TAG construido y probado en $FUSION (rama fusion/$TAG). Lista: $INFORMES/$TAG.md" 0
	;;
esac
