import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

Item {
    id: align
    property string cadFile: root.cadFile 
    property string scanFile: root.scanFile

    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onDisplayAligned(cadSource, scanSource, dist, percent) {
            loadingScreen.on = false
            cad.source = cadSource
            scan.source = scanSource
            //hdButton.enabled = true
            distLabel.text = dist.toFixed(3)
            percentLabel.text = (Math.round(percent * 10) / 10).toFixed(1) + "%"
        }
        function onSetFilename(scanFlag) {
            if (scanFlag) {
                scanFile = root.scanFile
                scanControl.fileColor = root.secondaryText
            } else {
                cadFile = root.cadFile
                cadControl.fileColor = root.secondaryText
            }
        }
        // function onHausdorffOutput(dist, percent) {
        //     distLabel.text = (Math.round(dist * 10) / 10).toFixed(3)
        //     percentLabel.text = (Math.round(percent * 10) / 10).toFixed(1)
        // }
    }

    View3D {
        id: view3D
        anchors.fill: parent
        environment: sceneEnvironment

        camera: OrthographicCamera {
            id: camera
            property double zoomX: 1
            property double zoomY: 1
            clipNear: -9999
            pivot: cad.pivot
            horizontalMagnification: zoomX
            verticalMagnification: zoomY
            eulerRotation: Qt.vector3d(-20.4556, 52.6713, 0)
        }

        MeshLighting {
            target: cad
            targetColor: cadControl.sliderColor
            camera: camera
        }

        RuntimeLoader {
            id: cad
            property vector3d dimensions
            scale:  Qt.vector3d(5,5,5)
        }

        MeshLighting {
            target: scan
            targetColor: scanControl.sliderColor
            camera: camera
        }

        RuntimeLoader {
            id: scan
            property vector3d dimensions
            scale:  Qt.vector3d(5,5,5)
        }

        // Timer { 
        //     interval: 1000; repeat: true; running: true
        //     onTriggered: {
        //         console.log("Position:", camera.position)
        //         console.log("Rotation:", camera.eulerRotation)
        //         console.log(" ")
        //     }
        // }

        SceneEnvironment {
            id: sceneEnvironment
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
            backgroundMode: SceneEnvironment.Color
            clearColor: root.bgColor 
        }

        MeshController {
            anchors.fill: parent
            scene: view3D
            camera: camera
            target: camera
        }

        AxisHelper {
            //enableXZGrid: false // Model kept in XY plane
            //enableXYGrid: true
            enableAxisLines: true
            gridColor: root.secondaryText
        }
    }

    // Algorithm running indicator
    BusyText {
        id: loadingScreen
        anchors.centerIn: view3D
        width: 200
        height: 150
        busyText: "Calculating alignment..."
        on: false
    }
    //-------------------------------------------------//
    // Menu for uploading files and button controls
    //-------------------------------------------------//
    Rectangle {
        id: topMenu
        opacity: 0.9
        color: root.menuColor
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.left: parent.left; anchors.leftMargin: 16
        implicitHeight: 230
        implicitWidth: 500
        radius: height/6

        ColumnLayout {
            spacing: 16
            //anchors.centerIn: parent
            anchors { left: parent.left; right: parent.right; 
                    verticalCenter: parent.verticalCenter; margins: 24 }

            AlignControls {
                id: cadControl
                scanFlag: false
                Layout.fillWidth: true
                Layout.preferredHeight: 28
            }

            AlignControls {
                id: scanControl
                scanFlag: true
                Layout.fillWidth: true
                Layout.preferredHeight: 28
            }

            RowLayout {
                spacing: 16
                //Layout.alignment: Qt.AlignCenter
                Label {
                    text: "CORRECTIVE SCALING:" //"Allow for corrective scaling?"
                    color: root.secondaryText
                    font.family: titleFont.font.family
                    font.pointSize: 12
                    //font.weight: Font.DemiBold
                }
                Button {
                    id: toggleScale
                    property bool toggle: false
                    text: (toggle) ? "ENABLED" : "DISABLED"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    //font.weight: Font.DemiBold
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: {
                        if (toggle) { toggle = false }
                        else { toggle = true }
                    }
                }
            }

            // RowLayout {
            //     spacing: 16
                Button {
                    id: alignButton
                    //anchors.bottom: parent.bottom
                    Layout.alignment: Qt.AlignCenter
                    text: "ALIGN AND COMPARE MESHES" //"Align Scan to CAD"
                    font.family: titleFont.font.family
                    font.weight: Font.DemiBold
                    font.pointSize: 13
                    palette.buttonText: root.menuColor
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: {
                        var error = false
                        // Turn labels red to indicate error if no file selected
                        if (align.scanFile == "No model selected.") {
                            scanControl.fileColor = "red"
                            error = true
                        } if (align.cadFile == "No model selected.") {
                            cadControl.fileColor = "red"
                            error = true
                        // Reset loader sources and run alignment from backend
                        } if (!error) {
                            cad.source = " "
                            scan.source = " "
                            loadingScreen.on = true
                            backend.alignMeshes(align.cadFile, align.scanFile, toggleScale.toggle)
                        }
                    }
                // }

                // Button {
                //     id: hdButton
                //     Layout.alignment: Qt.AlignCenter
                //     enabled: false
                //     text: "Calculate Similarity"
                //     font.family: titleFont.font.family
                //     font.weight: Font.DemiBold
                //     font.pointSize: 14
                //     palette.buttonText: root.menuColor
                //     background: Rectangle { color: root.textColor; radius: height/6 }
                //     onClicked: {
                //         backend.hausdorff(cad.source, scan.source)
                //         loadingScreen.on = true
                //         loadingScreen.busyText = "Calculating similarity..."
                //     }
                // }
            }
        }
    }

    Rectangle {
        id: results
        color: root.menuColor
        opacity: 0.8
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.right: parent.right; anchors.rightMargin: 16
        implicitHeight: 200
        implicitWidth: 200
        radius: height/6

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            Label {
                id: distLabel
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                text: "-"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 30
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                text: "Average Squared Distance"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                text: "Between Meshes"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                color: root.menuColor
                opacity: 0
                implicitHeight: 10
                implicitWidth: 10
            }
            Label {
                id: percentLabel
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                text: "-"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 30
                font.weight: Font.DemiBold
            }
            Label {
                text: "Similarity Percentage"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
}