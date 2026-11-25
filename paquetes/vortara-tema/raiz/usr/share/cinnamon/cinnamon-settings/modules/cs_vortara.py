#!/usr/bin/python3
# Vortara: «Estilo de Vortara» en Ajustes del sistema (Apariencia).
# Elige entre los dos estilos del escritorio: «Aero» (cristal translúcido) y
# «Terminal» (negro, minimalista y ligero). El cambio se aplica al reiniciar:
# /etc/X11/Xsession.d/90vortara-estilo llama a aplicar-estilo al entrar.
#
# Los textos están en español y se traducen con el dominio de la app de
# bienvenida (vortara-bienvenida), que ya tiene los idiomas de Vortara.
import gettext
import os
import subprocess
from pathlib import Path

from gi.repository import GLib, GdkPixbuf, Gtk

from SettingsWidgets import SidePage
from xapp.GSettingsWidgets import *  # noqa: F401,F403 (SettingsPage...)

DOMINIO = "vortara-bienvenida"
CONFIG = Path(GLib.get_user_config_dir()) / "vortara"
ELEGIDO = CONFIG / "estilo"
APLICADO = CONFIG / "estilo-aplicado"
VISTAS = "/usr/share/vortara/tema"

# Tarjetas de los estilos: la elegida, con borde teal (en los dos temas).
CSS = b"""
.vortara-tarjeta { border: 2px solid alpha(currentColor, 0.15); border-radius: 6px; padding: 6px;
                   background-image: none; background-color: transparent; box-shadow: none; }
.vortara-tarjeta:hover { border-color: alpha(#2dd4bf, 0.6); }
.vortara-tarjeta:checked { border-color: #2dd4bf; background-color: alpha(#2dd4bf, 0.10); }
"""


def _idioma():
    for variable in ("LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"):
        valor = os.environ.get(variable)
        if valor:
            return valor.split(":")[0].split(".")[0].split("@")[0]
    return ""


def _traduccion():
    """Como en la app de bienvenida: sin traducción y sin ser español, inglés."""
    idioma = _idioma()
    t = gettext.translation(DOMINIO, fallback=True)
    if type(t) is gettext.NullTranslations and idioma[:2] not in ("es", "", "C") and idioma != "POSIX":
        t = gettext.translation(DOMINIO, languages=["en"], fallback=True)
    return t.gettext


_ = _traduccion()


def _leer(ruta, defecto=""):
    try:
        valor = ruta.read_text().strip()
    except OSError:
        return defecto
    return valor if valor in ("aero", "terminal") else defecto


class Module:
    name = "vortara"
    comment = _("Elige el aspecto del escritorio: Aero o Terminal")
    category = "appear"

    def __init__(self, content_box):
        keywords = _("estilo, tema, aspecto, aero, terminal, vortara, minimalista, transparente")
        self.sidePage = SidePage(_("Estilo de Vortara"), "vortara-estilo", keywords, content_box, module=self)

    def on_module_selected(self):
        if self.loaded:
            return
        page = SettingsPage()
        self.sidePage.add_widget(page)
        section = page.add_section(_("Estilo del escritorio"),
                                   _("Cambia por completo el aspecto: ventanas, barra de tareas, iconos y fondo."))

        caja = Gtk.Box(spacing=24, margin=18, halign=Gtk.Align.CENTER, homogeneous=True)
        actual = _leer(ELEGIDO) or _leer(APLICADO, "aero")
        grupo = None
        self.botones = {}
        for estilo, titulo, texto in (
                ("aero", _("Aero"),
                 _("Cristal translúcido, fondos con brillo y la barra de tareas al estilo de Windows 7.")),
                ("terminal", _("Terminal"),
                 _("Negro, sencillo y ligero, como una terminal, con el toque teal de Vortara. Va mejor en equipos con pocos recursos."))):
            boton = Gtk.RadioButton.new_from_widget(grupo)
            grupo = grupo or boton
            boton.set_mode(False)
            estilo_css = Gtk.CssProvider()
            estilo_css.load_from_data(CSS)
            contexto = boton.get_style_context()
            contexto.add_provider(estilo_css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            contexto.add_class("vortara-tarjeta")
            contenido = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=8)
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(f"{VISTAS}/vista-{estilo}.png", 320, 180, True)
                contenido.add(Gtk.Image.new_from_pixbuf(pixbuf))
            except GLib.Error:
                pass
            etiqueta = Gtk.Label(xalign=0)
            etiqueta.set_markup(f"<b>{GLib.markup_escape_text(titulo)}</b>")
            contenido.add(etiqueta)
            descripcion = Gtk.Label(label=texto, xalign=0, wrap=True, max_width_chars=40)
            descripcion.get_style_context().add_class("dim-label")
            contenido.add(descripcion)
            boton.add(contenido)
            boton.set_active(estilo == actual)
            boton.connect("toggled", self._al_elegir, estilo)
            self.botones[estilo] = boton
            caja.add(boton)
        section.add_row(caja)

        self.aviso = Gtk.InfoBar(message_type=Gtk.MessageType.INFO, no_show_all=True)
        self.aviso.get_content_area().add(Gtk.Label(
            label=_("El nuevo estilo se aplicará al reiniciar el equipo."), wrap=True, xalign=0))
        self.aviso.add_button(_("Reiniciar ahora"), Gtk.ResponseType.ACCEPT)
        self.aviso.connect("response", self._reiniciar)
        self.aviso.get_content_area().show_all()
        page.pack_start(self.aviso, False, False, 0)
        self._actualizar_aviso()
        page.show_all()

    def _al_elegir(self, boton, estilo):
        if not boton.get_active():
            return
        CONFIG.mkdir(parents=True, exist_ok=True)
        ELEGIDO.write_text(estilo + "\n")
        self._actualizar_aviso()

    def _actualizar_aviso(self):
        pendiente = _leer(ELEGIDO) and _leer(ELEGIDO) != _leer(APLICADO, "aero")
        self.aviso.set_visible(bool(pendiente))

    def _reiniciar(self, _barra, respuesta):
        if respuesta != Gtk.ResponseType.ACCEPT:
            return
        try:
            subprocess.Popen(["cinnamon-session-quit", "--reboot"])
        except OSError:
            subprocess.Popen(["systemctl", "reboot"])
