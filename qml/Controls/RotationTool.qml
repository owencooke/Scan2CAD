import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: row

    property string title
    property string handleColour
    property real value: 0.0
    signal setEuler(double val)
    
    function zeroTo360(val) {
        return ((val % 360) + 360) % 360
    }

    function resetBinds() {
        field.text = Qt.binding(function() { 
            return roundDecimal(zeroTo360(row.value), 2).toString() + "°" 
        })
        slider.value = Qt.binding(function() {
            return roundDecimal(zeroTo360(row.value), 2)
        })
    }

    spacing: 15

    // Title
    Label {
        text: title
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 12
    }

    // Slider (degrees)
    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        from: 0
        value: roundDecimal(zeroTo360(row.value), 2)
        to: 360
        stepSize: 1

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 4
            width: slider.availableWidth
            height: implicitHeight
            radius: 2
            color: root.textColor
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 10
            implicitHeight: 20
            color: handleColour
        }

        onMoved: {
            // Change target rotation via signal handler
            setEuler(slider.value)
            resetBinds()
        }
    }

    // Input textbox
    TextField {
        id: field
        Layout.preferredWidth: 80
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: roundDecimal(zeroTo360(row.value), 2).toString() + "°"
        horizontalAlignment: TextInput.AlignHCenter
        font.family: regFont.font.family
        font.pointSize: 12

        background: Rectangle {
            y: field.height - height - field.bottomPadding
            color: root.textColor
            height: 1
            border.width: 0.001
        }

        onEditingFinished: {
            // Change target rotation via signal handler
            setEuler(parseFloat(field.text))
            resetBinds()
        }
    }
}
