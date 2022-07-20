import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

Item {
    id: align

    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Align") {
                if (scanFlag) {
                    scan.source = "backend_resources/converted_mesh/scan_align.glb"
                    scan.pivot = centroid
                    scan.dimensions = dim
                } else {
                    cad.source = "backend_resources/converted_mesh/cad_align.glb"
                    cad.pivot = centroid
                    cad.dimensions = dim
                }
            loadingScreen.on = false
            }
        }
        function onDisplayAligned(centroid, dist, percent) {
            loadingScreen.on = false
            // Set source URLs of aligned output
            cad.source = "backend_resources/converted_mesh/cad_align.glb"
            scan.source = "backend_resources/converted_mesh/scan_align.glb"
            // Display results
            results.dist = dist.toFixed(3)
            results.percent = (Math.round(percent * 10) / 10).toFixed(1) + "%"
            // Reset all Node properties to default
            cad.scale = scan.scale = Qt.vector3d(5, 5, 5)
            cad.eulerRotation = scan.eulerRotation = Qt.vector3d(0, 0, 0)
            cad.position = scan.position = Qt.vector3d(0, 0, 0)
            // Set centroids and controls to camera
            cad.pivot = scan.pivot = camera.pivot = centroid
            setMouseControl("CAMERA")
        }
    }

    function setMouseControl(mode) {
        switch(mode) {
            case "CAD":
                userControl.target = cad;
                userControl.keysEnabled = true;
                break;
            case "SCAN":
                userControl.target = scan;
                userControl.keysEnabled = true;
                break;
            case "CAMERA":
                userControl.target = camera;
                userControl.keysEnabled = false;
                break;
        }
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
        //         // console.log("Position:", camera.position)
        //         // console.log("Rotation:", scan.sceneTransform)
        //         console.log(sceneEnvironment.clearColor)
        //         sceneEnvironment.clearColor = "white"
        //         console.log(sceneEnvironment.clearColor)
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
            id: userControl
            anchors.fill: parent
            scene: view3D
            camera: camera
            target: camera
            keysEnabled: false
        }

        AxisHelper {
            enableAxisLines: true
            gridColor: root.secondaryText
        }
    }

    // Running Indicator
    BusyText {
        id: loadingScreen
        anchors.centerIn: view3D
        width: 200
        height: 150
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
        implicitHeight: 300
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
                Label {
                    text: "MOUSE CONTROLS:"
                    color: root.secondaryText
                    font.family: titleFont.font.family
                    font.pointSize: 12
                }
                Button {
                    text: "CAD"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: setMouseControl(text)
                }
                Button {
                    text: "SCAN"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: setMouseControl(text)
                }
                Button {
                    text: "CAMERA"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: setMouseControl(text)
                }
            }

            RowLayout {
                spacing: 16
                //Layout.alignment: Qt.AlignCenter
                Label {
                    text: "CORRECTIVE SCALING:"
                    color: root.secondaryText
                    font.family: titleFont.font.family
                    font.pointSize: 12
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
                    onClicked: toggle = !toggle
                }
            }

            Button {
                id: alignButton
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
                        backend.alignMeshes(cad.source, scan.source, cad.sceneTransform,
                                                    scan.sceneTransform, toggleScale.toggle)
                        cad.source = scan.source = " "
                    }
                }
            }
        }
    }

    ResultWidget {
        id: results
        anchors { top: parent.top; topMargin: 16;
                    right: parent.right; rightMargin: 16 }
        distText: "Average Squared Distance \n Between Meshes"
        percentText: "Similarity Percentage"
    }
}