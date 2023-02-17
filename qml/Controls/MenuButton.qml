import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    property int pageIndex
    property string iconURL
    property string tipText

    // Text
    font.family: regFont.font.family
    font.pointSize: 11
    palette.buttonText: root.textColor

    // Icon
    icon.source: iconURL
    icon.height: 28
    icon.width: 28

    // Layout
    display: AbstractButton.TextBesideIcon
    spacing: 20
    
    // Background
    background: Rectangle {
        opacity: 0
        implicitHeight: 52
        implicitWidth: 48
        width: parent.parent.width
    }
    
    containmentMask: Item {
        width: background.width
        height: 52
    }

    // Functionality
    onClicked: {
        // -1 indicates overwriting this handler code
        if (pageIndex != -1) {
            stack.currentIndex = pageIndex
            menuNav.close()
        }
    }

    // Hover description
    ToolTip {
        id: tip
        x: parent.width + 5
        y: parent.height/4
        // Only display if button is in the icon menu
        visible: (tipText == "") ? false : hovered
        delay: 750
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