import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Controls" as Controls

RowLayout {
    property alias text: label.text
    property alias fontSize: label.font.pointSize
    property bool open

    spacing: 4

    Controls.IconButton {
        icon.source: (open) ? icons.angle_down :
            icons.angle_right
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