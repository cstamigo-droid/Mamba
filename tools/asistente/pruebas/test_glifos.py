"""Glifos que la letra del juego NO trae (se ven como un cuadro vacío): visto en el juego el 18-11 con las
estrellas del panel de la guía y la flecha de Ir a…. Polestar ya lo anotaba en UI/ClassCard.lua ("›", no "→").
Revisa los textos (entre comillas, fuera de comentarios) de los módulos de Mamba. Uso: python test_glifos.py [addon]
Control negativo: python test_glifos.py --romper (mete una ★ y debe fallar).
"""
import re
import sys
import pathlib

sys.stdout.reconfigure(encoding="utf-8")
AQUI = pathlib.Path(__file__).parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ADDON = pathlib.Path(args[0]) if args else AQUI.parent.parent.parent / "addon"
ROMPER = "--romper" in sys.argv

PROHIBIDOS = "→←↑↓⇒★☆✓✔✗✘►▶◀▲▼•♥♦"
# Módulos de terceros que se instalan tal cual (no son de Mamba ni de Polestar).
TERCEROS = {"SkillUpForever", "WhatsTraining", "ForeverCore", "ForeverLootSparkles"}
CADENA = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'')

ok = fallas = 0
for p in sorted(ADDON.rglob("*.lua")):
    rel = p.relative_to(ADDON)
    if rel.parts[0].startswith("Polestar") or rel.parts[0] in TERCEROS or "libs" in rel.parts:
        continue
    texto = p.read_text(encoding="utf-8", errors="replace")
    if ROMPER and rel.as_posix() == "Mamba_Panel/Lineas.lua":
        texto += '\nlocal x = "★"\n'
    for i, linea in enumerate(texto.splitlines(), 1):
        codigo = linea.split("--", 1)[0]
        for m in CADENA.finditer(codigo):
            malos = sorted({c for c in m.group() if c in PROHIBIDOS})
            if malos:
                fallas += 1
                print("FALLA: %s:%d usa %s, que el juego dibuja como un cuadro: %s" % (rel, i, " ".join(malos), m.group()[:60]))
    ok += 1
print("%d OK, %d fallas" % (ok, fallas))
sys.exit(1 if fallas else 0)
