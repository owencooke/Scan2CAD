import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick3D

import "../Controls" as Controls

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
        return !prev_state
    }
    
    color: root.menuColor
    implicitHeight: 48
    width: Math.max(textRow.width + title.width + dropButton.width + 75, 260)

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
        Controls.IconButton {
            icon { source: icons.upload; 
                    width: 24; height: 24 }
            onClicked: dialog.open()

            FileDialog {
                id: dialog
                title: "Select a 3D model file"
                nameFilters: ["3D files (*.stl *.obj *.ply *.gltf *.glb)"]
                onAccepted: {
                    let mesh = cad
                    if (scanFlag) { mesh = scan }

                    showStatus("Loading 3D File...")
                    mesh.source = selectedFile
                    mesh.load(selectedFile)

                    // Set filename as new label
                    fileLabel.text = getFilename(selectedFile.toString())
                    fileLabel.color = Qt.binding(function() { return root.secondaryText })
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
    Controls.IconButton {
        id: dropButton
        property bool toggle: false
        anchors { left: parent.left; margins: 16; verticalCenter: parent.verticalCenter }
        icon.source: (toggle) ? icons.angle_down :
                        icons.angle_right
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
            Controls.IconButton {
                tipText: "Visibility"
                property bool toggle: true
                icon { 
                    width: 28; height: 24;
                    source: (toggle) ? icons.eye
                                : icons.eye_slash 
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
            Controls.IconButton {
                tipText: "Color"
                icon { source: icons.fill;
                        width: 24; height: 24 }
                onClicked: colorContainer.visible = closeTools(colorContainer.visible)
            }

            // Rotate dropdown
            Controls.IconButton {
                tipText: "Rotate"
                icon { source: icons.rotate;
                        width: 24; height: 24 }
                onClicked: rotateContainer.visible = closeTools(rotateContainer.visible)
            }

            // Scale dropdown
            Controls.IconButton {
                tipText: "Scale"
                icon { source: icons.maximize;
                        width: 24; height: 24 }
                onClicked: scaleContainer.visible = closeTools(scaleContainer.visible)
            }
            
            // Reset button
            Controls.IconButton {
                tipText: "Reset to default"
                icon { source: icons.eraser;
                        width: 24; height: 24 }
                onClicked: target.resetNode()
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
        
            Controls.ColorSlider {
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

                Controls.RotationTool {
                    id: xRot
                    title: "X"
                    handleColour: "red"
                    value: target.eulerRotation.x
                    onSetEuler: function(val) {
                        target.eulerRotation.x = val
                    }
                }

                Controls.RotationTool {
                    id: yRot
                    title: "Y"
                    handleColour: "green"
                    value: target.eulerRotation.y
                    onSetEuler: function(val) {
                        target.eulerRotation.y = val
                    }
                }

                Controls.RotationTool {
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

                Controls.ScalingTool {
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

                Controls.ScalingTool {
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

                Controls.ScalingTool {
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