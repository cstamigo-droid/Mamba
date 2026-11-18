"""Texturas PROPIAS de la mamba negra del encabezado (K63, MAMBA_ACEPTACION.md). Sin arte de terceros: todo
se dibuja aquí con fórmulas. Escribe en addon/Asistente/Media/ (TGA de 32 bits, origen arriba a la izquierda,
como las de Polestar) y, con --png DIR, copias PNG para la maqueta.

    python -I tools/asistente/serpiente_texturas.py [--png DIR]

Paleta (de Dendroaspis polylepis, la mamba negra: lomo gris pizarra casi negro, reflejo oliva arriba, canto
acerado abajo; el oliva es el mismo de "Mamba" en el encabezado, 0.55 0.62 0.42):
  lomo #262a27 · sombra #121416 · brillo oliva #8c9e6b · canto acero #6b7681 · lengua #2e1a1a
Cada textura mira hacia +x (la cabeza apunta a la derecha) y el lomo queda arriba (v < 0): en el juego se
rotan con SetRotation según la tangente del camino.
Licencia: GPL-3.0-only (como el resto de Mamba).
"""
from __future__ import annotations

import math
import struct
import sys
import zlib
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
MEDIA = RAIZ / "addon" / "Asistente" / "Media"

LOMO = (0x26, 0x2A, 0x27)
SOMBRA = (0x12, 0x14, 0x16)
OLIVA = (0x8C, 0x9E, 0x6B)
ACERO = (0x6B, 0x76, 0x81)
LENGUA = (0x2E, 0x1A, 0x1A)


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def piel(v):
    """Color de la piel a la altura v (-1 lomo, +1 vientre) de un cilindro visto de costado."""
    c = mezcla(LOMO, SOMBRA, max(0.0, v) * 0.9)  # el vientre cae a sombra
    c = mezcla(c, OLIVA, 0.62 * math.exp(-((v + 0.42) / 0.2) ** 2))  # reflejo oliva sobre el lomo
    c = mezcla(c, ACERO, 0.38 * math.exp(-((v - 0.78) / 0.14) ** 2))  # canto acerado abajo: la separa del fondo oscuro
    c = mezcla(c, ACERO, 0.55 * math.exp(-((v + 0.9) / 0.1) ** 2))  # filo acerado sobre el lomo (revisión de arte, 1)
    return c


def cuerpo(n=32):
    """Disco: un tramo del cuerpo. Los discos se solapan cada 1,5 px y forman el tubo."""
    px = []
    c = (n - 1) / 2
    r = n / 2 - 1
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c)
            a = max(0.0, min(1.0, r - d + 0.5))
            v = (y - c) / r
            px.append((*piel(v), a))
    return n, n, px


def cabeza(w=64, h=64):
    """Cabeza en forma de ataúd (la de la mamba), apenas más ancha que el cuello, hocico romo hacia +x. Va en
    una caja cuadrada (se dibuja de 9x9 px en el juego): así gira igual con cualquier SetRotation."""
    cy = (h - 1) / 2

    def semiancho(x):
        if x < 4 or x > 60:
            return 0.0
        if x < 16:  # cuello: del ancho del cuello (2,9 px) a las sienes
            return 10.3 + (x - 4) / 12 * 3.4
        if x < 32:
            return 13.7 + (x - 16) / 16 * 1.9
        if x < 46:
            return 15.6 - (x - 32) / 14 * 1.6
        u = (x - 46) / 14  # hocico: superelipse
        return 14.0 * max(0.0, 1 - u ** 3.0) ** (1 / 3.0)

    px = []
    for y in range(h):
        for x in range(w):
            hw = semiancho(x)
            dy = abs(y - cy)
            a = max(0.0, min(1.0, hw - dy + 0.5)) if hw > 0 else 0.0
            v = (y - cy) / hw if hw > 0 else 0
            col = piel(max(-1.0, min(1.0, v)))
            # comisura de la boca: la "sonrisa" de la mamba, una línea apenas más oscura
            if 36 <= x <= 58 and abs((y - cy) - (3.4 + (x - 36) * 0.06)) < 0.9:
                col = mezcla(col, SOMBRA, 0.5)
            # ojo oscuro con un punto de brillo mínimo
            de = math.hypot(x - 46, y - (cy - 6.8))
            if de < 2.8:
                col = mezcla(col, (0x0A, 0x0B, 0x0A), min(1.0, 2.8 - de))
            if math.hypot(x - 46.8, y - (cy - 7.6)) < 0.8:
                col = mezcla(col, ACERO, 0.6)
            px.append((*col, a))
    return w, h, px


def lengua(w=64, h=64):
    """Lengua bífida, fina, en una caja cuadrada con el mismo centro que la cabeza: sale del hocico hacia +x
    (en el juego la caja mide 24/11 del largo de la cabeza)."""
    cy = (h - 1) / 2
    px = []
    for y in range(h):
        for x in range(w):
            a = 0.0
            if 47 <= x <= 56:
                a = max(0.0, 1 - abs(y - cy) / 0.9)
            elif 56 < x <= 63:
                abra = (x - 56) / 7 * 2.4
                a = max(0.0, 1 - min(abs(y - (cy - abra)), abs(y - (cy + abra))) / 0.8)
            px.append((*LENGUA, a))
    return w, h, px


def tga(ruta: Path, w, h, px):
    cab = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    datos = bytearray()
    for r, g, b, a in px:
        datos += bytes((round(b), round(g), round(r), round(a * 255)))
    ruta.write_bytes(cab + bytes(datos))


def png(ruta: Path, w, h, px):
    filas = bytearray()
    for y in range(h):
        filas.append(0)
        for x in range(w):
            r, g, b, a = px[y * w + x]
            filas += bytes((round(r), round(g), round(b), round(a * 255)))
    def trozo(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    ruta.write_bytes(b"\x89PNG\r\n\x1a\n" + trozo(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                     + trozo(b"IDAT", zlib.compress(bytes(filas), 9)) + trozo(b"IEND", b""))


TEXTURAS = {"serpiente-cuerpo": cuerpo, "serpiente-cabeza": cabeza, "serpiente-lengua": lengua}


def main(argv):
    MEDIA.mkdir(parents=True, exist_ok=True)
    dir_png = Path(argv[argv.index("--png") + 1]) if "--png" in argv else None
    for nombre, fn in TEXTURAS.items():
        w, h, px = fn()
        tga(MEDIA / f"{nombre}.tga", w, h, px)
        if dir_png:
            dir_png.mkdir(parents=True, exist_ok=True)
            png(dir_png / f"{nombre}.png", w, h, px)
        print(f"{nombre}.tga {w}x{h}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
