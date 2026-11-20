// Genera las imágenes de Vortara a partir del logo SVG.
// Uso: node branding/generar-imagenes.js   (requiere Playwright con Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const raiz = path.resolve(__dirname, '..');
const logo = fs.readFileSync(path.join(raiz, 'branding/logo/vortara-logo.svg'), 'utf8');
// Cada imagen va al paquete que la instala (paquetes/<nombre>/raiz) o, si
// solo la usa la ISO (el instalador), a live-build/config/includes.chroot.
const branding = path.join(raiz, 'paquetes/vortara-branding/raiz');
const tema = path.join(raiz, 'paquetes/vortara-tema/raiz');
const iso = path.join(raiz, 'live-build/config/includes.chroot');
const pixmaps = path.join(branding, 'usr/share/pixmaps');
const fondos = path.join(branding, 'usr/share/backgrounds/vortara');
const pixmapsTema = path.join(tema, 'usr/share/pixmaps');
const pixmapsIso = path.join(iso, 'usr/share/pixmaps');
for (const d of [pixmaps, fondos, pixmapsTema, pixmapsIso]) fs.mkdirSync(d, { recursive: true });

const fuente = "'Noto Sans', 'DejaVu Sans', sans-serif";

const fondo = `
<body style="margin:0;width:1920px;height:1080px;overflow:hidden;
  background: radial-gradient(ellipse 70% 60% at 50% 45%, #0F3D38 0%, #0B1F1D 55%, #071211 100%);
  display:flex;align-items:center;justify-content:center;">
  <div style="width:520px;height:520px;opacity:.9;filter:drop-shadow(0 0 60px rgba(20,184,166,.35))">
    ${logo.replace('width="256" height="256"', 'width="520" height="520"')}
  </div>
</body>`;

// Fondo del menú de GRUB del sistema instalado (4:3, se estira a la pantalla).
// El logo va pequeño y en una esquina para no quedar debajo del texto del menú.
const grub = `
<body style="margin:0;width:1024px;height:768px;overflow:hidden;position:relative;
  background: radial-gradient(ellipse 80% 70% at 50% 40%, #0F3D38 0%, #0B1F1D 60%, #071211 100%);">
  <div style="position:absolute;right:40px;bottom:36px;width:120px;height:120px;opacity:.35">
    ${logo.replace('width="256" height="256"', 'width="120" height="120"')}
  </div>
</body>`;

const logoTexto = `
<body style="margin:0;background:transparent;display:flex;align-items:center;gap:12px;
  width:240px;height:64px;font-family:${fuente}">
  <div style="width:56px;height:56px">${logo.replace('width="256" height="256"', 'width="56" height="56"')}</div>
  <div style="color:#E6FFFA;font-size:32px;font-weight:600;letter-spacing:1px">Vortara</div>
</body>`;

const bienvenida = `
<body style="margin:0;width:800px;height:420px;background:transparent;
  display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:${fuente}">
  <div style="width:220px;height:220px">${logo.replace('width="256" height="256"', 'width="220" height="220"')}</div>
  <div style="color:#14B8A6;font-size:46px;font-weight:600;margin-top:18px">Vortara OS</div>
  <div style="color:#5EEAD4;font-size:22px;margin-top:6px">26.11 «Aurora»</div>
</body>`;

// Orbe del botón de inicio (estilo Aero): esfera de cristal oscuro con borde
// teal, brillo arriba y el logo dentro. Es un SVG, así que se ve nítido a
// cualquier tamaño del panel.
const interiorLogo = logo
  .replace(/^[\s\S]*?<defs>/, '<defs>')
  .replace(/<\/svg>\s*$/, '')
  .replace('<title>Vortara</title>', '');
const orbe = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <radialGradient id="orbe-fondo" cx="128" cy="150" r="130" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#11524C"/>
      <stop offset="0.65" stop-color="#082A27"/>
      <stop offset="1" stop-color="#03100F"/>
    </radialGradient>
    <linearGradient id="orbe-borde" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#99F6E4"/>
      <stop offset="1" stop-color="#0F766E"/>
    </linearGradient>
    <linearGradient id="orbe-brillo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <circle cx="128" cy="128" r="120" fill="url(#orbe-fondo)" stroke="url(#orbe-borde)" stroke-width="8"/>
  <g transform="translate(128 132) scale(0.72) translate(-128 -128)">${interiorLogo}</g>
  <ellipse cx="128" cy="70" rx="86" ry="50" fill="url(#orbe-brillo)"/>
</svg>
`;

(async () => {
  const b = await chromium.launch();
  const shot = async (html, w, h, file, transparente) => {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.setContent(html);
    await p.screenshot({ path: file, omitBackground: !!transparente });
    await p.close();
  };
  await shot(fondo, 1920, 1080, path.join(fondos, 'aurora.png'));
  await shot(grub, 1024, 768, path.join(fondos, 'grub.png'));
  await shot(logoTexto, 240, 64, path.join(pixmaps, 'vortara-logo-text.png'), true);
  await shot(bienvenida, 800, 420, path.join(pixmapsIso, 'vortara-calamares-bienvenida.png'), true);
  for (const s of [16, 22, 24, 32, 48, 64, 128, 256]) {
    const html = `<body style="margin:0;background:transparent">${logo.replace('width="256" height="256"', `width="${s}" height="${s}"`)}</body>`;
    await shot(html, s, s, path.join(pixmaps, `vortara-logo-${s}.png`), true);
  }
  const iconos = path.join(tema, 'usr/share/icons/hicolor/scalable/apps');
  fs.mkdirSync(iconos, { recursive: true });
  fs.writeFileSync(path.join(iconos, 'vortara-menu.svg'), orbe);
  // Avatar por defecto de los usuarios nuevos (/etc/skel/.face).
  await shot(`<body style="margin:0;background:transparent">${orbe}</body>`, 256, 256,
    path.join(pixmapsTema, 'vortara-avatar.png'), true);
  await shot(`<body style="margin:0;background:#222">${orbe}</body>`, 256, 256,
    path.join(raiz, 'branding/logo/vortara-menu-vista.png'));
  await b.close();
  console.log('Imágenes generadas en paquetes/ y live-build/config/includes.chroot');
})();
