"""Arma la rama que se publica en GitHub (refs/heads/publica) desde `asistente`, sin tocar `asistente` (20-11-2026).

Decisión de Cristian: "Sí, ocultarlo".
  1. En los commits de Mamba (los que no son de Polestar), el correo personal del autor y del committer pasa al
     correo noreply de GitHub. El nombre no cambia.
  2. En esos mismos commits se quitan los workflows de Polestar (.github/workflows/*): necesitan secretos de
     Discord y de releases que este repo no tiene, y las tareas programadas correrían en la rama por defecto.
     Cristian no autorizó cambiar los ajustes de Actions: va como cambio de código, solo en la rama publicada.
  Los commits de Polestar (los que están en upstream o en sus etiquetas) no se exportan: quedan con su hash de
  siempre. La reescritura es determinista: correrla otra vez da los mismos hashes, así cada push avanza sin forzar.

Uso:
    python -I tools/asistente/grupo/rama_publica.py            arma o actualiza refs/heads/publica y la verifica
    python -I tools/asistente/grupo/rama_publica.py --revisar  solo verifica la rama publica que ya existe
    ... [--origen <commit>] [--destino <rama>]
Sale con 1 si algo no se cumple (correo personal en autor, committer o mensaje; contenido distinto de asistente
fuera de .github/workflows; la rama ya publicada en GitHub no es ancestro). Push: SOLO con el sí de Cristian.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]
ORIGEN, DESTINO = "asistente", "publica"
# El correo personal NO va escrito en este archivo (el archivo también se publica): se lee de la configuración
# GLOBAL de git (la del repo ya es el noreply) o de MAMBA_CORREO_PERSONAL.
PERSONAL = b""
NOREPLY = b"cstamigo-droid@users.noreply.github.com"
PUBLICADO = "f924685f7"  # punta de origin/asistente en GitHub (16-11): la rama nueva tiene que contenerla
EXCLUIR = ["--remotes=upstream", "--tags"]  # lo de Polestar no se reescribe
CABECERA = re.compile(rb"^(author|committer) (.*) <([^>]*)> (\d+ [+-]\d{4})$")
# Revisor (20-11): datos personales DENTRO de los archivos (número de cuenta de WoW, usuario de Windows). La lista
# vive en <.git>/mamba_ocultar.txt (nunca se publica), una línea por dato: "texto => reemplazo". El correo
# personal se agrega solo (-> noreply).
OCULTAR: list[tuple[bytes, bytes]] = []
# Plantillas de Polestar que en el fork confunden (Discord, botón de donar a fitzforge, @fitzforge como revisor):
# se quitan en la rama publicada junto con los workflows.
QUITAR_RUTAS = (".github/workflows", ".github/ISSUE_TEMPLATE", ".github/FUNDING.yml", ".github/CODEOWNERS")


def git(*a: str, entrada: bytes | None = None) -> bytes:
    r = subprocess.run(["git", "-C", str(RAIZ), *a], input=entrada, capture_output=True)
    if r.returncode != 0:
        raise SystemExit(f"git {' '.join(a)} falló: {r.stderr.decode('utf-8', 'replace')}")
    return r.stdout


def correo_personal() -> bytes:
    import os
    c = os.environ.get("MAMBA_CORREO_PERSONAL", "").encode()
    if not c:
        r = subprocess.run(["git", "config", "--global", "user.email"], capture_output=True)
        c = r.stdout.strip()
    if not c or c == NOREPLY or b"@" not in c:
        raise SystemExit("no sé cuál es el correo personal a ocultar (git config --global user.email o "
                         "MAMBA_CORREO_PERSONAL)")
    return c


def leer_ocultar() -> list[tuple[bytes, bytes]]:
    lista = [(PERSONAL, NOREPLY)]
    comun = Path(git("rev-parse", "--git-common-dir").decode().strip())
    f = (comun if comun.is_absolute() else RAIZ / comun) / "mamba_ocultar.txt"
    if f.exists():
        for l in f.read_text("utf-8").splitlines():
            if "=>" in l and not l.lstrip().startswith("#"):
                a, b = (x.strip() for x in l.split("=>", 1))
                if a:
                    lista.append((a.encode("utf-8"), b.encode("utf-8")))
    return lista


def ocultar(datos: bytes) -> bytes:
    for a, b in OCULTAR:
        datos = datos.replace(a, b)
    return datos


def workflows() -> list[bytes]:
    """Rutas que se borran en cada commit reescrito: los workflows y las plantillas de Polestar (QUITAR_RUTAS)."""
    salida = git("ls-tree", "-r", "--name-only", ORIGEN, "--", *QUITAR_RUTAS)
    return [l for l in salida.splitlines() if l]


def reescribir(flujo: bytes, borrar: list[bytes]) -> tuple[bytes, int]:
    """Recorre el flujo de fast-export: cambia el ref, los correos y agrega los D al final de cada commit tocado."""
    out, i, n, cambiados = [], 0, len(flujo), 0
    commit: list[bytes] | None = None
    tocado = False

    def cerrar():
        nonlocal commit, tocado, cambiados
        if commit is None:
            return
        if tocado:
            cambiados += 1
            # Los D van antes de las líneas en blanco que cierran el commit (si no, fast-import los lee como
            # un comando nuevo).
            cola = []
            while commit and commit[-1] == b"\n":
                cola.append(commit.pop())
            commit.extend(b"D " + p + b"\n" for p in borrar)
            commit.extend(cola)
        out.extend(commit)
        commit, tocado = None, False

    while i < n:
        fin = flujo.find(b"\n", i)
        if fin == -1:
            fin = n
        linea = flujo[i:fin]
        sig = fin + 1
        if linea.startswith(b"data "):
            largo = int(linea[5:])
            carga = flujo[sig:sig + largo]
            sig = sig + largo
            nueva = ocultar(carga)  # también dentro de los archivos y los mensajes (revisor, 20-11)
            if nueva != carga:
                carga = nueva
                if commit is not None:
                    tocado = True
            bloque = b"data %d\n" % len(carga) + carga
            (commit if commit is not None else out).append(bloque)
            i = sig
            continue
        if linea.startswith((b"commit ", b"reset ", b"blob", b"tag ", b"progress ", b"done", b"feature ")):
            cerrar()
            if linea.startswith(b"commit "):
                commit = []
                linea = b"commit refs/heads/" + DESTINO.encode()
            elif linea.startswith(b"reset "):
                linea = b"reset refs/heads/" + DESTINO.encode()
        m = CABECERA.match(linea)
        if m and commit is not None and m.group(3) == PERSONAL:
            linea = m.group(1) + b" " + m.group(2) + b" <" + NOREPLY + b"> " + m.group(4)
            tocado = True
        (commit if commit is not None else out).append(linea + (b"\n" if fin < n else b""))
        i = sig
    cerrar()
    return b"".join(out), cambiados


def armar() -> None:
    borrar = workflows()
    flujo = git("fast-export", "--reference-excluded-parents", "--signed-tags=strip", "--reencode=no",
                ORIGEN, "--not", *EXCLUIR)
    nuevo, cambiados = reescribir(flujo, borrar)
    git("fast-import", "--quiet", "--force", entrada=nuevo)
    print(f"publica: {git('rev-parse', '--short', DESTINO).decode().strip()} · {cambiados} commits reescritos · "
          f"{len(borrar)} archivos de .github quitados · {len(OCULTAR)} datos ocultos")


def revisar() -> int:
    fallas = []
    rango = [DESTINO, "--not", *EXCLUIR]
    historia = git("log", "-p", "--format=", *rango)
    for k, (a, _) in enumerate(OCULTAR):
        que = "el correo personal" if k == 0 else f"el dato oculto n.º {k}"
        if a in historia:
            fallas.append(f"queda {que} DENTRO de algún archivo del historial reescrito")
        if subprocess.run(["git", "-C", str(RAIZ), "grep", "-q", "-F", a.decode("utf-8"), DESTINO]).returncode == 0:
            fallas.append(f"queda {que} dentro de un archivo de la punta")
    for fmt, que in (("%ae", "autor"), ("%ce", "committer"), ("%B", "mensaje")):
        if PERSONAL in git("log", f"--format={fmt}", *rango):
            fallas.append(f"queda el correo personal en {que}")
    if PERSONAL in git("log", "--format=%ae%n%ce%n%B", DESTINO):
        fallas.append("queda el correo personal en algún commit de la rama (también los de Polestar)")
    dif = git("diff", "--name-only", ORIGEN, DESTINO).decode().split()
    # Fuera de lo quitado, solo puede diferir un archivo cuyo único cambio sean los datos ocultos.
    quitado = tuple(r if r.endswith(".yml") or r.endswith("CODEOWNERS") else r + "/" for r in QUITAR_RUTAS)
    otros = [d for d in dif if not (d.startswith(quitado) or d in QUITAR_RUTAS)
             and ocultar(git("show", f"{ORIGEN}:{d}")) != git("show", f"{DESTINO}:{d}")]
    if otros:
        fallas.append(f"publica difiere de asistente en algo más que lo quitado y lo oculto: {otros[:5]}")
    if git("ls-tree", "-r", "--name-only", DESTINO, "--", *QUITAR_RUTAS).strip():
        fallas.append("publica todavía tiene workflows o plantillas de Polestar")
    if subprocess.run(["git", "-C", str(RAIZ), "merge-base", "--is-ancestor", PUBLICADO, DESTINO]).returncode != 0:
        fallas.append(f"{PUBLICADO} (lo ya publicado) no es ancestro: el push necesitaría forzar")
    n_or = git("rev-list", "--count", ORIGEN).strip()
    n_de = git("rev-list", "--count", DESTINO).strip()
    if n_or != n_de:
        fallas.append(f"cantidad de commits distinta: asistente {n_or}, publica {n_de}")
    for f in fallas:
        print("FALLA:", f)
    print(f"revisión de {DESTINO}: {'OK' if not fallas else str(len(fallas)) + ' fallas'} ({n_de} commits)")
    return 1 if fallas else 0


if __name__ == "__main__":
    # --origen <commit>: reescribe hasta ese commit (el instalado en el juego) en vez de la punta de asistente.
    # --destino <rama>: otra rama local (por defecto "publica"). Mismo commit de origen = mismos hashes.
    if "--origen" in sys.argv:
        ORIGEN = sys.argv[sys.argv.index("--origen") + 1]
    if "--destino" in sys.argv:
        DESTINO = sys.argv[sys.argv.index("--destino") + 1]
    PERSONAL = correo_personal()
    OCULTAR = leer_ocultar()
    if "--revisar" not in sys.argv:
        armar()
    sys.exit(revisar())
