# Vortara OS — Decisiones base

Este documento fija las bases de Vortara. Cualquier cambio en estas decisiones
debe actualizarse aquí antes de tocar la configuración de construcción.

## 1. Base del sistema

| Aspecto | Decisión |
|---|---|
| Distribución base | Debian 13 "Trixie" (stable) |
| Backports | Activados (kernel y drivers más recientes) |
| Arquitectura | amd64 |
| Arranque | UEFI + BIOS (Legacy) |
| Herramienta de construcción | `live-build` |
| Instalador | Calamares |
| Sistema de archivos por defecto | ext4 |

## 2. Público objetivo

Una sola ISO pensada para tres perfiles:

- **Equipos antiguos**: debe funcionar bien con **2 GB de RAM**.
- **Escritorio general**: usuarios que vienen de Windows o macOS.
- **Desarrolladores**: herramientas disponibles como pack opcional.

Estrategia: **base ligera + extras**. La ISO instala un sistema ligero y una app
de bienvenida ofrece instalar packs opcionales después.

## 3. Escritorio e identidad visual

| Aspecto | Decisión |
|---|---|
| Entorno de escritorio | Cinnamon |
| Estilo | Oscuro moderno (modo claro disponible) |
| Color de acento | Verde azulado (teal) |
| Logo | Vórtice/espiral teal (boceto en `branding/logo/vortara-logo.svg`) |

## 4. Software

| Aspecto | Decisión |
|---|---|
| Firmware/drivers no libres | Incluidos (`non-free`, `non-free-firmware`, codecs) |
| Formatos de aplicaciones | APT + Flatpak (Flathub). Sin Snap |
| Navegador | Firefox ESR |

### Packs opcionales (app de bienvenida)

- **Desarrollo — Básico**: git, build-essential, Python, Geany y VSCodium
  (VSCodium vía Flatpak/repositorio oficial; Geany para equipos con poca RAM).
- **Desarrollo — Lenguajes extra**: Node.js, Go, Rust, Java (OpenJDK).
- **Ofimática / Multimedia**: LibreOffice, VLC, GIMP, Thunderbird.

## 5. Idioma

- Español por defecto (`es_ES.UTF-8`).
- El instalador permite elegir cualquier idioma y distribución de teclado.

## 6. Versiones y actualizaciones

| Aspecto | Decisión |
|---|---|
| Numeración | Año.mes, p. ej. `26.11` |
| Nombres en clave | Fenómenos naturales, en orden alfabético |
| Primera versión | **Vortara 26.11 "Aurora"** |
| Actualizaciones | Solo notificar; nada se instala automáticamente |

## 7. Repositorio APT propio

- Alojado en **GitHub Pages**, publicado con GitHub Actions desde este repositorio.
- Firmado con una clave GPG de Vortara.
- Contiene los paquetes propios: branding, tema, app de bienvenida y metapaquetes
  de los packs opcionales.

## 8. Detalles técnicos de la ISO

- Se construye **sin paquetes recomendados** para mantener la base ligera; los
  recomendados que sí hacen falta (WiFi, portales de Flatpak, gvfs, usuario
  live...) se listan explícitamente en `live-build/config/package-lists/`.
- El firmware se elige a mano (`firmware.list.chroot`). No se usa la opción de
  live-build que instala *todo* el firmware, porque incluye paquetes
  `*-installer` que descargan de internet al instalarse.
- El **initramfs** no incluye drivers de gráficas (se cargan desde el disco al
  arrancar) y va comprimido con zstd: pasa de ~220 MB a ~75 MB.
- Para Secure Boot, la entrada EFI se mantiene como `debian` (el GRUB firmado
  por Debian busca ahí su configuración). El menú de GRUB muestra "Vortara".
- Calamares desinstala del sistema instalado el propio instalador y las
  herramientas del modo live.
- La ISO lleva un pequeño repositorio (`pool/`, ~26 MB) con GRUB para UEFI
  (shim y GRUB firmados) y para BIOS, así que **se puede instalar sin
  Internet**. El sistema instalado conserva las fuentes de APT completas
  (main, contrib, non-free, non-free-firmware y backports).

## Pruebas

- **Instalación UEFI** (QEMU, 2 GB de RAM, sin red, borrando el disco):
  correcta. El sistema arranca con GRUB "Vortara", inicia sesión en Cinnamon,
  usa el kernel de backports, zram tiene prioridad sobre la swap del disco y
  ocupa 3,8 GB. Shim y GRUB firmados quedan en `EFI/debian`.

## Pendiente

- Probar la instalación en BIOS.
- Comprobar en la próxima ISO la presentación del instalador (faltaba `qml6-module-qtquick`, ya añadido).
- App de bienvenida con los packs opcionales (Desarrollo, Ofimática/Multimedia).
- Repositorio APT en GitHub Pages con los paquetes propios de Vortara.
- Tema de Cinnamon con acento teal e icono del menú con el logo de Vortara.
