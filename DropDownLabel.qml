import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    property alias text: label.text
    property alias fontSize: label.font.pointSize
    property bool open

    spacing: 4

    IconButton {
        icon.source: (open) ? "backend_resources/icons/angle-down-solid.svg" :
            "backend_resources/icons/angle-right-solid.svg"
        icon.width: (open) ? label.height : label.height * 0.625
        icon.height: label.height

        onClicked: open = !open
    }

    Label {
        id: label
        text: "Menu"
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 11
    }
}