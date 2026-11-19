// Genera las imágenes de Vortara a partir del logo SVG.
// Uso: node branding/generar-imagenes.js   (requiere Playwright con Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const raiz = path.resolve(__dirname, '..');
const logo = fs.readFileSync(path.join(raiz, 'branding/logo/vortara-logo.svg'), 'utf8');
const dest = path.join(raiz, 'live-build/config/includes.chroot');
const pixmaps = path.join(dest, 'usr/share/pixmaps');
const fondos = path.join(dest, 'usr/share/backgrounds/vortara');
fs.mkdirSync(pixmaps, { recursive: true });
fs.mkdirSync(fondos, { recursive: true });

const fuente = "'Noto Sans', 'DejaVu Sans', sans-serif";

const fondo = `
<body style="margin:0;width:1920px;height:1080px;overflow:hidden;
  background: radial-gradient(ellipse 70% 60% at 50% 45%, #0F3D38 0%, #0B1F1D 55%, #071211 100%);
  display:flex;align-items:center;justify-content:center;">
  <div style="width:520px;height:520px;opacity:.9;filter:drop-shadow(0 0 60px rgba(20,184,166,.35))">
    ${logo.replace('width="256" height="256"', 'width="520" height="520"')}
  </div>
</body>`;

const logoTexto = `
<body style="margin:0;background:transparent;display:flex;align-items:center;gap:20px;
  width:520px;height:128px;font-family:${fuente}">
  <div style="width:112px;height:112px">${logo.replace('width="256" height="256"', 'width="112" height="112"')}</div>
  <div style="color:#E6FFFA;font-size:64px;font-weight:600;letter-spacing:2px">Vortara</div>
</body>`;

const bienvenida = `
<body style="margin:0;width:800px;height:420px;background:transparent;
  display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:${fuente}">
  <div style="width:220px;height:220px">${logo.replace('width="256" height="256"', 'width="220" height="220"')}</div>
  <div style="color:#14B8A6;font-size:46px;font-weight:600;margin-top:18px">Vortara OS</div>
  <div style="color:#5EEAD4;font-size:22px;margin-top:6px">26.11 «Aurora»</div>
</body>`;

(async () => {
  const b = await chromium.launch();
  const shot = async (html, w, h, file, transparente) => {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.setContent(html);
    await p.screenshot({ path: file, omitBackground: !!transparente });
    await p.close();
  };
  await shot(fondo, 1920, 1080, path.join(fondos, 'aurora.png'));
  await shot(logoTexto, 520, 128, path.join(pixmaps, 'vortara-logo-text.png'), true);
  await shot(bienvenida, 800, 420, path.join(pixmaps, 'vortara-calamares-bienvenida.png'), true);
  for (const s of [16, 22, 24, 32, 48, 64, 128, 256]) {
    const html = `<body style="margin:0;background:transparent">${logo.replace('width="256" height="256"', `width="${s}" height="${s}"`)}</body>`;
    await shot(html, s, s, path.join(pixmaps, `vortara-logo-${s}.png`), true);
  }
  await b.close();
  console.log('Imágenes generadas en', dest);
})();
