import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D.AssetUtils

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
            text: "500"
            fontSize: 10 
            validator: IntValidator {
                bottom: 1
                top: 1000000
            }
        }

        Label {
            text: "Max Iterations"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }
        
        TextBox {
            id: iterations
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
            text: "50"
            fontSize: 10 
            validator: IntValidator {
                bottom: 1
                top: 999
            }
        }

        Label {
            text: "Corrective Scaling"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }
        
        CheckBox {
            id: toggleScale
            Layout.alignment: Qt.AlignRight
        }
    }

    // Button for running alignment algorithm
    Button {
        id: alignButton
        Layout.alignment: Qt.AlignCenter
        text: "Align Meshes"
        font.family: titleFont.font.family
        font.pointSize: 10
        palette.buttonText: root.bgColor
        background: Rectangle { color: root.textColor; radius: height/6 }

        onClicked: {
            // Calculate alignment
            backend.align_meshes(cad.source, scan.source, cad.sceneTransform, 
                                    scan.sceneTransform, toggleScale.checked, 
                                    parseInt(samples.text), parseInt(iterations.text))
        
            // Set mouse controls back to camera to avoid accidental movement
            switchControls(camera, "CAMERA")
            
            // Display running indicator
            showStatus("Aligning Meshes...")
        }
    }
}