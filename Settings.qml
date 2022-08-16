import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settings
    color: root.bgColor

    Label {
        id: title
        anchors.horizontalCenter: parent.horizontalCenter
        y: 50
        text: "SETTINGS"
        color: root.secondaryText
        font.family: titleFont.font.family
        font.pointSize: 36
    }

    RowLayout {
        id: themeLayout
        anchors.top: title.bottom; anchors.topMargin: 16
        anchors.left: parent.left; anchors.leftMargin: 100
        spacing: 25

        Label {
            text: "THEME:"
            color: root.secondaryText
            font.family: titleFont.font.family
            font.pointSize: 16
        }

        Button {
            text: "Light"
            font.family: regFont.font.family
            font.pointSize: 14
            font.weight: Font.DemiBold
            background: Rectangle { color: "#bfbfbf" }
            onClicked: {
                root.theme = "light"
                root.textColor = "black"
                root.secondaryText = "#4f4f4f"
                root.menuColor = "#bfbfbf"
                root.bgColor = "#e8e8e8"
            }
        }

        Button {
            text: "Dark"
            font.family: regFont.font.family
            font.pointSize: 14
            font.weight: Font.DemiBold
            palette.buttonText: "white"
            background: Rectangle { color: "#303030" }
            onClicked: {
                root.theme = "dark"
                root.textColor = "white"
                root.secondaryText = "#9e9d9d"
                root.menuColor = "#303030"
                root.bgColor = "#252525"
            }
        }
    }
}