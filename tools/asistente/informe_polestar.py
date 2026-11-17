"""Lista de chequeo de una versión nueva de Polestar para Mamba (HOJA_DE_RUTA_MAMBA §7, ESTETICA_MAMBA.md).

    python -I tools/asistente/informe_polestar.py v0.4.0.1 v0.4.1 SALIDA.md

Junta los HECHOS que se miden solos, leyendo git (no descarga nada):
  1. qué trae: las notas de la versión (CHANGELOG.md) de cada versión entre ANTES y NUEVA;
  2. si choca con Mamba: archivos de PARCHES.md que la versión tocó, funciones internas que usan nuestros
     módulos (internas_entre.py) y si la versión tocó nuestras carpetas (no debería);
  3. estética: si cambió cómo dibuja Polestar (Theme, Widgets, apariencias, ajustes) y si trae apariencias nuevas.
Deja vacías, marcadas «POR COMPLETAR», las partes que hay que JUZGAR (en español, para Cristian): resumen de
funciones nuevas, qué módulo nuestro debería aprovecharlas y el veredicto. Las completa la tarea de Claude
que sigue a Polestar (WOW_FOREVER/TAREA_SEGUIR_POLESTAR.md). Sale 0 siempre que pudo escribir el informe.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
NUESTRAS = ["addon/Asistente", "addon/Asistente_Datos", "addon/Asistente_Servicios", "addon/Asistente_Equipo",
            "addon/Asistente_Clase", "addon/Tasador", "addon/Medidor"]
MODULOS = ["Asistente (núcleo, capa, comandos)", "Servicios (buscador de la ciudad y flecha)", "Tasador (vender, subastar o guardar)",
           "Medidor (oro, botín y profesión por hora)", "Equipo (asesor de equipo y mazmorra)", "Clase (talentos, profesiones, builds)"]
ESTETICA = ["addon/Polestar/Theme", "addon/Polestar_Looks", "addon/Polestar_SkinAPI", "addon/Polestar_Options",
            "docs/DESIGN.md", "docs/SKINS-API.md"]


def git(*args: str) -> str:
    r = subprocess.run(["git", *args], cwd=RAIZ, capture_output=True)
    return r.stdout.decode("utf-8", errors="replace")


def notas(antes: str, nueva: str) -> str:
    """Las secciones '## X.Y.Z' del CHANGELOG de la versión nueva que no están en el de la anterior."""
    viejo = set(re.findall(r"^## (\S+)", git("show", f"{antes}:CHANGELOG.md"), re.M))
    texto = git("show", f"{nueva}:CHANGELOG.md")
    partes = re.split(r"(?m)^(?=## \S)", texto)
    nuevas = [p for p in partes if (m := re.match(r"## (\S+)", p)) and m.group(1) not in viejo]
    return "\n".join(p.strip() for p in nuevas) or "(el CHANGELOG no trae una sección nueva)"


def stat(antes: str, nueva: str, rutas: list[str]) -> str:
    return git("diff", "--stat=120", antes, nueva, "--", *rutas).strip()


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__)
        return 2
    antes, nueva, salida = argv
    parches = sorted(set(re.findall(r"addon/[A-Za-z_/]+\.(?:lua|toc|xml)", (RAIZ / "PARCHES.md").read_text(encoding="utf-8"))))
    tocados = set(git("diff", "--name-only", antes, nueva).split())
    choque_parches = [p for p in parches if p in tocados]
    nuestras_tocadas = sorted(f for f in tocados if any(f.startswith(n + "/") for n in NUESTRAS))
    vigia = RAIZ / "tools/asistente/generador/polestar_al_dia.py"
    r = subprocess.run([sys.executable, "-I", str(RAIZ / "tools/asistente/internas_entre.py"), antes, nueva, "--vigia", str(vigia)],
                       cwd=RAIZ, capture_output=True)
    internas = (r.stdout + r.stderr).decode("utf-8", errors="replace").strip()
    skins_antes = set(re.findall(r"addon/(Polestar_Skin_\w+)/", git("ls-tree", "-r", "--name-only", antes, "addon")))
    skins_nueva = set(re.findall(r"addon/(Polestar_Skin_\w+)/", git("ls-tree", "-r", "--name-only", nueva, "addon")))
    api = stat(antes, nueva, ["docs/API.md"])
    est = stat(antes, nueva, ESTETICA)
    total = git("diff", "--shortstat", antes, nueva).strip()

    L = [f"# Polestar {nueva} en Mamba: lista de chequeo", "",
         f"De {antes} a {nueva}. Cambio total: {total}.",
         "Generado por `tools/asistente/informe_polestar.py` (hechos medidos en git). Las partes «POR COMPLETAR» las",
         "completa la tarea que sigue a Polestar, en español simple, antes de dar la versión por lista.", "",
         "## 1. Qué funciones nuevas trae", "",
         "### En español, para Cristian (POR COMPLETAR)",
         "Una línea por novedad que se nota al jugar, agrupadas: guía y rutas · ventanas y ajustes · equipo · profesiones · otras.", "",
         "### Notas originales de Polestar (inglés, CHANGELOG.md)", "", "```text", notas(antes, nueva), "```", "",
         "## 2. ¿Choca con Mamba?", "",
         f"- Archivos con parche de Mamba (PARCHES.md) que esta versión tocó: {', '.join(choque_parches) or 'ninguno'}"
         + (" → `parches.py` tiene que volver a calzar; si no, se resuelve a mano." if choque_parches else "."),
         f"- Funciones internas de Polestar que usan nuestros módulos: `{internas.splitlines()[-1] if internas else 'sin salida'}`",
         f"- Nuestras carpetas tocadas por Polestar (debería ser ninguna): {', '.join(nuestras_tocadas) or 'ninguna'}.",
         f"- API pública (docs/API.md): {api.splitlines()[-1] if api else 'sin cambios'}.",
         "- Resultado de la fusión y de las pruebas: ver el registro de `seguir_polestar.sh` (POR COMPLETAR: OK o qué falló).", "",
         "## 3. ¿Qué módulo de Mamba debería aprovechar algo nuevo? (POR COMPLETAR)", "",
         "| Módulo | ¿Le sirve algo de esta versión? | Qué hacer (y en qué versión de Mamba) |", "|---|---|---|"]
    L += [f"| {m} | | |" for m in MODULOS]
    L += ["", "Ejemplo de lo que se busca: la «Lista de objetivos» de 0.4.0 marca enemigos en pantalla; el Tasador o el",
          "planificador podrían marcar ahí lo que hay que farmear en vez de dibujar su propia marca.", "",
          "## 4. Estética (ESTETICA_MAMBA.md)", "",
          f"- Apariencias nuevas: {', '.join(sorted(skins_nueva - skins_antes)) or 'ninguna'}; quitadas: {', '.join(sorted(skins_antes - skins_nueva)) or 'ninguna'}.",
          "- Cambios en cómo dibuja Polestar (Theme, Widgets, apariencias, ajustes):", "", "```text", est or "sin cambios", "```", "",
          "- `tests/mamba-estetica.test.js` (prueba cada apariencia contra una ventana de Polestar): POR COMPLETAR (OK o qué falló).",
          "- Criterio E1–E6 de HOJA_DE_RUTA_MAMBA §7: POR COMPLETAR.", "",
          "## 5. Veredicto (POR COMPLETAR)", "",
          "LISTA PARA INSTALAR · o · BLOQUEADA porque … (y qué falta, con dueño).", ""]
    Path(salida).parent.mkdir(parents=True, exist_ok=True)
    Path(salida).write_text("\n".join(L), encoding="utf-8")
    print("Informe:", salida)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
