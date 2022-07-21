import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item { 
    property bool scanFlag
    property string sliderColor: (scanFlag) ? Qt.hsla(colorSlider.value, 1, 0.5, 1)
                                    : Qt.hsla(0, 0, colorSlider.value, 1)
    property string fileColor: root.secondaryText
    
    RowLayout {
        spacing: 8
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }

        // Header
        Label {
            text: (scanFlag) ? "3D SCAN:" : "CAD MODEL:"
            color: root.secondaryText
            font.family: titleFont.font.family
            font.pointSize: 12
        }

        // Filename from upload
        Label {
            id: fileLabel
            text: "No model selected."
            color: fileColor
            font.family: regFont.font.family
            font.pointSize: 12
        }

        // Upload button
        IconButton {
            iconURL: "backend_resources/icons/upload-solid.svg"
            onClicked: dialog.open()

            FileDialog {
                id: dialog
                title: "Select a 3D model file"
                nameFilters: ["3D files (*.stl *.obj *.ply *.gltf *.glb)"]
                onAccepted: {
                    if (scanFlag) {
                        scan.source = ""
                    } else {
                        cad.source = ""
                    }
                    // Set filename as new label
                    fileLabel.text = getFilename(selectedFile.toString())
                    fileLabel.color = root.secondaryText
                    // Start busy indicator for loading
                    loadingScreen.busyText = "Loading 3D File..."
                    loadingScreen.on = true
                    backend.loadMesh("Align", selectedFile, scanFlag)
                }
            }
        }
    }

    // Align buttons in a row
    RowLayout {
        id: buttonRow
        spacing: 0
        anchors { right: parent.right; verticalCenter: parent.verticalCenter}

        // Toggle mesh visibility 
        IconButton {
            property bool toggle: true
            iconURL: (toggle) ? "backend_resources/icons/eye-solid.svg" :
                            "backend_resources/icons/eye-slash-solid.svg"
            icon.width: 32
            onClicked: {
                toggle = !toggle 
                if (scanFlag) {
                    scan.opacity = toggle
                } else {
                    cad.opacity = toggle
                }
            }
        }

        // Button for opening color slider
        IconButton {
            iconURL: "backend_resources/icons/palette-solid.svg"
            onClicked: colorSlider.visible = !colorSlider.visible
        }
    }

    ColorSlider {
        id: colorSlider
        anchors.left: buttonRow.right
        anchors.verticalCenter: buttonRow.verticalCenter
        height: parent.height * 0.75
        width: parent.width * 0.25
        visible: false
        bnw: !scanFlag
        value: 0.5
    }
}