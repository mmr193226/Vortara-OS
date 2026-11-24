// Cristal de Vortara: pone bajo cada barra (panel) una copia desenfocada del
// fondo de pantalla. Como la barra es translúcida, se ve a través de ella el
// fondo borroso, como el cristal de Aero.
//
// El desenfoque se calcula una sola vez con GdkPixbuf (se reduce la imagen y
// se vuelve a ampliar), así que no gasta nada al dibujar: va bien en equipos
// sin aceleración gráfica. Se recalcula si cambia el fondo, la pantalla o
// una barra.
const Clutter = imports.gi.Clutter;
const Cogl = imports.gi.Cogl;
const GdkPixbuf = imports.gi.GdkPixbuf;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Main = imports.ui.main;

const REDUCCION = 28;      // cuánto se reduce la imagen: más = más borroso

let ajustes = null;
let senalesAjustes = [];
let senalesGlobales = [];
let capas = [];            // { panel, actor, senales }
let pendiente = 0;
let cache = null;          // { clave, pixbuf } fondo desenfocado por monitor

function init(_meta) {}

function enable() {
    ajustes = new Gio.Settings({ schema_id: "org.cinnamon.desktop.background" });
    for (let clave of ["picture-uri", "picture-options", "primary-color", "picture-opacity"])
        senalesAjustes.push(ajustes.connect("changed::" + clave, () => { cache = null; programar(); }));
    senalesGlobales.push([Main.layoutManager, Main.layoutManager.connect("monitors-changed", programar)]);
    senalesGlobales.push([global.settings, global.settings.connect("changed::panels-enabled", programar)]);
    senalesGlobales.push([global.settings, global.settings.connect("changed::panels-height", programar)]);
    programar();
}

function disable() {
    if (pendiente) {
        GLib.source_remove(pendiente);
        pendiente = 0;
    }
    quitarCapas();
    for (let id of senalesAjustes) ajustes.disconnect(id);
    senalesAjustes = [];
    for (let [obj, id] of senalesGlobales) obj.disconnect(id);
    senalesGlobales = [];
    ajustes = null;
    cache = null;
}

// Espera un poco: al arrancar, o al cambiar varias cosas a la vez, las barras
// aún se están colocando.
function programar() {
    if (pendiente) GLib.source_remove(pendiente);
    pendiente = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 400, () => {
        pendiente = 0;
        try {
            reconstruir();
        } catch (e) {
            global.logError("Cristal de Vortara: " + e);
        }
        return GLib.SOURCE_REMOVE;
    });
}

function quitarCapas() {
    for (let c of capas) {
        for (let id of c.senales) c.panel.actor.disconnect(id);
        Main.layoutManager.removeChrome(c.actor);
        c.actor.destroy();
    }
    capas = [];
}

function reconstruir() {
    quitarCapas();
    for (let panel of Main.panelManager.panels) {
        if (!panel || !panel.actor) continue;
        let actor = new Clutter.Actor({ reactive: false });
        Main.layoutManager.addChrome(actor, {
            affectsStruts: false, affectsInputRegion: false, visibleInFullscreen: false
        });
        actor.get_parent().set_child_below_sibling(actor, panel.actor);
        let capa = { panel: panel, actor: actor, senales: [], clave: "" };
        let seguir = () => ajustarCapa(capa);
        for (let prop of ["allocation", "visible", "opacity", "translation-x", "translation-y"])
            capa.senales.push(panel.actor.connect("notify::" + prop, seguir));
        capas.push(capa);
        ajustarCapa(capa);
    }
}

// Coloca la capa justo debajo de la barra y le pone su trozo de fondo.
function ajustarCapa(capa) {
    let p = capa.panel.actor;
    let monitor = Main.layoutManager.monitors[capa.panel.monitorIndex];
    if (!monitor) return;
    let [x, y] = p.get_transformed_position();
    let [w, h] = p.get_transformed_size();
    x = Math.round(x); y = Math.round(y);
    w = Math.round(w); h = Math.round(h);
    capa.actor.set_position(x, y);
    capa.actor.set_size(w, h);
    capa.actor.visible = p.visible && w > 0 && h > 0;
    capa.actor.opacity = p.opacity;
    if (!capa.actor.visible) return;

    // Solo se recorta otra vez si la barra se ha movido o cambiado de tamaño.
    let clave = [monitor.x, monitor.y, monitor.width, monitor.height, x, y, w, h].join(",");
    if (clave == capa.clave) return;
    capa.clave = clave;
    try {
        let fondo = fondoDesenfocado(monitor);
        // Parte del fondo que queda bajo la barra (en coordenadas del monitor).
        let rx = Math.max(0, x - monitor.x), ry = Math.max(0, y - monitor.y);
        let rw = Math.min(w, monitor.width - rx), rh = Math.min(h, monitor.height - ry);
        if (rw <= 0 || rh <= 0) return;
        let trozo = fondo.new_subpixbuf(rx, ry, rw, rh).copy();
        let imagen = new Clutter.Image();
        imagen.set_data(trozo.get_pixels(),
                        trozo.get_has_alpha() ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                        rw, rh, trozo.get_rowstride());
        capa.actor.set_content(imagen);
    } catch (e) {
        global.logError("Cristal de Vortara: " + e);
        capa.actor.set_content(null);
    }
}

function colorLiso(texto, w, h) {
    let m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.exec(texto || "");
    let pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, false, 8, w, h);
    pb.fill(m ? (parseInt(m[1] + m[2] + m[3], 16) << 8 | 0xff) >>> 0 : 0x0b1f1dff);
    return pb;
}

// Fondo de pantalla del tamaño del monitor, tal como lo pinta Cinnamon con la
// opción «zoom» (lo cubre entero, recortando lo que sobra), ya desenfocado.
function fondoDesenfocado(monitor) {
    let uri = ajustes.get_string("picture-uri");
    let opcion = ajustes.get_string("picture-options");
    let w = monitor.width, h = monitor.height;
    let clave = [uri, opcion, w, h].join("|");
    if (cache && cache.clave == clave) return cache.pixbuf;

    let pb = null;
    if (opcion != "none" && uri) {
        try {
            let ruta = Gio.File.new_for_uri(uri).get_path();
            let original = GdkPixbuf.Pixbuf.new_from_file(ruta);
            let ow = original.get_width(), oh = original.get_height();
            let escala = opcion == "stretched" ? null
                       : (opcion == "scaled" || opcion == "centered")
                         ? Math.min(w / ow, h / oh) : Math.max(w / ow, h / oh);
            // Se trabaja ya en pequeño: es lo que se va a desenfocar.
            let pw = Math.max(1, Math.round(w / REDUCCION)), ph = Math.max(1, Math.round(h / REDUCCION));
            pb = colorLiso(ajustes.get_string("primary-color"), pw, ph);
            if (escala === null) {
                original.scale(pb, 0, 0, pw, ph, 0, 0, pw / ow, ph / oh, GdkPixbuf.InterpType.HYPER);
            } else {
                let s = escala / REDUCCION;
                let dw = ow * s, dh = oh * s;
                let ox = (pw - dw) / 2, oy = (ph - dh) / 2;
                let dx = Math.max(0, Math.round(ox)), dy = Math.max(0, Math.round(oy));
                let ancho = Math.min(pw, Math.round(ox + dw)) - dx;
                let alto = Math.min(ph, Math.round(oy + dh)) - dy;
                if (ancho > 0 && alto > 0)
                    original.composite(pb, dx, dy, ancho, alto, ox, oy, s, s,
                                       GdkPixbuf.InterpType.HYPER, 255);
            }
        } catch (e) {
            global.logError("Cristal de Vortara: no se puede leer el fondo: " + e);
            pb = null;
        }
    }
    if (!pb)
        pb = colorLiso(ajustes.get_string("primary-color"),
                       Math.max(1, Math.round(w / REDUCCION)), Math.max(1, Math.round(h / REDUCCION)));
    // Se amplía en dos pasos con interpolación bilineal: queda suave, sin cuadros.
    let medio = pb.scale_simple(Math.max(1, Math.round(w / 5)), Math.max(1, Math.round(h / 5)),
                                GdkPixbuf.InterpType.BILINEAR);
    let grande = medio.scale_simple(w, h, GdkPixbuf.InterpType.BILINEAR);
    cache = { clave: clave, pixbuf: grande };
    return grande;
}
