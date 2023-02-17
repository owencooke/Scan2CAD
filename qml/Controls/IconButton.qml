import QtQuick
import QtQuick.Controls

Button {
    property string iconURL: ""
    property string tipText: ""
    
    // Text
    text: ""
    palette.buttonText: root.textColor
    font.family: titleFont.font.family
    font.pointSize: 10.5

    // Icon
    icon { source: iconURL; color: root.textColor; width: 28; height: 28 }

    // Display
    display: AbstractButton.IconOnly
    spacing: 10
    background: Rectangle { opacity: 0 }

    // Hover text 
    ToolTip {
        x: parent.width + 5
        y: parent.height/4
        // Display only if tip text assigned/no text shown
        visible: (parent.display == AbstractButton.IconOnly 
                    && tipText != "") ? parent.hovered : false
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