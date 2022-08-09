import QtQuick
import QtQuick.Controls

Rectangle {
    id: container

    property alias text: field.text
    property alias fontSize: field.font.pointSize
    property alias validator: field.validator
    property alias hovered: field.hovered
    property string tipText: ""

    color: root.menuColor
    implicitWidth: 1
    implicitHeight: 1

    TextField {
        id: field
        anchors { right: parent.right;
                    verticalCenter: parent.verticalCenter }
        color: root.textColor
        text: "type here"
        horizontalAlignment: TextInput.AlignRight
        font.family: regFont.font.family
        font.pointSize: 12
        background: Rectangle {
            y: field.height - height - field.bottomPadding
            color: root.textColor
            height: 1
            border.width: 0.001
        }

        ToolTip {
            x: parent.width + 5
            y: parent.height/4
            delay: 750
            visible: (tipText == "") ? false : parent.hovered
            contentItem: Text {
                text: tipText
                font.family: regFont.font.family
                font.weight: Font.DemiBold
                font.pointSize: 8
                color: root.textColor
            }
            background: Rectangle { color: root.menuColor }
        }
    }
}