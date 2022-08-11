import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property alias pointSize: pointSlider.value

    spacing: 8

    // Title
    Label {
        Layout.alignment: Qt.AlignCenter
        text: "Depth Map"
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 12
    }

    GridLayout {
        columns: 2
        columnSpacing: 16
        rowSpacing: 10
        width: parent.width
    
        Label {
            Layout.fillWidth: true
            text: "Sampled Points"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
            id: sampled
            Layout.alignment: Qt.AlignRight
            tipText: "Number of points randomly sampled from the\nsurface/vertices of the loaded meshes."
            text: "2000"
            fontSize: 10 
            validator: IntValidator {
                bottom: 1
                top: 1000000
            }
        }

        Label {
            Layout.fillWidth: true
            text: "Assert Match (mm)"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
            id: matchThresh
            Layout.alignment: Qt.AlignRight
            tipText: "Defines the guaranteed range within which points are\nconsidered to match with extremely high similarity."
            text: (1e-9).toString()
            fontSize: 10 
            validator: DoubleValidator {}
        }

        Label {
            Layout.fillWidth: true
            text: "Enable Custom Range"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }
        
        CheckBox {
            id: customRange
            Layout.alignment: Qt.AlignRight
        }

        Label {
            Layout.leftMargin: 16
            Layout.fillWidth: true
            text: "Maximum (mm)"
            color: (customRange.checked) ? root.textColor : root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
            id: max
            Layout.alignment: Qt.AlignRight
            tipText: "Set the maximum distance to be considered for over-extrusion."
            text: ""
            fontSize: 10
            validator: DoubleValidator {}
            enabled: customRange.checked
        }

        Label {
            Layout.leftMargin: 16
            Layout.fillWidth: true
            text: "Minimum (mm)"
            color: (customRange.checked) ? root.textColor : root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
            id: min
            Layout.alignment: Qt.AlignRight
            tipText: "Set the minimum distance to be considered for under-extrusion."
            text: ""
            fontSize: 10 
            validator: DoubleValidator {}
            enabled: customRange.checked
        }

        Label {
            text: "Point Size"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }

        Slider {
            id: pointSlider
            from: 1
            value: 1
            to: 50
        }
    }

    Button {
        Layout.alignment: Qt.AlignCenter
        text: "Calculate Depth Map"
        font.family: titleFont.font.family
        font.pointSize: 10
        palette.buttonText: root.bgColor
        background: Rectangle { color: root.textColor; radius: height/6 }
        
        onClicked: {
            backend.depth_map(cloudClass, cad.source, scan.source, parseInt(sampled.text),
                                parseFloat(matchThresh.text), parseFloat(min.text), parseFloat(max.text))
            cad.opacity = scan.opacity = 0
            cloud.opacity = 1
        }
    }
}