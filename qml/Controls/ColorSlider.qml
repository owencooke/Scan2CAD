import QtQuick
import QtQuick.Controls

Slider {
    id: slider
    // Enable for black->white gradient;
    // otherwise, rainbow gradient
    property bool bnw: false

    from: 0
    to: 1
    implicitHeight: 20
    implicitWidth: 100

    // Gradient
    background: Rectangle {
        width: parent.width
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: (bnw) ? "black" : "red" }
            GradientStop { position: 0.125; color: (bnw) ? "#1c1c1c" : "orange" }
            GradientStop { position: 0.2; color: (bnw) ? "#333333" : "yellow" }
            GradientStop { position: 0.375; color: (bnw) ? "#595858" : "green" }
            GradientStop { position: 0.50; color: (bnw) ? "#7a7979" : "cyan" }
            GradientStop { position: 0.625; color: (bnw) ? "#9e9d9d" : "blue" }
            GradientStop { position: 0.75; color: (bnw) ? "#b3b1b1" : "indigo" }
            GradientStop { position: 0.875; color: (bnw) ? "#d1cfcf" : "#FF00CE" }
            GradientStop { position: 1; color: (bnw) ? "white" : "red" }
        }
    }

    // Handle
    handle: Rectangle {
        color: (bnw) ? Qt.hsla(0, 0, colorSlider.value, 1) 
                    : Qt.hsla(slider.value, 1, 0.5, 1)
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2 
        height: parent.height + 12
        implicitWidth: 8
        border.color: root.textColor
        border.width: 2
    }
}