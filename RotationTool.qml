import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    property string title
    property string handleColour
    signal setEuler(double value)
    
    function zeroTo360(val) {
        return ((val % 360) + 360) % 360
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
        value: parseFloat(field.text)
        to: 360

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
            field.text = Math.round(slider.value) + "°"
            setEuler(slider.value)
        }
    }

    // Input textbox
    TextField {
        id: field
        Layout.preferredWidth: 60
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: "0°"
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
            field.text = zeroTo360(parseFloat(field.text))
            slider.value = parseFloat(field.text)
            if (field.text.indexOf("°") == -1) {
                field.text += "°"
            }
            setEuler(slider.value)
        }
    }
}
