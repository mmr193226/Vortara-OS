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
| Estilo | Oscuro, con cristal al estilo Aero de Windows 7 (tema «Vortara») |
| Color de acento | Verde azulado (teal) |
| Logo | Vórtice/espiral teal (boceto en `branding/logo/vortara-logo.svg`) |
| Barra de tareas | Abajo, 44 px, al estilo de Windows 7 |

### Tema «Vortara»

Diseño propio inspirado en Aero (no usa imágenes ni recursos de Windows):

- **GTK3** (`/usr/share/themes/Vortara/gtk-3.0`): parte de Adwaita-dark. Selección
  y botones principales en teal, cabeceras de cristal oscuro con brillo, botones
  de la barra de título como rectángulos de cristal (cerrar en rojo, los demás
  con brillo teal al pasar por encima).
- **Bordes de ventana**: Muffin (Cinnamon 6.4) ya no usa temas `metacity-1`;
  dibuja los bordes con el CSS del tema GTK, así que todas las ventanas comparten
  el mismo aspecto.
- **Cinnamon**: el gancho `0400-vortara-tema` copia el tema por defecto de
  Cinnamon, cambia sus azules por teal y le añade
  `/usr/share/vortara/tema/cinnamon-vortara.css`: panel de cristal translúcido,
  programas abiertos con marco de cristal (el activo con brillo teal) y menús de
  cristal. Al partir del tema del paquete, se adapta solo a nuevas versiones.
- **Barra**: orbe de Vortara como botón de inicio (`vortara-menu.svg`), programas
  anclados (Firefox ESR, Archivos, Terminal), reloj con fecha en dos líneas y la
  esquina derecha para mostrar el escritorio.
- Avatar de Vortara para los usuarios nuevos (`/etc/skel/.face`), el fondo en
  Configuración > Fondos y la pantalla de inicio de sesión con el mismo tema.
- No se usa transparencia con desenfoque: Cinnamon no la tiene de serie y
  costaría rendimiento en equipos con poca RAM.

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

La app de bienvenida (`vortara-bienvenida`, Python + GTK3):

- Sale al iniciar sesión hasta que se desmarca «Mostrar esta ventana al iniciar
  sesión». En la sesión live ofrece «Instalar Vortara» y los packs aparecen
  desactivados.
- Tres secciones: Inicio, Programas (los packs) y Primeros pasos (fondo,
  configuración, avisos de actualizaciones, impresoras, terminal, ayuda).
- Los packs están en `/usr/share/vortara/packs.json`. VSCodium se instala
  desde Flathub; lo demás desde los repositorios de Debian.
- Instala con `/usr/libexec/vortara/instalar-pack`, que se ejecuta con pkexec
  (pide la contraseña con un mensaje en español) y **solo acepta packs de esa
  lista**, nunca nombres de paquetes de fuera.
- Sin conexión avisa al momento; si un paquete falla al configurarse, lo
  repara y reintenta una vez; si apt está ocupado, espera.

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

- Alojado en **GitHub Pages** (<https://mmr193226.github.io/Vortara-OS/>),
  publicado con GitHub Actions (`.github/workflows/repositorio.yml`) al llevar
  cambios de `paquetes/` a la rama `main`.
- Suite `aurora`, componente `main` (el nombre de la versión).
- Firmado con una clave GPG de Vortara (Ed25519, solo firma). La **privada** la
  crea el responsable del proyecto en su ordenador con
  `scripts/crear-clave-repo.sh` y la guarda en el secreto
  `VORTARA_GPG_PRIVATE_KEY` de GitHub; nunca va al repositorio. La **pública**
  va en el paquete `vortara-archive-keyring`, que añade el repositorio a apt.
- Contiene los paquetes propios: `vortara-branding`, `vortara-tema`,
  `vortara-bienvenida`, `vortara-archive-keyring` y los metapaquetes
  `vortara-pack-*`. Detalles en `paquetes/LEEME.md`.
- La ISO instala los mismos paquetes (menos los packs), así que lo que se
  publique llega también a los equipos ya instalados.

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

- **GRUB en español**: la traducción de Debian es de 2019 y no tiene los textos
  del menú de las versiones nuevas. El gancho `0500-vortara-grub-es` añade los
  que faltan («Opciones avanzadas para…», «Cargando Linux…», «modo de
  recuperación», «Configuración del firmware UEFI») sin tocar los demás, y
  aparta el catálogo original con `dpkg-divert` para que las actualizaciones
  de GRUB no lo pisen.

## Pruebas

- **Instalación UEFI** (QEMU, 2 GB de RAM, sin red, borrando el disco):
  correcta. El sistema arranca con GRUB "Vortara", inicia sesión en Cinnamon,
  usa el kernel de backports, zram tiene prioridad sobre la swap del disco y
  ocupa 3,8 GB. Shim y GRUB firmados quedan en `EFI/debian`.
- **Instalación BIOS** (tabla MSDOS, GRUB en el MBR): correcta, con los mismos
  resultados.
- **Presentación del instalador**: se ve y avanza sola (hacían falta los
  módulos QML `qtquick` y `qtquick-window`, que Calamares no declara).
- **GRUB del sistema instalado**: fondo y colores de Vortara, aplicados por el
  propio instalador.
- **Icono «Instalar Vortara»**: aparece una sola vez y abre el instalador
  directamente. Sin disco, el instalador avisa y no deja continuar.
- **Tema Vortara** (instalación UEFI nueva): el sistema instalado arranca con
  el tema, la barra al estilo Windows 7, el orbe y el avatar de Vortara; el
  inicio de sesión muestra el usuario y pide solo la contraseña.
- **App de bienvenida**: los tres packs se instalaron desde la app (VSCodium
  incluido) y quedaron marcados como instalados. En el sistema instalado sale
  al iniciar sesión, pide la contraseña con polkit y, sin red, avisa al momento.

## Pendiente

- Repositorio APT en GitHub Pages con los paquetes propios de Vortara.
