"""K136 (auditoría 20-11, D8): manifiesto de lo instalado. Responde «¿qué tiene el juego?» sin adivinar.

La coordinadora lo corre DESPUÉS de instalar (instalar_mamba.ps1 + copiar_bartender):
    python -I tools/asistente/manifiesto_instalado.py escribir <paquete> <commit>
        hashea (sha256) cada archivo de las carpetas del paquete TAL COMO QUEDARON en AddOns, guarda el commit y
        anota qué carpetas del paquete NO quedaron iguales (las que el instalador no toca por ser más nuevas, como
        ForeverCore, y los generados en el juego, como Mamba_Barras/DeBartender.lua).
    python -I tools/asistente/manifiesto_instalado.py comparar
        vuelve a hashear AddOns y dice qué cambió desde que se instaló (archivo cambiado, agregado o que falta).
        Sale con 1 si algo cambió: alguien copió a mano o el juego no tiene lo que dice el manifiesto.
    python -I tools/asistente/manifiesto_instalado.py --probar
        control positivo y negativo sobre carpetas temporales.
Opciones: --addons <carpeta AddOns> (por defecto, la de WoW Forever) y --manifiesto <json>
(por defecto D:\\rust\\mamba_instalado.json).
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import sys
import tempfile
from pathlib import Path

ADDONS = Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns")
MANIFIESTO = Path(r"D:\rust\mamba_instalado.json")


def _sha(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def _hashes(raiz: Path) -> dict[str, str]:
    if not raiz.is_dir():
        return {}
    return {q.relative_to(raiz).as_posix(): _sha(q) for q in sorted(raiz.rglob("*")) if q.is_file()}


def escribir(paquete: Path, commit: str, addons: Path, salida: Path) -> dict:
    carpetas = sorted(d.name for d in paquete.iterdir() if d.is_dir())
    archivos, distintas = {}, {}
    for c in carpetas:
        inst = _hashes(addons / c)
        paq = _hashes(paquete / c)
        archivos[c] = inst
        dif = sorted(k for k in set(inst) | set(paq) if inst.get(k) != paq.get(k))
        if dif:
            distintas[c] = dif[:20] + ([f"... y {len(dif) - 20} más"] if len(dif) > 20 else [])
    m = {"commit": commit, "paquete": str(paquete), "addons": str(addons),
         "fecha": dt.datetime.now().isoformat(timespec="seconds"),
         "carpetas": carpetas, "distintas_del_paquete": distintas, "archivos": archivos}
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(json.dumps(m, ensure_ascii=False, indent=1), encoding="utf-8")
    return m


def comparar(addons: Path, manifiesto: Path) -> list[str]:
    m = json.loads(manifiesto.read_text(encoding="utf-8"))
    cambios = []
    for c in m["carpetas"]:
        antes, ahora = m["archivos"].get(c, {}), _hashes(addons / c)
        for k in sorted(set(antes) | set(ahora)):
            if k not in ahora:
                cambios.append(f"falta     {c}/{k}")
            elif k not in antes:
                cambios.append(f"agregado  {c}/{k}")
            elif antes[k] != ahora[k]:
                cambios.append(f"cambiado  {c}/{k}")
    return cambios


def probar() -> int:
    ok = fallas = 0

    def check(cond, que):
        nonlocal ok, fallas
        if cond:
            ok += 1
        else:
            fallas += 1
            print("FALLA", que)

    with tempfile.TemporaryDirectory() as t:
        t = Path(t)
        paq, add, man = t / "paq", t / "AddOns", t / "m.json"
        for raiz in (paq, add):
            (raiz / "Mamba_X").mkdir(parents=True)
            (raiz / "Mamba_X" / "a.lua").write_text("print(1)\n", encoding="utf-8")
        (add / "Otro").mkdir()  # lo que no es del paquete no cuenta
        (add / "Otro" / "z.lua").write_text("z", encoding="utf-8")
        m = escribir(paq, "abc123", add, man)
        check(m["commit"] == "abc123" and m["carpetas"] == ["Mamba_X"], "escribe commit y carpetas")
        check(m["distintas_del_paquete"] == {}, "instalado = paquete: sin distintas")
        check(comparar(add, man) == [], "positivo: nada cambió")
        (add / "Mamba_X" / "a.lua").write_text("print(2)\n", encoding="utf-8")  # negativo: copia a mano
        check(comparar(add, man) == ["cambiado  Mamba_X/a.lua"], "negativo: archivo cambiado")
        (add / "Mamba_X" / "b.lua").write_text("x", encoding="utf-8")
        check("agregado  Mamba_X/b.lua" in comparar(add, man), "negativo: archivo agregado")
        (add / "Mamba_X" / "a.lua").unlink()
        check("falta     Mamba_X/a.lua" in comparar(add, man), "negativo: archivo que falta")
        m2 = escribir(paq, "abc123", add, man)
        check("Mamba_X" in m2["distintas_del_paquete"], "anota la carpeta distinta del paquete")
    print(f"{ok} OK, {fallas} fallas")
    return 1 if fallas else 0


def main(argv: list[str]) -> int:
    if "--probar" in argv:
        return probar()
    addons, man = ADDONS, MANIFIESTO
    args = []
    i = 0
    while i < len(argv):
        if argv[i] == "--addons":
            addons = Path(argv[i + 1]); i += 2
        elif argv[i] == "--manifiesto":
            man = Path(argv[i + 1]); i += 2
        else:
            args.append(argv[i]); i += 1
    if args[:1] == ["escribir"] and len(args) == 3:
        m = escribir(Path(args[1]), args[2], addons, man)
        n = sum(len(v) for v in m["archivos"].values())
        print(f"manifiesto: {man} · commit {m['commit']} · {len(m['carpetas'])} carpetas · {n} archivos")
        for c, d in m["distintas_del_paquete"].items():
            print(f"  distinta del paquete: {c}: {', '.join(d[:5])}")
        return 0
    if args[:1] == ["comparar"]:
        cambios = comparar(addons, man)
        m = json.loads(man.read_text(encoding="utf-8"))
        if not cambios:
            print(f"OK: AddOns = manifiesto (commit {m['commit']}, instalado {m['fecha']})")
            return 0
        print(f"DISTINTO del manifiesto (commit {m['commit']}): {len(cambios)} cambios")
        for c in cambios[:40]:
            print("  " + c)
        return 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
