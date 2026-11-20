"""El ZIP del grupo nunca sale sin sellar (revisor t6, 19-11-2026): con build 0 el aviso "hay una versión
nueva" no funciona para nadie y no se nota. Prueba verificar_sello() y main() de armar_zip_grupo.py con un
armado mínimo falso (sin control_zip ni forge).
Uso: python test_sello_zip.py [--romper]   (--romper: verificar_sello acepta todo; las pruebas tienen que fallar)"""
import sys
import tempfile
import zipfile
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent / "grupo"))
import armar_zip_grupo as A  # noqa: E402
import sellar_version as S  # noqa: E402

if "--romper" in sys.argv:
    A.verificar_sello = lambda z: 202611190100
ok = fail = 0


def check(c, m):
    global ok, fail
    ok, fail = (ok + 1, fail) if c else (ok, fail + 1)
    if not c:
        print("FALLA:", m)


def zip_con(tmp: Path, sello: str | None) -> Path:
    z = tmp / f"z{len(list(tmp.iterdir()))}.zip"
    with zipfile.ZipFile(z, "w") as f:
        f.writestr("archivos/instalar.ps1", "x")
        if sello is not None:
            f.writestr("archivos/Mamba/Mamba_Version/Sello.lua", sello)
    return z


with tempfile.TemporaryDirectory() as t:
    tmp = Path(t)
    check(A.verificar_sello(zip_con(tmp, S.PLANTILLA.format(build=202611190100, texto="b", commit="c"))) == 202611190100,
          "lee el build de un ZIP sellado")
    check(A.verificar_sello(zip_con(tmp, S.PLANTILLA.format(build=0, texto="b", commit="c"))) == 0,
          "un ZIP con build 0 se reconoce como SIN SELLAR")
    check(A.verificar_sello(zip_con(tmp, None)) == 0, "un ZIP sin Mamba_Version se reconoce como sin sellar")
    check(A.verificar_sello(zip_con(tmp, "MambaSello = basura")) == 0, "un Sello.lua ilegible cuenta como sin sellar")

    # main() de punta a punta con un armado falso: control_zip se reemplaza (aquí no se prueba licencias).
    paq = tmp / "paq"
    (paq / "Polestar").mkdir(parents=True)
    (paq / "Polestar" / "Polestar.toc").write_text("## Interface: 16001\n", "utf-8")
    (paq / "Mamba_Version").mkdir()
    (paq / "Mamba_Version" / "Sello.lua").write_text(S.PLANTILLA.format(build=0, texto="x", commit="y"), "utf-8")
    man = tmp / "man.json"
    man.write_text("{}", "utf-8")

    class R:
        returncode, stdout, stderr = 0, "0 rechazos, 0 avisos", ""
    A.subprocess.run = lambda *a, **k: R()
    A.creditos = lambda paquete: "creditos"

    def armar(extra, salida):
        sys.argv = ["x", "--paquete", str(paq), "--manifiesto", str(man), "--version", "beta t", "--commit", "abc",
                    "--fecha", "2026-11-19", "--salida", str(tmp / salida)] + extra
        return A.main()

    # Revisor t7: el sello se lee con BOM y espacios de más, y el motivo dice qué falló
    (paq / "Mamba_Version" / "Sello.lua").write_text(
        "﻿MambaSello  =  {build=202611191400 ,  texto = \"b\",commit = \"c\" }", "utf-8")
    check((S.leer(paq) or {}).get("build") == 202611191400, "lee un Sello.lua con BOM y espacios de más")
    (paq / "Mamba_Version" / "Sello.lua").write_text("MambaSello = basura", "utf-8")
    check("no se entiende" in S.leer_con_motivo(paq)[1], "el motivo dice que el Sello.lua no se entiende")
    check("falta" in S.leer_con_motivo(tmp / "nada")[1], "el motivo dice que falta el Sello.lua")
    (paq / "Mamba_Version" / "Sello.lua").write_text(S.PLANTILLA.format(build=0, texto="x", commit="y"), "utf-8")

    check(armar(["--build", "202611191500"], "s1") == 0, "un armado sin sellar + --build sí se arma")
    zs = list((tmp / "s1").glob("Mamba_Horda_*.zip"))
    check(len(zs) == 1 and A.verificar_sello(zs[0]) == 202611191500, "y el ZIP lleva ese build, no 0")
    (paq / "Mamba_Version" / "Sello.lua").unlink()
    check(armar(["--build", "202611191500"], "s2") == 1, "sin Sello.lua NO se arma")
    check(not list((tmp / "s2").glob("*.zip")), "y no queda ningún ZIP")
    # Revisor t7: una corrida que falla no deja a la vista lo de una corrida anterior en la misma salida
    s1 = tmp / "s1"
    (paq / "Mamba_Version" / "Sello.lua").write_text(S.PLANTILLA.format(build=0, texto="x", commit="y"), "utf-8")
    A.verificar_sello = lambda z: 0  # simula un ZIP que sale sin sellar
    check(armar(["--build", "202611191500"], "s1") == 1, "un ZIP que sale sin sellar hace fallar el armado")
    check(not list(s1.glob("*.zip")) and not list(s1.glob("*.sha256")), "no quedan el ZIP ni el .sha256 viejos")
    check(not (s1 / "canal" / "Mamba_Horda.zip").exists() and not (s1 / "canal" / "mamba_grupo.json").exists(),
          "no quedan el canal/Mamba_Horda.zip ni el mamba_grupo.json viejos")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
