import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: loadingScreen
    property alias text: label.text
    property alias on: busy.running

    implicitHeight: 150
    implicitWidth: 200

    ColumnLayout {
        anchors { top: parent.top; bottom: parent.bottom;
                    horizontalCenter: parent.horizontalCenter }
        spacing: 0

        // Loading progress wheel
        BusyIndicator {
            id: busy
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.preferredHeight: loadingScreen.height/2
            Layout.preferredWidth: loadingScreen.height/2
            running: false
            Material.accent: root.textColor
        }

        // Descriptive text
        Label {
            id: label
            Layout.alignment: Qt.AlignCenter
            text: "Loading..."
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 12
            visible: on
        }

        // // Cancel button
        // Button {
        //     Layout.alignment: Qt.AlignCenter
        //     Layout.fillWidth: true
        //     text: "Cancel"
        //     palette.buttonText: root.textColor
        //     font.family: titleFont.font.family
        //     font.pointSize: 10
        //     visible: on
        //     onClicked: {
        //         // FIXME: add cancel function to abort current task
        //     }
        // }
    }
}