import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: row
    property string title: "Scale"
    property real value: 0.0
    property real initial_dim: 0.0
    signal setValue(double value)

    spacing: 8

    // Title
    Label {
        text: title
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 11
    }

    // Input textfield (default is initial measurement)
    TextField {
        id: distField
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: row.value
        horizontalAlignment: TextInput.AlignRight
        font.family: regFont.font.family
        font.pointSize: 12

        background: Rectangle {
            y: distField.height - height - distField.bottomPadding
            color: root.textColor
            height: 1
            border.width: 0.001
        }

        onEditingFinished: {
            var val = parseFloat(text)
            setValue(val)
            text = Qt.binding(function() { return value })
            percentField.text = roundDecimal(val * 100 / initial_dim, 2)
        }
    }

    // Distance units
    Label {
        text: "(mm)"
        color: root.secondaryText
        font.family: regFont.font.family
        font.pointSize: 10
    }

    // Percentage scale based on initial distance
    TextField {
        id: percentField
        Layout.preferredWidth: 100
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: "100"
        horizontalAlignment: TextInput.AlignRight
        font.family: regFont.font.family
        font.pointSize: 12

        background: Rectangle {
            y: percentField.height - height - percentField.bottomPadding
            color: root.textColor
            height: 1
            border.width: 0.001
        }

        onEditingFinished: {
            setValue(parseFloat(percentField.text)*initial_dim/100)
        }
    }

    Label {
        text: "%"
        color: root.secondaryText
        font.family: regFont.font.family
        font.pointSize: 11
    }
}