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
- **Cristal esmerilado de verdad**: la barra es translúcida y, debajo, la
  extensión `vortara-cristal@vortara` (activada por defecto) pone el fondo de
  pantalla desenfocado. Cinnamon no tiene desenfoque en vivo, y hacerlo en cada
  fotograma costaría rendimiento; por eso el desenfoque se calcula una sola vez
  (GdkPixbuf: reducir y volver a ampliar) y solo se repite si cambia el fondo,
  la pantalla o la barra. Los menús son de cristal translúcido sin desenfoque.
- Las barras de título no son transparentes: GTK3 pinta el fondo de la ventana
  debajo, y Muffin solo hace transparentes los marcos de ventanas con canal alfa.
- **Fondos «Aero»** (`aero.jpg`, `cielo.jpg`, `noche.jpg`, 2560×1440): se dibujan
  con código (`scripts/generar-fondos.py`: degradados, cintas de luz, rayos y
  burbujas), así que son propios y de dominio público (CC0). El de por defecto
  es `aero.jpg`; `aurora.png` sigue disponible.

### Dos estilos: «Aero» y «Terminal»

El escritorio tiene dos estilos que lo cambian por completo. Se eligen en
**Ajustes del sistema > Estilo de Vortara** (módulo
`cinnamon-settings/modules/cs_vortara.py`) y se aplican **al reiniciar**:

- **Aero** (por defecto): todo lo descrito arriba. Ahora más transparente:
  barra, menús, Alt+Tab, notificaciones, menús y ayudas de GTK translúcidos, y
  la Terminal con un 18 % de transparencia.
- **Terminal**: negro, plano y ligero. Tema GTK `Vortara-Terminal` (sin
  degradados ni sombras, esquinas rectas, acento teal), tema de Cinnamon con la
  misma idea (`cinnamon-terminal.css`), letra DejaVu Sans Mono, iconos Adwaita
  (sencillos), barra fina de 30 px con «>_ vortara» como menú, lista de
  ventanas en texto y reloj solo con la hora, fondo `terminal.jpg`, sin efectos
  ni animaciones ni la extensión de cristal, y la Terminal en negro con cursor
  teal.

Cómo funciona:

- La elección se guarda en `~/.config/vortara/estilo` (cada usuario la suya).
- Al entrar en la sesión, antes de que arranque Cinnamon,
  `/etc/X11/Xsession.d/90vortara-estilo` llama a
  `/usr/libexec/vortara/aplicar-estilo --pendiente`, que aplica el estilo si
  aún no está aplicado (`~/.config/vortara/estilo-aplicado`). Así el cambio es
  de una vez y completo, sin medias tintas con el escritorio en marcha.
- «Aero» son los valores de `90_vortara.gschema.override`: volver a él es
  devolver las claves a su valor por defecto. Al cambiar de estilo se
  restablecen la barra, el fondo y el tema (lo que el usuario hubiera cambiado
  a mano en ellos se pierde).
- La barra «Terminal» usa applets con número propio (100-110) y sus ajustes se
  escriben en `~/.config/cinnamon/spices/` antes de que Cinnamon los cargue.
- Los textos del módulo se traducen con el dominio de la app de bienvenida.
- Probado con Cinnamon 6.4 en una pantalla virtual: Aero → Terminal → Aero.

### Cursor en máquinas virtuales

En VirtualBox, VMware, Hyper-V y QEMU, el cursor «por hardware» a menudo no se
ve (el ratón funciona, pero la flecha no aparece). `vortara-tema` instala
`/usr/share/X11/xorg.conf.d/20-vortara-cursor-maquina-virtual.conf`, que pide a
Xorg usar el controlador modesetting y dibujar el cursor por software solo con
tarjetas gráficas virtuales (`MatchDriver`: vmwgfx, vboxvideo, virtio_gpu, qxl,
bochs, cirrus, hyperv_drm). En equipos reales no cambia nada.

La primera versión (vortara-tema 26.11.3) no ponía `Driver "modesetting"` en la
sección `OutputClass`: así Xorg no carga ningún controlador («no screens
found»), LightDM se rinde y el equipo se queda en la pantalla de texto (tty1).
Corregido en 26.11.4 y probado en QEMU: el escritorio arranca y se ve el cursor.
La comprobación de los pull requests revisa ahora que ninguna `OutputClass`
quede sin `Driver`.

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
- Lo propio de Vortara está traducido a **inglés, portugués (de Portugal y de
  Brasil), francés, alemán, italiano y catalán**: la app de bienvenida, sus
  lanzadores y el mensaje de la contraseña, el lanzador del instalador y su
  presentación, el menú de GRUB y la descripción del tema. Si el idioma del
  usuario no tiene traducción, la app sale en **inglés**, no en español.
- El pack de ofimática instala los diccionarios, la ayuda y el idioma de
  LibreOffice y Thunderbird del idioma del usuario.
- El reloj de la barra muestra la fecha con el formato de cada idioma.
- Las traducciones de la app están en `paquetes/vortara-bienvenida/po/` (formato
  `.po`, editable con Poedit); `scripts/traducciones.py` las extrae, comprueba
  y compila. Las de GRUB, en
  `paquetes/vortara-branding/raiz/usr/share/vortara/grub/traducciones.json`.
- La presentación del instalador tiene los textos en inglés con `qsTr()`;
  Calamares carga `lang/calamares-vortara_<idioma>.qm` del tema y los cambia al
  elegir idioma (sin traducción, sale en inglés). Las traducciones están en
  `branding/presentacion/traducciones.json`; `scripts/compilar-presentacion.py`
  genera los `.ts` y los compila con `lrelease` (paquete `qt6-l10n-tools`). Los
  `.qm` se guardan en el repositorio, así que la ISO no necesita `lrelease`.

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
  de GRUB no lo pisen. Además, la configuración de GRUB de Vortara toma el
  idioma de `/etc/default/locale`: el instalador y algunas actualizaciones del
  kernel ejecutan `update-grub` sin idioma, y el menú salía en inglés. (Ahora
  todo esto vive en el paquete `vortara-branding`.)

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
- **Instalación en francés** (UEFI): el instalador cambia al francés y pone el
  teclado francés; el sistema instalado arranca con GRUB en francés («Options
  avancées pour Vortara GNU/Linux», «Paramètres du micrologiciel UEFI») y la
  app de bienvenida en francés, con el pack de ofimática «dans votre langue».
  La presentación seguía en español: se corrigió después con las traducciones
  de Calamares (comprobadas con el motor QML de Qt).
- **Repositorio APT publicado** (<https://mmr193226.github.io/Vortara-OS/>):
  GitHub Actions lo firma con la clave del secreto y lo publica; apt acepta la
  firma y ve todos los paquetes. Una actualización real (vortara-branding
  26.11.1 → 26.11.2) se descargó del repositorio y se instaló. La ISO final
  ya trae el repositorio configurado con la clave.
- **Paquetes propios** (ISO con `paquetes/`, instalación UEFI nueva): los
  paquetes se instalan bien en la ISO; el menú de GRUB del sistema instalado
  sale entero en español incluso si `update-grub` se ejecuta con `LC_ALL=C`;
  el avatar de Vortara se pone al iniciar sesión. Los disparadores funcionan
  al actualizar Cinnamon y grub-common, y al desinstalar todo vuelve a Debian.
- **Tema Vortara** (instalación UEFI nueva): el sistema instalado arranca con
  el tema, la barra al estilo Windows 7, el orbe y el avatar de Vortara; el
  inicio de sesión muestra el usuario y pide solo la contraseña.
- **App de bienvenida**: los tres packs se instalaron desde la app (VSCodium
  incluido) y quedaron marcados como instalados. En el sistema instalado sale
  al iniciar sesión, pide la contraseña con polkit y, sin red, avisa al momento.

## Pendiente

Todo lo decidido al principio está hecho. Ideas para más adelante:

- Probar en equipos reales antiguos (2 GB de RAM) además de la máquina virtual.
