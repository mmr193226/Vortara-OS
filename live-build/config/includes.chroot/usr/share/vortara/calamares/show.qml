/* Presentación de Vortara OS durante la instalación (Calamares, slideshowAPI 2).
 *
 * Los textos están en inglés, marcados con qsTr(). Calamares carga las
 * traducciones de lang/calamares-vortara_<idioma>.qm (en la carpeta del tema)
 * y las cambia en cuanto el usuario elige otro idioma; sin traducción, sale en
 * inglés. Las traducciones están en branding/presentacion/traducciones.json y
 * se compilan con scripts/compilar-presentacion.py.
 *
 * No edites los textos de abajo a mano: deben coincidir con «en» de ese JSON. */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        id: avance
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function onActivate() { presentation.currentSlide = 0 }
    function onLeave() { }

    component Diapositiva: Slide {
        property string titulo
        property string texto
        Column {
            anchors.centerIn: parent
            spacing: 18
            width: parent.width * 0.75
            Image {
                source: "vortara-logo.png"
                width: 128; height: 128
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: titulo
                color: "#0F766E"
                font.pixelSize: 28
                font.bold: true
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Text {
                text: texto
                color: "#1F2937"
                font.pixelSize: 17
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    Diapositiva { titulo: qsTr("Welcome to Vortara OS"); texto: qsTr("Version 26.11 “Aurora”, based on Debian 13.<br/>The installation carries on by itself; it will take a few minutes.") }
    Diapositiva { titulo: qsTr("Truly lightweight"); texto: qsTr("Designed to run well from 2 GB of RAM: a tuned Cinnamon desktop and compressed memory with zram.") }
    Diapositiva { titulo: qsTr("Thousands of applications"); texto: qsTr("Besides Debian's packages, you can install applications from Flathub with Flatpak.") }
    Diapositiva { titulo: qsTr("You decide when to update"); texto: qsTr("Vortara lets you know when updates are available, but never installs anything without your permission.") }
}
