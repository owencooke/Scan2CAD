import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: row

    property string title: "Scale"
    property real value
    property real initial_dim

    signal setValue(double value)

    function resetBinds() {
        distField.text = Qt.binding(function() { 
            return roundDecimal(row.value, 2)
        })
        percentField.text = Qt.binding(function() {
            return roundDecimal(row.value * 100 / initial_dim, 2)
        })
    }

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
        Layout.minimumWidth: 70
        Layout.alignment: Qt.AlignHCenter
        color: root.textColor
        text: roundDecimal(row.value, 2)
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
            // Change value via signal handler
            setValue(parseFloat(text))
            resetBinds()
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
        Layout.fillWidth: true
        Layout.minimumWidth: 70
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
            // Change value via signal handler
            setValue(parseFloat(percentField.text)*initial_dim/100)
            resetBinds()
        }
    }

    Label {
        text: "%"
        color: root.secondaryText
        font.family: regFont.font.family
        font.pointSize: 11
    }
}