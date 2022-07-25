import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: row
    property string title: "Scale"
    property string handleColour: "black"
    property real value: 0.0
    signal setValue(double value)

    function round3dec(num) {
        return (Math.round(num * 1000) / 1000).toFixed(3)
    }

    spacing: 8

    Label {
        text: title
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 11
    }

    TextField {
        id: field
        Layout.preferredWidth: 80
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: row.value
        horizontalAlignment: TextInput.AlignRight
        font.family: regFont.font.family
        font.pointSize: 12
        background: Rectangle {
            y: field.height - height - field.bottomPadding
            color: root.textColor
            height: 1
            border.width: 0.001
        }

        onEditingFinished: text = round3dec(parseFloat(text))
    }

    Label {
        text: "(mm)"
        color: root.secondaryText
        font.family: regFont.font.family
        font.pointSize: 9
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        from: 0
        value: parseFloat(field.text)
        to: 300

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
            setValue(slider.value)
        }
    }
}