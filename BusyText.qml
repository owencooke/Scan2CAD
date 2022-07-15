import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: loadingScreen
    property string busyText: "Loading..."
    property bool on: false

    implicitHeight: 150
    implicitWidth: 200

    ColumnLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.bottomMargin: loadingScreen.radius
        spacing: 0

        BusyIndicator {
            id: busy
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.preferredHeight: loadingScreen.height/2
            Layout.preferredWidth: loadingScreen.height/2
            running: on
            Material.accent: root.textColor
        }

        Label {
            id: loadText
            Layout.alignment: Qt.AlignCenter
            text: (on) ? busyText : ""
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 12
        }
    }
}