import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 8

    // Parameter controls
    GridLayout {
        columns: 2
        columnSpacing: 16
        rowSpacing: 10
        width: parent.width

        Label {
            text: "Sampled Points"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
            id: samples
            Layout.alignment: Qt.AlignRight
            tipText: "Number of points randomly sampled from the\nsurface/vertices of the loaded meshes."
            text: "100000"
            fontSize: 10 
            validator: IntValidator {
                bottom: 1
                top: 1000000
            }
        }

        Label {
            text: "Error Distance (mm)"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }
        
        TextBox {
            id: thresh
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
            text: "0.5"
            fontSize: 10 
            validator: DoubleValidator {
                bottom: 0
                top: 1e10
            }
        }
    }

    // Button for running volume extraction algorithm
    Button {
        id: alignButton
        Layout.alignment: Qt.AlignCenter
        text: "Extract Volumes"
        font.family: titleFont.font.family
        font.pointSize: 10
        palette.buttonText: root.bgColor
        background: Rectangle { color: root.textColor; radius: height/6 }

        onClicked: {
            showStatus("Extracting volumes...")
            backend.repair(cad.source, scan.source, cad.sceneTransform, 
                                    scan.sceneTransform, parseInt(samples.text),
                                    parseFloat(thresh.text))
        }
    }
}