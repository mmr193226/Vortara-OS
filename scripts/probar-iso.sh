#!/bin/bash
# Arranca la ISO de Vortara en QEMU con 2 GB de RAM (el mínimo objetivo).
#
# Uso:
#   ./scripts/probar-iso.sh [bios|uefi] [ruta.iso]
#   ./scripts/probar-iso.sh [bios|uefi] disco      # arranca el sistema ya instalado
#
# Variables opcionales:
#   VORTARA_DISCO=ruta.qcow2   disco virtual donde instalar (se crea de 20 GB si
#                              no existe). Necesario para probar el instalador.
#   VORTARA_SIN_PANTALLA=1     sin ventana (servidores, CI)
#
# Abre una ventana si hay entorno gráfico. Sin pantalla (servidor, CI) usa
# VORTARA_SIN_PANTALLA=1 y controla la VM por el socket de monitor:
#   echo "screendump captura.ppm" | socat - UNIX-CONNECT:/tmp/vortara-qemu.sock
set -euo pipefail

MODO="${1:-uefi}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
. "$RAIZ/live-build/vortara.conf"
ISO="${2:-$RAIZ/salida/vortara-${VORTARA_VERSION}-amd64.hybrid.iso}"
DISCO="${VORTARA_DISCO:-}"

args=(-m 2048 -smp 2
	-device virtio-vga -device virtio-net,netdev=red -netdev user,id=red
	-audiodev none,id=snd -usb -device usb-tablet
	-monitor unix:/tmp/vortara-qemu.sock,server,nowait
	-qmp unix:/tmp/vortara-qmp.sock,server,nowait)

if [ -n "$DISCO" ]; then
	[ -f "$DISCO" ] || qemu-img create -q -f qcow2 "$DISCO" 20G
	args+=(-drive file="$DISCO",if=virtio,format=qcow2)
fi

if [ "$ISO" = "disco" ]; then
	[ -n "$DISCO" ] || { echo "Indica el disco con VORTARA_DISCO=..." >&2; exit 1; }
	args+=(-boot c)
else
	[ -f "$ISO" ] || { echo "No encuentro la ISO: $ISO" >&2; exit 1; }
	args+=(-cdrom "$ISO" -boot d)
fi

if [ -e /dev/kvm ]; then
	args+=(-enable-kvm -cpu host)
fi

if [ "$MODO" = "uefi" ]; then
	# Con disco, las variables EFI se guardan junto a él para que la entrada
	# de arranque que crea el instalador siga ahí al reiniciar.
	if [ -n "$DISCO" ]; then
		vars="${DISCO%.*}-efivars.fd"
		[ -f "$vars" ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$vars"
	else
		vars="$(mktemp --suffix=-ovmf-vars.fd)"
		cp /usr/share/OVMF/OVMF_VARS_4M.fd "$vars"
	fi
	args+=(-machine q35
		-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
		-drive if=pflash,format=raw,file="$vars")
fi

if [ "${VORTARA_SIN_PANTALLA:-0}" = "1" ]; then
	args+=(-display none)
fi

exec qemu-system-x86_64 "${args[@]}"
