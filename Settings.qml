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
            //color: root.secondaryText
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
                root.selectedColor = "#2D209E"
            }
        }

        Button {
            text: "Dark"
            //color: root.secondaryText
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
                root.selectedColor = "#7BCCDF"
            }
        }
    }
    // RowLayout {
    //     anchors.left: themeLayout.left
    //     anchors.top: themeLayout.bottom
    //     anchors.margins: 32
    //     height: parent.height * (1/4)
    //     width: parent.width * (1/2)
    //     spacing: 6

    //     Image {
    //         id: light
    //         Layout.fillWidth: true
    //         Layout.fillHeight: true
    //         source: "backend_resources/icons/lightmode.png"
    //         fillMode: Image.PreserveAspectFit
    //     }

    //     Image {
    //         id: dark
    //         Layout.fillWidth: true
    //         Layout.fillHeight: true
    //         source: "backend_resources/icons/darkmode.png"
    //         fillMode: Image.PreserveAspectFit
    //     }
    // }
}