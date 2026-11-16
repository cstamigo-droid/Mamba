"""Parches de Mamba sobre archivos de Polestar (ARQUITECTURA §13b.2 y §13f.4).

Cada parche es "buscar este texto exacto -> reemplazarlo". El script es
idempotente: si el parche ya está, no hace nada; si el texto original ya no
existe (una versión nueva de Polestar lo cambió), FALLA y lo dice, para
revisarlo a mano. Respeta los saltos de línea de cada archivo (CRLF o LF).
Después de cada fusión con Polestar:

    python -I tools/asistente/parches.py            # aplica
    python -I tools/asistente/parches.py --revisar  # solo dice qué falta (sale 1 si falta algo)

La lista legible, con el porqué de cada uno, está en PARCHES.md.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
ADDON = RAIZ / "addon"
FECHA = "2026-11-16"
REPO = "https://github.com/cstamigo-droid/Mamba"
CR = chr(13)
LF = chr(10)

# (id, archivo relativo a addon/, texto original, texto nuevo)
PARCHES = [
    ("P1-errores", "Polestar/Core/Init.lua",
     'ns.DiscordURL = "https://discord.gg/polestar"',
     f'ns.DiscordURL = "{REPO}/issues" -- Mamba (PARCHES.md P1): los avisos del fork no van al Discord de Polestar'),
    ("P1-errores", "Polestar/Core/Init.lua",
     'ns.IssueURL = "https://github.com/fitzforge/polestar/issues/new"',
     f'ns.IssueURL = "{REPO}/issues/new" -- Mamba (PARCHES.md P1)' + LF +
     'ns.mamba = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "X-Mamba")) or nil'),
    ("P2-version", "Polestar/Core/Update.lua",
     'local function mine()' + LF + '\tlocal v = tostring(ns.version or "")',
     'local function mine()' + LF +
     '\tif ns.mamba then return nil end -- Mamba (PARCHES.md P2): el fork no se compara con Polestar oficial' + LF +
     '\tlocal v = tostring(ns.version or "")'),
    ("P2-version", "Polestar/Core/Update.lua",
     'local base = "https://github.com/fitzforge/polestar/releases"',
     f'local base = "{REPO}/releases" -- Mamba (PARCHES.md P2)'),
    ("P3-tomtom", "Polestar/Nav/Journey.lua",
     "answerTomTom = false, -- the stand-in has methods only: an addon reading TomTom.db would error",
     "answerTomTom = true, -- Mamba (PARCHES.md P3): reemplaza a TomTom (/way y su API de puntos). "
     "The stand-in has methods only: an addon reading TomTom.db would error"),
]

# Las pruebas de Polestar que fijan esos mismos valores (rutas relativas a la raíz del repositorio).
PARCHES_PRUEBAS = [
    ("P1-errores", "tests/ui-report.test.js",
     "const INVITE = 'https://discord.gg/polestar';",
     f"const INVITE = '{REPO}/issues'; // Mamba (PARCHES.md P1)"),
    ("P1-errores", "tests/ui-report.test.js",
     "assert.equal(url.origin + url.pathname, 'https://github.com/fitzforge/polestar/issues/new');",
     f"assert.equal(url.origin + url.pathname, '{REPO}/issues/new'); // Mamba (PARCHES.md P1)"),
    ("P1-errores", "rust/crates/forge-addontest/tests/addontest/ui-welcome.rs",
     'json!({ "link": "discord.gg/polestar",',
     'json!({ "link": "github.com/cstamigo-droid/Mamba/issues", /* Mamba (PARCHES.md P1) */'),
    ("P2-version", "rust/crates/forge-addontest/tests/addontest/ui-update.rs",
     '"link": "https://github.com/fitzforge/polestar/releases/tag/v0.3.7"',
     f'"link": "{REPO}/releases/tag/v0.3.7" /* Mamba (PARCHES.md P2) */'),
    ("P3-tomtom", "rust/crates/forge-addontest/tests/addontest/nav-journey.rs",
     'assert_eq!(out[0], json!({ "tomtom": true, "answering": false, "way": true, "default": false }));',
     '// Mamba (PARCHES.md P3): on by default, so the stand-in and /way answer.' + LF +
     '\tassert_eq!(out[0], json!({ "tomtom": false, "answering": true, "way": false, "default": true }));'),
]

TITULO = re.compile(r"^(## Title(?:-\w+)?: )([^\r\n]*?)(?: · Mamba)?(\r?)$", re.M)
MARCA = re.compile(r"^## X-Mamba:[^\r\n]*", re.M)


def _toc(texto: str) -> str:
    """P4: título "… · Mamba" y la marca X-Mamba (aviso de modificación, GPL-3.0 §5a)."""
    texto = TITULO.sub(lambda m: f"{m.group(1)}{m.group(2)} · Mamba{m.group(3)}", texto)
    marca = f"## X-Mamba: fork de Polestar, modificado {FECHA} ({REPO}). No es el Polestar oficial."
    if MARCA.search(texto):
        return MARCA.sub(marca, texto)
    lineas = texto.splitlines(keepends=True)
    ultimo = max(i for i, l in enumerate(lineas) if l.startswith("## "))
    fin = CR + LF if lineas[ultimo].endswith(CR + LF) else LF
    lineas.insert(ultimo + 1, marca + fin)
    return "".join(lineas)


def _con_fin(texto_archivo: str, s: str) -> str:
    """El texto del parche con los saltos de línea del archivo."""
    return s.replace(LF, CR + LF) if CR + LF in texto_archivo else s


def aplicar(solo_revisar: bool) -> int:
    faltan, cambiados = [], []
    todos = [(pid, ADDON / rel, viejo, nuevo) for pid, rel, viejo, nuevo in PARCHES]
    todos += [(pid, RAIZ / rel, viejo, nuevo) for pid, rel, viejo, nuevo in PARCHES_PRUEBAS]
    for pid, p, viejo, nuevo in todos:
        rel = p.relative_to(RAIZ).as_posix()
        t = p.read_bytes().decode("utf-8")
        viejo, nuevo = _con_fin(t, viejo), _con_fin(t, nuevo)
        if nuevo in t:
            continue
        if t.count(viejo) != 1:
            faltan.append(f"{pid} {rel}: el texto original aparece {t.count(viejo)} veces; revisar a mano")
            continue
        if solo_revisar:
            faltan.append(f"{pid} {rel}: sin aplicar")
            continue
        p.write_bytes(t.replace(viejo, nuevo).encode("utf-8"))
        cambiados.append(f"{pid} {rel}")
    for toc in sorted(ADDON.glob("Polestar*/Polestar*.toc")):
        t = toc.read_bytes().decode("utf-8")
        n = _toc(t)
        if n != t:
            if solo_revisar:
                faltan.append(f"P4-toc {toc.relative_to(ADDON).as_posix()}: sin aplicar")
            else:
                toc.write_bytes(n.encode("utf-8"))
                cambiados.append(f"P4-toc {toc.relative_to(ADDON).as_posix()}")
    for c in cambiados:
        print("aplicado:", c)
    for f in faltan:
        print("FALTA:", f)
    print(f"{len(cambiados)} aplicados, {len(faltan)} pendientes")
    return 1 if faltan else 0


if __name__ == "__main__":
    sys.exit(aplicar("--revisar" in sys.argv))
