import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick3D

Rectangle { 
    property Node target
    property bool scanFlag
    property string sliderColor: (scanFlag) ? Qt.hsla(colorSlider.value, 1, 0.5, 1)
                                    : Qt.hsla(0, 0, colorSlider.value, 1)
    property string fileColor: root.secondaryText
    property string buttonColor: root.textColor

    function closeTools(prev_state) {
        // Close all tool containers
        colorContainer.visible = false
        rotateContainer.visible = false
        scaleContainer.visible = false
        // Invert prev state, return
        return !prev_state
    }
    
    color: root.menuColor
    implicitHeight: 48
    width: textRow.width + title.width + dropButton.width + 75

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

        // File upload button
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
                    fileLabel.color = Qt.binding(function() { return root.secondaryText })
                    // Start busy indicator for loading
                    loadingScreen.text = "Loading 3D File..."
                    loadingScreen.on = true
                    backend.load_mesh("Align", selectedFile, scanFlag)
                }
            }
        }
    }

    // Title
    Label {
        id: title
        anchors { left: dropButton.right; verticalCenter: parent.verticalCenter; margins: 8}
        text: (scanFlag) ? "SCAN" : "CAD"
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 18
    }

    // Dropdown menu button
    IconButton {
        id: dropButton
        property bool toggle: false
        anchors { left: parent.left; margins: 16; verticalCenter: parent.verticalCenter }
        icon.source: (toggle) ? "backend_resources/icons/angle-down-solid.svg" :
                        "backend_resources/icons/angle-right-solid.svg"
        icon.width: (toggle) ? 24 : 16; icon.height: 24
        
        onClicked: toggle = !toggle
    }

    // Drop down menu for button controls
    Rectangle {
        anchors { top: parent.bottom; left: parent.left }
        implicitHeight: 32
        width: parent.width
        opacity: parent.opacity
        color: root.menuColor
        visible: (dropButton.toggle) ? true : false

        RowLayout {
            id: buttonRow
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter}

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
                        scan.visible = toggle
                    } else {
                        cad.visible = toggle
                    }
                }
            }

            // Color dropdown
            IconButton {
                tipText: "Color"
                icon { source: "backend_resources/icons/fill-solid.svg";
                        width: 24; height: 24 }
                onClicked: colorContainer.visible = closeTools(colorContainer.visible)
            }

            // Rotate dropdown
            IconButton {
                tipText: "Rotate"
                icon { source: "backend_resources/icons/rotate-solid.svg";
                        width: 24; height: 24 }
                onClicked: rotateContainer.visible = closeTools(rotateContainer.visible)
            }

            // Scale dropdown
            IconButton {
                tipText: "Scale"
                icon { source: "backend_resources/icons/maximize-solid.svg";
                        width: 24; height: 24 }
                onClicked: scaleContainer.visible = closeTools(scaleContainer.visible)
            }
            
            // Reset button
            IconButton {
                tipText: "Reset to default"
                icon { source: "backend_resources/icons/eraser-solid.svg";
                        width: 24; height: 24 }
                onClicked: resetNode(target)
            }
        }

        // Slider for mesh color 
        Rectangle {
            id: colorContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: parent.opacity
            color: root.menuColor
            implicitHeight: 40
            width: parent.width
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

        // Rotational tools for x, y, z axes
        Rectangle {
            id: rotateContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: parent.opacity
            color: root.menuColor
            implicitHeight: 100
            width: parent.width
            visible: false
        
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; leftMargin: 16;
                            rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 4

                RotationTool {
                    id: xRot
                    title: "X"
                    handleColour: "red"
                    value: target.eulerRotation.x
                    onSetEuler: function(val) {
                        target.eulerRotation.x = val
                    }
                }

                RotationTool {
                    id: yRot
                    title: "Y"
                    handleColour: "green"
                    value: target.eulerRotation.y
                    onSetEuler: function(val) {
                        target.eulerRotation.y = val
                    }
                }

                RotationTool {
                    id: zRot
                    title: "Z"
                    handleColour: "blue"
                    value: target.eulerRotation.z
                    onSetEuler: function(val) {
                        target.eulerRotation.z = val
                    }
                }
            }
        }

        // Scale tools for length, width, height
        Rectangle {
            id: scaleContainer
            anchors { left: parent.left; top: parent.bottom}
            opacity: parent.opacity
            color: root.menuColor
            implicitHeight: 100
            width: parent.width
            visible: false
        
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; leftMargin: 16;
                            rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 4

                ScalingTool {
                    title: " L "
                    value: roundDecimal(target.dimensions.x, 3)
                    initial_dim: target.init_dims.x
                    onSetValue: function(new_dim) {
                        if (new_dim != 0) { 
                            target.scale.x = (new_dim * target.scale.x) / target.dimensions.x
                            target.dimensions.x = new_dim
                        } 
                    }
                }

                ScalingTool {
                    title: "W"
                    value: roundDecimal(target.dimensions.y, 3)
                    initial_dim: target.init_dims.y
                    onSetValue: function(new_dim) {
                        if (new_dim != 0) { 
                            target.scale.y = (new_dim * target.scale.y) / target.dimensions.y
                            target.dimensions.y = new_dim
                        } 
                    }
                }

                ScalingTool {
                    title: " H "
                    value: roundDecimal(target.dimensions.z, 3)
                    initial_dim: target.init_dims.z
                    onSetValue: function(new_dim) {
                        if (new_dim != 0) { 
                            target.scale.z = (new_dim * target.scale.z) / target.dimensions.z
                            target.dimensions.z = new_dim
                        } 
                    }
                }
            }
        }
    }
}