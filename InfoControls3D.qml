import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick3D

Rectangle {
    id: controls
    property vector3d sliderRot: Qt.vector3d(xRot.getValue, yRot.getValue, zRot.getValue)
    property string title
    property Node target
    property string targetColor: Qt.hsla(colorSlider.value, 1, 0.5, 1)
    property bool gridChecked: gridToggle.toggle
    property bool scan
    property bool loading: false

    color: root.bgColor

    Connections {
        target: backend
        function onConvertedMesh(file, scanFlag, x, y, z, l, w, h) {
            controls.loading = false
            loadTimer.stop()
        }
    }

    Button {
        id: gridToggle
        property bool toggle: false
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        //checkable: true
        highlighted: true
        //flat: true
        icon.source: toggle ? "backend_resources/icons/border-all-solid.svg" 
                        : "backend_resources/icons/border-none-solid.svg"
        icon.color: root.textColor
        icon.width: 28; icon.height: 28
        background: Rectangle { opacity: 0 }
        onClicked: {
            if (toggle) {
                toggle = false
            } else {
                toggle = true
            }
        }
    }

    Button { 
        id: colorToggle
        anchors.top: gridToggle.top
        anchors.right: gridToggle.left
        anchors.rightMargin: 5
        icon.source: "backend_resources/icons/palette-solid.svg"
        icon.color: root.textColor
        icon.width: 28; icon.height: 28
        background: Rectangle { opacity: 0 }

        onClicked: colorSlider.visible = !colorSlider.visible
    }

    ColorSlider {
        id: colorSlider
        anchors.verticalCenter: colorToggle.verticalCenter
        anchors.right: colorToggle.left
        anchors.rightMargin: 5
        implicitHeight: 28
        width: colorToggle.x - colorToggle.width - uploadButton.x - uploadButton.width
        visible: false
        value: (scan) ? 0.84 : 0.4
    }

    // Rounding function for outputting dimensional values
    //FIXME: add support for different units (cm, m, etc.)
    function round1dec(num) {
        return (Math.round(num * 10) / 10).toFixed(1)
    }

    ColumnLayout {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 16
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 48
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
                //font.weight: Font.DemiBold
            }

            // Upload Button
            Button {
                id: uploadButton
                icon.source: "backend_resources/icons/upload-solid.svg"
                icon.color: root.textColor
                icon.width: 28
                icon.height: 28
                background: Rectangle {
                    opacity: 0
                }
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
                        loadTimer.start()
                        backend.loadMesh("Model3D", selectedFile, scan)
                    }
                }

                Timer {
                    id: loadTimer
                    interval: 1000
                    onTriggered: {
                        controls.loading = true
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
                Layout.columnSpan: 2
                text: "Length: " + round1dec(target.dimensions.x) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
                //font.weight: Font.DemiBold
            }
            Label {
                Layout.columnSpan: 2
                text: "Width: " + round1dec(target.dimensions.y) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
                //font.weight: Font.DemiBold
            }
            Label {
                Layout.columnSpan: 2
                text: "Height: " + round1dec(target.dimensions.z) + "mm"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 12
                //font.weight: Font.DemiBold
            }
        }

        Label {
            text: "ROTATE ABOUT AXIS:"
            color: root.secondaryText
            font.family: titleFont.font.family
            font.pointSize: 14
            visible: false
        }

        RotationTool {
            id: xRot
            title: "X"
            handleColour: "red"
            bgContainer: controls
            Layout.leftMargin: 15
            visible: false
        }

        RotationTool {
            id: yRot
            title: "Y"
            handleColour: "green"
            bgContainer: controls
            Layout.leftMargin: 15
            visible: false
        }

        RotationTool {
            id: zRot
            title: "Z"
            handleColour: "blue"
            bgContainer: controls
            Layout.leftMargin: 15
            visible: false
        }
    }
}
        