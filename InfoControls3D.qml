import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick3D

Rectangle {
    id: controls
    property Node target
    property string targetColor: Qt.hsla(colorSlider.value, 1, 0.5, 1)
    property bool gridChecked: gridToggle.toggle
    property bool scan

    color: root.bgColor

    // Header with filename and upload button
    RowLayout {
        id: header
        anchors { top: parent.top; left: parent.left;
                    topMargin: 16; leftMargin: 24 }
        spacing: 16

        // Title
        Label {
            text: "FILENAME"
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 12.5
        }

        // Input filename
        Label {
            id: fileLabel
            text: "No model selected."
            color: root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 11
        }

        // Upload Button
        IconButton {
            id: uploadButton
            iconURL: "backend_resources/icons/upload-solid.svg"
            onClicked: dialog.open()

            FileDialog {
                id: dialog
                title: "Select a 3D model file"
                nameFilters: ["3D files (*.stl *.obj *.ply *.gltf *.glb)"]
                onAccepted: {
                    // Update name display
                    fileLabel.text = getFilename(selectedFile.toString())
                    // Load new model
                    target.load(selectedFile)
                    showStatus("Loading 3D file...")
                }
            }
        }
    }

    // Gridline button
    IconButton {
        id: gridToggle
        property bool toggle: false
        anchors { top: parent.top; right: parent.right; margins: 16 }
        iconURL: toggle ? "backend_resources/icons/border-all-solid.svg" 
                        : "backend_resources/icons/border-none-solid.svg"
        onClicked: toggle = !toggle
    }

    // Toggle for color slider
    IconButton { 
        id: colorToggle
        anchors { top: gridToggle.top; right: gridToggle.left; rightMargin: 5 }
        iconURL: "backend_resources/icons/fill-solid.svg"
        onClicked: colorSlider.visible = !colorSlider.visible
    }

    ColorSlider {
        id: colorSlider
        anchors { verticalCenter: colorToggle.verticalCenter; 
                right: colorToggle.left; rightMargin: 5 }
        implicitHeight: 28
        width: colorToggle.x - colorToggle.width - uploadButton.x - uploadButton.width
        visible: false
        value: (scan) ? 0.84 : 0.4
    }

    // Scrollable tools below file header
    Flickable {
        id: flickable
        anchors { top: header.bottom; left: header.left; topMargin: 16
                    bottom: parent.bottom; right: parent.right }
        clip: true
        contentHeight: toolColumn.height + 24
        contentWidth: toolColumn.width
        flickableDirection: Flickable.VerticalFlick

        ScrollIndicator.vertical: ScrollIndicator {
            anchors { top: flickable.top; right: flickable.right;
                        bottom: flickable.bottom }
            active: true
        }

        // Tool and info layout
        ColumnLayout {
            id: toolColumn
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 16

            // Dimension labels
            RowLayout {
                spacing: 16
                
                Label {
                    text: "DIMENSIONS"
                    color: root.textColor
                    font.family: titleFont.font.family
                    font.pointSize: 12.5
                }

                Label {
                    text: "Length: " + roundDecimal(target.dimensions.x, 1) + "mm"
                    color: root.secondaryText
                    font.family: regFont.font.family
                    font.pointSize: 11
                }

                Label {
                    text: "Width: " + roundDecimal(target.dimensions.y, 1) + "mm"
                    color: root.secondaryText
                    font.family: regFont.font.family
                    font.pointSize: 11
                }
                
                Label {
                    text: "Height: " + roundDecimal(target.dimensions.z, 1) + "mm"
                    color: root.secondaryText
                    font.family: regFont.font.family
                    font.pointSize: 11
                }
            }

            // Rotational tools
            Label {
                text: "ROTATE"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 12.5
            }

            RotationTool {
                id: xRot
                title: "X"
                handleColour: "red"
                Layout.leftMargin: 15
                value: target.eulerRotation.x
                onSetEuler: function(val) {
                    target.eulerRotation.x = val
                }
            }

            RotationTool {
                id: yRot
                title: "Y"
                handleColour: "green"
                Layout.leftMargin: 15
                value: target.eulerRotation.y
                onSetEuler: function(val) {
                    target.eulerRotation.y = val
                }
            }

            RotationTool {
                id: zRot
                title: "Z"
                handleColour: "blue"
                Layout.leftMargin: 15
                value: target.eulerRotation.z
                onSetEuler: function(val) {
                    target.eulerRotation.z = val
                }
            }

            // Scaling tools
            Label {
                text: "SCALE"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 12.5
            }

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
        