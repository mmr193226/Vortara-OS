/* Presentación de Vortara OS durante la instalación (Calamares, slideshowAPI 2). */
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

    Diapositiva {
        titulo: "Bienvenido a Vortara OS"
        texto: "Versión 26.11 «Aurora», basada en Debian 13.<br/>La instalación sigue sola; tardará unos minutos."
    }
    Diapositiva {
        titulo: "Ligero de verdad"
        texto: "Pensado para ir bien desde 2 GB de RAM: escritorio Cinnamon ajustado y memoria comprimida con zram."
    }
    Diapositiva {
        titulo: "Miles de aplicaciones"
        texto: "Además de los paquetes de Debian, puedes instalar aplicaciones de Flathub con Flatpak."
    }
    Diapositiva {
        titulo: "Tú decides cuándo actualizar"
        texto: "Vortara te avisa cuando hay actualizaciones, pero nunca instala nada sin tu permiso."
    }
}
