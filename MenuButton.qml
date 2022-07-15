import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    property int pageIndex
    property string iconURL
    property string tipText
    Layout.alignment: Qt.AlignLeft

    // Text
    font.family: regFont.font.family
    font.weight: Font.DemiBold
    font.pointSize: 12
    palette.buttonText: root.textColor

    // Icon
    icon.source: iconURL
    icon.height: 28//32
    icon.width: 28//32

    // Display
    display: AbstractButton.TextBesideIcon
    spacing: 20
    //padding: 0
    //rightPadding: availableWidth - spacing - icon.width - text.width
    
    // Background
    background: Rectangle {
            opacity: 0
            radius: 4
            implicitHeight: 52// 62
            implicitWidth: 48//menuNav.width
    }

    // Functionality
    onClicked: {
        stack.currentIndex = pageIndex
        menuNav.close()
    }

    ToolTip {
        id: tip
        x: parent.width + 5
        y: parent.height/4
        // Only show if button is in the icon menu
        visible: (tipText == "") ? false : hovered
        delay: 750
        contentItem: Text {
            text: tipText
            font.family: regFont.font.family
            font.weight: Font.DemiBold
            font.pointSize: 8
            color: root.textColor
        }
        background: Rectangle {
            color: root.menuColor
            //border.color: "#8a8888"
        }
    }
}