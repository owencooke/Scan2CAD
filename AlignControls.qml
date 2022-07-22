import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle { 
    property bool scanFlag
    property string sliderColor: (scanFlag) ? Qt.hsla(colorSlider.value, 1, 0.5, 1)
                                    : Qt.hsla(0, 0, colorSlider.value, 1)
    property string fileColor: root.textColor //root.secondaryText
    property string buttonColor: root.textColor

    function closeTools(prev_state) {
        // Close all tool containers
        colorContainer.visible = false
        rotateContainer.visible = false
        scaleContainer.visible = false
        // Invert prev state, return
        return !prev_state
    }
    
    opacity: 0.9
    color: root.menuColor
    implicitHeight: 64
    width: textRow.width + targetButton.width + dropButton.width + 64

    RowLayout {
        id: textRow
        spacing: 8
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }

        // Filename from upload
        Label {
            id: fileLabel
            text: "No model selected."
            color: fileColor
            font.family: regFont.font.family
            font.pointSize: 11
        }

        IconButton {
            icon { source: "backend_resources/icons/upload-solid.svg"; 
                    width: 24; height: 24 }
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

    Button {
        id: targetButton
        anchors { left: dropButton.right; verticalCenter: parent.verticalCenter; margins: 8 }
        text: (scanFlag) ? "SCAN" : "CAD"
        palette.buttonText: buttonColor
        font.family: titleFont.font.family
        font.pointSize: 18
        background: Rectangle { color: root.menuColor; radius: height/6 }
        onClicked: align.setMouseControl(text)
    }

    IconButton {
        id: dropButton
        property bool toggle: false
        anchors { left: parent.left; margins: 16; verticalCenter: parent.verticalCenter }
        icon.source: (toggle) ? "backend_resources/icons/angle-down-solid.svg" :
                        "backend_resources/icons/angle-right-solid.svg"
        icon.width: (toggle) ? 24 : 16; icon.height: 24
        // icon.source: "backend_resources/icons/toolbox-solid.svg"
        onClicked: {
            toggle = !toggle
        }
    }

    Rectangle {
        anchors { top: parent.bottom; left: parent.left; leftMargin: 8}
        opacity: (dropButton.toggle) ? 0.9 : 0
        color: root.menuColor
        implicitHeight: 40
        implicitWidth: 300
        width: parent.width
        //radius: height/8

        // Align buttons in a row
        RowLayout {
            id: buttonRow
            //spacing: 0
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter}

            // Toggle mesh visibility 
            IconButton {
                tipText: "Visibility"
                property bool toggle: true
                icon { 
                    width: 28; height: 24;
                    source: (toggle) ? "backend_resources/icons/eye-solid.svg"
                                : "backend_resources/icons/eye-slash-solid.svg" 
                }
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
                tipText: "Color"
                icon { source: "backend_resources/icons/palette-solid.svg";
                        width: 24; height: 24 }
                onClicked: colorContainer.visible = closeTools(colorContainer.visible)
            }

            // Rotations
            IconButton {
                tipText: "Rotate"
                icon { source: "backend_resources/icons/rotate-solid.svg";
                        width: 24; height: 24 }
                onClicked: rotateContainer.visible = closeTools(rotateContainer.visible)
            }

            // Scaling
            IconButton {
                tipText: "Scale"
                icon { source: "backend_resources/icons/maximize-solid.svg";
                        width: 24; height: 24 }
                onClicked: scaleContainer.visible = closeTools(scaleContainer.visible)
            }
        }

        Rectangle {
            id: colorContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: 0.9
            color: root.menuColor
            implicitHeight: 40
            implicitWidth: 300
            visible: false
        
            ColorSlider {
                id: colorSlider
                anchors.centerIn: parent
                height: parent.height * 0.5
                width: parent.width * 0.9
                bnw: !scanFlag
                value: 0.5
            }
        }

        Rectangle {
            id: rotateContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: 0.9
            color: root.menuColor
            implicitHeight: 100
            implicitWidth: 300
            visible: false
        
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; leftMargin: 16;
                            rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 4

                RotationTool {
                    id: xRot
                    title: "X"
                    handleColour: "red"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.x = value
                    // }
                }

                RotationTool {
                    id: yRot
                    title: "Y"
                    handleColour: "green"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.y = value
                    // }
                }

                RotationTool {
                    id: zRot
                    title: "Z"
                    handleColour: "blue"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.z = value
                    // }
                }
            }
        }

        Rectangle {
            id: scaleContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: 0.9
            color: root.menuColor
            implicitHeight: 100
            implicitWidth: 300
            visible: false
        
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; leftMargin: 16;
                            rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 4

                RotationTool {
                    //id: xRot
                    title: "X"
                    handleColour: "red"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.x = value
                    // }
                }

                RotationTool {
                    //id: yRot
                    title: "Y"
                    handleColour: "green"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.y = value
                    // }
                }

                RotationTool {
                    //id: zRot
                    title: "Z"
                    handleColour: "blue"
                    // onSetEuler: function(value) {
                    //     target.eulerRotation.z = value
                    // }
                }
            }
        }
    }
}