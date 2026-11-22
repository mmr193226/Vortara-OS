#!/usr/bin/env python3
"""Traducciones de la app de bienvenida (formato gettext .po/.mo).

Uso:
  scripts/traducciones.py extraer      actualiza la plantilla .pot y los .po
                                       con los textos nuevos de la app
  scripts/traducciones.py comprobar    cuenta lo que falta por traducir y
                                       revisa los marcadores {nombre}
  scripts/traducciones.py compilar DESTINO
                                       compila los .po en
                                       DESTINO/usr/share/locale/<idioma>/LC_MESSAGES/

Los textos originales están en español. Para añadir un idioma, copia la
plantilla po/vortara-bienvenida.pot a po/<código>.po (por ejemplo nl.po),
traduce los msgstr (con un editor de texto o Poedit) y vuelve a construir.

No necesita las herramientas de gettext (msgfmt...): solo Python.
"""
import ast
import json
import re
import struct
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PAQUETE = RAIZ / "paquetes" / "vortara-bienvenida"
APP = PAQUETE / "raiz" / "usr" / "bin" / "vortara-bienvenida"
PACKS = PAQUETE / "raiz" / "usr" / "share" / "vortara" / "packs.json"
DIR_PO = PAQUETE / "po"
DOMINIO = "vortara-bienvenida"


# --- Lectura y escritura de .po --------------------------------------------

def _escapar(texto):
    return texto.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def _desescapar(texto):
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), texto)


def leer_po(ruta):
    """Devuelve (cabecera, {msgid: msgstr}) en el orden del archivo."""
    entradas, actual, campo = {}, {}, None
    cabecera = ""

    def cerrar():
        if "msgid" in actual:
            if actual["msgid"] == "":
                nonlocal cabecera
                cabecera = actual.get("msgstr", "")
            else:
                entradas[actual["msgid"]] = actual.get("msgstr", "")

    for linea in Path(ruta).read_text(encoding="utf-8").splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("#"):
            if not linea and actual:
                cerrar()
                actual, campo = {}, None
            continue
        m = re.match(r'^(msgid|msgstr)\s+"(.*)"$', linea)
        if m:
            if m.group(1) == "msgid" and "msgid" in actual:
                cerrar()
                actual = {}
            campo = m.group(1)
            actual[campo] = _desescapar(m.group(2))
        elif linea.startswith('"') and campo:
            actual[campo] += _desescapar(linea[1:-1])
    cerrar()
    return cabecera, entradas


def _cadena_po(clave, texto):
    if "\n" not in texto.rstrip("\n") and len(texto) < 70:
        return f'{clave} "{_escapar(texto)}"\n'
    partes = re.split(r"(?<=\n)", texto)
    salida = f'{clave} ""\n'
    for parte in partes:
        if parte:
            salida += f'"{_escapar(parte)}"\n'
    return salida


def escribir_po(ruta, cabecera, entradas, comentario):
    texto = f"# {comentario}\n"
    texto += _cadena_po("msgid", "") + _cadena_po("msgstr", cabecera) + "\n"
    for msgid, msgstr in entradas.items():
        texto += _cadena_po("msgid", msgid) + _cadena_po("msgstr", msgstr) + "\n"
    Path(ruta).write_text(texto, encoding="utf-8")


def cabecera_po(idioma=""):
    return ("Project-Id-Version: vortara-bienvenida\n"
            f"Language: {idioma}\n"
            "MIME-Version: 1.0\n"
            "Content-Type: text/plain; charset=UTF-8\n"
            "Content-Transfer-Encoding: 8bit\n")


# --- Extracción --------------------------------------------------------------

def textos_de_la_app():
    """Textos marcados con _("...") en la app y textos de packs.json."""
    textos = []
    arbol = ast.parse(APP.read_text(encoding="utf-8"))
    for nodo in ast.walk(arbol):
        if (isinstance(nodo, ast.Call) and isinstance(nodo.func, ast.Name)
                and nodo.func.id == "_" and nodo.args
                and isinstance(nodo.args[0], ast.Constant)
                and isinstance(nodo.args[0].value, str)):
            textos.append((nodo.lineno, nodo.args[0].value))
    textos = [t for _l, t in sorted(textos)]
    packs = json.loads(PACKS.read_text(encoding="utf-8"))
    for pack in packs.values():
        textos += [pack["nombre"], pack["descripcion"], pack["incluye"]]
    unicos = []
    for t in textos:
        if t not in unicos:
            unicos.append(t)
    return unicos


def extraer():
    textos = textos_de_la_app()
    DIR_PO.mkdir(exist_ok=True)
    escribir_po(DIR_PO / f"{DOMINIO}.pot", cabecera_po(), {t: "" for t in textos},
                "Plantilla de traducción de la app de bienvenida de Vortara OS.")
    for po in sorted(DIR_PO.glob("*.po")):
        cabecera, viejas = leer_po(po)
        nuevas = {t: viejas.get(t, "") for t in textos}
        escribir_po(po, cabecera or cabecera_po(po.stem), nuevas,
                    f"Traducción de la app de bienvenida de Vortara OS ({po.stem}).")
        faltan = sum(1 for v in nuevas.values() if not v)
        print(f"{po.name}: {len(nuevas)} textos, {faltan} sin traducir")
    print(f"Plantilla: {len(textos)} textos")


# --- Comprobación -------------------------------------------------------------

def comprobar():
    marcador = re.compile(r"\{[a-z_]+\}")
    errores = 0
    for po in sorted(DIR_PO.glob("*.po")):
        _c, entradas = leer_po(po)
        faltan = [k for k, v in entradas.items() if not v]
        for msgid, msgstr in entradas.items():
            if msgstr and sorted(marcador.findall(msgid)) != sorted(marcador.findall(msgstr)):
                print(f"{po.name}: marcadores distintos en «{msgid[:50]}»")
                errores += 1
        print(f"{po.name}: {len(entradas) - len(faltan)}/{len(entradas)} traducidos")
    actuales = set(textos_de_la_app())
    for po in sorted(DIR_PO.glob("*.po")):
        _c, entradas = leer_po(po)
        if set(entradas) != actuales:
            print(f"{po.name}: no está al día con la app (ejecuta «extraer»)")
            errores += 1
    return 1 if errores else 0


# --- Compilación --------------------------------------------------------------

def escribir_mo(ruta, cabecera, entradas):
    catalogo = {"": cabecera}
    catalogo.update({k: v for k, v in entradas.items() if v})
    claves = sorted(k.encode("utf-8") for k in catalogo)
    valores = {k.encode("utf-8"): v.encode("utf-8") for k, v in catalogo.items()}
    n = len(claves)
    pos_ids, pos_strs = 7 * 4, 7 * 4 + n * 8
    datos = pos_strs + n * 8
    tabla, cuerpo = [], b""
    for k in claves:
        tabla.append((len(k), datos + len(cuerpo)))
        cuerpo += k + b"\0"
    for k in claves:
        tabla.append((len(valores[k]), datos + len(cuerpo)))
        cuerpo += valores[k] + b"\0"
    ruta.parent.mkdir(parents=True, exist_ok=True)
    with open(ruta, "wb") as f:
        f.write(struct.pack("<7I", 0x950412DE, 0, n, pos_ids, pos_strs, 0, 0))
        for longitud, posicion in tabla:
            f.write(struct.pack("<2I", longitud, posicion))
        f.write(cuerpo)


def compilar(destino):
    for po in sorted(DIR_PO.glob("*.po")):
        cabecera, entradas = leer_po(po)
        mo = Path(destino) / "usr/share/locale" / po.stem / "LC_MESSAGES" / f"{DOMINIO}.mo"
        escribir_mo(mo, cabecera, entradas)


if __name__ == "__main__":
    orden = sys.argv[1] if len(sys.argv) > 1 else ""
    if orden == "extraer":
        extraer()
    elif orden == "comprobar":
        sys.exit(comprobar())
    elif orden == "compilar" and len(sys.argv) == 3:
        compilar(sys.argv[2])
    else:
        print(__doc__)
        sys.exit(2)
