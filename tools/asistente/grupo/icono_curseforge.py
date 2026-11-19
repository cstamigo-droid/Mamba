"""Icono de Mamba para CurseForge (400x400, lo pide su regla "Project Avatar"). Arte PROPIO: se dibuja aquí con
fórmulas, con la paleta de la mamba negra de serpiente_texturas.py. Licencia: GPL-3.0-only, como Mamba.

    python -I tools/asistente/grupo/icono_curseforge.py SALIDA.png
"""
from __future__ import annotations

import math
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

LOMO, SOMBRA, OLIVA, ACERO, LENGUA = (38, 42, 39), (18, 20, 22), (140, 158, 107), (107, 118, 129), (150, 40, 40)
FONDO_A, FONDO_B = (24, 27, 31), (10, 11, 13)
N = 4  # sobremuestreo


def main(salida: str) -> None:
    W = 400 * N
    im = Image.new("RGB", (W, W), FONDO_B)
    d = ImageDraw.Draw(im)
    # fondo: degradé radial suave
    for r in range(W // 2, 0, -4 * N):
        t = r / (W / 2)
        c = tuple(int(FONDO_A[i] * (1 - t) + FONDO_B[i] * t) for i in range(3))
        d.ellipse([W / 2 - r, W * 0.45 - r, W / 2 + r, W * 0.45 + r], fill=c)
    # cuerpo en S (dos vueltas de seno), de la cola (abajo izq.) a la cabeza (arriba der.)
    pts = []
    for k in range(400):
        t = k / 399
        x = W * (0.12 + 0.50 * t)
        y = W * (0.62 - 0.22 * t) + W * 0.11 * math.sin(t * 2.2 * math.pi)
        pts.append((x, y))
    def grosor(t):
        return (10 + 26 * min(1, t * 3)) * N
    for capa, dy, col, esc in ((0, 3 * N, SOMBRA, 1.12), (1, 0, LOMO, 1.0)):
        for k, (x, y) in enumerate(pts):
            r = grosor(k / (len(pts) - 1)) * esc / 2
            d.ellipse([x - r, y + dy - r, x + r, y + dy + r], fill=col)
    for k, (x, y) in enumerate(pts):  # brillo oliva sobre el lomo
        g = grosor(k / (len(pts) - 1))
        r = max(N, g * 0.08)
        d.ellipse([x - r, y - g * 0.28 - r, x + r, y - g * 0.28 + r], fill=OLIVA)
    # cabeza: elipse alargada mirando a la derecha, con ojo y lengua
    hx, hy = pts[-1]
    d.polygon([(hx + 62 * N, hy - 2 * N), (hx + 92 * N, hy - 10 * N), (hx + 84 * N, hy), (hx + 92 * N, hy + 10 * N),
               (hx + 62 * N, hy + 2 * N)], fill=LENGUA)
    d.ellipse([hx - 30 * N, hy - 27 * N, hx + 68 * N, hy + 25 * N], fill=SOMBRA)
    d.ellipse([hx - 28 * N, hy - 25 * N, hx + 64 * N, hy + 21 * N], fill=LOMO)
    d.arc([hx - 20 * N, hy - 22 * N, hx + 56 * N, hy + 10 * N], 200, 330, fill=OLIVA, width=3 * N)
    d.ellipse([hx + 28 * N, hy - 12 * N, hx + 38 * N, hy - 2 * N], fill=(8, 8, 8))
    d.ellipse([hx + 31 * N, hy - 10 * N, hx + 34 * N, hy - 7 * N], fill=ACERO)
    # palabra MAMBA
    try:
        f = ImageFont.truetype("georgiab.ttf", 74 * N)
    except OSError:
        f = ImageFont.load_default()
    txt = "MAMBA"
    w = d.textlength(txt, font=f)
    d.text(((W - w) / 2, W * 0.76), txt, font=f, fill=OLIVA, stroke_width=2 * N, stroke_fill=SOMBRA)
    im = im.filter(ImageFilter.GaussianBlur(N * 0.4)).resize((400, 400), Image.LANCZOS)
    im.save(salida)
    print(salida, im.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "mamba_icono_400.png")
