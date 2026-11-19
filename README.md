# Vortara OS

Sistema operativo basado en **Debian 13 "Trixie"** con escritorio **Cinnamon**,
pensado para equipos antiguos, desarrolladores y uso general desde una sola ISO.

Versión actual: **Vortara 26.11 "Aurora"**.

Las decisiones de diseño están en [docs/DECISIONES.md](docs/DECISIONES.md).

## Construir la ISO

Necesitas un equipo Linux con permisos de root, unos 20 GB libres y conexión a
internet. En Debian 13 con `live-build` instalado se construye directamente; en
cualquier otra distribución basta con tener `debootstrap`.

```bash
sudo ./scripts/build-iso.sh
```

La ISO queda en `salida/vortara-26.11-amd64.hybrid.iso`. Se puede grabar en un
USB (con `dd`, Ventoy, balenaEtcher...) y arranca en equipos UEFI y BIOS.

Para borrar los archivos temporales de construcción:

```bash
sudo ./scripts/build-iso.sh --limpiar
```

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `live-build/vortara.conf` | Versión, nombre en clave y espejos de Debian |
| `live-build/auto/config` | Opciones de `live-build` (rama, arranque, firmware...) |
| `live-build/config/package-lists/` | Paquetes que se incluyen en la ISO |
| `live-build/config/archives/` | Repositorio backports y prioridad del kernel |
| `live-build/config/hooks/live/` | Scripts que personalizan el sistema durante la construcción |
| `live-build/config/includes.chroot/` | Archivos que se copian tal cual al sistema |
| `branding/` | Logo y generador de imágenes (`node branding/generar-imagenes.js`) |
| `scripts/build-iso.sh` | Script de construcción |
