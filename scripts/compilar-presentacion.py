#!/usr/bin/env python3
"""Traducciones de la presentación del instalador (Calamares).

Los textos de show.qml están en inglés, marcados con qsTr(). Calamares carga
las traducciones de lang/calamares-vortara_<idioma>.qm (en la carpeta del
tema) y las cambia en cuanto el usuario elige otro idioma. Si el idioma no
tiene traducción, la presentación sale en inglés.

Uso: scripts/compilar-presentacion.py [LRELEASE]

Lee branding/presentacion/traducciones.json (por idioma, los 8 textos en el
orden de show.qml; «en» son los originales), escribe los .ts en
branding/presentacion/ts/ y los compila con lrelease (paquete qt6-l10n-tools)
en live-build/config/includes.chroot/usr/share/vortara/calamares/lang/.
Los .qm resultantes se guardan en el repositorio: la ISO no necesita lrelease.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

RAIZ = Path(__file__).resolve().parent.parent
FUENTE = RAIZ / "branding" / "presentacion" / "traducciones.json"
DIR_TS = RAIZ / "branding" / "presentacion" / "ts"
DIR_QM = RAIZ / "live-build/config/includes.chroot/usr/share/vortara/calamares/lang"
CONTEXTO = "show"  # qsTr() en show.qml usa el nombre del archivo


def escribir_ts(idioma, originales, traducciones):
    lineas = ['<?xml version="1.0" encoding="utf-8"?>',
              '<!DOCTYPE TS>',
              f'<TS version="2.1" language="{idioma}" sourcelanguage="en">',
              '<context>',
              f'    <name>{CONTEXTO}</name>']
    for original, traduccion in zip(originales, traducciones):
        lineas += ['    <message>',
                   f'        <source>{escape(original)}</source>',
                   f'        <translation>{escape(traduccion)}</translation>',
                   '    </message>']
    lineas += ['</context>', '</TS>', '']
    ruta = DIR_TS / f"calamares-vortara_{idioma}.ts"
    ruta.write_text("\n".join(lineas), encoding="utf-8")
    return ruta


def main():
    lrelease = sys.argv[1] if len(sys.argv) > 1 else (
        shutil.which("lrelease") or "/usr/lib/qt6/bin/lrelease")
    datos = json.loads(FUENTE.read_text(encoding="utf-8"))
    originales = datos["en"]
    DIR_TS.mkdir(parents=True, exist_ok=True)
    DIR_QM.mkdir(parents=True, exist_ok=True)
    for idioma, textos in datos.items():
        if idioma == "en":
            continue
        assert len(textos) == len(originales), idioma
        ts = escribir_ts(idioma, originales, textos)
        qm = DIR_QM / f"calamares-vortara_{idioma}.qm"
        subprocess.run([lrelease, "-silent", str(ts), "-qm", str(qm)], check=True)
        print(f"{qm.name}")


if __name__ == "__main__":
    main()
