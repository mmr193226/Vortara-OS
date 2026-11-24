#!/usr/bin/env python3
"""Genera los fondos de pantalla «Aero» de Vortara.

Se dibujan desde cero con código (degradados, cintas de luz y burbujas), así
que no tienen derechos de autor de nadie: son de dominio público (CC0).

Uso: scripts/generar-fondos.py [DESTINO]
Por defecto, en paquetes/vortara-branding/raiz/usr/share/backgrounds/vortara/.
Necesita python3-numpy y python3-pil.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = Path(sys.argv[1]) if len(sys.argv) > 1 else \
    RAIZ / "paquetes/vortara-branding/raiz/usr/share/backgrounds/vortara"
ANCHO, ALTO = 2560, 1440
rng = np.random.default_rng(2611)

Y, X = np.mgrid[0:ALTO, 0:ANCHO].astype(np.float32)
U, V = X / ANCHO, Y / ALTO


def color(hexa):
    hexa = hexa.lstrip("#")
    return np.array([int(hexa[i:i + 2], 16) / 255 for i in (0, 2, 4)], np.float32)


def degradado(paradas, t):
    """paradas: [(posición, '#rrggbb'), ...]; t: matriz 0..1."""
    pos = [p for p, _c in paradas]
    cols = np.stack([color(c) for _p, c in paradas])
    return np.stack([np.interp(t, pos, cols[:, k]) for k in range(3)], -1)


def pantalla(base, luz, fuerza=1.0):
    """Mezcla «trama» (screen): ilumina sin quemar."""
    return 1 - (1 - base) * (1 - np.clip(luz * fuerza, 0, 1))


def cinta(centro_y, amplitud, fase, frecuencia, grosor, tinte, intensidad):
    """Cinta de luz ondulada a lo ancho de la imagen."""
    curva = centro_y + amplitud * np.sin(2 * np.pi * (U * frecuencia) + fase) \
        + 0.35 * amplitud * np.sin(2 * np.pi * (U * frecuencia * 2.3) + fase * 1.7)
    d = np.abs(V - curva)
    halo = np.exp(-(d / grosor) ** 2) * 0.55 + np.exp(-(d / (grosor * 0.18)) ** 2)
    # Algo más tenue en los bordes, pero sin cortarse.
    halo *= 0.55 + 0.45 * np.sin(np.pi * U)
    return halo[..., None] * color(tinte) * intensidad


def burbujas(img, n, tam, tinte, alfa, zona=None):
    """Círculos de cristal desenfocados (bokeh)."""
    capa = Image.new("RGB", (ANCHO, ALTO))
    px = np.zeros((ALTO, ANCHO, 3), np.float32)
    for _ in range(n):
        r = rng.uniform(*tam)
        cx = rng.uniform(0, ANCHO)
        cy = rng.uniform(*(zona or (0, ALTO)))
        x0, x1 = int(max(cx - r - 2, 0)), int(min(cx + r + 2, ANCHO))
        y0, y1 = int(max(cy - r - 2, 0)), int(min(cy + r + 2, ALTO))
        if x0 >= x1 or y0 >= y1:
            continue
        sx, sy = X[y0:y1, x0:x1] - cx, Y[y0:y1, x0:x1] - cy
        d = np.sqrt(sx ** 2 + sy ** 2) / r
        disco = np.clip((1 - d) * r / 2, 0, 1) * (0.35 + 0.65 * d ** 3)
        brillo = np.exp(-(((sx + r * 0.35) ** 2 + (sy + r * 0.4) ** 2) / (r * 0.25) ** 2)) * 0.6
        px[y0:y1, x0:x1] += (disco + brillo * (d < 1))[..., None] * color(tinte) * rng.uniform(0.4, 1) * alfa
    capa = Image.fromarray((np.clip(px, 0, 1) * 255).astype(np.uint8))
    capa = np.asarray(capa.filter(ImageFilter.GaussianBlur(3)), np.float32) / 255
    return pantalla(img, capa)


def rayos(img, origen, n, tinte, intensidad):
    """Haces de luz que salen de un punto (como el sol tras el cristal)."""
    ang = np.arctan2(V - origen[1], (U - origen[0]) * ANCHO / ALTO)
    patron = np.zeros_like(U)
    for _ in range(n):
        a = rng.uniform(-np.pi, np.pi)
        w = rng.uniform(0.01, 0.05)
        patron += np.exp(-((np.angle(np.exp(1j * (ang - a)))) / w) ** 2) * rng.uniform(0.3, 1)
    dist = np.sqrt(((U - origen[0]) * ANCHO / ALTO) ** 2 + (V - origen[1]) ** 2)
    patron *= np.exp(-dist * 1.4)
    foco = np.exp(-(dist / 0.18) ** 2)
    return pantalla(img, (patron * 0.5 + foco)[..., None] * color(tinte), intensidad)


def ruido(img, cantidad=0.012):
    """Grano fino: evita las bandas en los degradados."""
    return img + rng.normal(0, cantidad, img.shape).astype(np.float32)


def guardar(img, nombre):
    img = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
    ruta = DESTINO / nombre
    Image.fromarray(img).save(ruta, quality=92, optimize=True, progressive=True)
    print(ruta)


def fondo_aero():
    """Aero: azul profundo a teal, con cintas de luz y burbujas."""
    t = np.clip(0.55 * V + 0.45 * U, 0, 1)
    img = degradado([(0, "#0a3d62"), (0.45, "#0b6e80"), (0.75, "#0e8f88"), (1, "#063c3f")], t)
    img = pantalla(img, cinta(0.58, 0.07, 0.4, 0.9, 0.14, "#7fe3d6", 0.6))
    img = pantalla(img, cinta(0.64, 0.05, 2.1, 1.2, 0.05, "#bdf4ff", 0.45))
    img = pantalla(img, cinta(0.52, 0.09, 4.0, 0.7, 0.03, "#ffffff", 0.35))
    img = rayos(img, (0.18, 0.12), 14, "#d9fbff", 0.45)
    img = burbujas(img, 45, (8, 60), "#c9fff7", 0.3)
    return ruido(img)


def fondo_cielo():
    """Cielo: azul claro de Aero con un sol suave y burbujas de cristal."""
    t = V
    img = degradado([(0, "#1e6fb8"), (0.5, "#3fa7d6"), (0.82, "#8fd8e8"), (1, "#d7f3f5")], t)
    img = rayos(img, (0.78, 0.18), 18, "#ffffff", 0.6)
    img = pantalla(img, cinta(0.78, 0.04, 1.0, 0.8, 0.12, "#ffffff", 0.35))
    img = burbujas(img, 55, (12, 90), "#ffffff", 0.4, (ALTO * 0.3, ALTO))
    return ruido(img)


def fondo_noche():
    """Noche: teal muy oscuro con un brillo de cristal en diagonal."""
    t = np.clip(0.6 * V + 0.4 * (1 - U), 0, 1)
    img = degradado([(0, "#04161a"), (0.5, "#08323a"), (1, "#021012")], t)
    d = (U - 0.15) * 0.8 - (V - 0.2)
    franja = np.exp(-(d / 0.12) ** 2) * 0.35 + np.exp(-((d - 0.18) / 0.02) ** 2) * 0.25
    img = pantalla(img, franja[..., None] * color("#2dd4bf"))
    img = pantalla(img, cinta(0.7, 0.06, 3.0, 1.0, 0.04, "#5eead4", 0.5))
    img = burbujas(img, 90, (4, 40), "#5eead4", 0.35)
    return ruido(img, 0.008)


if __name__ == "__main__":
    DESTINO.mkdir(parents=True, exist_ok=True)
    guardar(fondo_aero(), "aero.jpg")
    guardar(fondo_cielo(), "cielo.jpg")
    guardar(fondo_noche(), "noche.jpg")
