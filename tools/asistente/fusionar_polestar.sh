#!/usr/bin/env bash
# Trae una versión nueva de Polestar a la rama `asistente` de Mamba (ARQUITECTURA §13b y §13f.3).
# Uso (Git Bash, desde cualquier carpeta):  bash tools/asistente/fusionar_polestar.sh v0.4.0.1
# No hace push. Se detiene en el primer problema y dice qué revisar.
set -u -o pipefail
TAG="${1:?uso: fusionar_polestar.sh vX.Y.Z[.W]}"
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$RAIZ"
export PYTHONIOENCODING=utf-8
alto() { echo "ALTO: $*"; exit 1; }

# En la rama asistente, o en una rama fusion/vX de la copia aparte que arma seguir_polestar.sh (prueba/ para la prueba en seco).
RAMA="$(git branch --show-current)"
[ "$RAMA" = asistente ] || [[ "$RAMA" == fusion/* || "$RAMA" == prueba/* ]] || alto "no estás en la rama asistente (ni en una fusion/* o prueba/*)"
[ -z "$(git status --porcelain)" ] || alto "hay cambios sin commitear; commitea o descártalos primero"
git fetch upstream --tags || alto "no pude traer las etiquetas de upstream (fitzforge/polestar)"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || alto "no existe la etiqueta $TAG"
ANTES="$(git describe --tags --abbrev=0 --match 'v*' HEAD)"
echo "== De $ANTES a $TAG"

echo "== 1. Licencias y permisos de datos que cambiaron (releer ARQUITECTURA §5b si sale algo)"
git diff --stat "$ANTES" "$TAG" -- LICENSE LICENSE-EXCEPTION.md THIRD_PARTY.md '*LICENSE-DATA.txt' '*CREDITS.md'

echo "== 2. Fusión"
if ! git merge --no-ff --no-edit -m "Fusionar Polestar $TAG en asistente" "$TAG"; then
	# Regla §13f.3: los generados se toman de Polestar y se regeneran; solo PARCHES.md se resuelve a mano.
	for f in $(grep -v '^#' GENERADOS.txt | sed 's/^\[[A-Z]*\] //'); do
		git diff --name-only --diff-filter=U | grep -qx "$f" && git checkout --theirs -- "$f" && git add "$f"
	done
	if git diff --name-only --diff-filter=U | grep -q .; then
		echo "Choques que hay que resolver a mano (deberían ser solo archivos de PARCHES.md):"
		git diff --name-only --diff-filter=U
		alto "resolver, git add, git commit, y volver a correr desde el paso 3 a mano"
	fi
	git commit --no-edit || alto "no pude cerrar la fusión"
fi

echo "== 3. Parches de Mamba (P1-P4)"
python -I tools/asistente/parches.py || alto "un parche ya no calza: Polestar cambió ese texto; ver PARCHES.md"
python -I tools/asistente/parches.py --revisar || alto "quedaron parches sin aplicar"

echo "== 4. Listas y controles"
python -I tools/asistente/generados.py
python -I tools/asistente/incluidos.py revisar || alto "un addon incluido cambió"
python -I tools/asistente/internas_entre.py "$ANTES" "$TAG" --vigia tools/asistente/generador/polestar_al_dia.py \
	|| echo "AVISO: cambió una función interna de Polestar que usa un módulo de Mamba (la línea CAMBIÓ de arriba dice cuál): revisar ese módulo y correr sus pruebas"

echo "== 5. Pruebas"
LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-reemplazos.test.js || alto "falló mamba-reemplazos"
# Regla de estética: los módulos de Mamba siguen dibujándose con las piezas de Polestar (ESTETICA_MAMBA.md).
LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-estetica.test.js || alto "falló mamba-estetica: Polestar cambió cómo dibuja; revisar addon/Asistente/Estilo.lua"
(cd tools/asistente/pruebas && python test_capa.py ../../../addon && python test_servicios.py ../../../addon ../../.. \
	&& python test_tasador.py ../../../addon/Tasador && python test_escaneo.py ../../../addon/Tasador \
	&& python test_medidor.py ../../../addon/Medidor) || alto "falló una prueba de los módulos de Mamba"

if ! git diff --quiet; then
	git add -A addon GENERADOS.txt tests rust/crates/forge-addontest
	git commit -m "Mamba: parches y listas sobre Polestar $TAG" || alto "no pude commitear"
fi
echo "LISTO: $TAG fusionado en $RAMA, sin push. La próxima construcción (construir_noche.sh) recompila forge y usa esta base."
