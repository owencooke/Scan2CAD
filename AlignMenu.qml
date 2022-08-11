import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D.AssetUtils

ColumnLayout {
    spacing: 8

    Label {
        Layout.alignment: Qt.AlignCenter
        text: "Alignment"
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
            text: "Sampled Points"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }

        TextBox {
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
            text: "Number of Iterations"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 9
        }
        
        TextBox {
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

    Button {
        id: alignButton
        Layout.alignment: Qt.AlignCenter
        text: "Align Meshes"
        font.family: titleFont.font.family
        font.pointSize: 10
        palette.buttonText: root.bgColor
        background: Rectangle { color: root.textColor; radius: height/6 }
        onClicked: {
            var error = false
            // Turn labels red to indicate error if no file selected
            if (cad.status != RuntimeLoader.Success) {
                scanControl.fileColor = "red"
                error = true
            } if (scan.status != RuntimeLoader.Success) {
                cadControl.fileColor = "red"
                error = true
            // Reset loader sources and run alignment from backend
            } if (!error) {
                cad.scale = scan.scale = Qt.vector3d(1, 1, 1)
                loadingScreen.busyText = "Calculating alignment..."
                loadingScreen.on = true
                backend.align_meshes(cad.source, scan.source, cad.sceneTransform,
                                            scan.sceneTransform, toggleScale.checked)
                cad.source = scan.source = " "
            }
        }
    }
}