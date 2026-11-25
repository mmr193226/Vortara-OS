# Paquetes propios de Vortara

Todo lo que es propio de Vortara y se puede actualizar en los equipos ya
instalados va en paquetes `.deb`. La ISO los instala, y el repositorio APT de
Vortara (<https://mmr193226.github.io/Vortara-OS/>) publica sus versiones nuevas.

| Paquete | Qué lleva |
|---|---|
| `vortara-branding` | Logo, fondos (`scripts/generar-fondos.py` crea los «Aero»), aspecto de GRUB y su traducción completa al español |
| `vortara-tema` | Estilos «Aero» y «Terminal» (GTK y Cinnamon) y su selector en Ajustes del sistema, cristal esmerilado tras la barra, barra estilo Windows 7, avatar, inicio de sesión, cursor en máquinas virtuales |
| `vortara-bienvenida` | App de bienvenida y la lista de packs (`packs.json`) |
| `vortara-archive-keyring` | Clave pública y dirección del repositorio |
| `vortara-pack-*` | Metapaquetes de los packs; se generan solos a partir de `packs.json` |

Cada carpeta tiene:

- `DEBIAN/`: el `control` (nombre, **versión**, dependencias) y los scripts
  (`postinst`, `triggers`...).
- `raiz/`: los archivos tal como quedan en el sistema (`raiz/usr/bin/...`).

## Publicar una actualización

1. Cambia los archivos del paquete.
2. **Sube la versión** en `DEBIAN/control` (por ejemplo `26.11.1` → `26.11.2`).
   Si no se sube, apt no ve que haya nada nuevo. Para los packs, la versión es
   la de `vortara-bienvenida`.
3. Lleva los cambios a la rama `main`. GitHub Actions
   (`.github/workflows/repositorio.yml`) construye los paquetes, los firma y
   publica el repositorio. Los equipos con Vortara verán el aviso de
   actualización.

## Traducciones

- **App de bienvenida**: los textos están en español en el código, marcados con
  `_("...")`. Las traducciones, en `vortara-bienvenida/po/<idioma>.po`.
  - El módulo «Estilo de Vortara» de Ajustes (en `vortara-tema`) usa el
    mismo dominio y la misma lista de traducciones.
  - Tras cambiar textos de la app, del módulo o de `packs.json`:
    `python3 scripts/traducciones.py extraer` (añade los textos nuevos a
    todos los `.po`) y traducirlos.
  - Para un idioma nuevo: copiar `po/vortara-bienvenida.pot` a
    `po/<código>.po` (por ejemplo `nl.po`) y traducirlo. Si el pack de
    ofimática tiene paquetes de idioma para él, añadirlos en `por_idioma`
    de `packs.json`.
  - `python3 scripts/traducciones.py comprobar` revisa que todo esté al día;
    también lo hace GitHub en cada pull request.
- **GRUB**: `vortara-branding/raiz/usr/share/vortara/grub/traducciones.json`.
  Un idioma nuevo hay que añadirlo también en `DEBIAN/preinst`, `DEBIAN/postrm`
  y `DEBIAN/triggers` (la comprobación avisa si no coinciden).

## Probar en local

```bash
./scripts/construir-paquetes.sh salida/paquetes
```

```bash
./scripts/construir-repo.sh salida/paquetes salida/repo
```

`construir-repo.sh` necesita `apt-ftparchive` (paquete `apt-utils`) y, para
firmar, la clave privada en gpg. Sin ella monta el repositorio sin firmar,
y apt no lo acepta: sirve solo para revisar la estructura.

## Detalles

- `vortara-tema` genera el tema de Cinnamon a partir del tema por defecto del
  paquete `cinnamon` y ajusta los valores por defecto de sus applets. Un
  disparador de dpkg lo repite cada vez que Cinnamon se actualiza.
- `vortara-branding` aparta con `dpkg-divert` la traducción de GRUB de Debian y
  pone una completa; otro disparador la regenera si `grub-common` se actualiza.
- Al desinstalar, los dos dejan el sistema como estaba en Debian.
