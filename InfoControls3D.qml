import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick3D

Rectangle {
    id: controls
    property string title
    property Node target
    property string targetColor: Qt.hsla(colorSlider.value, 1, 0.5, 1)
    property bool gridChecked: gridToggle.toggle
    property bool scan
    property bool loading: false

    // Rounding function for outputting dimensional values
    //FIXME: add support for different units (cm, m, etc.)
    function round1dec(num) {
        return (Math.round(num * 10) / 10).toFixed(1)
    }

    color: root.bgColor

    IconButton {
        id: gridToggle
        property bool toggle: false
        anchors { top: parent.top; right: parent.right; margins: 16 }
        iconURL: toggle ? "backend_resources/icons/border-all-solid.svg" 
                        : "backend_resources/icons/border-none-solid.svg"
        onClicked: toggle = !toggle
    }

    IconButton { 
        id: colorToggle
        anchors { top: gridToggle.top; right: gridToggle.left; rightMargin: 5 }
        iconURL: "backend_resources/icons/palette-solid.svg"
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

    ColumnLayout {
        anchors { top: parent.top; left: parent.left; topMargin: 16;
                leftMargin: 24; right: parent.right; rightMargin: 48 }
        spacing: 16

        RowLayout {
            spacing: 16

            Label {
                text: "FILENAME:"
                color: root.secondaryText
                font.family: titleFont.font.family
                font.pointSize: 14
            }

            // Model filename
            Label {
                text: title
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
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
                        if (scan) {
                            root.scanFile = selectedFile
                            scanScene.target.source = " "
                        } else {
                            root.cadFile = selectedFile
                            cadScene.target.source = " "
                        }
                        controls.loading = true
                        backend.loadMesh("Model3D", selectedFile, scan)
                    }
                }
            }
        }

        RowLayout {
            spacing: 16
            
            Label {
                text: "DIMENSIONS:"
                color: root.secondaryText
                font.family: titleFont.font.family
                font.pointSize: 14
            }

            Label {
                text: "Length: " + round1dec(target.dimensions.x) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
            }

            Label {
                text: "Width: " + round1dec(target.dimensions.y) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
            }
            
            Label {
                text: "Height: " + round1dec(target.dimensions.z) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
            }
        }

        Label {
            text: "ROTATE ABOUT AXIS:"
            color: root.secondaryText
            font.family: titleFont.font.family
            font.pointSize: 14
            //visible: false
        }

        RotationTool {
            id: xRot
            title: "X"
            handleColour: "red"
            bgContainer: controls
            Layout.leftMargin: 15
            onSetEuler: function(value) {
                target.eulerRotation.x = value
            }
         }

        RotationTool {
            id: yRot
            title: "Y"
            handleColour: "green"
            bgContainer: controls
            Layout.leftMargin: 15
            onSetEuler: function(value) {
                target.eulerRotation.y = value
            }
        }

        RotationTool {
            id: zRot
            title: "Z"
            handleColour: "blue"
            bgContainer: controls
            Layout.leftMargin: 15
            onSetEuler: function(value) {
                target.eulerRotation.z = value
            }
        }
    }
}
        