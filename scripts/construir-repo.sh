#!/bin/bash
# Monta el repositorio APT de Vortara a partir de los .deb y lo firma.
#
# Uso: ./scripts/construir-repo.sh CARPETA_DEBS CARPETA_REPO
#
# Para firmar, la clave privada de Vortara tiene que estar en el llavero de
# gpg (en GitHub Actions se importa del secreto VORTARA_GPG_PRIVATE_KEY). Sin
# clave, el repositorio se monta igual pero sin firmar: sirve para probarlo,
# no para publicarlo.
#
# Estructura (la que espera /etc/apt/sources.list.d/vortara.sources):
#   pool/main/*.deb
#   dists/aurora/{Release,InRelease,Release.gpg}
#   dists/aurora/main/binary-amd64/Packages(.gz)
#   vortara-archive-keyring.asc   (clave pública, para descargarla a mano)
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
. "$RAIZ/live-build/vortara.conf"
DEBS="$(cd "$1" && pwd)"
REPO="$(mkdir -p "$2" && cd "$2" && pwd)"
SUITE="$VORTARA_CODENAME"
CLAVE_PUBLICA="$RAIZ/paquetes/vortara-archive-keyring/raiz/usr/share/keyrings/vortara-archive-keyring.asc"

command -v apt-ftparchive >/dev/null || { echo "Falta apt-ftparchive (paquete apt-utils)." >&2; exit 1; }

mkdir -p "$REPO/pool/main" "$REPO/dists/$SUITE/main/binary-amd64"
cp "$DEBS"/*.deb "$REPO/pool/main/"

cd "$REPO"
# Los paquetes de Vortara son «all»: se listan para amd64, la arquitectura de la ISO.
apt-ftparchive packages pool/main > "dists/$SUITE/main/binary-amd64/Packages"
gzip -9 -k -f "dists/$SUITE/main/binary-amd64/Packages"
apt-ftparchive \
	-o APT::FTPArchive::Release::Origin="Vortara" \
	-o APT::FTPArchive::Release::Label="Vortara" \
	-o APT::FTPArchive::Release::Suite="$SUITE" \
	-o APT::FTPArchive::Release::Codename="$SUITE" \
	-o APT::FTPArchive::Release::Version="$VORTARA_VERSION" \
	-o APT::FTPArchive::Release::Architectures="amd64" \
	-o APT::FTPArchive::Release::Components="main" \
	-o APT::FTPArchive::Release::Description="Vortara OS $VORTARA_VERSION ($VORTARA_CODENAME_PRETTY)" \
	release "dists/$SUITE" > "dists/$SUITE/Release.tmp"
mv "dists/$SUITE/Release.tmp" "dists/$SUITE/Release"

if gpg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
	gpg --batch --yes --armor --detach-sign -o "dists/$SUITE/Release.gpg" "dists/$SUITE/Release"
	gpg --batch --yes --clearsign -o "dists/$SUITE/InRelease" "dists/$SUITE/Release"
	echo ">> Repositorio firmado."
else
	echo ">> Aviso: no hay clave privada en gpg; el repositorio queda SIN FIRMAR." >&2
fi

[ -f "$CLAVE_PUBLICA" ] && cp "$CLAVE_PUBLICA" "$REPO/vortara-archive-keyring.asc"

# Página de presentación (GitHub Pages muestra index.html en la raíz).
cat > "$REPO/index.html" <<EOF
<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Repositorio de Vortara OS</title>
<style>
body{font-family:system-ui,sans-serif;max-width:46rem;margin:2rem auto;padding:0 1rem;
background:#0B1F1D;color:#E6FFFA;line-height:1.5}
a{color:#5EEAD4} code,pre{background:#123331;border-radius:6px}
pre{padding:.8rem;overflow-x:auto} code{padding:.1rem .3rem}
</style></head><body>
<h1>Repositorio APT de Vortara OS</h1>
<p>Paquetes propios de <a href="https://github.com/mmr193226/Vortara-OS">Vortara OS</a>
$VORTARA_VERSION «$VORTARA_CODENAME_PRETTY»: tema, app de bienvenida, identidad visual y packs.</p>
<p>Vortara ya viene con este repositorio configurado. No hace falta hacer nada.</p>
<p>Clave pública: <a href="vortara-archive-keyring.asc">vortara-archive-keyring.asc</a></p>
<h2>Paquetes</h2>
<pre>$(cd pool/main && ls *.deb)</pre>
</body></html>
EOF
echo ">> Repositorio listo en $REPO"
