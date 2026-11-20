"""K127: habilitar_addons.ps1 deja enabled SOLO SkillUpForever, WhatsTraining y ForeverLootSparkles en el AddOns.txt
de cada personaje, con respaldo, sin tocar nada más (20-11-2026).
Uso: python test_habilitar_addons.py [--romper]   (--romper: le pasa otra lista de addons; las pruebas tienen que fallar)"""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
SCRIPT = Path(__file__).resolve().parents[1] / "grupo" / "habilitar_addons.ps1"
ROMPER = "--romper" in sys.argv
ok = fail = 0


def check(c, m):
    global ok, fail
    ok, fail = (ok + 1, fail) if c else (ok, fail + 1)
    if not c:
        print("FALLA:", m)


PJ1 = ("SkillUpForever: disabled\r\nWhatsTraining: disabled\r\nForeverLootSparkles: enabled\r\n"
       "Bagnon: disabled\r\nSkillUpForeverExtra: disabled\r\nPolestar: enabled\r\n")
PJ2 = "SkillUpForever: enabled\r\nWhatsTraining: enabled\r\n"
PJ3 = "ForeverLootSparkles: disabled\n"  # LF y sin las otras
CUENTA = "SkillUpForever: disabled\r\n"  # no es de personaje (otra profundidad): no se toca

with tempfile.TemporaryDirectory() as t:
    t = Path(t)
    wtf = t / "WTF"
    p1 = wtf / "Account" / "CUENTA1" / "Reino" / "Pj1" / "AddOns.txt"
    p2 = wtf / "Account" / "CUENTA1" / "Reino" / "Pj2" / "AddOns.txt"
    p3 = wtf / "Account" / "CUENTA2" / "Otro Reino" / "Pj Tres" / "AddOns.txt"
    pc = wtf / "Account" / "CUENTA1" / "AddOns.txt"
    for p, s in ((p1, PJ1), (p2, PJ2), (p3, PJ3), (pc, CUENTA)):
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(s.encode("ascii"))
    resp = t / "respaldo"
    lista = "'Nada'" if ROMPER else "$MambaAddonsHabilitar"
    cmd = (f". '{SCRIPT}'; $r = Enable-MambaAddons -WTF '{wtf}' -Respaldo '{resp}' -Addons {lista}; "
           "'LINEAS=' + $r.lineas; 'ARCHIVOS=' + $r.cambiados.Count; 'ERRORES=' + $r.errores.Count")
    out = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd],
                         capture_output=True, text=True).stdout
    check("LINEAS=3" in out and "ARCHIVOS=2" in out and "ERRORES=0" in out, f"3 líneas en 2 archivos, sin errores ({out.strip()})")
    n1 = p1.read_bytes().decode("ascii")
    check(n1 == PJ1.replace("SkillUpForever: disabled", "SkillUpForever: enabled")
          .replace("WhatsTraining: disabled", "WhatsTraining: enabled"),
          "Pj1: solo SkillUpForever y WhatsTraining pasan a enabled; lo demás, byte a byte igual (CRLF incluido)")
    check("Bagnon: disabled" in n1, "un addon ajeno apagado sigue apagado")
    check("SkillUpForeverExtra: disabled" in n1, "un nombre que solo empieza igual no se toca")
    check(p2.read_bytes().decode("ascii") == PJ2, "Pj2, ya habilitado, queda igual")
    check(p3.read_bytes().decode("ascii") == "ForeverLootSparkles: enabled\n", "Pj3 (LF, otro reino con espacios): habilitado, LF intacto")
    check(pc.read_bytes().decode("ascii") == CUENTA, "el AddOns.txt de la cuenta (no de personaje) no se toca")
    r1 = resp / "Account" / "CUENTA1" / "Reino" / "Pj1" / "AddOns.txt"
    check(r1.exists() and r1.read_bytes().decode("ascii") == PJ1, "respaldo del original de Pj1, con su ruta")
    check(not (resp / "Account" / "CUENTA1" / "Reino" / "Pj2").exists(), "lo que no cambia no se respalda")
    # Segunda vez: ya no hay nada que cambiar
    out2 = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd],
                          capture_output=True, text=True).stdout
    check("LINEAS=0" in out2, "correrlo dos veces no cambia nada más")

# Dentro de instalar.ps1 (dot-source): el archivo no puede pisar las variables del que lo carga (falló así el 20-11:
# un param() dejaba $WTF vacío y el instalador decía "No pude habilitar…")
out3 = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
                       f"$WTF = 'C:/X'; $Respaldo = 'R'; . '{SCRIPT}'; 'WTF=' + $WTF + '|R=' + $Respaldo"],
                      capture_output=True, text=True).stdout
check("WTF=C:/X|R=R" in out3, f"cargarlo con dot-source no pisa $WTF ni $Respaldo ({out3.strip()})")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
