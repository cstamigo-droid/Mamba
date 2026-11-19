#!/usr/bin/env bash
# GATE de la tanda conjunta (pedido de Cristian, 18-11: "corrobora que no tengamos errores y valida bien antes
# de nada"). Corre TODAS las suites, la sintaxis de cada .lua del paquete, parches.py y control_zip. Sale con 1
# si algo falla. Uso, desde el repositorio Mamba: bash tools/asistente/gate_tanda.sh
cd "$(dirname "$0")/../.."
P=tools/asistente/pruebas
POL=/c/Users/<usuario>/OneDrive/Escritorio/WOW_FOREVER/generador/_descargas/polestar
fallas=0
corre() { # nombre, comando...
	local n=$1; shift
	local out; out=$(timeout 600 "$@" 2>&1); local rc=$?
	local ult; ult=$(printf "%s\n" "$out" | tail -1)
	if [ $rc -eq 0 ] && ! printf "%s" "$ult" | grep -qiE "[1-9][0-9]* fallas|FALLAS [1-9]|fail [1-9]"; then echo "OK    $n: $ult"
	else echo "FALLA $n (salida $rc): $ult"; printf "%s\n" "$out" | grep -iE "falla|error" | head -5 | sed 's/^/      /'; fallas=$((fallas+1)); fi
}
echo "== 1. árbol limpio"
if [ -n "$(git status --porcelain -- addon tools PARCHES.md)" ]; then echo "FALLA cambios sin commit:"; git status --porcelain -- addon tools PARCHES.md | sed 's/^/      /'; fallas=$((fallas+1)); else echo "OK    git status limpio"; fi
echo "== 2. suites"
corre hub        python -I $P/test_hub.py addon
corre ventana    python -I $P/test_ventana.py addon
corre equipo     python -I $P/test_equipo.py addon
corre tasador    python -I $P/test_tasador.py addon/Tasador
corre escaneo    python -I $P/test_escaneo.py addon/Tasador
corre comercio   python -I $P/test_comercio.py addon/Tasador
corre medidor    python -I $P/test_medidor.py addon/Medidor
corre capa       python -I $P/test_capa.py addon
corre servicios  python -I $P/test_servicios.py addon $POL
corre llevame    python -I $P/test_llevame.py addon
corre barras     python -I $P/test_barras.py
corre bolsas     python -I $P/test_bolsas.py
corre plan       python -I $P/test_plan.py
corre comodidades python -I $P/test_comodidades.py
corre curacion   python -I $P/test_curacion.py
corre mapa       python -I $P/test_mapa.py
corre profesiones python -I $P/test_profesiones.py
[ -f $P/test_combate.py ] && corre combate python -I $P/test_combate.py
[ -f $P/test_combate_pvp.py ] && corre combate_pvp python -I $P/test_combate_pvp.py
[ -f $P/test_raros.py ] && corre raros python -I $P/test_raros.py
# todas las pruebas Node de Mamba (panel, estética, misiones, reemplazos y las que se sumen)
for t in tests/mamba-*.test.js; do
	n=$(basename "$t" .test.js)
	corre "${n#mamba-}" env LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test "$t"
done
# las de Polestar que tocan los parches de Mamba (P13 Calabozos)
for t in tests/dungeons*.test.js; do [ -f "$t" ] && corre "polestar-$(basename "$t" .test.js)" env LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test "$t"; done
corre glifos     python -I $P/test_glifos.py addon
# K111 (19-11): valores secretos de Forever usados en un if, and/or/not, comparación o cuenta (el simulado no los atrapa)
corre secretos_detector python -I tools/asistente/secretos_lua.py --probar
corre secretos   python -I tools/asistente/secretos_lua.py addon
echo "== 3. sintaxis de cada .lua (Lua 5.1)"
corre sintaxis   python -I tools/asistente/sintaxis_lua.py addon
echo "== 5. parches.py"
corre parches    python -I tools/asistente/parches.py --revisar
echo "== 6. control_zip --estricto"
corre armar      python -I tools/asistente/armar_instalar.py
corre control_zip python -I tools/asistente/control_zip.py 'D:\rust\mamba_instalar' --manifiesto 'D:\rust\noche\manifiesto_mamba.json' --estricto
echo "== RESULTADO: $fallas fallas"
[ $fallas -eq 0 ]
