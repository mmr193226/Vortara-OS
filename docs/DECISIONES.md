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

## 4. Software

| Aspecto | Decisión |
|---|---|
| Firmware/drivers no libres | Incluidos (`non-free`, `non-free-firmware`, codecs) |
| Formatos de aplicaciones | APT + Flatpak (Flathub). Sin Snap |
| Navegador | Firefox ESR |

### Packs opcionales (app de bienvenida)

- **Desarrollo — Básico**: git, build-essential, Python, editor de código.
- **Desarrollo — Lenguajes extra**: Node.js, Go, Rust, Java (OpenJDK).
- **Ofimática / Multimedia**: por definir.

## 5. Idioma

- Español por defecto (`es_ES.UTF-8`).
- El instalador permite elegir cualquier idioma y distribución de teclado.

## 6. Versiones y actualizaciones

| Aspecto | Decisión |
|---|---|
| Numeración | Año.mes, p. ej. `26.11` |
| Actualizaciones | Solo notificar; nada se instala automáticamente |

## Pendiente de decidir

- Logo y nombre de la versión (si tendrá nombre en clave).
- Contenido exacto del pack Ofimática / Multimedia.
- Editor de código del pack de Desarrollo (VSCodium, Geany…).
- Repositorio APT propio para paquetes de Vortara (alojamiento).
