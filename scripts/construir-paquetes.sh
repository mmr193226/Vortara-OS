#!/bin/bash
# Construye los paquetes .deb propios de Vortara a partir de paquetes/.
#
# Uso: ./scripts/construir-paquetes.sh [--sin-packs] [DESTINO]
#        DESTINO por defecto: ./salida/paquetes
#        --sin-packs: no construye los metapaquetes de los packs (la ISO no los
#                     lleva: se instalan después, desde la app de bienvenida).
#
# Cada carpeta paquetes/<nombre>/ tiene:
#   DEBIAN/   control y scripts del paquete (postinst, triggers...)
#   raiz/     los archivos tal como quedan instalados en el sistema
#
# Además se generan los metapaquetes de los packs (vortara-pack-*) a partir de
# paquetes/vortara-bienvenida/raiz/usr/share/vortara/packs.json, la misma lista
# que usa la app de bienvenida.
#
# Solo necesita dpkg-deb y python3 (funciona en Debian, Ubuntu y en GitHub Actions).
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
CON_PACKS=1
if [ "${1:-}" = "--sin-packs" ]; then
	CON_PACKS=0
	shift
fi
DESTINO="$(mkdir -p "${1:-$RAIZ/salida/paquetes}" && cd "${1:-$RAIZ/salida/paquetes}" && pwd)"
TRABAJO="$(mktemp -d)"
trap 'rm -rf "$TRABAJO"' EXIT

campo() { sed -n "s/^$2: *//p" "$1/DEBIAN/control" | head -1; }

empaquetar() {
	# $1 = carpeta ya preparada (con DEBIAN/)
	local dir="$1" nombre version
	nombre="$(campo "$dir" Package)"
	version="$(campo "$dir" Version)"
	# Permisos normales: directorios 755, archivos 644; se respetan los ejecutables.
	find "$dir" -type d -exec chmod 755 {} +
	find "$dir" -type f ! -perm -u+x -exec chmod 644 {} +
	find "$dir" -type f -perm -u+x -exec chmod 755 {} +
	# Tamaño instalado (en KiB), como lo calcula dpkg.
	echo "Installed-Size: $(du -sk --exclude=DEBIAN "$dir" | cut -f1)" >> "$dir/DEBIAN/control"
	dpkg-deb --root-owner-group -Zxz --build "$dir" "$DESTINO/${nombre}_${version}_all.deb" >/dev/null
	echo "  ${nombre}_${version}_all.deb"
}

echo ">> Construyendo paquetes en $DESTINO"
for origen in "$RAIZ"/paquetes/*/; do
	[ -f "$origen/DEBIAN/control" ] || continue
	nombre="$(basename "$origen")"

	if [ "$nombre" = vortara-archive-keyring ] && \
	   [ ! -f "$origen/raiz/usr/share/keyrings/vortara-archive-keyring.asc" ]; then
		echo "  (vortara-archive-keyring: falta la clave pública, se omite)"
		continue
	fi

	dir="$TRABAJO/$nombre"
	mkdir -p "$dir"
	cp -a "$origen/raiz/." "$dir/"
	cp -a "$origen/DEBIAN" "$dir/DEBIAN"

	if [ "$nombre" = vortara-branding ]; then
		# Iconos del logo en el tema hicolor (los usa el sistema: LOGO= en
		# os-release, lanzadores...), a partir de los de /usr/share/pixmaps.
		for t in 16 22 24 32 48 64 128 256; do
			mkdir -p "$dir/usr/share/icons/hicolor/${t}x${t}/apps"
			cp "$dir/usr/share/pixmaps/vortara-logo-$t.png" \
				"$dir/usr/share/icons/hicolor/${t}x${t}/apps/vortara-logo.png"
		done
		mkdir -p "$dir/usr/share/icons/hicolor/scalable/apps"
		cp "$dir/usr/share/pixmaps/vortara-logo.svg" "$dir/usr/share/icons/hicolor/scalable/apps/"
	fi

	empaquetar "$dir"
done

# --- Metapaquetes de los packs ---------------------------------------------
if [ "$CON_PACKS" = 0 ]; then
	echo ">> Listo (sin los metapaquetes de los packs)."
	exit 0
fi
packs="$RAIZ/paquetes/vortara-bienvenida/raiz/usr/share/vortara/packs.json"
version="$(campo "$RAIZ/paquetes/vortara-bienvenida" Version)"
python3 - "$packs" "$version" "$TRABAJO" <<'FIN'
import json, os, sys
packs, version, trabajo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(packs, encoding="utf-8") as f:
    datos = json.load(f)
for ident, pack in datos.items():
    nombre = f"vortara-pack-{ident}"
    dir_debian = os.path.join(trabajo, nombre, "DEBIAN")
    os.makedirs(dir_debian)
    extra = ""
    if pack.get("flatpak"):
        extra = ("\n .\n Desde Flathub (no se instala con este paquete; usa la app de "
                 "bienvenida):\n " + ", ".join(pack["flatpak"]))
    with open(os.path.join(dir_debian, "control"), "w", encoding="utf-8") as f:
        f.write(f"""Package: {nombre}
Version: {version}
Architecture: all
Maintainer: Vortara OS <mmr193226@users.noreply.github.com>
Section: metapackages
Priority: optional
Depends: {", ".join(pack["apt"])}
Homepage: https://github.com/mmr193226/Vortara-OS
Description: pack «{pack["nombre"]}» de Vortara OS
 {pack["descripcion"]}
 .
 Incluye: {pack["incluye"]}.{extra}
""")
FIN
for dir in "$TRABAJO"/vortara-pack-*/; do
	empaquetar "${dir%/}"
done
echo ">> Listo."
