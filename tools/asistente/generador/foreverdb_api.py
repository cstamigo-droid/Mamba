# -*- coding: utf-8 -*-
"""Adaptador de la API de ForeverDB (https://foreverdb.net/developers). HOY APAGADO: falta la clave.

Reglas de ForeverDB que este archivo respeta:
- La clave se lee de la variable de entorno FOREVERDB_KEY o de un archivo FUERA del addon.
  Nunca se escribe en la salida ("Never ship a key inside a plugin or app you give out").
- Lo que se baje se guarda en generador/_descargas/foreverdb/ y se empaqueta con crédito visible
  ("credit ForeverDB.net as the source, with a visible link") donde el addon muestre esos datos.
- No se revende ni se presenta como propio.

Para qué sirve cuando haya clave: confirmar las recetas (materiales y colores) de /professions/{slug}
contra las guías de Polestar, y traer vendedores (/vendors) para el plan de bolsas.
Uso:  set FOREVERDB_KEY=...   y   python -I foreverdb_api.py <carpeta de descargas>
"""
import json
import os
import pathlib
import sys
import urllib.request

BASE = "https://foreverdb.net/api/v1"
AGENTE = "AsistenteForever-generador/0.1 (uso personal)"
PROFESIONES = ["cooking", "alchemy", "first-aid", "herbalism"]


class SinClave(Exception):
    pass


def leer_clave(archivo=None):
    clave = os.environ.get("FOREVERDB_KEY", "").strip()
    if not clave and archivo and pathlib.Path(archivo).exists():
        clave = pathlib.Path(archivo).read_text(encoding="utf-8").strip()
    if not clave:
        raise SinClave("ForeverDB apagado: falta la clave (la pide Cristian con su cuenta Battle.net).")
    return clave


def pedir(ruta, clave, params=None):
    url = BASE + ruta
    if params:
        url += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    req = urllib.request.Request(url, headers={"X-API-Key": clave, "User-Agent": AGENTE,
                                               "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def descargar(carpeta, clave):
    """Baja las profesiones y guarda el JSON tal cual llega. La clave NO se guarda."""
    carpeta = pathlib.Path(carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    meta = pedir("/meta", clave)
    (carpeta / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")
    for slug in PROFESIONES:
        datos = pedir(f"/professions/{slug}", clave)
        (carpeta / f"professions_{slug}.json").write_text(json.dumps(datos, ensure_ascii=False, indent=1),
                                                          encoding="utf-8")
    return meta


if __name__ == "__main__":
    try:
        clave = leer_clave(sys.argv[2] if len(sys.argv) > 2 else None)
    except SinClave as e:
        print(e)
        sys.exit(2)
    print(descargar(sys.argv[1], clave))
