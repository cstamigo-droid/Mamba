"""Deja en <grid>/walk una sola máscara de caminos: la que registró la etapa prepare vigente
(.forge/prepare.outputs). Las demás se mueven a <out>/viejos_roads y se quitan de .forge/grid.outputs,
para que forge no crea la grilla incompleta y la rehaga (eso crea otra máscara: un círculo, 17-11).
Uso: python -I apartar_roads.py D:/rust/forge-out"""
import pathlib, re, shutil, sys
out = pathlib.Path(sys.argv[1]); fz = out / ".forge"; walk = out / "grid" / "walk"
prep = fz / "prepare.outputs"
if not prep.exists() or not walk.is_dir():
	print("sin prepare.outputs o sin walk: nada que hacer"); sys.exit(0)
vigente = {m.group(1) for m in re.finditer(r"roads-\d+-([0-9a-f]+)\.bin", prep.read_text(encoding="utf-8"))}
if len(vigente) != 1:
	print(f"prepare.outputs con {len(vigente)} máscaras: no toco nada"); sys.exit(0)
(v,) = vigente
viejos = [f for f in walk.glob("roads-*.bin") if not f.name.endswith(f"-{v}.bin")]
dest = out / "viejos_roads"; dest.mkdir(exist_ok=True)
for f in viejos:
	shutil.move(str(f), str(dest / f.name))
g = fz / "grid.outputs"
if g.exists():
	nombres = {f.name for f in viejos}
	lineas = [l for l in g.read_text(encoding="utf-8").splitlines() if pathlib.PurePath(l.replace("\\", "/")).name not in nombres]
	g.write_text("\n".join(lineas), encoding="utf-8")
print(f"máscara vigente {v}; apartadas {len(viejos)}")
