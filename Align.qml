import QtQuick
import QtQuick.Controls
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

        // Display results of the ICP algorithm to user
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
            cad.pivot = scan.pivot = camera.pivot = centroid
            // Set user controls back to camera
            mouseButton.text = "CAMERA"
            userControl.target = camera
            userControl.keysEnabled = false
        }
    }

    // 3D scene for rendering the models
    View3D {
        id: view3D
        anchors.fill: parent

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

        // CAD model's node
        RuntimeLoader {
            id: cad
            property vector3d dimensions
            scale:  Qt.vector3d(5,5,5)
        }

        MeshLighting {
            target: cad
            targetColor: cadControl.sliderColor
            camera: camera
        }

        // 3D Scan's node
        RuntimeLoader {
            id: scan
            property vector3d dimensions
            scale:  Qt.vector3d(5,5,5)
        }

        MeshLighting {
            target: scan
            targetColor: scanControl.sliderColor
            camera: camera
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

        // Mouse controls for zooming/rotation
        MeshController {
            id: userControl
            anchors.fill: parent
            scene: view3D
            camera: camera
            target: camera
            keysEnabled: false
        }

        // Gridlines
        AxisHelper {
            enableAxisLines: true
            gridColor: root.secondaryText
        }

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
            backgroundMode: SceneEnvironment.Color
            clearColor: root.bgColor 
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

    // Toggle menu for user's mouse control
    Rectangle {
        id: mouseMenu
        anchors { horizontalCenter: parent.horizontalCenter
            top: parent.top; topMargin: 16 }
        opacity: 0.9
        color: root.menuColor
        implicitHeight: 56
        implicitWidth: 150
        radius: height/5

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -8

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "Mouse controls:"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 8
            }

            Button {
                id: mouseButton
                Layout.alignment: Qt.AlignCenter
                text: "CAMERA"
                palette.buttonText: root.selectedColor
                font.family: titleFont.font.family
                font.pointSize: 18
                background: Rectangle { opacity: 0 }

                onClicked: {
                    switch(mouseButton.text) {
                        case "CAMERA":
                            mouseButton.text = "CAD"
                            userControl.target = cad
                            userControl.keysEnabled = true
                            break

                        case "CAD":
                            mouseButton.text = "SCAN"
                            userControl.target = scan
                            userControl.keysEnabled = true
                            break

                        case "SCAN":
                            mouseButton.text = "CAMERA"
                            userControl.target = camera
                            userControl.keysEnabled = false
                            break
                    }
                }
            }
        }
    }

    // Dropdown menu for CAD model controls
    AlignControls {
        id: cadControl
        anchors { right: mouseMenu.left; rightMargin: 32
                verticalCenter: mouseMenu.verticalCenter }
        scanFlag: false
    }

    // Dropdown menu for 3D scan controls
    AlignControls {
        id: scanControl
        anchors { left: mouseMenu.right; leftMargin: 32
                verticalCenter: mouseMenu.verticalCenter }
        scanFlag: true
    }

    // Menu for running alignment/comparison algorithm
    Rectangle {
        id: algoMenu
        //anchors { top: parent.top; right: results.left; margins: 16 }
        anchors { bottom: parent.bottom; left: parent.left; margins: 16 }
        opacity: 0.9
        color: root.menuColor
        height: algoColumn.height * 1.5
        width: algoColumn.width * 1.25
        radius: height/6

        ColumnLayout {
            id: algoColumn
            spacing: 8
            // anchors { //left: parent.left; right: parent.right; 
            //         verticalCenter: parent.verticalCenter; margins: 24 }
            anchors.centerIn: parent

            RowLayout {
                spacing: 16
                //Layout.alignment: Qt.AlignCenter
                Label {
                    text: "CORRECTIVE SCALING:"
                    color: root.secondaryText
                    font.family: titleFont.font.family
                    font.pointSize: 11
                }
                Button {
                    id: toggleScale
                    property bool toggle: false
                    text: (toggle) ? "ENABLED" : "DISABLED"
                    palette.buttonText: root.bgColor
                    font.family: titleFont.font.family
                    font.pointSize: 10
                    //font.weight: Font.DemiBold
                    background: Rectangle { radius: height/6;
                                color: (parent.toggle) ? root.selectedColor : root.textColor;}
                    onClicked: toggle = !toggle
                }
            }

            Button {
                id: alignButton
                Layout.alignment: Qt.AlignCenter
                text: "ALIGN AND COMPARE MESHES"
                font.family: titleFont.font.family
                font.pointSize: 11
                palette.buttonText: root.bgColor
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
        anchors { bottom: algoMenu.top; bottomMargin: 16; left: algoMenu.left}
        distText: "Average Squared Distance \n Between Meshes"
        percentText: "Similarity Percentage"
    }
}