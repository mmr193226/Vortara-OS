#!/bin/bash
# Construye la ISO de Vortara OS.
#
# Uso (como root):
#   sudo ./scripts/build-iso.sh            # construye la ISO
#   sudo ./scripts/build-iso.sh --limpiar  # borra el directorio de trabajo
#
# En Debian 13 con live-build instalado se construye directamente.
# En cualquier otra distribución se crea primero un entorno Debian 13
# con debootstrap (solo la primera vez) y se construye dentro.
#
# Variables opcionales:
#   VORTARA_TRABAJO  directorio de trabajo (por defecto /var/tmp/vortara-build)
#   VORTARA_SALIDA   dónde dejar la ISO (por defecto ./salida)
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TRABAJO="${VORTARA_TRABAJO:-/var/tmp/vortara-build}"
SALIDA="${VORTARA_SALIDA:-$RAIZ/salida}"
HOST="$TRABAJO/host"
. "$RAIZ/live-build/vortara.conf"

[ "$(id -u)" -eq 0 ] || { echo "Ejecuta este script como root (sudo)." >&2; exit 1; }

if [ "${1:-}" = "--limpiar" ]; then
	for m in dev/pts dev proc sys; do umount "$HOST/$m" 2>/dev/null || true; done
	rm -rf "$TRABAJO"
	echo "Directorio de trabajo borrado."
	exit 0
fi

es_debian_trixie() {
	. /etc/os-release
	[ "${VERSION_CODENAME:-}" = "trixie" ] && [ "${ID:-}" = "debian" ] && command -v lb >/dev/null
}

preparar_config() {
	# Copia la configuración y sustituye los datos de la versión.
	local dir="$1"
	rm -rf "$dir"
	mkdir -p "$dir"
	cp -a "$RAIZ/live-build/." "$dir/"
	grep -rlZ '@VORTARA_' "$dir/config" | xargs -0 -r sed -i \
		-e "s/@VORTARA_VERSION@/${VORTARA_VERSION}/g" \
		-e "s/@VORTARA_CODENAME@/${VORTARA_CODENAME}/g" \
		-e "s/@VORTARA_CODENAME_PRETTY@/${VORTARA_CODENAME_PRETTY}/g"
}

construir() {
	# $1 = directorio con la configuración (visto desde donde se ejecuta lb)
	cd "$1"
	lb clean --purge >/dev/null 2>&1 || true
	lb config
	lb build
}

mkdir -p "$TRABAJO" "$SALIDA"
ISO="vortara-${VORTARA_VERSION}-amd64.hybrid.iso"

if es_debian_trixie; then
	preparar_config "$TRABAJO/vortara"
	construir "$TRABAJO/vortara"
	cp "$TRABAJO/vortara/$ISO" "$SALIDA/"
else
	command -v debootstrap >/dev/null || { echo "Instala debootstrap primero." >&2; exit 1; }
	if [ ! -x "$HOST/usr/bin/lb" ]; then
		echo ">> Creando entorno Debian 13 para construir (solo la primera vez)..."
		debootstrap --variant=minbase --include=live-build,ca-certificates \
			trixie "$HOST" "${VORTARA_MIRROR}"
	fi
	cp /etc/resolv.conf "$HOST/etc/resolv.conf"
	for m in proc sys dev dev/pts; do
		mountpoint -q "$HOST/$m" || mount --bind "/$m" "$HOST/$m"
	done
	trap 'for m in dev/pts dev sys proc; do umount -l "$HOST/$m" 2>/dev/null || true; done' EXIT

	preparar_config "$HOST/build/vortara"
	chroot "$HOST" /bin/bash -c "cd /build/vortara && lb clean --purge >/dev/null 2>&1; lb config && lb build"
	cp "$HOST/build/vortara/$ISO" "$SALIDA/"
fi

echo ">> ISO lista: $SALIDA/$ISO"
ls -lh "$SALIDA/$ISO"
