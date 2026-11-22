#!/bin/bash
# Crea la clave GPG que firma el repositorio APT de Vortara.
#
# Ejecútalo UNA SOLA VEZ en tu ordenador (Linux, macOS, o Windows con WSL o
# Git Bash; hace falta gpg). No toca tus otras claves de gpg.
#
#   bash crear-clave-repo.sh
#
# Deja dos archivos en la carpeta donde lo ejecutes:
#   vortara-archive-keyring.asc  clave PÚBLICA: va en la ISO y en el repositorio.
#                                No es secreta.
#   vortara-clave-PRIVADA.asc    clave PRIVADA: es la que firma las
#                                actualizaciones. Pégala en el secreto de GitHub,
#                                guarda una copia en lugar seguro y no la
#                                compartas con nadie.
set -euo pipefail

command -v gpg >/dev/null || { echo "Necesitas gpg (en Debian/Ubuntu: sudo apt install gpg)." >&2; exit 1; }

publica="vortara-archive-keyring.asc"
privada="vortara-clave-PRIVADA.asc"
for f in "$publica" "$privada"; do
	if [ -e "$f" ]; then
		echo "Ya existe $f en esta carpeta. Muévelo o bórralo antes, para no perder una clave anterior." >&2
		exit 1
	fi
done

# Llavero temporal: la clave no se mezcla con las tuyas.
temporal="$(mktemp -d)"
trap 'rm -rf "$temporal"' EXIT
export GNUPGHOME="$temporal"
chmod 700 "$GNUPGHOME"

# Clave Ed25519 solo para firmar, sin contraseña (la usan las máquinas de
# GitHub sin nadie delante) y sin caducidad. La protección es el secreto de
# GitHub y tu copia guardada.
gpg --batch --quiet --passphrase '' \
	--quick-generate-key "Vortara OS (repositorio APT)" ed25519 sign never

huella="$(gpg --list-keys --with-colons 2>/dev/null | awk -F: '/^fpr/ {print $10; exit}')"
gpg --armor --export "$huella" > "$publica"
umask 077
gpg --armor --export-secret-keys "$huella" > "$privada"

cat <<EOF

Clave creada. Huella: $huella

Pasos:
 1. Abre $privada con un editor de texto y copia TODO su contenido
    (desde -----BEGIN PGP PRIVATE KEY BLOCK----- hasta -----END ...-----).
 2. En GitHub: Settings > Secrets and variables > Actions > New repository secret
      Name:   VORTARA_GPG_PRIVATE_KEY
      Secret: (pega el contenido)
 3. Guarda $privada en un lugar seguro (gestor de contraseñas, USB...) y
    bórralo de esta carpeta. Si se pierde, habría que crear otra clave.
 4. Envía a Claude el contenido de $publica (esa no es secreta) para meterla
    en la ISO, o súbela tú a:
    paquetes/vortara-archive-keyring/raiz/usr/share/keyrings/vortara-archive-keyring.asc
EOF
