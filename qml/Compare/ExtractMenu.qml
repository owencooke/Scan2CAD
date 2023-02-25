import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "../Controls" as Controls

ColumnLayout {
    property bool exportAdd

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

        Controls.TextBox {
            id: samples
            Layout.alignment: Qt.AlignRight
            tipText: "Number of points randomly sampled from the\nsurface/vertices of the loaded meshes."
            text: "300"
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
        
        Controls.TextBox {
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
        text: "Extract Features"
        font.family: titleFont.font.family
        font.pointSize: 10
        palette.buttonText: root.bgColor
        background: Rectangle { color: root.textColor; radius: height/6 }

        onClicked: {
            showStatus("Extracting volumes...")
            backend.repair(cad.source, scan.source, cad.getTransform(), 
                                    scan.getTransform(), parseInt(samples.text),
                                    parseFloat(thresh.text))
        }
    }

    // Export feature buttons
    Label {
        text: "Export Features"
        color: root.textColor
        font.family: regFont.font.family
        font.pointSize: 10
    }
    
    RowLayout {
        Layout.alignment: Qt.AlignCenter
        spacing: 8

        Button {
            id: add
            Layout.alignment: Qt.AlignCenter
            text: "Additive"
            font.family: titleFont.font.family
            font.pointSize: 8
            palette.buttonText: root.bgColor
            background: Rectangle { color: root.textColor; radius: height/6 }

            onClicked: {exportAdd = true; dialog.open()}
        }

        Button {
            id: sub
            Layout.alignment: Qt.AlignCenter
            text: "Subtractive"
            font.family: titleFont.font.family
            font.pointSize: 8
            palette.buttonText: root.bgColor
            background: Rectangle { color: root.textColor; radius: height/6 }

            onClicked: {exportAdd = false; dialog.open()}
        }
    }

    FileDialog {
        id: dialog
        fileMode: FileDialog.SaveFile
        nameFilters: ["STL file (*.stl)", "GLB file (*.glb)"]
        onAccepted: {
            if (exportAdd) {
                title = add.text
                additive.export(selectedFile)
            } else {
                title = sub.text
                subtractive.export(selectedFile)
            }
        }
    }
}