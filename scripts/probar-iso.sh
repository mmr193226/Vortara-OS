#!/bin/bash
# Arranca la ISO de Vortara en QEMU con 2 GB de RAM (el mínimo objetivo).
#
# Uso:
#   ./scripts/probar-iso.sh [bios|uefi] [ruta.iso]
#
# Abre una ventana si hay entorno gráfico. Sin pantalla (servidor, CI) usa
# VORTARA_SIN_PANTALLA=1 y controla la VM por el socket de monitor:
#   echo "screendump captura.ppm" | socat - UNIX-CONNECT:/tmp/vortara-qemu.sock
set -euo pipefail

MODO="${1:-uefi}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
. "$RAIZ/live-build/vortara.conf"
ISO="${2:-$RAIZ/salida/vortara-${VORTARA_VERSION}-amd64.hybrid.iso}"
[ -f "$ISO" ] || { echo "No encuentro la ISO: $ISO" >&2; exit 1; }

args=(-m 2048 -smp 2 -cdrom "$ISO" -boot d
	-device virtio-vga -device virtio-net,netdev=red -netdev user,id=red
	-audiodev none,id=snd -usb -device usb-tablet
	-monitor unix:/tmp/vortara-qemu.sock,server,nowait)

if [ -e /dev/kvm ]; then
	args+=(-enable-kvm -cpu host)
fi

if [ "$MODO" = "uefi" ]; then
	vars="$(mktemp --suffix=-ovmf-vars.fd)"
	cp /usr/share/OVMF/OVMF_VARS_4M.fd "$vars"
	args+=(-machine q35
		-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
		-drive if=pflash,format=raw,file="$vars")
fi

if [ "${VORTARA_SIN_PANTALLA:-0}" = "1" ]; then
	args+=(-display none)
fi

exec qemu-system-x86_64 "${args[@]}"
