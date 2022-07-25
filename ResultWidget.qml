import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    property alias dist: distValue.text
    property alias distText: distTitle.text
    property alias percent: percentValue.text
    property alias percentText: percentTitle.text

    // Default property values
    color: root.menuColor
    opacity: 0.8
    height: column.height * 1.35
    width: column.width * 1.35
    radius: height/6

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 0
        Label {
            id: distValue
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            text: "-"
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 24
            font.weight: Font.DemiBold
        }
        Label {
            id: distTitle
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            horizontalAlignment: Text.AlignHCenter
            text: "Distance label"
            color: root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 9
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            color: root.menuColor
            opacity: 0
            implicitHeight: 10
            implicitWidth: 10
        }
        Label {
            id: percentValue
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            text: "-"
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 24
            font.weight: Font.DemiBold
        }
        Label {
            id: percentTitle
            text: "Percent label"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            color: root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 9
            font.weight: Font.DemiBold
        }
    }
}