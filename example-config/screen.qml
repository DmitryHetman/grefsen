import QtQuick 2.6
import Grefsen 1.0 as Grefsen

Image {
    fillMode: Image.PreserveAspectCrop
    source: Grefsen.env.home + ".config/grefsen/Oslo_mot_Grefsentoppen_fra_Ekeberg.jpg"
    //source: "qrc:/images/background.jpg"

    Grefsen.LeftSlidePanel {
        id: leftPanel
        Text { color: "white"; text: "boo!" }
    }

    // TODO doesn't seem to work
    Shortcut {
        sequence: "Ctrl+Alt+Backspace"
        onActivated: Qt.quit()
    }

    Shortcut {
        sequence: "Meta+A" // maybe not the best one... or maybe we don't need it at all
        onActivated: leftPanel.toggle()
    }
}
